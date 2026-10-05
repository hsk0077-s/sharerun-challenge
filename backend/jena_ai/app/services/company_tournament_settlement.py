"""Settle a company prize race when it ends.

Prize DIA, top-percent SHARE, finisher VALUE, and the company km donation
come from ``config/company_tournament``. Entry fees are not a prize pool.
Bonus DIA is free DIA. The monthly cap is ``monthlyCompanyPrizeCapDia``;
a prize that does not fit is capped or held and written to the ledger.

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

from app.models.ops_result import PrizeSettlementResult
from app.services.company_tournament_config import (
    COMPANY_TOURNAMENT_CONFIG_ID,
    prize_claim_reason,
    prize_tier_id,
    resolve_account_created_at,
    resolve_company_tournament_config,
    verified_runs_in_window,
)
from app.services.streak_protection import kst_month_key
from app.services.wallet_funding import move_currency

logger = logging.getLogger(__name__)

PRIZE_POOLS = "companyPrizePools"
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
        self.ineligible_reason: str | None = None


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
    cap = int(config["monthlyCompanyPrizeCapDia"])
    requested = sum(
        payout.dia_requested for payout in payouts if not payout.ineligible_reason
    )
    budget = _reserve_prize_budget(db, month, tournament_id, requested, cap)
    assign_dia_budget(payouts, budget)
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
        )
        batch.flush_if_full()

    summary = _summary(payouts, month, tier_id, cap, donation_krw)
    held = summary["heldDia"]
    if held > 0:
        reason = (
            f"Settled. {held} bonus DIA was capped or held by the monthly "
            f"company prize cap of {cap} DIA."
        )
    else:
        reason = "Prize race settled from server config. Entry fees were not used."
    batch.update(
        tournament_ref,
        {
            "status": "finished",
            "prizeSettled": True,
            "prizeSettlement": summary,
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    batch.commit()
    return _result(tournament_id, "settled", reason, summary)


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
) -> None:
    user_ref = db.collection("users").document(payout.uid)
    dia_ref = _wallet_ref(db, f"tournament_prize_{tournament_id}_{payout.uid}")
    share_ref = _wallet_ref(db, f"tournament_share_{tournament_id}_{payout.uid}")
    value_ref = _wallet_ref(db, f"tournament_value_{tournament_id}_{payout.uid}")
    donation_ref = db.collection(DONATION_LEDGER).document(
        f"tournament_km_{tournament_id}_{payout.uid}"
    )
    dia_exists = dia_ref.get().exists
    share_exists = share_ref.get().exists
    value_exists = value_ref.get().exists
    donation_exists = donation_ref.get().exists

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
        if payout.dia_paid <= 0:
            row["diamondFreeAmount"] = 0
            row["diamondPaidAmount"] = 0
        batch.set(dia_ref, row)

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
        if payout.dia_requested > 0 and not payout.ineligible_reason
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
    return {
        "uid": doc_id,
        "distance_km": distance,
        "duration_seconds": duration,
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

    def set(self, ref, data: dict) -> None:
        if self._live is None:
            self._db.store[ref.path] = deepcopy(data)
            return
        self._live.set(ref, data)
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
