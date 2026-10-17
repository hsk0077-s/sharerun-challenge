"""Tier tournaments and free tournaments (the two kinds of ranked race).

A tournament doc with ``kind`` ``"tier"`` or ``"free"`` is a ranked race:

* ``free``: any graded runner. Promotion points are half (see promotion_points).
* ``tier``: ``tierAnimal`` 1..5 (turtle..cheetah). A runner whose animal matches
  enters normally, one animal below enters one step up with a challenge ticket
  (once a week), and everyone else is refused: lower tournaments are closed so
  nobody wins low on purpose, and two or more steps up is too far.

A snail (no grade yet) cannot enter either kind. Finishes are stored on the
participant as verified runs come in; ``settle_ranked_tournament`` ranks them
and gives promotion points once.
"""

from datetime import datetime, timezone

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.ops_result import PrizeSettlementResult
from app.services.company_tournament_settlement import _participants, _save
from app.services.item_price_config import CHALLENGE_TICKET_ITEM_ID
from app.services.promotion_points import (
    week_key,
    animal_of_rank,
    award_tournament_results,
    ANIMALS,
)
from app.services.share_activity_items import _exists, _ledger_ref, _quantity, _user

RANKED_KINDS = frozenset({"tier", "free"})
CHALLENGE_USES_PER_WEEK = 1


def ranked_kind(tournament: dict) -> str | None:
    kind = tournament.get("kind")
    return kind if kind in RANKED_KINDS else None


def tier_animal_index(tournament: dict) -> int | None:
    value = tournament.get("tierAnimal")
    if isinstance(value, bool) or not isinstance(value, int) or not 1 <= value <= 5:
        return None
    return value


def user_animal_index(user: dict) -> int:
    """1..5 for a graded runner, 0 for a snail."""
    rank = user.get("gradeRank")
    if isinstance(rank, bool) or not isinstance(rank, int) or rank < 1:
        return 0
    return ANIMALS.index(animal_of_rank(rank)) + 1


def entry_decision(user: dict, tournament: dict) -> dict:
    """``{"allowed", "needsTicket", "reason"}`` for a ranked tournament."""
    mine = user_animal_index(user)
    if mine == 0:
        return {"allowed": False, "needsTicket": False, "reason": "ungraded"}
    if ranked_kind(tournament) == "free":
        return {"allowed": True, "needsTicket": False, "reason": ""}
    target = tier_animal_index(tournament)
    if target is None:
        return {"allowed": False, "needsTicket": False, "reason": "bad_tier"}
    if target == mine:
        return {"allowed": True, "needsTicket": False, "reason": ""}
    if target == mine + 1:
        return {"allowed": True, "needsTicket": True, "reason": ""}
    return {
        "allowed": False,
        "needsTicket": False,
        "reason": "too_low" if target < mine else "too_high",
    }


_REFUSALS = {
    "ungraded": "Finish three verified 1km runs to get a grade first.",
    "bad_tier": "This tournament has no valid tier.",
    "too_low": "Lower-tier tournaments are closed to your grade.",
    "too_high": "This tournament is more than one step above your grade.",
}


def require_entry(user: dict, tournament: dict) -> bool:
    """Raise 403 when the runner may not enter. Returns ``needsTicket``."""
    decision = entry_decision(user, tournament)
    if not decision["allowed"]:
        raise HTTPException(
            status_code=403,
            detail=_REFUSALS.get(decision["reason"], "Entry is closed."),
        )
    return bool(decision["needsTicket"])


def consume_challenge_ticket(
    service,
    transaction,
    uid: str,
    user_ref,
    tournament_id: str,
    now: datetime | None = None,
) -> None:
    """Spend one challenge ticket inside the join transaction."""
    current = now or datetime.now(timezone.utc)
    user = _user(user_ref, transaction)
    week = week_key(current)
    raw = user.get("challengeTicketUse")
    used = (
        int(raw.get("count") or 0)
        if isinstance(raw, dict) and raw.get("weekKey") == week
        else 0
    )
    if used >= CHALLENGE_USES_PER_WEEK:
        raise HTTPException(
            status_code=400,
            detail="A challenge ticket can be used once a week.",
        )
    inventory_ref = user_ref.collection("shopInventory").document(
        CHALLENGE_TICKET_ITEM_ID
    )
    quantity = _quantity(inventory_ref, transaction)
    if quantity < 1:
        raise HTTPException(status_code=400, detail="No challenge ticket.")
    ledger_ref = _ledger_ref(
        service, f"shop_use_{uid}_{CHALLENGE_TICKET_ITEM_ID}_{tournament_id}"
    )
    if _exists(ledger_ref, transaction):
        return
    transaction.set(inventory_ref, {"quantity": quantity - 1}, merge=True)
    transaction.update(
        user_ref,
        {
            "challengeTicketUse": {"weekKey": week, "count": used + 1},
            "updatedAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "shop_item_use",
            "itemId": CHALLENGE_TICKET_ITEM_ID,
            "tournamentId": tournament_id,
            "requestId": tournament_id,
            "quantityAmount": -1,
            "createdAt": SERVER_TIMESTAMP,
        },
    )


