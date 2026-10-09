"""Settle a company prize race when it ends.

Prize DIA, top-percent SHARE, finisher VALUE, and the company km donation
come from ``config/company_tournament``. Entry fees are not a prize pool.
Bonus DIA is free DIA. The monthly cap is ``monthlyCompanyPrizeCapDia``;
a prize that does not fit is capped or held and written to the ledger.
A final race stays outside that cap unless ``finalCountsTowardMonthlyCap``
is true. When ``finalFrequency`` is ``season``, one final edition can be
opened or settled per ``prizeSeasonId``.

Calling settle again does not pay twice. A verified finish is stored on
the participant by the run-validation transaction, then this module ranks
those rows.
"""

from copy import deepcopy
from datetime import datetime, timezone
import logging

from fastapi import HTTPException
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.ops_result import CreatePrizeRaceResult, PrizeSettlementResult
from app.services.company_tournament_config import (
    COMPANY_TOURNAMENT_CONFIG_ID,
    FINAL_SEASON_TAKEN,
    beginner_dia_season_blocked,
    prize_claim_reason,
    prize_tier_id,
    resolve_account_created_at,
    resolve_company_tournament_config,
    ticket_edition_bounds,
    ticket_is_open,
    ticket_reward_for_rank,
    ticket_reward_label,
    ticket_share_label,
    tournament_edition,
    verified_runs_in_window,
)
from app.services.donation_cap import (
    DONATION_MONTH_TOTALS,
    month_total_won,
    read_monthly_cap_won,
    won_within_cap,
)
from app.services.streak_protection import kst_month_key
from app.services.wallet_funding import move_currency

logger = logging.getLogger(__name__)

PRIZE_POOLS = "companyPrizePools"
FINAL_SEASONS = "companyFinalSeasons"
DONATION_POOLS = "companyDonationPools"
DONATION_LEDGER = "donationLedger"
_BATCH_LIMIT = 450


class _Payout:
    def __init__(self, uid: str, rank: int, distance_km: float, duration_seconds: float) -> None:
        self.uid = uid
        self.rank = rank
        self.distance_km = distance_km
        self.duration_seconds = duration_seconds
        self.dia_requested = 0
        self.dia_paid = 0
        self.dia_status = "none"
        self.share = 0
        self.value = 0
        self.donation_krw = 0
        self.activity_id: str | None = None
        self.ineligible_reason: str | None = None
        self.dia_zero_reason: str | None = None
        self.ticket_kind: str | None = None
        self.ticket_target: str | None = None
        self.ticket_label: str | None = None
        self.ticket_share = 0
        self.ticket_reason: str | None = None
        self.ticket_already = False
        self.valid_after = 0
        self.valid_through = 0


def prize_finish_fields(
    tournament: dict,
    participant: dict,
    *,
    distance_km: float,
    duration_seconds: int | float,
    activity_id: str,
) -> dict | None:
    """Best verified finish for a prize race. Slower repeats are ignored."""
    if prize_tier_id(tournament) is None or tournament.get("prizeSettled") is True:
        return None
    distance = _number(distance_km)
    duration = _number(duration_seconds)
    if distance is None or distance <= 0 or duration is None or duration <= 0:
        return None
    target = _number(tournament.get("targetDistanceKm")) or 0
    if target > 0 and distance + 1e-9 < target:
        return None
    if participant.get("verifiedFinish") is True:
        previous = _number(participant.get("durationSeconds"))
        if previous is not None and duration >= previous:
            return None
    return {
        "verifiedFinish": True,
        "distanceKm": distance,
        "durationSeconds": duration,
        "finishActivityId": activity_id,
    }


def plan_payouts(config: dict, tier_id: str, finishers: list[dict]) -> list[_Payout]:
    """Rank verified finishers and attach config amounts. No wallet writes."""
    tier = config["tiers"][tier_id]
    prizes = tier["prizeDiaByRank"]
    ranked = sorted(finishers, key=lambda row: (row["duration_seconds"], row["uid"]))
    payouts: list[_Payout] = []
    per_km = int(config["finisherValueTokensPerKm"])
    krw_per_km = int(config["companyDonationKrwPerKm"])
    for index, row in enumerate(ranked, start=1):
        payout = _Payout(
            row["uid"],
            index,
            float(row["distance_km"]),
            float(row["duration_seconds"]),
        )
        payout.dia_requested = int(prizes.get(str(index), 0))
        payout.value = int(payout.distance_km * per_km)
        payout.activity_id = row.get("activity_id")
        # The finishing run was validated through the run donation path, which
        # already recorded (or capped) this km under verified_run_{id}.
        if not payout.activity_id:
            payout.donation_krw = int(round(payout.distance_km * krw_per_km))
        payouts.append(payout)

    percent = int(config["topPercent"])
    slots = (len(payouts) * percent) // 100 if percent > 0 else 0
    if config.get("topPercentExcludesPrizeRanks", True):
        candidates = [payout for payout in payouts if payout.dia_requested <= 0]
    else:
        candidates = payouts
    share_each = int(tier["top10PercentShare"])
    for payout in candidates[:slots]:
        payout.share = share_each
    return payouts


