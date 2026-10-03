from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from google.cloud.firestore_v1.base_query import BaseQuery

from app.constants.economy_constants import TEST_WALLET_GRANT_AMOUNT
from app.models.admin_api import (
    WalletLedgerCurrency,
    WalletLedgerEntry,
    WalletLedgerResult,
)
from app.services.admin_audit_service import admin_audit_service
from app.services.firebase_service import FirebaseService

LEDGER_CAP = 2000
_KST = timezone(timedelta(hours=9))
_CURRENCIES = (
    ("SHARE", "shareAmount", "shareBalance"),
    ("DIA", "diamondAmount", "diamondBalance"),
    ("VALUE", "valueAmount", "valueTokenBalance"),
)
_RELATED = (
    "paymentIntentId",
    "tournamentId",
    "activityId",
    "itemId",
    "pgTransactionId",
)


class AdminWalletLedgerService:
    """Reads one user's wallet and walletTransactions. Does not change balances."""

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def lookup(
        self,
        *,
        uid: str,
        actor_uid: str,
        actor_email: str | None,
    ) -> WalletLedgerResult:
        owner = _uid(uid)
        db = self._db()
        snap = db.collection("users").document(owner).get()
        if not getattr(snap, "exists", False):
            self._audit(actor_uid, actor_email, owner, "user not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found.",
            )
        user = snap.to_dict() or {}
        snaps = list(
            db.collection("walletTransactions")
            .where("uid", "==", owner)
            .order_by("createdAt", direction=BaseQuery.DESCENDING)
            .limit(LEDGER_CAP + 1)
            .stream()
        )
        truncated = len(snaps) > LEDGER_CAP
        snaps = snaps[:LEDGER_CAP]
        entries = [entry for snap in snaps for entry in _entries(snap)]
        currencies = _currencies(user, snaps)
        self._audit(actor_uid, actor_email, owner, "read wallet ledger")
        return WalletLedgerResult(
            uid=owner,
            nickname=_text(user.get("nickname")) or _text(user.get("displayName")),
            email=_text(user.get("email")),
            truncated=truncated,
            currencies=currencies,
            entries=entries,
        )

    def _db(self):
        service = self.firebase_service or FirebaseService()
        return service.db

    def _audit(self, actor_uid: str, actor_email: str | None, target: str, reason: str) -> None:
        admin_audit_service.write(
            uid=actor_uid,
            email=actor_email,
            action="wallet_ledger_lookup",
            target_uid=target,
            before=None,
            after=None,
            reason=reason,
        )


def _currencies(user: dict, snaps: list) -> list[WalletLedgerCurrency]:
    sums = {currency: 0 for currency, _field, _key in _CURRENCIES}
    for snap in snaps:
        data = snap.to_dict() or {}
        for currency, field, _key in _CURRENCIES:
            number = _stored_int(data.get(field)) if field in data else None
            if number:
                sums[currency] += number
    rows: list[WalletLedgerCurrency] = []
    for currency, _field, balance_key in _CURRENCIES:
        balance = _wallet_balance(user, balance_key)
        ledger_sum = sums[currency]
        gap = balance - ledger_sum
        rows.append(
            WalletLedgerCurrency(
                currency=currency,
                balance=balance,
                ledgerSum=ledger_sum,
                mismatch=gap != 0,
                seedGap=gap == TEST_WALLET_GRANT_AMOUNT,
            )
        )
    return rows


def _entries(snap) -> list[WalletLedgerEntry]:
    data = snap.to_dict() or {}
    related = _related(data)
    when = _time_kst(data.get("createdAt"))
    kind = _text(data.get("type")) or "unknown"
    rows: list[WalletLedgerEntry] = []
    for currency, field, _balance in _CURRENCIES:
        if field not in data:
            continue
        amount = _stored_int(data.get(field))
        if amount is None:
            continue
        rows.append(
            WalletLedgerEntry(
                id=snap.id,
                timeKst=when,
                type=kind,
                currency=currency,
                amount=amount,
                relatedId=related,
            )
        )
    if rows:
        return rows
    return [
        WalletLedgerEntry(
            id=snap.id,
            timeKst=when,
            type=kind,
            currency="-",
            amount=0,
            relatedId=related,
        )
    ]


def _related(data: dict) -> str | None:
    for key in _RELATED:
        text = _text(data.get(key))
        if text:
            return text
    return None


def _wallet_balance(user: dict, key: str) -> int:
    wallet = user.get("wallet") if isinstance(user.get("wallet"), dict) else {}
    keys = (key, "valueBalance") if key == "valueTokenBalance" else (key,)
    for name in keys:
        if name in wallet:
            number = _stored_int(wallet.get(name))
            return 0 if number is None else number
    for name in keys:
        if name in user:
            number = _stored_int(user.get(name))
            return 0 if number is None else number
    return 0


def _time_kst(value: object) -> str | None:
    if isinstance(value, datetime):
        current = value if value.tzinfo else value.replace(tzinfo=timezone.utc)
        return current.astimezone(_KST).strftime("%Y-%m-%d %H:%M:%S")
    if isinstance(value, str):
        text = value.strip()
        if not text:
            return None
        try:
            parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
        except ValueError:
            return text
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(_KST).strftime("%Y-%m-%d %H:%M:%S")
    return None


def _uid(uid: str) -> str:
    text = uid.strip()
    if not text or "/" in text or len(text) > 128:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid uid.",
        )
    return text


def _stored_int(value: object) -> int | None:
    if isinstance(value, bool) or value is None:
        return None
    if isinstance(value, int):
        return value
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return None


def _text(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    text = value.strip()
    return text or None


admin_wallet_ledger_service = AdminWalletLedgerService()
