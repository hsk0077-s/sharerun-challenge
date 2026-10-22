"""Take back what a Play purchase gave when Google Play refunds or charges it back.

The money goes back to the buyer without the app being involved, so the app asks Play on a
schedule which orders were voided and undoes them here.

* DIA pack: the paid DIA from that pack that is still in the wallet is taken back (capped at
  what the pack paid in), plus the free bonus in proportion, like the in-app 7-day refund. Paid
  DIA already spent cannot be taken back: that part is written down as a shortfall on the
  purchase and on the user so an operator can follow it up. The wallet never goes below zero.
* Coach+: access ends now, but only when this order is the one the account's Coach+ is
  currently running on. A different, still paid subscription is left alone.
* A purchase is handled once. One the in-app refund already settled (``refundStatus``) takes
  nothing more, because that refund also shows up in Play's list.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP, Increment

from app.constants.economy_constants import DIA_PACKS
from app.services.play_billing import list_voided_purchases, purchase_token_hash
from app.services.wallet_funding import move_currency, resolved_buckets

CURSOR_PATH = ("opsState", "playVoided")
DEFAULT_LOOKBACK_DAYS = 7
OVERLAP = timedelta(days=1)
PLAY_HISTORY = timedelta(days=29)  # Play keeps about 30 days


def process_voided_purchases(db, now: datetime | None = None) -> dict:
    now = now or datetime.now(timezone.utc)
    cursor_ref = db.collection(CURSOR_PATH[0]).document(CURSOR_PATH[1])
    cursor = cursor_ref.get()
    last_end = (cursor.to_dict() or {}).get("lastEndMillis") if cursor.exists else None
    if isinstance(last_end, int):
        start = datetime.fromtimestamp(last_end / 1000, timezone.utc) - OVERLAP
    else:
        start = now - timedelta(days=DEFAULT_LOOKBACK_DAYS)
    start = max(start, now - PLAY_HISTORY)  # older than this Play cannot answer
    end_ms = int(now.timestamp() * 1000)

    rows = list_voided_purchases(int(start.timestamp() * 1000), end_ms)
    counts = {"dia_taken_back": 0, "coach_plus_ended": 0, "already_handled": 0, "unknown": 0, "failed": 0}
    shortfall_total = 0
    for row in rows:
        token = str(row.get("purchaseToken") or "")
        if not token:
            counts["unknown"] += 1
            continue
        token_hash = purchase_token_hash(token)
        try:
            outcome = _handle_one(db, token_hash, row, now)
        except Exception:  # one bad record must not stop the rest; the next run retries it
            counts["failed"] += 1
            continue
        counts[outcome["kind"]] += 1
        shortfall_total += outcome.get("shortfall", 0)

    # Move the cursor only when every row was handled, so a failed row is read again.
    if counts["failed"] == 0:
        cursor_ref.set({"lastEndMillis": end_ms, "updatedAt": SERVER_TIMESTAMP}, merge=True)
    return {"read": len(rows), "shortfall_dia": shortfall_total, **counts}


def _handle_one(db, token_hash: str, row: dict, now: datetime) -> dict:
    purchase_ref = db.collection("playPurchases").document(token_hash)
    if purchase_ref.get().exists:
        return _void_dia_tx(db.transaction(), db, purchase_ref, row)
    subscription_ref = db.collection("playSubscriptions").document(token_hash)
    if subscription_ref.get().exists:
        return _void_coach_tx(db.transaction(), db, subscription_ref, token_hash, row, now)
    return {"kind": "unknown"}


def _void_info(row: dict) -> dict:
    return {
        "voidedSource": row.get("voidedSource"),
        "voidedReason": row.get("voidedReason"),
        "voidedTimeMillis": row.get("voidedTimeMillis"),
    }


@firestore.transactional
def _void_dia_tx(transaction, db, purchase_ref, row) -> dict:
    purchase_snapshot = purchase_ref.get(transaction=transaction)
    purchase = purchase_snapshot.to_dict() or {}
    uid = str(purchase.get("uid") or "")
    user_ref = db.collection("users").document(uid) if uid else None
    user_snapshot = user_ref.get(transaction=transaction) if user_ref else None
    if purchase.get("voidedAt") is not None:
        return {"kind": "already_handled"}
    if purchase.get("refundStatus"):
        # The in-app refund already took the DIA back. Just note that Play lists it too.
        transaction.update(purchase_ref, {"voidedAt": SERVER_TIMESTAMP, **_void_info(row)})
        return {"kind": "already_handled"}
    if user_snapshot is None or not user_snapshot.exists:
        transaction.update(
            purchase_ref,
            {"voidedAt": SERVER_TIMESTAMP, "voidedNote": "user_missing", **_void_info(row)},
        )
        return {"kind": "dia_taken_back", "shortfall": 0}

    pack = next((p for p in DIA_PACKS if p["productId"] == purchase.get("productId")), {})
    base = int(purchase["baseDia"] if purchase.get("baseDia") is not None else pack.get("baseDia", 0))
    bonus = int(purchase["bonusDia"] if purchase.get("bonusDia") is not None else pack.get("bonusDia", 0))
    wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
    buckets = resolved_buckets(wallet)
    paid_back = max(0, min(base, buckets["paid_diamond"]))
    shortfall = max(0, base - paid_back)
    bonus_due = round(bonus * paid_back / base) if base > 0 else 0
    bonus_back = max(0, min(bonus_due, buckets["free_diamond"]))

    updates: dict = {}
    ledger: dict = {}
    if paid_back:
        paid = move_currency(wallet, diamond=-paid_back, paid_only=True)
        updates.update(paid["updates"])
        ledger.update(paid["ledger"])
    if bonus_back:
        free = move_currency(wallet, diamond=-bonus_back, free_only=True)
        updates.update(free["updates"])
        ledger["diamondFreeAmount"] = free["ledger"].get("diamondFreeAmount", -bonus_back)
    user_updates = dict(updates)
    if shortfall:
        user_updates["refundShortfallDia"] = Increment(shortfall)
    if user_updates:
        transaction.update(user_ref, {**user_updates, "updatedAt": SERVER_TIMESTAMP})
    transaction.update(
        purchase_ref,
        {
            "voidedAt": SERVER_TIMESTAMP,
            "refundStatus": "voided",
            "clawbackPaidDia": paid_back,
            "clawbackBonusDia": bonus_back,
            "shortfallDia": shortfall,
            **_void_info(row),
        },
    )
    transaction.set(
        db.collection("walletTransactions").document(),
        {
            "uid": uid,
            "type": "play_void_clawback",
            "diamondAmount": -(paid_back + bonus_back),
            "shortfallDia": shortfall,
            "purchaseId": purchase_ref.id,
            "productId": purchase.get("productId", ""),
            "createdAt": SERVER_TIMESTAMP,
            **ledger,
        },
    )
    return {"kind": "dia_taken_back", "shortfall": shortfall}


@firestore.transactional
def _void_coach_tx(transaction, db, subscription_ref, token_hash, row, now) -> dict:
    subscription_snapshot = subscription_ref.get(transaction=transaction)
    subscription = subscription_snapshot.to_dict() or {}
    uid = str(subscription.get("uid") or "")
    user_ref = db.collection("users").document(uid) if uid else None
    user_snapshot = user_ref.get(transaction=transaction) if user_ref else None
    if subscription.get("voidedAt") is not None:
        return {"kind": "already_handled"}
    transaction.update(subscription_ref, {"voidedAt": SERVER_TIMESTAMP, **_void_info(row)})
    if user_snapshot is not None and user_snapshot.exists:
        coach = (user_snapshot.to_dict() or {}).get("coachPlus") or {}
        # Only end access that was running on this very order.
        if coach.get("tokenHash") == token_hash:
            transaction.update(
                user_ref,
                {
                    "coachPlus": {**coach, "activeUntil": now.isoformat()},
                    "updatedAt": SERVER_TIMESTAMP,
                },
            )
    return {"kind": "coach_plus_ended"}