def assign_dia_budget(payouts: list[_Payout], budget: int) -> None:
    """Spend the reserved bonus-DIA budget from rank 1 downward."""
    remaining = max(0, budget)
    for payout in payouts:
        if payout.ineligible_reason:
            payout.dia_paid = 0
            payout.dia_status = "ineligible"
            continue
        if payout.dia_zero_reason:
            payout.dia_paid = 0
            payout.dia_status = "season_limited"
            continue
        requested = payout.dia_requested
        if requested <= 0:
            payout.dia_paid = 0
            payout.dia_status = "none"
            continue
        if remaining <= 0:
            payout.dia_paid = 0
            payout.dia_status = "held"
            continue
        if requested <= remaining:
            payout.dia_paid = requested
            payout.dia_status = "paid"
            remaining -= requested
            continue
        payout.dia_paid = remaining
        payout.dia_status = "capped"
        remaining = 0


def settle_company_prize_race(
    db,
    tournament_id: str,
    now: datetime | None = None,
) -> PrizeSettlementResult:
    if not tournament_id or "/" in tournament_id:
        raise HTTPException(status_code=400, detail="Invalid tournament id.")
    current = now or datetime.now(timezone.utc)
    month = kst_month_key(current)
    tournament_ref = db.collection("tournaments").document(tournament_id)
    snapshot = tournament_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Tournament does not exist.")
    tournament = snapshot.to_dict() or {}
    if tournament.get("prizeSettled") is True:
        return _result(
            tournament_id,
            "already_settled",
            "Prize settlement was already recorded.",
            tournament.get("prizeSettlement") or {},
        )

    tier_id = prize_tier_id(tournament)
    if tier_id is None:
        raise HTTPException(status_code=400, detail="Not a company prize race.")
    config = _load_config(db)
    if not tier_id or tier_id not in config["tiers"]:
        raise HTTPException(status_code=400, detail="Unknown prize tier.")
    status = tournament.get("status") or "recruiting"
    if status not in {"active", "finished"}:
        raise HTTPException(
            status_code=400,
            detail="Only an active or finished prize race can be settled.",
        )

    final_season = ensure_final_season_slot(
        db, config, tier_id, tournament_id, tournament
    )
    target = _number(tournament.get("targetDistanceKm")) or 0
    finishers: list[dict] = []
    participant_refs: dict = {}
    for doc_id, data, ref in _participants(db, tournament_id):
        row = _finisher_row(doc_id, data, target)
        if row is None:
            continue
        finishers.append(row)
        participant_refs[row["uid"]] = ref

    payouts = plan_payouts(config, tier_id, finishers)
    accounts = _require_accounts(db, payouts)
    _mark_ineligible_claims(db, payouts, accounts, config, current)
    _apply_beginner_dia_limit(db, payouts, config, tier_id, tournament_id)
    _attach_ticket_rewards(db, payouts, config, tier_id, tournament_id, tournament)
    cap = int(config["monthlyCompanyPrizeCapDia"])
    requested = sum(
        payout.dia_requested
        for payout in payouts
        if not payout.ineligible_reason and not payout.dia_zero_reason
    )
    if tier_id == "final" and config.get("finalCountsTowardMonthlyCap") is not True:
        budget = requested
    else:
        budget = _reserve_prize_budget(db, month, tournament_id, requested, cap)
    assign_dia_budget(payouts, budget)
    _apply_monthly_donation_cap(db, payouts, month, tournament_id)
    donation_krw = sum(payout.donation_krw for payout in payouts)
    _record_donation_total(db, month, tournament_id, donation_krw)

    batch = _Batch(db)
    for payout in payouts:
        _apply_payout(
            db,
            batch,
            payout,
            accounts[payout.uid],
            participant_refs[payout.uid],
            tournament_id=tournament_id,
            tier_id=tier_id,
            month=month,
            cap=cap,
            value_rule=str(config["finisherValueRule"]),
            tokens_per_km=int(config["finisherValueTokensPerKm"]),
            krw_per_km=int(config["companyDonationKrwPerKm"]),
            season_id=str(config["prizeSeasonId"]),
        )
        batch.flush_if_full()

    _advance_settled_edition(batch, db, tier_id, tournament)
    summary = _summary(payouts, month, tier_id, cap, donation_krw)
    held = summary["heldDia"]
    if held > 0:
        reason = (
            f"Settled. {held} bonus DIA was capped or held by the monthly "
            f"company prize cap of {cap} DIA."
        )
    else:
        reason = "Prize race settled from server config. Entry fees were not used."
    finished = {
        "status": "finished",
        "prizeSettled": True,
        "prizeSettlement": summary,
        "updatedAt": SERVER_TIMESTAMP,
    }
    if final_season is not None:
        finished["prizeSeasonId"] = final_season
    batch.update(tournament_ref, finished)
    batch.commit()
    return _result(tournament_id, "settled", reason, summary)


