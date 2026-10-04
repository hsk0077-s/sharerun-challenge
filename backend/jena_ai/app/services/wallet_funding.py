"""Paid and free SHARE / DIA buckets.

Missing bucket fields mean the existing balance is free. Spends take free
first. Cash refunds take paid first so unused paid currency can be returned.
Referral SHARE can be locked inside the free bucket so it is not exchangeable.
"""

from datetime import datetime, timezone

from fastapi import HTTPException


def move_currency(
    wallet: dict,
    *,
    share: int = 0,
    diamond: int = 0,
    paid_credit: bool = False,
    paid_first: bool = False,
    paid_only: bool = False,
    for_exchange: bool = False,
    lock_until: datetime | None = None,
    now: datetime | None = None,
) -> dict:
    """Apply a signed delta. Mutates ``wallet`` and returns updates + ledger split."""
    current = now or datetime.now(timezone.utc)
    locked, locks = _active_locks(wallet, current)
    state = resolved_buckets(wallet)
    locked = min(locked, state["free_share"])
    unlocked = state["free_share"] - locked
    ledger: dict[str, int] = {}
    updates: dict = {}
    if share:
        hidden = locked if share < 0 and for_exchange else 0
        if hidden:
            state["free_share"] -= hidden
        free_delta, paid_delta = _apply(
            state,
            "free_share",
            "paid_share",
            share,
            paid_credit=paid_credit,
            paid_first=paid_first,
            paid_only=paid_only,
            label="Share",
        )
        if hidden:
            state["free_share"] += hidden
        elif share < 0:
            spent_locked = max(0, -free_delta - unlocked)
            locked -= spent_locked
            locks = _consume_locks(locks, spent_locked)
        if share > 0 and lock_until is not None:
            locks = [
                *locks,
                {"amount": share, "unlockAt": lock_until.isoformat()},
            ]
            locked += share
        state["share"] += share
        ledger["shareFreeAmount"] = free_delta
        ledger["sharePaidAmount"] = paid_delta
        updates["wallet.shareBalance"] = state["share"]
        updates["wallet.freeShareBalance"] = state["free_share"]
        updates["wallet.paidShareBalance"] = state["paid_share"]
        if locks or int(wallet.get("lockedReferralShare") or 0):
            updates["wallet.lockedReferralShare"] = locked
            updates["wallet.referralShareLocks"] = locks
            wallet["lockedReferralShare"] = locked
            wallet["referralShareLocks"] = locks
    if diamond:
        free_delta, paid_delta = _apply(
            state,
            "free_diamond",
            "paid_diamond",
            diamond,
            paid_credit=paid_credit,
            paid_first=paid_first,
            paid_only=paid_only,
            label="Diamond",
        )
        state["diamond"] += diamond
        ledger["diamondFreeAmount"] = free_delta
        ledger["diamondPaidAmount"] = paid_delta
        updates["wallet.diamondBalance"] = state["diamond"]
        updates["wallet.freeDiamondBalance"] = state["free_diamond"]
        updates["wallet.paidDiamondBalance"] = state["paid_diamond"]
    _write(wallet, state)
    return {"updates": updates, "ledger": ledger}


def assign_free_balances(
    wallet: dict,
    *,
    share: int | None = None,
    diamond: int | None = None,
) -> dict:
    """Set a balance as entirely free. Used by the 1,000,000 test grant."""
    state = resolved_buckets(wallet)
    updates: dict[str, int] = {}
    ledger: dict[str, int] = {}
    if share is not None:
        state["share"] = share
        state["free_share"] = share
        state["paid_share"] = 0
        updates["wallet.shareBalance"] = share
        updates["wallet.freeShareBalance"] = share
        updates["wallet.paidShareBalance"] = 0
        ledger["shareFreeAmount"] = share
        ledger["sharePaidAmount"] = 0
    if diamond is not None:
        state["diamond"] = diamond
        state["free_diamond"] = diamond
        state["paid_diamond"] = 0
        updates["wallet.diamondBalance"] = diamond
        updates["wallet.freeDiamondBalance"] = diamond
        updates["wallet.paidDiamondBalance"] = 0
        ledger["diamondFreeAmount"] = diamond
        ledger["diamondPaidAmount"] = 0
    _write(wallet, state)
    return {"updates": updates, "ledger": ledger}


