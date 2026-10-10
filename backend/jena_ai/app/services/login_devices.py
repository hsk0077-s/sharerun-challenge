"""Devices signed in to an account, and sign-out on every device.

`users/{uid}/loginDevices/{deviceId}` keeps model, OS, app version and the last
time the device was seen. No IP address and no location are stored.
"""

import re

from google.cloud.firestore_v1 import SERVER_TIMESTAMP

MAX_LISTED = 20
_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{8,128}$")


def clean_device_id(raw: object) -> str | None:
    if isinstance(raw, str) and _ID_PATTERN.match(raw.strip()):
        return raw.strip()
    return None


def _clip(value: object, limit: int) -> str:
    if not isinstance(value, str):
        return ""
    cleaned = "".join(ch if ch.isprintable() else " " for ch in value)
    return " ".join(cleaned.split())[:limit]


def _devices(db, uid: str):
    return db.collection("users").document(uid).collection("loginDevices")


def register_device(
    db, uid: str, device_id: str, *, model: str, os_version: str, app_version: str
) -> None:
    ref = _devices(db, uid).document(device_id)
    fields = {
        "deviceId": device_id,
        "model": _clip(model, 80),
        "osVersion": _clip(os_version, 80),
        "appVersion": _clip(app_version, 32),
        "lastSeenAt": SERVER_TIMESTAMP,
    }
    if not ref.get().exists:
        fields["firstSeenAt"] = SERVER_TIMESTAMP
    ref.set(fields, merge=True)


def _iso(value: object) -> str:
    return value.isoformat() if hasattr(value, "isoformat") else ""


def list_devices(db, uid: str, current_id: str | None) -> list[dict]:
    rows = []
    for snapshot in _devices(db, uid).get():
        data = snapshot.to_dict() or {}
        rows.append(
            {
                "device_id": data.get("deviceId", ""),
                "model": data.get("model", ""),
                "os_version": data.get("osVersion", ""),
                "app_version": data.get("appVersion", ""),
                "last_seen_at": _iso(data.get("lastSeenAt")),
                "current": bool(current_id) and data.get("deviceId") == current_id,
            }
        )
    rows.sort(key=lambda row: row["last_seen_at"], reverse=True)
    return rows[:MAX_LISTED]


def sign_out_everywhere(db, uid: str, revoke) -> None:
    """Revoke every login of the account, then clear the device list.

    `revoke(uid)` invalidates the refresh tokens. The change is logged once,
    append-only, in `securityLog`.
    """
    revoke(uid)
    for snapshot in _devices(db, uid).get():
        _devices(db, uid).document(snapshot.id).delete()
    db.collection("securityLog").document().set(
        {"uid": uid, "type": "sign_out_everywhere", "createdAt": SERVER_TIMESTAMP}
    )