def ensure_final_season_slot(
    db,
    config: dict,
    tier_id: str,
    tournament_id: str,
    tournament: dict | None = None,
) -> str | None:
    """Claim the season final. The same tournament id can retry."""
    if tier_id != "final" or config.get("finalFrequency") != "season":
        return None
    season_id = _final_season_id(config, tournament)
    _claim_final_season(db, season_id, tournament_id)
    return season_id


def create_company_prize_race(
    db,
    tournament_id: str,
    tier: str,
    edition: int,
) -> CreatePrizeRaceResult:
    """Open one prize-race edition. A second final in the season is rejected."""
    if not tournament_id or "/" in tournament_id:
        raise HTTPException(status_code=400, detail="Invalid tournament id.")
    if isinstance(edition, bool) or not isinstance(edition, int) or edition < 1:
        raise HTTPException(status_code=400, detail="Invalid edition.")
    if not isinstance(tier, str) or not tier.strip():
        raise HTTPException(status_code=400, detail="Unknown prize tier.")
    config = _load_config(db)
    tier_id = tier.strip().lower()
    tier_row = config["tiers"].get(tier_id)
    if tier_row is None:
        raise HTTPException(status_code=400, detail="Unknown prize tier.")

    ref = db.collection("tournaments").document(tournament_id)
    snapshot = ref.get()
    if snapshot.exists:
        existing = snapshot.to_dict() or {}
        if prize_tier_id(existing) != tier_id or tournament_edition(existing) != edition:
            raise HTTPException(status_code=409, detail="Tournament id is already used.")
        season_id = ensure_final_season_slot(db, config, tier_id, tournament_id, existing)
        if season_id is not None and not isinstance(existing.get("prizeSeasonId"), str):
            _save(db, ref, {"prizeSeasonId": season_id, "updatedAt": SERVER_TIMESTAMP})
        return _create_result(
            tournament_id,
            tier_id,
            edition,
            season_id,
            "already_created",
            "Prize race edition was already opened.",
        )

    season_id = ensure_final_season_slot(db, config, tier_id, tournament_id, None)
    payload = {
        "title": tier_row["labelKo"],
        "prizeTier": tier_id,
        "edition": edition,
        "status": "recruiting",
        "participantCount": 0,
        "targetDistanceKm": 0,
        "minParticipantsBep": int(tier_row["minEntrants"]),
        "maxParticipants": int(tier_row["maxEntrants"]),
        "entryFeeShare": int(tier_row["entryShare"]),
        "requiredTier": 1,
        "createdAt": SERVER_TIMESTAMP,
        "updatedAt": SERVER_TIMESTAMP,
    }
    if season_id is not None:
        payload["prizeSeasonId"] = season_id
    _save(db, ref, payload)
    return _create_result(
        tournament_id,
        tier_id,
        edition,
        season_id,
        "created",
        "Prize race edition opened.",
    )


def _final_season_id(config: dict, tournament: dict | None) -> str:
    if isinstance(tournament, dict):
        raw = tournament.get("prizeSeasonId")
        if isinstance(raw, str):
            season = raw.strip()
            if season and len(season) <= 32:
                return season
    return str(config["prizeSeasonId"])


def _claim_final_season(db, season_id: str, tournament_id: str) -> None:
    ref = db.collection(FINAL_SEASONS).document(season_id)

    def apply(data: dict | None) -> dict | None:
        current = (data or {}).get("tournamentId")
        if isinstance(current, str) and current:
            if current == tournament_id:
                return None
            logger.warning(
                "Final season already claimed: season %s owner %s rejected %s",
                season_id,
                current,
                tournament_id,
            )
            raise HTTPException(status_code=409, detail=FINAL_SEASON_TAKEN)
        return {
            "seasonId": season_id,
            "tournamentId": tournament_id,
            "updatedAt": SERVER_TIMESTAMP,
        }

    if getattr(db, "store", None) is not None:
        payload = apply(_read(ref))
        if payload is not None:
            _save(db, ref, payload)
        return

    @firestore.transactional
    def _tx(transaction):
        snapshot = ref.get(transaction=transaction)
        data = snapshot.to_dict() if snapshot.exists else None
        payload = apply(data)
        if payload is not None:
            transaction.set(ref, payload, merge=True)

    _tx(db.transaction())


def _create_result(
    tournament_id: str,
    tier_id: str,
    edition: int,
    season_id: str | None,
    status: str,
    reason: str,
) -> CreatePrizeRaceResult:
    return CreatePrizeRaceResult(
        accepted=True,
        tournament_id=tournament_id,
        tier=tier_id,
        edition=edition,
        season_id=season_id,
        status=status,
        reason=reason,
    )