def resolved_buckets(wallet: dict | None) -> dict:
    wallet = wallet or {}
    share = int(wallet.get("shareBalance") or 0)
    diamond = int(wallet.get("diamondBalance") or 0)
    free_share, paid_share = _pair(
        wallet, share, "freeShareBalance", "paidShareBalance"
    )
    free_diamond, paid_diamond = _pair(
        wallet, diamond, "freeDiamondBalance", "paidDiamondBalance"
    )
    return {
        "share": share,
        "free_share": free_share,
        "paid_share": paid_share,
        "diamond": diamond,
        "free_diamond": free_diamond,
        "paid_diamond": paid_diamond,
    }


def _pair(wallet: dict, total: int, free_key: str, paid_key: str) -> tuple[int, int]:
    if free_key not in wallet and paid_key not in wallet:
        return total, 0
    free = int(wallet.get(free_key) or 0)
    paid = int(wallet.get(paid_key) or 0)
    drift = total - free - paid
    if drift > 0:
        free += drift
    elif drift < 0:
        overflow = -drift
        cut = min(paid, overflow)
        paid -= cut
        overflow -= cut
        free = max(0, free - overflow)
    return free, paid


def _apply(
    state: dict,
    free_key: str,
    paid_key: str,
    delta: int,
    *,
    paid_credit: bool,
    paid_first: bool,
    paid_only: bool,
    label: str,
) -> tuple[int, int]:
    if delta > 0:
        if paid_credit:
            state[paid_key] += delta
            return 0, delta
        state[free_key] += delta
        return delta, 0
    need = -delta
    if paid_only:
        if state[paid_key] < need:
            raise HTTPException(
                status_code=400,
                detail=f"Insufficient paid {label} balance.",
            )
        state[paid_key] -= need
        return 0, -need
    if paid_first:
        take_paid = min(need, state[paid_key])
        take_free = need - take_paid
        if take_free > state[free_key]:
            raise HTTPException(status_code=400, detail=f"Insufficient {label} balance.")
    else:
        take_free = min(need, state[free_key])
        take_paid = need - take_free
        if take_paid > state[paid_key]:
            raise HTTPException(status_code=400, detail=f"Insufficient {label} balance.")
    state[free_key] -= take_free
    state[paid_key] -= take_paid
    return -take_free, -take_paid


def exchange_spendable(wallet: dict, now: datetime | None = None) -> tuple[int, int]:
    """SHARE that can be exchanged, and referral SHARE still inside the 30-day lock."""
    current = now or datetime.now(timezone.utc)
    state = resolved_buckets(wallet)
    locked, _locks = _active_locks(wallet, current)
    locked = min(locked, state["free_share"])
    return state["free_share"] - locked + state["paid_share"], locked


def _active_locks(wallet: dict, now: datetime) -> tuple[int, list]:
    kept = []
    locked = 0
    for row in wallet.get("referralShareLocks") or []:
        if not isinstance(row, dict):
            continue
        amount = int(row.get("amount") or 0)
        if amount <= 0:
            continue
        unlock_at = _parse_time(row.get("unlockAt"))
        if unlock_at is not None and unlock_at <= now:
            continue
        kept.append({"amount": amount, "unlockAt": row.get("unlockAt")})
        locked += amount
    if not kept and int(wallet.get("lockedReferralShare") or 0) > 0:
        locked = int(wallet.get("lockedReferralShare") or 0)
    return locked, kept


def _consume_locks(locks: list, amount: int) -> list:
    if amount <= 0:
        return locks
    kept = []
    left = amount
    for row in locks:
        row_amount = int(row.get("amount") or 0)
        if left <= 0:
            kept.append(row)
            continue
        if row_amount <= left:
            left -= row_amount
            continue
        kept.append({**row, "amount": row_amount - left})
        left = 0
    return kept


def _parse_time(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value)
    except ValueError:
        return None
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


def _write(wallet: dict, state: dict) -> None:
    wallet["shareBalance"] = state["share"]
    wallet["freeShareBalance"] = state["free_share"]
    wallet["paidShareBalance"] = state["paid_share"]
    wallet["diamondBalance"] = state["diamond"]
    wallet["freeDiamondBalance"] = state["free_diamond"]
    wallet["paidDiamondBalance"] = state["paid_diamond"]
