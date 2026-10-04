"""Google Play product purchase checks. Missing credentials never grant DIA."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
from urllib.parse import quote

from fastapi import HTTPException

_ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher"


def purchase_token_hash(purchase_token: str) -> str:
    return hashlib.sha256(purchase_token.encode("utf-8")).hexdigest()


def dia_pack_by_id(product_id: str) -> dict | None:
    from app.constants.economy_constants import DIA_PACKS

    for pack in DIA_PACKS:
        if pack["productId"] == product_id:
            return pack
    return None


def verify_play_product_purchase(product_id: str, purchase_token: str) -> None:
    """Reject unless Android Publisher reports purchaseState purchased (0)."""
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


def consume_play_product_purchase(product_id: str, purchase_token: str) -> None:
    """Consume a verified product so it can be bought again. No-op without credentials."""
    opened = _play_session()
    if opened is None:
        return
    session, package = opened
    url = (
        "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/"
        f"{quote(package, safe='')}/purchases/products/"
        f"{quote(product_id, safe='')}/tokens/{quote(purchase_token, safe='')}:consume"
    )
    session.post(url, timeout=15)


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