def _apply_payout(
    db,
    batch: "_Batch",
    payout: _Payout,
    user: dict,
    participant_ref,
    *,
    tournament_id: str,
    tier_id: str,
    month: str,
    cap: int,
    value_rule: str,
    tokens_per_km: int,
    krw_per_km: int,
    season_id: str,
) -> None:
    user_ref = db.collection("users").document(payout.uid)
    dia_ref = _wallet_ref(db, f"tournament_prize_{tournament_id}_{payout.uid}")
    share_ref = _wallet_ref(db, f"tournament_share_{tournament_id}_{payout.uid}")
    value_ref = _wallet_ref(db, f"tournament_value_{tournament_id}_{payout.uid}")
    donation_ref = _tournament_donation_ref(db, tournament_id, payout.uid)
    grant_ref = _wallet_ref(db, f"tournament_ticket_{tournament_id}_{payout.uid}")
    ticket_share_ref = _wallet_ref(
        db, f"tournament_ticket_share_{tournament_id}_{payout.uid}"
    )
    dia_exists = dia_ref.get().exists
    share_exists = share_ref.get().exists
    value_exists = value_ref.get().exists
    donation_exists = donation_ref.get().exists
    grant_exists = grant_ref.get().exists
    ticket_share_exists = ticket_share_ref.get().exists

    wallet = dict(user.get("wallet") or {})
    updates: dict = {}
    if payout.dia_paid > 0 and not dia_exists:
        moved = move_currency(wallet, diamond=payout.dia_paid)
        updates.update(moved["updates"])
        dia_ledger = moved["ledger"]
    else:
        dia_ledger = {}
    if payout.share > 0 and not share_exists:
        moved = move_currency(wallet, share=payout.share)
        updates.update(moved["updates"])
        share_ledger = moved["ledger"]
    else:
        share_ledger = {}
    if payout.value > 0 and not value_exists:
        updates["wallet.valueTokenBalance"] = firestore.Increment(payout.value)
    ticket_share_ledger: dict = {}
    if (
        payout.ticket_kind == "share"
        and payout.ticket_share > 0
        and not ticket_share_exists
        and not payout.ticket_already
    ):
        moved = move_currency(wallet, share=payout.ticket_share)
        updates.update(moved["updates"])
        ticket_share_ledger = moved["ledger"]
    if updates:
        batch.update(user_ref, {**updates, "updatedAt": SERVER_TIMESTAMP})

    if payout.dia_requested > 0 and not dia_exists and not payout.ineligible_reason:
        if payout.dia_status in {"held", "capped"}:
            logger.warning(
                "Company prize %s: tournament %s uid %s rank %s requested %s "
                "paid %s held %s month %s cap %s reason monthly_company_prize_cap",
                payout.dia_status,
                tournament_id,
                payout.uid,
                payout.rank,
                payout.dia_requested,
                payout.dia_paid,
                payout.dia_requested - payout.dia_paid,
                month,
                cap,
            )
        row = {
            "uid": payout.uid,
            "tournamentId": tournament_id,
            "type": "tournament_prize_dia",
            "prizeTier": tier_id,
            "rank": payout.rank,
            "diamondAmount": payout.dia_paid,
            "requestedDia": payout.dia_requested,
            "heldDia": payout.dia_requested - payout.dia_paid,
            "prizeStatus": payout.dia_status,
            "bonusDia": True,
            "fundedByEntryFees": False,
            "monthKey": month,
            "capDia": cap,
            "createdAt": SERVER_TIMESTAMP,
            **dia_ledger,
        }
        if payout.dia_status in {"held", "capped"}:
            row["capReason"] = "monthly_company_prize_cap"
        if payout.dia_zero_reason:
            row["heldDia"] = 0
            row["zeroReason"] = payout.dia_zero_reason
        if payout.dia_paid <= 0:
            row["diamondFreeAmount"] = 0
            row["diamondPaidAmount"] = 0
        batch.set(dia_ref, row)
        if (
            tier_id == "beginner"
            and payout.dia_status in {"paid", "capped", "held"}
            and not payout.dia_zero_reason
        ):
            _remember_beginner_dia(db, batch, payout.uid, season_id, tournament_id)

    if payout.share > 0 and not share_exists:
        batch.set(
            share_ref,
            {
                "uid": payout.uid,
                "tournamentId": tournament_id,
                "type": "tournament_top_percent_share",
                "prizeTier": tier_id,
                "rank": payout.rank,
                "shareAmount": payout.share,
                "fundedByEntryFees": False,
                "createdAt": SERVER_TIMESTAMP,
                **share_ledger,
            },
        )

    if payout.value > 0 and not value_exists:
        batch.set(
            value_ref,
            {
                "uid": payout.uid,
                "tournamentId": tournament_id,
                "type": "tournament_finisher_value",
                "prizeTier": tier_id,
                "rank": payout.rank,
                "valueAmount": payout.value,
                "distanceKm": payout.distance_km,
                "tokensPerKm": tokens_per_km,
                "valueRule": value_rule,
                "fundedByEntryFees": False,
                "createdAt": SERVER_TIMESTAMP,
            },
        )

    _write_ticket_grant(
        db,
        batch,
        payout,
        tournament_id=tournament_id,
        tier_id=tier_id,
        grant_ref=grant_ref,
        grant_exists=grant_exists,
        ticket_share_ref=ticket_share_ref,
        ticket_share_exists=ticket_share_exists,
        ticket_share_ledger=ticket_share_ledger,
    )

    if payout.donation_krw > 0 and not donation_exists:
        batch.set(
            donation_ref,
            {
                "uid": payout.uid,
                "tournamentId": tournament_id,
                "type": "tournament_km_donation",
                "prizeTier": tier_id,
                "rank": payout.rank,
                "distanceKm": payout.distance_km,
                "krwPerKm": krw_per_km,
                "companyWon": payout.donation_krw,
                "monthKey": month,
                "sponsorName": "SRC",
                "donationTarget": "UNICEF",
                "receiptIssued": False,
                "fundedByEntryFees": False,
                "createdAt": SERVER_TIMESTAMP,
            },
        )

    participant_update = {
        "prizeSettled": True,
        "finishRank": payout.rank,
        "prizeDiaPaid": payout.dia_paid,
        "prizeDiaRequested": payout.dia_requested,
        "prizeDiaStatus": payout.dia_status,
        "topPercentShare": payout.share,
        "finisherValue": payout.value,
        "companyDonationKrw": payout.donation_krw,
        "settledAt": SERVER_TIMESTAMP,
    }
    if payout.ineligible_reason:
        participant_update["prizeIneligibleReason"] = payout.ineligible_reason
    if payout.dia_zero_reason:
        participant_update["prizeZeroReason"] = payout.dia_zero_reason
    if payout.ticket_label:
        participant_update["ticketRewardLabel"] = payout.ticket_label
        participant_update["ticketRewardKind"] = payout.ticket_kind
        participant_update["ticketTargetTier"] = payout.ticket_target
    batch.update(participant_ref, participant_update)


