"""Allow-list for the phone diagnostics stored on an activity."""

from app.models.secured_actions import RunDeviceInfo


def _clip(value: object, limit: int) -> str:
    if not isinstance(value, str):
        return ""
    cleaned = "".join(
        ch if ch.isprintable() and ch not in "\r\n\t" else " " for ch in value
    )
    collapsed = " ".join(cleaned.split())
    return collapsed[:limit]


def device_info_document(info: RunDeviceInfo | None) -> dict | None:
    """Fields an admin can use to diagnose a rejection. Nothing else."""
    if info is None:
        return None
    return {
        "model": _clip(info.model, 80),
        "osVersion": _clip(info.os_version, 80),
        "appVersion": _clip(info.app_version, 32),
        "watchUsed": info.watch_used is True,
        "heartRateUsed": info.heart_rate_used is True,
    }
