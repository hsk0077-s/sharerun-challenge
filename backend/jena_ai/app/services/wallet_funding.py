"""Paid and free SHARE / DIA buckets.

Missing bucket fields mean the existing balance is free. Spends take free
first. Cash refunds take paid first so unused paid currency can be returned.
"""

from fastapi import HTTPException


def move_currency(
    wallet: dict,
    *,
    share: int = 0,
    diamond: int = 0,
    paid_credit: bool = False,
    paid_first: bool = False,
) -> dict:
    """Apply a signed delta. Mutates ``wallet`` and returns updates + ledger split."""
    state = resolved_buckets(wallet)
    ledger: dict[str, int] = {}
    updates: dict[str, int] = {}
    if share:
        free_delta, paid_delta = _apply(
            state,
            "free_share",
            "paid_share",
            share,
            paid_credit=paid_credit,
            paid_first=paid_first,
            label="Share",
        )
        state["share"] += share
        ledger["shareFreeAmount"] = free_delta
        ledger["sharePaidAmount"] = paid_delta
        updates["wallet.shareBalance"] = state["share"]
        updates["wallet.freeShareBalance"] = state["free_share"]
        updates["wallet.paidShareBalance"] = state["paid_share"]
    if diamond:
        free_delta, paid_delta = _apply(
            state,
            "free_diamond",
            "paid_diamond",
            diamond,
            paid_credit=paid_credit,
            paid_first=paid_first,
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
    label: str,
) -> tuple[int, int]:
    if delta > 0:
        if paid_credit:
            state[paid_key] += delta
            return 0, delta
        state[free_key] += delta
        return delta, 0
    need = -delta
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


def _write(wallet: dict, state: dict) -> None:
    wallet["shareBalance"] = state["share"]
    wallet["freeShareBalance"] = state["free_share"]
    wallet["paidShareBalance"] = state["paid_share"]
    wallet["diamondBalance"] = state["diamond"]
    wallet["freeDiamondBalance"] = state["free_diamond"]
    wallet["paidDiamondBalance"] = state["paid_diamond"]