def _summary(
    payouts: list[_Payout],
    month: str,
    tier_id: str,
    cap: int,
    donation_krw: int,
) -> dict:
    paid = sum(payout.dia_paid for payout in payouts)
    held = sum(
        payout.dia_requested - payout.dia_paid
        for payout in payouts
        if payout.dia_requested > 0
        and not payout.ineligible_reason
        and not payout.dia_zero_reason
    )
    return {
        "status": "settled",
        "monthKey": month,
        "tier": tier_id,
        "finisherCount": len(payouts),
        "paidDia": paid,
        "heldDia": held,
        "sharePaid": sum(payout.share for payout in payouts),
        "valuePaid": sum(payout.value for payout in payouts),
        "donationKrw": donation_krw,
        "capDia": cap,
        "fundedByEntryFees": False,
        "ticketsGranted": sum(1 for payout in payouts if payout.ticket_kind == "ticket"),
        "ticketSharePaid": sum(
            payout.ticket_share for payout in payouts if payout.ticket_kind == "share"
        ),
    }


def _result(tournament_id: str, status: str, reason: str, summary: dict) -> PrizeSettlementResult:
    return PrizeSettlementResult(
        accepted=True,
        tournament_id=tournament_id,
        status=status,
        finisher_count=int(summary.get("finisherCount") or 0),
        paid_dia=int(summary.get("paidDia") or 0),
        held_dia=int(summary.get("heldDia") or 0),
        share_paid=int(summary.get("sharePaid") or 0),
        value_paid=int(summary.get("valuePaid") or 0),
        donation_krw=int(summary.get("donationKrw") or 0),
        reason=reason,
    )


def _mark_ineligible_claims(db, payouts: list[_Payout], accounts: dict, config: dict, now: datetime) -> None:
    window = int(config["prizeClaimVerifiedRunWindowDays"])
    for payout in payouts:
        if payout.dia_requested <= 0:
            continue
        user = accounts[payout.uid]
        reason = prize_claim_reason(
            identity_verified=user.get("identityVerified") is True,
            created_at=resolve_account_created_at(user, payout.uid),
            verified_runs=verified_runs_in_window(db, payout.uid, now, window),
            config=config,
            now=now,
        )
        if not reason:
            continue
        payout.ineligible_reason = reason
        logger.warning(
            "Company prize ineligible: uid %s rank %s requested %s reason %s",
            payout.uid,
            payout.rank,
            payout.dia_requested,
            reason,
        )


def _apply_beginner_dia_limit(db, payouts, config, tier_id: str, tournament_id: str) -> None:
    if tier_id != "beginner":
        return
    limit = int(config["beginnerDiaPrizeLimitPerSeason"])
    season = str(config["prizeSeasonId"])
    for payout in payouts:
        if payout.dia_requested <= 0 or payout.ineligible_reason:
            continue
        recognized = _beginner_dia_ids(db, payout.uid, season)
        if not beginner_dia_season_blocked(recognized, tournament_id, limit):
            continue
        payout.dia_zero_reason = "beginner_dia_season_limit"
        logger.warning(
            "Beginner DIA season limit: uid %s tournament %s rank %s season %s "
            "recognized %s limit %s reason beginner_dia_season_limit",
            payout.uid,
            tournament_id,
            payout.rank,
            season,
            len(recognized),
            limit,
        )