def ranked_finish_fields(
    tournament: dict,
    participant: dict,
    *,
    distance_km: float,
    duration_seconds: int | float,
    activity_id: str,
) -> dict | None:
    """Best verified finish for a ranked race. Slower repeats are ignored."""
    if ranked_kind(tournament) is None or tournament.get("rankedSettled") is True:
        return None
    if (
        isinstance(distance_km, bool)
        or isinstance(duration_seconds, bool)
        or not isinstance(distance_km, (int, float))
        or not isinstance(duration_seconds, (int, float))
        or distance_km <= 0
        or duration_seconds <= 0
    ):
        return None
    target = tournament.get("targetDistanceKm")
    if (
        isinstance(target, (int, float))
        and not isinstance(target, bool)
        and target > 0
        and distance_km + 1e-9 < target
    ):
        return None
    if participant.get("verifiedFinish") is True:
        previous = participant.get("durationSeconds")
        if isinstance(previous, (int, float)) and duration_seconds >= previous:
            return None
    return {
        "verifiedFinish": True,
        "distanceKm": float(distance_km),
        "durationSeconds": float(duration_seconds),
        "finishActivityId": activity_id,
    }


def settle_ranked_tournament(
    db,
    tournament_id: str,
    now: datetime | None = None,
) -> PrizeSettlementResult:
    """Rank verified finishers and give promotion points once."""
    current = now or datetime.now(timezone.utc)
    if not tournament_id or "/" in tournament_id:
        raise HTTPException(status_code=400, detail="Invalid tournament id.")
    tournament_ref = db.collection("tournaments").document(tournament_id)
    snapshot = tournament_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Tournament does not exist.")
    tournament = snapshot.to_dict() or {}
    kind = ranked_kind(tournament)
    if kind is None:
        raise HTTPException(status_code=400, detail="Not a ranked tournament.")
    if tournament.get("rankedSettled") is True:
        return _result(tournament_id, "already_settled", "Already settled.", 0)
    if (tournament.get("status") or "recruiting") not in {"active", "finished"}:
        raise HTTPException(
            status_code=400,
            detail="Only an active or finished tournament can be settled.",
        )

    rows = []
    for doc_id, data, _ref in _participants(db, tournament_id):
        if data.get("verifiedFinish") is not True:
            continue
        duration = data.get("durationSeconds")
        if isinstance(duration, bool) or not isinstance(duration, (int, float)):
            continue
        if duration <= 0:
            continue
        rows.append((float(duration), doc_id, bool(data.get("challengedUp"))))
    rows.sort(key=lambda row: (row[0], row[1]))
    results = [
        {"uid": uid, "rank": index, "challengedUp": challenged}
        for index, (_, uid, challenged) in enumerate(rows, start=1)
    ]
    summary = award_tournament_results(
        db,
        tournament_id=tournament_id,
        tournament_class=kind,
        results=results,
        now=current,
    )
    _save(
        db,
        tournament_ref,
        {
            "status": "finished",
            "rankedSettled": True,
            "rankedSettlement": {
                "finishers": len(results),
                "awarded": summary["awarded"],
                "promoted": summary["promoted"],
                "points": summary["points"],
            },
            "updatedAt": SERVER_TIMESTAMP,
        }
    )
    return _result(
        tournament_id,
        "settled",
        f"Gave promotion points to {summary['awarded']} runners.",
        len(results),
    )


def _result(
    tournament_id: str, status: str, reason: str, finishers: int
) -> PrizeSettlementResult:
    return PrizeSettlementResult(
        accepted=True,
        tournament_id=tournament_id,
        status=status,
        finisher_count=finishers,
        paid_dia=0,
        held_dia=0,
        share_paid=0,
        value_paid=0,
        donation_krw=0,
        reason=reason,
    )


def open_ranked_tournament(
    db,
    tournament_id: str,
    *,
    kind: str,
    title: str,
    target_distance_km: float,
    tier_animal: int | None = None,
    entry_fee_share: int = 0,
    max_participants: int = 1000,
) -> dict:
    """Create a tier or free tournament. Calling again with the same fields
    changes nothing; the same id with other fields is refused."""
    if not tournament_id or "/" in tournament_id:
        raise HTTPException(status_code=400, detail="Invalid tournament id.")
    if kind not in RANKED_KINDS:
        raise HTTPException(status_code=400, detail="Kind must be tier or free.")
    if kind == "tier" and (
        isinstance(tier_animal, bool)
        or not isinstance(tier_animal, int)
        or not 1 <= tier_animal <= 5
    ):
        raise HTTPException(status_code=400, detail="tierAnimal must be 1 to 5.")
    if kind == "free":
        tier_animal = None
    if not title.strip() or target_distance_km <= 0 or entry_fee_share < 0:
        raise HTTPException(status_code=400, detail="Invalid tournament fields.")
    payload = {
        "title": title.strip(),
        "kind": kind,
        "targetDistanceKm": float(target_distance_km),
        "entryFeeShare": int(entry_fee_share),
        "maxParticipants": int(max_participants),
        "requiredTier": 1,
    }
    if tier_animal is not None:
        payload["tierAnimal"] = tier_animal
    ref = db.collection("tournaments").document(tournament_id)
    snapshot = ref.get()
    if snapshot.exists:
        existing = snapshot.to_dict() or {}
        if all(existing.get(key) == value for key, value in payload.items()):
            return {"status": "already_created", "tournamentId": tournament_id}
        raise HTTPException(status_code=409, detail="Tournament id is already used.")
    ref.set(
        {
            **payload,
            "status": "recruiting",
            "participantCount": 0,
            "createdAt": SERVER_TIMESTAMP,
            "updatedAt": SERVER_TIMESTAMP,
        }
    )
    return {"status": "created", "tournamentId": tournament_id}
