"""Cash refund (청약철회) of a DIA pack: within 7 days, the unused paid part only.

* 1 paid DIA is 100 KRW. A pack's ``baseDia`` is paid, its ``bonusDia`` (덤) is free.
* What can come back is the paid DIA from that pack still in the wallet, capped by what the
  pack paid in. Spends take free DIA first, so the paid part stays as long as it can.
* The 덤 comes back out too, in proportion to the paid DIA refunded. A 덤 already spent is
  taken off the refund at 100 KRW per DIA.
* One purchase is refunded once. The wallet is debited at once; the money goes back through
  Google Play when the service account is configured, otherwise the request waits for an
  operator in ``refundRequests``.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.constants.economy_constants import DIA_PACKS
from app.services.wallet_funding import move_currency, resolved_buckets

KRW_PER_DIA = 100
DEFAULT_REFUND_DAYS = 7


def refund_days() -> int:
    raw = os.environ.get("DIA_REFUND_DAYS", "").strip()
    try:
        return max(0, int(raw)) if raw else DEFAULT_REFUND_DAYS
    except ValueError:
        return DEFAULT_REFUND_DAYS


def _pack(product_id: str) -> dict | None:
    return next((p for p in DIA_PACKS if p["productId"] == product_id), None)


def _created(purchase: dict) -> datetime | None:
    value = purchase.get("createdAt")
    if not isinstance(value, datetime):
        return None
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def compute(purchase: dict, wallet: dict, now: datetime | None = None) -> dict:
    """What a refund of this purchase would pay, or why it cannot be refunded."""
    now = now or datetime.now(timezone.utc)
    pack = _pack(str(purchase.get("productId") or ""))
    base = int(purchase.get("baseDia") if purchase.get("baseDia") is not None else (pack or {}).get("baseDia", 0))
    bonus = int(purchase.get("bonusDia") if purchase.get("bonusDia") is not None else (pack or {}).get("bonusDia", 0))
    out = {"eligible": False, "reason": "", "paid_dia": 0, "bonus_revoked": 0, "bonus_spent": 0, "refund_krw": 0}
    if purchase.get("refundStatus"):
        out["reason"] = "already_refunded"
        return out
    created = _created(purchase)
    if created is None or now - created > timedelta(days=refund_days()):
        out["reason"] = "period_over"
        return out
    if base <= 0:
        out["reason"] = "unknown_pack"
        return out
    buckets = resolved_buckets(wallet)
    paid = min(base, buckets["paid_diamond"])
    if paid <= 0:
        out["reason"] = "nothing_left"
        return out
    due = round(bonus * paid / base)
    revoked = min(due, buckets["free_diamond"])
    spent = due - revoked
    krw = (paid - spent) * KRW_PER_DIA
    if krw <= 0:
        out["reason"] = "nothing_left"
        return out
    return {"eligible": True, "reason": "", "paid_dia": paid, "bonus_revoked": revoked, "bonus_spent": spent, "refund_krw": krw}


def list_refundable(db, uid: str) -> list[dict]:
    """The user's purchases inside the refund period, each with its refund preview."""
    user_snapshot = db.collection("users").document(uid).get()
    wallet = ((user_snapshot.to_dict() or {}).get("wallet") or {}) if user_snapshot.exists else {}
    out = []
    for snapshot in db.collection("playPurchases").where("uid", "==", uid).get():
        purchase = snapshot.to_dict() or {}
        created = _created(purchase)
        pack = _pack(str(purchase.get("productId") or "")) or {}
        preview = compute(purchase, wallet)
        if preview["reason"] == "period_over" and not purchase.get("refundStatus"):
            continue
        out.append(
            {
                "purchase_id": snapshot.id,
                "product_id": purchase.get("productId", ""),
                "price_krw": int(purchase.get("priceKrw") or pack.get("priceKrw") or 0),
                "created_at": created.isoformat() if created else "",
                "status": purchase.get("refundStatus") or "",
                **{k: preview[k] for k in ("eligible", "reason", "paid_dia", "bonus_revoked", "bonus_spent", "refund_krw")},
            }
        )
    out.sort(key=lambda r: r["created_at"], reverse=True)
    return out