def _attach_ticket_rewards(db, payouts, config, tier_id, tournament_id, tournament) -> None:
    tier = config["tiers"][tier_id]
    source_edition = tournament_edition(tournament)
    for payout in payouts:
        reward = ticket_reward_for_rank(tier, payout.rank)
        if reward is None:
            continue
        target = str(reward["targetTier"])
        payout.ticket_target = target
        existing = _existing_ticket_grant(db, payout.uid, tournament_id, config, target)
        if existing is not None:
            payout.ticket_already = True
            payout.ticket_kind = existing["kind"]
            payout.ticket_share = existing["share"]
            payout.ticket_label = existing["label"]
            continue
        holds = _holds_open_ticket(db, payout.uid, target)
        registered = _registered_for_tier(db, payout.uid, target, tournament_id)
        if holds or registered:
            amount = int(config["tiers"][target]["entryShare"])
            payout.ticket_kind = "share"
            payout.ticket_share = amount
            payout.ticket_label = ticket_share_label(amount)
            payout.ticket_reason = "already_holds_ticket" if holds else "already_registered"
            continue
        latest = _latest_settled_edition(db, target)
        if target == tier_id and source_edition is not None:
            latest = max(latest, source_edition)
        after, through = ticket_edition_bounds(latest, int(config["ticketValidEditions"]))
        payout.ticket_kind = "ticket"
        payout.ticket_label = ticket_reward_label(config, target)
        payout.valid_after = after
        payout.valid_through = through


def _write_ticket_grant(
    db,
    batch,
    payout: _Payout,
    *,
    tournament_id: str,
    tier_id: str,
    grant_ref,
    grant_exists: bool,
    ticket_share_ref,
    ticket_share_exists: bool,
    ticket_share_ledger: dict,
) -> None:
    if payout.ticket_already or payout.ticket_kind is None:
        return
    if payout.ticket_kind == "ticket" and not grant_exists:
        batch.set(
            grant_ref,
            {
                "uid": payout.uid,
                "tournamentId": tournament_id,
                "type": "ticket_grant",
                "prizeTier": tier_id,
                "targetTier": payout.ticket_target,
                "rank": payout.rank,
                "ticketAmount": 1,
                "shareAmount": 0,
                "diamondAmount": 0,
                "transferable": False,
                "validAfterEdition": payout.valid_after,
                "validThroughEdition": payout.valid_through,
                "fundedByEntryFees": False,
                "createdAt": SERVER_TIMESTAMP,
            },
        )
        ticket_ref = (
            db.collection("users")
            .document(payout.uid)
            .collection("prizeTickets")
            .document(f"from_{tournament_id}")
        )
        if not ticket_ref.get().exists:
            batch.set(
                ticket_ref,
                {
                    "uid": payout.uid,
                    "targetTier": payout.ticket_target,
                    "status": "valid",
                    "transferable": False,
                    "sourceTournamentId": tournament_id,
                    "sourceTier": tier_id,
                    "sourceRank": payout.rank,
                    "validAfterEdition": payout.valid_after,
                    "validThroughEdition": payout.valid_through,
                    "createdAt": SERVER_TIMESTAMP,
                },
            )
        return
    if payout.ticket_kind == "share" and not ticket_share_exists:
        batch.set(
            ticket_share_ref,
            {
                "uid": payout.uid,
                "tournamentId": tournament_id,
                "type": "ticket_share_fallback",
                "prizeTier": tier_id,
                "targetTier": payout.ticket_target,
                "rank": payout.rank,
                "shareAmount": payout.ticket_share,
                "diamondAmount": 0,
                "ticketAmount": 0,
                "reason": payout.ticket_reason or "duplicate_ticket",
                "transferable": False,
                "fundedByEntryFees": False,
                "createdAt": SERVER_TIMESTAMP,
                **ticket_share_ledger,
            },
        )


def _existing_ticket_grant(db, uid: str, tournament_id: str, config: dict, target: str):
    ticket_ref = (
        db.collection("users")
        .document(uid)
        .collection("prizeTickets")
        .document(f"from_{tournament_id}")
    )
    grant_ref = _wallet_ref(db, f"tournament_ticket_{tournament_id}_{uid}")
    share_ref = _wallet_ref(db, f"tournament_ticket_share_{tournament_id}_{uid}")
    if _read(ticket_ref) is not None or _read(grant_ref) is not None:
        return {"kind": "ticket", "share": 0, "label": ticket_reward_label(config, target)}
    share = _read(share_ref)
    if share is None:
        return None
    amount = int(share.get("shareAmount") or 0)
    return {"kind": "share", "share": amount, "label": ticket_share_label(amount)}


def _holds_open_ticket(db, uid: str, target: str) -> bool:
    latest = _latest_settled_edition(db, target)
    parent = db.collection("users").document(uid).collection("prizeTickets")
    for snap in parent.get():
        row = snap.to_dict() or {}
        if row.get("targetTier") != target:
            continue
        if ticket_is_open(row, latest):
            return True
    return False


