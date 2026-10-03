"""Paid and free buckets. Existing balances with no split count as free."""

import pytest
from fastapi import HTTPException

from app.services.wallet_funding import assign_free_balances, move_currency, resolved_buckets


def test_missing_buckets_count_as_free() -> None:
    wallet = {"shareBalance": 1_000_000, "diamondBalance": 1_000_000}
    state = resolved_buckets(wallet)
    assert state["free_share"] == 1_000_000
    assert state["paid_share"] == 0
    assert state["free_diamond"] == 1_000_000
    assert state["paid_diamond"] == 0


def test_spend_takes_free_before_paid() -> None:
    wallet = {
        "shareBalance": 25,
        "freeShareBalance": 10,
        "paidShareBalance": 15,
        "diamondBalance": 8,
        "freeDiamondBalance": 3,
        "paidDiamondBalance": 5,
    }
    share = move_currency(wallet, share=-12)
    assert share["ledger"] == {"shareFreeAmount": -10, "sharePaidAmount": -2}
    assert wallet["shareBalance"] == 13
    assert wallet["freeShareBalance"] == 0
    assert wallet["paidShareBalance"] == 13

    diamond = move_currency(wallet, diamond=-4)
    assert diamond["ledger"] == {"diamondFreeAmount": -3, "diamondPaidAmount": -1}
    assert wallet["diamondBalance"] == 4
    assert wallet["freeDiamondBalance"] == 0
    assert wallet["paidDiamondBalance"] == 4


def test_paid_credit_and_paid_first_refund() -> None:
    wallet = {"shareBalance": 40}
    credited = move_currency(wallet, share=100, paid_credit=True)
    assert credited["ledger"]["sharePaidAmount"] == 100
    assert wallet["freeShareBalance"] == 40
    assert wallet["paidShareBalance"] == 100
    assert wallet["shareBalance"] == 140

    refunded = move_currency(wallet, share=-30, paid_first=True)
    assert refunded["ledger"] == {"shareFreeAmount": 0, "sharePaidAmount": -30}
    assert wallet["paidShareBalance"] == 70
    assert wallet["freeShareBalance"] == 40


def test_test_grant_amount_stays_free() -> None:
    wallet = {"shareBalance": 5, "diamondBalance": 5, "totalDonationValue": 9}
    moved = assign_free_balances(wallet, share=1_000_000, diamond=1_000_000)
    assert moved["updates"]["wallet.shareBalance"] == 1_000_000
    assert moved["updates"]["wallet.freeShareBalance"] == 1_000_000
    assert moved["updates"]["wallet.paidShareBalance"] == 0
    assert wallet["totalDonationValue"] == 9


def test_short_bucket_still_reports_insufficient() -> None:
    wallet = {"shareBalance": 1, "freeShareBalance": 1, "paidShareBalance": 0}
    with pytest.raises(HTTPException) as exc:
        move_currency(wallet, share=-5)
    assert exc.value.detail == "Insufficient Share balance."