def request_refund(service, uid: str, purchase_id: str) -> dict:
    purchase_id = (purchase_id or "").strip()
    if not purchase_id or "/" in purchase_id:
        raise HTTPException(status_code=400, detail="Invalid purchase.")
    db = service.firebase_service.db
    result = _refund_tx(
        db.transaction(),
        db,
        uid,
        db.collection("users").document(uid),
        db.collection("playPurchases").document(purchase_id),
        db.collection("refundRequests").document(purchase_id),
    )
    if result["status"] == "refund_requested":
        play_refunded = _try_play_refund(db, purchase_id)
        result["play_refunded"] = play_refunded
        if play_refunded:
            result["status"] = "refunded"
    return result


def _try_play_refund(db, purchase_id: str) -> bool:
    """Ask Google Play to return the money. False when it is not configured or fails."""
    from app.services.play_billing import refund_play_order

    purchase_ref = db.collection("playPurchases").document(purchase_id)
    snapshot = purchase_ref.get()
    order_id = (snapshot.to_dict() or {}).get("orderId") if snapshot.exists else None
    if not isinstance(order_id, str) or not order_id:
        return False
    try:
        done = refund_play_order(order_id)
    except Exception:
        return False
    if done:
        purchase_ref.update({"refundStatus": "refunded", "updatedAt": SERVER_TIMESTAMP})
        db.collection("refundRequests").document(purchase_id).update(
            {"status": "refunded", "updatedAt": SERVER_TIMESTAMP}
        )
    return done


@firestore.transactional
def _refund_tx(transaction, db, uid, user_ref, purchase_ref, request_ref) -> dict:
    purchase_snapshot = purchase_ref.get(transaction=transaction)
    if not purchase_snapshot.exists or (purchase_snapshot.to_dict() or {}).get("uid") != uid:
        raise HTTPException(status_code=404, detail="Purchase not found.")
    user_snapshot = user_ref.get(transaction=transaction)
    if not user_snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    purchase = purchase_snapshot.to_dict() or {}
    wallet = (user_snapshot.to_dict() or {}).get("wallet") or {}
    quote = compute(purchase, wallet)
    if not quote["eligible"]:
        status = 409 if quote["reason"] == "already_refunded" else 400
        raise HTTPException(status_code=status, detail=f"Not refundable: {quote['reason']}.")
    paid = move_currency(wallet, diamond=-quote["paid_dia"], paid_only=True)
    updates = dict(paid["updates"])
    ledger = dict(paid["ledger"])
    if quote["bonus_revoked"]:
        free = move_currency(wallet, diamond=-quote["bonus_revoked"], free_only=True)
        updates.update(free["updates"])
        ledger["diamondFreeAmount"] = free["ledger"].get("diamondFreeAmount", -quote["bonus_revoked"])
    transaction.update(user_ref, {**updates, "updatedAt": SERVER_TIMESTAMP})
    transaction.update(purchase_ref, {"refundStatus": "requested", "refundKrw": quote["refund_krw"], "updatedAt": SERVER_TIMESTAMP})
    transaction.set(
        request_ref,
        {
            "uid": uid,
            "purchaseId": purchase_ref.id,
            "productId": purchase.get("productId", ""),
            "refundKrw": quote["refund_krw"],
            "paidDia": quote["paid_dia"],
            "bonusRevoked": quote["bonus_revoked"],
            "bonusSpent": quote["bonus_spent"],
            "status": "requested",
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    transaction.set(
        db.collection("walletTransactions").document(),
        {
            "uid": uid,
            "type": "dia_refund_requested",
            "diamondAmount": -(quote["paid_dia"] + quote["bonus_revoked"]),
            "refundKrw": quote["refund_krw"],
            "purchaseId": purchase_ref.id,
            "createdAt": SERVER_TIMESTAMP,
            **ledger,
        },
    )
    return {
        "status": "refund_requested",
        "refund_krw": quote["refund_krw"],
        "paid_dia": quote["paid_dia"],
        "bonus_revoked": quote["bonus_revoked"],
        "bonus_spent": quote["bonus_spent"],
        "play_refunded": False,
    }