def _registered_for_tier(db, uid: str, target: str, source_id: str) -> bool:
    for snap in db.collection("tournaments").where("prizeTier", "==", target).get():
        if snap.id == source_id:
            continue
        data = snap.to_dict() or {}
        if data.get("status") not in {"recruiting", "active"}:
            continue
        participant = (
            db.collection("tournaments")
            .document(snap.id)
            .collection("participants")
            .document(uid)
            .get()
        )
        if not participant.exists:
            continue
        if (participant.to_dict() or {}).get("status") == "joined":
            return True
    return False


def _latest_settled_edition(db, tier_id: str) -> int:
    data = _read(db.collection("companyPrizeEditions").document(tier_id)) or {}
    value = data.get("latestSettledEdition")
    if isinstance(value, bool) or not isinstance(value, int) or value < 0:
        return 0
    return value


def _advance_settled_edition(batch, db, tier_id: str, tournament: dict) -> None:
    edition = tournament_edition(tournament)
    if edition is None:
        return
    current = _latest_settled_edition(db, tier_id)
    if edition <= current:
        return
    batch.set(
        db.collection("companyPrizeEditions").document(tier_id),
        {
            "tier": tier_id,
            "latestSettledEdition": edition,
            "updatedAt": SERVER_TIMESTAMP,
        },
        merge=True,
    )


def _beginner_dia_ids(db, uid: str, season: str) -> list[str]:
    data = _read(
        db.collection("users").document(uid).collection("companyPrizeRace").document("state")
    ) or {}
    raw = (data.get("beginnerDiaPrizeIds") or {}).get(season)
    if not isinstance(raw, list):
        return []
    return [item for item in raw if isinstance(item, str)]


def _remember_beginner_dia(db, batch, uid: str, season: str, tournament_id: str) -> None:
    ref = db.collection("users").document(uid).collection("companyPrizeRace").document("state")
    data = _read(ref) or {}
    by_season = dict(data.get("beginnerDiaPrizeIds") or {})
    ids = [item for item in (by_season.get(season) or []) if isinstance(item, str)]
    if tournament_id in ids:
        return
    ids.append(tournament_id)
    by_season[season] = ids
    batch.set(
        ref,
        {"beginnerDiaPrizeIds": by_season, "updatedAt": SERVER_TIMESTAMP},
        merge=True,
    )


def _load_config(db) -> dict:
    snapshot = db.collection("config").document(COMPANY_TOURNAMENT_CONFIG_ID).get()
    raw = snapshot.to_dict() if snapshot.exists else None
    return resolve_company_tournament_config(raw)


def _reserve_prize_budget(db, month: str, tournament_id: str, requested: int, cap: int) -> int:
    ref = db.collection(PRIZE_POOLS).document(month)

    def apply(data: dict | None) -> tuple[int, dict | None]:
        current = data or {}
        reservations = dict(current.get("reservations") or {})
        if tournament_id in reservations:
            return int(reservations[tournament_id]), None
        paid = int(current.get("paidDia") or 0)
        room = max(0, cap - paid)
        budget = min(max(0, requested), room)
        reservations[tournament_id] = budget
        if budget < requested:
            logger.warning(
                "Monthly company prize cap: tournament %s requested %s bonus DIA, "
                "reserved %s, month pool already %s, cap %s, month %s",
                tournament_id,
                requested,
                budget,
                paid,
                cap,
                month,
            )
        return budget, {
            "monthKey": month,
            "paidDia": paid + budget,
            "capDia": cap,
            "reservations": reservations,
            "updatedAt": SERVER_TIMESTAMP,
        }

    if getattr(db, "store", None) is not None:
        budget, payload = apply(_read(ref))
        if payload is not None:
            _save(db, ref, payload)
        return budget

    @firestore.transactional
    def _tx(transaction):
        snapshot = ref.get(transaction=transaction)
        data = snapshot.to_dict() if snapshot.exists else None
        budget, payload = apply(data)
        if payload is not None:
            transaction.set(ref, payload, merge=True)
        return budget

    return _tx(db.transaction())


def _tournament_donation_ref(db, tournament_id: str, uid: str):
    return db.collection(DONATION_LEDGER).document(f"tournament_km_{tournament_id}_{uid}")


def _apply_monthly_donation_cap(
    db, payouts: list[_Payout], month: str, tournament_id: str
) -> None:
    """Fit settlement-only donations (no finish run id) under the monthly cap."""
    pending = [
        payout
        for payout in payouts
        if payout.donation_krw > 0
        and not _tournament_donation_ref(db, tournament_id, payout.uid).get().exists
    ]
    if not pending:
        return
    totals_ref = db.collection(DONATION_MONTH_TOTALS).document(month)
    total = month_total_won(_read(totals_ref))
    cap = read_monthly_cap_won(db)
    for payout in pending:
        payout.donation_krw = won_within_cap(payout.donation_krw, total, cap)
        total += payout.donation_krw
    _save(
        db,
        totals_ref,
        {
            "monthKey": month,
            "totalWon": total,
            "capWon": cap,
            "updatedAt": SERVER_TIMESTAMP,
        },
    )


