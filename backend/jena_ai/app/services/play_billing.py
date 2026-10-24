"""Google Play product purchase checks. Missing credentials never grant DIA."""

from __future__ import annotations

import hashlib
import json
import logging
import os
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote

from fastapi import HTTPException

logger = logging.getLogger(__name__)

_ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def purchase_token_hash(purchase_token: str) -> str:
    return hashlib.sha256(purchase_token.encode("utf-8")).hexdigest()


def dia_pack_by_id(product_id: str) -> dict | None:
    from app.constants.economy_constants import DIA_PACKS

    for pack in DIA_PACKS:
        if pack["productId"] == product_id:
            return pack
    return None


def verify_play_product_purchase(product_id: str, purchase_token: str) -> dict:
    """Reject unless Android Publisher reports purchaseState purchased (0). Returns the body."""
    session, package = _authorized_session()
    url = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{quote(package, safe='')}/purchases/products/"
        f"{quote(product_id, safe='')}/tokens/{quote(purchase_token, safe='')}"
    )
    response = session.get(url, timeout=15)
    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Purchase token could not be verified.")
    body = response.json()
    if int(body.get("purchaseState", -1)) != 0:
        raise HTTPException(status_code=400, detail="Purchase is not completed.")
    return body


# A subscription still pays for access in these states. A user who cancelled keeps access
# until the period they already paid for ends; ON_HOLD, PAUSED, EXPIRED and PENDING do not.
ENTITLED_SUBSCRIPTION_STATES = {
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_CANCELED",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
}


def verify_play_subscription(product_id: str, purchase_token: str) -> dict:
    """Reject unless Play says this token is a paid-up subscription to ``product_id``.

    Returns ``{"orderId", "expiresAt" (aware datetime), "state"}``. The expiry is the one Play
    reports, never one the client or the server makes up.
    """
    session, package = _authorized_session()
    url = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{quote(package, safe='')}/purchases/subscriptionsv2/tokens/"
        f"{quote(purchase_token, safe='')}"
    )
    response = session.get(url, timeout=15)
    if response.status_code != 200:
        raise HTTPException(status_code=400, detail="Subscription token could not be verified.")
    body = response.json() or {}
    state = str(body.get("subscriptionState", ""))
    if state not in ENTITLED_SUBSCRIPTION_STATES:
        raise HTTPException(status_code=400, detail="Subscription is not active.")
    expiry = None
    for item in body.get("lineItems") or []:
        if not isinstance(item, dict) or item.get("productId") != product_id:
            continue
        parsed = _parse_rfc3339(item.get("expiryTime"))
        if parsed is not None and (expiry is None or parsed > expiry):
            expiry = parsed
    if expiry is None:
        raise HTTPException(status_code=400, detail="Subscription does not match this product.")
    if expiry <= datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Subscription has expired.")
    return {"orderId": body.get("latestOrderId"), "expiresAt": expiry, "state": state}


def _parse_rfc3339(value) -> datetime | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def list_voided_purchases(start_ms: int, end_ms: int) -> list[dict]:
    """Orders Play refunded or charged back between the two times (milliseconds since epoch).

    Covers one-time products and subscriptions (``type=1``). Play keeps about 30 days of
    history, so callers ask for a recent window and repeat it on a schedule.
    """
    session, package = _authorized_session()
    url = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{quote(package, safe='')}/purchases/voidedpurchases"
    )
    voided: list[dict] = []
    page_token: str | None = None
    for _ in range(20):  # a hard stop so a bad page token can never loop forever
        params: dict = {
            "startTime": str(start_ms),
            "endTime": str(end_ms),
            "maxResults": "1000",
            "type": "1",
        }
        if page_token:
            params["token"] = page_token
        response = session.get(url, params=params, timeout=30)
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="Play voided purchases could not be read.")
        body = response.json() or {}
        voided.extend(row for row in body.get("voidedPurchases") or [] if isinstance(row, dict))
        page_token = (body.get("tokenPagination") or {}).get("nextPageToken")
        if not page_token:
            break
    return voided


def consume_play_product_purchase(product_id: str, purchase_token: str) -> bool:
    """Consume a verified product so it can be bought again.

    False when nothing was consumed (no credentials, or Play refused). Play refunds a
    purchase that is never acknowledged or consumed after about three days, so a refusal
    is logged for the operator. The DIA is already granted, so this never raises.
    """
    opened = _play_session()
    if opened is None:
        return False
    session, package = opened
    url = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{quote(package, safe='')}/purchases/products/"
        f"{quote(product_id, safe='')}/tokens/{quote(purchase_token, safe='')}:consume"
    )
    try:
        response = session.post(url, timeout=15)
    except Exception:  # network trouble must not undo a grant that already committed
        logger.warning("Play consume failed for %s", product_id, exc_info=True)
        return False
    if 200 <= response.status_code < 300:
        return True
    logger.warning(
        "Play consume refused for %s (HTTP %s); it may be refunded if left unconsumed",
        product_id,
        response.status_code,
    )
    return False


def refund_play_order(order_id: str) -> bool:
    """Refund an order through Google Play. False when no service account is configured."""
    opened = _play_session()
    if opened is None:
        return False
    session, package = opened
    url = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{quote(package, safe='')}/orders/{quote(order_id, safe='')}:refund"
    )
    response = session.post(url, timeout=15)
    return 200 <= response.status_code < 300


def _authorized_session():
    opened = _play_session()
    if opened is None:
        raise HTTPException(
            status_code=503,
            detail="Play purchase verification is not configured.",
        )
    return opened


def _play_session():
    package = os.getenv("GOOGLE_PLAY_PACKAGE_NAME", "").strip()
    raw = os.getenv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", "").strip()
    if not package or not raw:
        return None
    try:
        from google.auth.transport.requests import AuthorizedSession
        from google.oauth2 import service_account
    except ImportError as exc:
        raise HTTPException(
            status_code=503,
            detail="Play purchase verification is not configured.",
        ) from exc
    info = json.loads(raw) if raw.startswith("{") else json.loads(Path(raw).read_text())
    credentials = service_account.Credentials.from_service_account_info(
        info,
        scopes=[_ANDROID_PUBLISHER_SCOPE],
    )
    return AuthorizedSession(credentials), package
