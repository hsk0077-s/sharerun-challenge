"""Load project-root .env before other app modules read os.environ."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

_REPO_ROOT = Path(__file__).resolve().parents[3]
_ENV_FILE = _REPO_ROOT / ".env"
_LOADED = load_dotenv(_ENV_FILE, override=False)


def repo_root() -> Path:
    return _REPO_ROOT


def is_local_dev_mode() -> bool:
    return os.getenv("LOCAL_DEV_MODE", "").lower() in {"1", "true", "yes"}


def test_wallet_grant_uids() -> frozenset[str]:
    from app.constants.economy_constants import TEST_WALLET_GRANT_UIDS

    raw = os.getenv("TEST_WALLET_GRANT_UIDS", "")
    from_env = {part.strip() for part in raw.split(",") if part.strip()}
    return frozenset(TEST_WALLET_GRANT_UIDS) | from_env


def test_wallet_grant_secret() -> str:
    return os.getenv("TEST_WALLET_GRANT_SECRET", "").strip()