def _record_donation_total(db, month: str, tournament_id: str, krw: int) -> None:
    ref = db.collection(DONATION_POOLS).document(month)
    current = _read(ref) or {}
    by_tournament = dict(current.get("tournaments") or {})
    if tournament_id in by_tournament:
        return
    by_tournament[tournament_id] = krw
    _save(
        db,
        ref,
        {
            "monthKey": month,
            "totalKrw": sum(int(amount) for amount in by_tournament.values()),
            "tournaments": by_tournament,
            "updatedAt": SERVER_TIMESTAMP,
        },
    )


def _require_accounts(db, payouts: list[_Payout]) -> dict[str, dict]:
    accounts: dict[str, dict] = {}
    for payout in payouts:
        ref = db.collection("users").document(payout.uid)
        snapshot = ref.get()
        if not snapshot.exists:
            raise HTTPException(
                status_code=409,
                detail=f"Finisher {payout.uid} has no user document.",
            )
        accounts[payout.uid] = snapshot.to_dict() or {}
    return accounts


def _finisher_row(doc_id: str, participant: dict, target_km: float) -> dict | None:
    if participant.get("verifiedFinish") is not True:
        return None
    distance = _number(participant.get("distanceKm"))
    duration = _number(participant.get("durationSeconds"))
    if distance is None or distance <= 0 or duration is None or duration <= 0:
        return None
    if target_km > 0 and distance + 1e-9 < target_km:
        return None
    activity_id = participant.get("finishActivityId")
    return {
        "uid": doc_id,
        "distance_km": distance,
        "duration_seconds": duration,
        "activity_id": activity_id.strip()
        if isinstance(activity_id, str) and activity_id.strip()
        else None,
    }


def _participants(db, tournament_id: str) -> list[tuple[str, dict, object]]:
    prefix = f"tournaments/{tournament_id}/participants/"
    store = getattr(db, "store", None)
    if isinstance(store, dict):
        rows = []
        parent = db.collection("tournaments").document(tournament_id)
        for path, data in list(store.items()):
            if not path.startswith(prefix):
                continue
            doc_id = path[len(prefix) :]
            if not doc_id or "/" in doc_id:
                continue
            ref = parent.collection("participants").document(doc_id)
            rows.append((doc_id, deepcopy(data), ref))
        return rows
    parent = db.collection("tournaments").document(tournament_id)
    return [
        (snap.id, snap.to_dict() or {}, snap.reference)
        for snap in parent.collection("participants").stream()
    ]


def _wallet_ref(db, doc_id: str):
    return db.collection("walletTransactions").document(doc_id)


def _read(ref) -> dict | None:
    snapshot = ref.get()
    if not snapshot.exists:
        return None
    return snapshot.to_dict() or {}


def _save(db, ref, data: dict) -> None:
    store = getattr(db, "store", None)
    if store is not None:
        current = dict(store.get(ref.path) or {})
        current.update(deepcopy(data))
        store[ref.path] = current
        return
    ref.set(data, merge=True)


def _number(value: object) -> float | None:
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, (int, float)):
        return float(value)
    return None


class _Batch:
    """Firestore batch, or direct writes on the in-memory test database."""

    def __init__(self, db) -> None:
        self._db = db
        self._live = db.batch() if hasattr(db, "batch") else None
        self._ops = 0

    def set(self, ref, data: dict, merge: bool = False) -> None:
        if self._live is None:
            if merge and ref.path in self._db.store:
                current = dict(self._db.store[ref.path])
                current.update(deepcopy(data))
                self._db.store[ref.path] = current
                return
            self._db.store[ref.path] = deepcopy(data)
            return
        self._live.set(ref, data, merge=merge)
        self._ops += 1

    def update(self, ref, data: dict) -> None:
        if self._live is None:
            _memory_update(self._db.store[ref.path], data)
            return
        self._live.update(ref, data)
        self._ops += 1

    def flush_if_full(self) -> None:
        if self._live is not None and self._ops >= _BATCH_LIMIT:
            self.commit()

    def commit(self) -> None:
        if self._live is None or self._ops == 0:
            return
        self._live.commit()
        self._live = self._db.batch()
        self._ops = 0


def _memory_update(current: dict, data: dict) -> None:
    for key, value in data.items():
        if isinstance(value, firestore.Increment):
            _memory_increment(current, key, value.value)
            continue
        if "." not in key:
            current[key] = deepcopy(value)
            continue
        parent, child = key.split(".", 1)
        nested = dict(current.get(parent) or {})
        nested[child] = deepcopy(value)
        current[parent] = nested


def _memory_increment(current: dict, key: str, amount) -> None:
    if "." not in key:
        current[key] = (current.get(key) or 0) + amount
        return
    parent, child = key.split(".", 1)
    nested = dict(current.get(parent) or {})
    nested[child] = (nested.get(child) or 0) + amount
    current[parent] = nested
