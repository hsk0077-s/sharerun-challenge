"""Load project-root .env before other app modules read os.environ."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv

# Checkout: <repo>/backend/jena_ai/app/config.py -> parents[3] is <repo>.
# Cloud Run copies app/ to /app/app/config.py, which has no parents[3].
_REPO_ROOT_DEPTH = 3


def repo_root_from(config_file: Path) -> Path | None:
    parents = config_file.resolve().parents
    if len(parents) <= _REPO_ROOT_DEPTH:
        return None
    return parents[_REPO_ROOT_DEPTH]


def dotenv_path(config_file: Path) -> Path | None:
    root = repo_root_from(config_file)
    if root is None:
        return None
    env_file = root / ".env"
    if not env_file.is_file():
        return None
    return env_file


def load_repo_dotenv(config_file: Path | None = None) -> bool:
    env_file = dotenv_path(config_file or Path(__file__))
    if env_file is None:
        return False
    return bool(load_dotenv(env_file, override=False))


_REPO_ROOT = repo_root_from(Path(__file__))
load_repo_dotenv()


def repo_root() -> Path | None:
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
