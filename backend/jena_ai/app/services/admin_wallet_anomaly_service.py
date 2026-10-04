from fastapi import HTTPException, status
from google.cloud.firestore_v1.field_path import FieldPath

from app.constants.economy_constants import (
    TEST_WALLET_GRANT_AMOUNT,
    TEST_WALLET_GRANT_FLAG,
)
from app.models.admin_api import WalletAnomalyListResult, WalletAnomalyRow
from app.services.firebase_service import FirebaseService

DEFAULT_LIMIT = 20
MAX_LIMIT = 40
LEDGER_CAP = 80
INTENT_CAP = 40


class AdminWalletAnomalyService:
    """Reads wallets and the server ledger. Does not write."""

    def __init__(self, firebase_service: FirebaseService | None = None) -> None:
        self.firebase_service = firebase_service

    def list_anomalies(
        self,
        *,
        uid: str | None = None,
        limit: int = DEFAULT_LIMIT,
        cursor: str | None = None,
    ) -> WalletAnomalyListResult:
        owner = _uid(uid)
        db = self._db()
        if owner:
            snap = db.collection("users").document(owner).get()
            users = [snap] if getattr(snap, "exists", False) else []
            next_cursor = None
            page_size = 1
        else:
            page_size = _page_size(limit)
            query = (
                db.collection("users")
                .order_by(FieldPath.document_id())
                .limit(page_size + 1)
            )
            start = _cursor(cursor)
            if start:
                query = query.start_after(
                    [db.collection("users").document(start)]
                )
            docs = list(query.stream())
            has_more = len(docs) > page_size
            users = docs[:page_size]
            next_cursor = users[-1].id if has_more and users else None
        rows: list[WalletAnomalyRow] = []
        truncated = False
        for user in users:
            found, hit_cap = self._for_user(db, user.id, user.to_dict() or {})
            rows.extend(found)
            truncated = truncated or hit_cap
        return WalletAnomalyListResult(
            rows=rows,
            nextCursor=next_cursor,
            limit=page_size,
            truncated=truncated,
        )

    def _db(self):
        service = self.firebase_service or FirebaseService()
        return service.db

    def _for_user(self, db, uid: str, user: dict) -> tuple[list[WalletAnomalyRow], bool]:
        ledger = list(
            db.collection("walletTransactions")
            .where("uid", "==", uid)
            .limit(LEDGER_CAP)
            .stream()
        )
        intents = list(
            db.collection("paymentIntents")
            .where("uid", "==", uid)
            .limit(INTENT_CAP)
            .stream()
        )
        truncated = len(ledger) >= LEDGER_CAP or len(intents) >= INTENT_CAP
        share, diamond, value = _balances(user)
        rows: list[WalletAnomalyRow] = []
        grant = _grant_detail(user, ledger)
        if grant:
            rows.append(
                WalletAnomalyRow(
                    uid=uid,
                    reason="debug_test_grant_1m",
                    detail=grant,
                    shareBalance=share,
                    diamondBalance=diamond,
                    valueTokenBalance=value,
                )
            )
        negative = _negative_detail(share, diamond, value)
        if negative:
            rows.append(
                WalletAnomalyRow(
                    uid=uid,
                    reason="negative_balance",
                    detail=negative,
                    shareBalance=share,
                    diamondBalance=diamond,
                    valueTokenBalance=value,
                )
            )
        for snap in intents:
            data = snap.to_dict() or {}
            if data.get("status") != "amount_mismatch":
                continue
            rows.append(
                WalletAnomalyRow(
                    uid=uid,
                    reason="payment_amount_mismatch",
                    detail=_intent_detail(snap.id, data),
                    receiptId=snap.id,
                    amount=_stored_int(
                        data.get("pgAmount")
                        if data.get("pgAmount") is not None
                        else data.get("amountKrw") or data.get("amountShare")
                    ),
                )
            )
        return rows, truncated


def _grant_detail(user: dict, ledger: list) -> str | None:
    parts: list[str] = []
    if user.get(TEST_WALLET_GRANT_FLAG) is True:
        parts.append(TEST_WALLET_GRANT_FLAG)
    share, diamond, value = _balances(user)
    amount = TEST_WALLET_GRANT_AMOUNT
    if share == amount:
        parts.append(f"shareBalance={amount}")
    if diamond == amount:
        parts.append(f"diamondBalance={amount}")
    if value == amount:
        parts.append(f"valueTokenBalance={amount}")
    if any((snap.to_dict() or {}).get("type") == "debug_test_grant_1m" for snap in ledger):
        parts.append("원장 type=debug_test_grant_1m")
    if not parts:
        return None
    return "디버그 테스트 지급 흔적: " + ", ".join(parts)


def _negative_detail(
    share: int | None,
    diamond: int | None,
    value: int | None,
) -> str | None:
    parts = []
    if share is not None and share < 0:
        parts.append(f"shareBalance={share}")
    if diamond is not None and diamond < 0:
        parts.append(f"diamondBalance={diamond}")
    if value is not None and value < 0:
        parts.append(f"valueTokenBalance={value}")
    if not parts:
        return None
    return "음수 잔액: " + ", ".join(parts)


def _intent_detail(intent_id: str, data: dict) -> str:
    expected = data.get("amountKrw")
    if expected is None:
        expected = data.get("amountShare")
    return (
        f"paymentIntents/{intent_id} status=amount_mismatch "
        f"expected={expected} pgAmount={data.get('pgAmount')}"
    )


def _balances(user: dict) -> tuple[int | None, int | None, int | None]:
    return (
        _balance(user, "shareBalance"),
        _balance(user, "diamondBalance"),
        _balance(user, "valueTokenBalance", "valueBalance"),
    )


def _balance(user: dict, *keys: str) -> int | None:
    wallet = user.get("wallet") if isinstance(user.get("wallet"), dict) else {}
    for key in keys:
        if key in wallet:
            return _stored_int(wallet.get(key))
    for key in keys:
        if key in user:
            return _stored_int(user.get(key))
    return None


def _page_size(limit: int) -> int:
    if limit < 1:
        return DEFAULT_LIMIT
    return min(limit, MAX_LIMIT)


def _cursor(cursor: str | None) -> str | None:
    if cursor is None:
        return None
    text = cursor.strip()
    if not text:
        return None
    if "/" in text or len(text) > 128:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid cursor.",
        )
    return text


def _uid(uid: str | None) -> str | None:
    if uid is None:
        return None
    text = uid.strip()
    if not text:
        return None
    if "/" in text or len(text) > 128:
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


admin_wallet_anomaly_service = AdminWalletAnomalyService()
