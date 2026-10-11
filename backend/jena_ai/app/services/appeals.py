"""Appeals (소명) for a run the server did not accept.

The app sends the reason and one proof photo to the server. The server checks
that the run is the caller's, was rejected, is recent and has not been
appealed yet, then writes the appeal, the photo and the run's lock together.
Clients cannot write any of these directly.

The photo is kept in `appealProofs/{appealId}` with a `purgeAt` date 14 days
out (a Firestore TTL policy on `purgeAt` removes it). Ids are derived from the
run id, so sending the same appeal twice changes nothing.
"""

import base64
import binascii
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

PROOF_TTL = timedelta(days=14)
MAX_PROOF_BYTES = 700 * 1024
_IMAGE_MAGIC = (b"\xff\xd8\xff", b"\x89PNG\r\n\x1a\n")


def appeal_id_for(activity_id: str) -> str:
    return f"appeal-{activity_id}"


def decode_proof(raw: str) -> bytes:
    try:
        data = base64.b64decode(raw, validate=True)
    except (binascii.Error, ValueError):
        raise HTTPException(status_code=400, detail="invalid_proof_image")
    if not data or not data.startswith(_IMAGE_MAGIC):
        raise HTTPException(status_code=400, detail="invalid_proof_image")
    if len(data) > MAX_PROOF_BYTES:
        raise HTTPException(status_code=413, detail="proof_image_too_large")
    return data


def _clip(value: object, limit: int) -> str:
    if not isinstance(value, str):
        return ""
    cleaned = "".join(ch if ch.isprintable() else " " for ch in value)
    return " ".join(cleaned.split())[:limit]


def _as_utc(value: object) -> datetime | None:
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    return None


def submit_appeal(
    db,
    uid: str,
    *,
    activity_id: str,
    reason_category: str,
    reason_detail: str,
    proof_base64: str,
    now: datetime | None = None,
) -> dict:
    now = now or datetime.now(timezone.utc)
    proof = decode_proof(proof_base64)
    category = _clip(reason_category, 40) or "other"

    activity_ref = db.collection("activities").document(activity_id)
    snap = activity_ref.get()
    activity = snap.to_dict() if snap.exists else None
    if not activity or activity.get("userId") != uid:
        raise HTTPException(status_code=404, detail="activity_not_found")

    appeal_id = appeal_id_for(activity_id)
    if activity.get("appealStatus") == "under_review" and activity.get("appealId") == appeal_id:
        return {"status": "under_review", "appeal_id": appeal_id}
    if activity.get("appealStatus"):
        raise HTTPException(status_code=409, detail="already_decided")
    if activity.get("jenaVerified") is True or not str(
        activity.get("jenaDecision") or ""
    ).startswith("rejected"):
        raise HTTPException(status_code=400, detail="not_appealable")
    completed = _as_utc(activity.get("completedAt"))
    if completed is not None and now - completed > PROOF_TTL:
        raise HTTPException(status_code=400, detail="appeal_window_closed")

    user = db.collection("users").document(uid).get()
    nickname = _clip((user.to_dict() or {}).get("nickname"), 40) if user.exists else ""
    purge_at = now + PROOF_TTL

    db.collection("appealProofs").document(appeal_id).set(
        {
            "userId": uid,
            "activityId": activity_id,
            "contentType": "image/png" if proof.startswith(_IMAGE_MAGIC[1]) else "image/jpeg",
            "bytes": proof,
            "createdAt": SERVER_TIMESTAMP,
            "purgeAt": purge_at,
        }
    )
    db.collection("appeals").document(appeal_id).set(
        {
            "appealId": appeal_id,
            "userId": uid,
            "userNickname": nickname,
            "activityId": activity_id,
            "reasonCategory": category,
            "reasonDetail": _clip(reason_detail, 500),
            "proofRef": f"appealProofs/{appeal_id}",
            "status": "under_review",
            "adminQueue": "src-admin-2",
            "jenaReason": _clip(activity.get("jenaReason"), 300),
            "distanceKm": activity.get("distanceKm"),
            "ttlDays": 14,
            "purgeOnAdminDecision": True,
            "retentionPolicy": "purge_on_admin_decision_or_14d",
            "createdAt": SERVER_TIMESTAMP,
            "updatedAt": SERVER_TIMESTAMP,
            "expireAt": purge_at,
            "purgeAt": purge_at,
        }
    )
    activity_ref.set(
        {
            "appealStatus": "under_review",
            "appealId": appeal_id,
            "locked": True,
            "updatedAt": SERVER_TIMESTAMP,
        },
        merge=True,
    )
    return {"status": "under_review", "appeal_id": appeal_id}
