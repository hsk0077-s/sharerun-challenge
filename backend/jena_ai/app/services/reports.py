"""Player reports of an inappropriate nickname or crew name.

A report is a row in `reports` for the operator to review. It never changes the
reported player's account by itself. One report per reporter and target, so the
same person cannot flood the queue.
"""

from fastapi import HTTPException
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

REASONS = {"offensive_name", "sexual", "hate", "spam", "other"}
TARGET_TYPES = {"crew", "user"}


def submit_report(
    db,
    uid: str,
    target_type: str,
    target_id: str,
    reason: str,
    detail: str = "",
) -> dict:
    if target_type not in TARGET_TYPES or reason not in REASONS:
        raise HTTPException(status_code=400, detail="Invalid report.")
    target_id = (target_id or "").strip()
    if not target_id or "/" in target_id or len(target_id) > 128:
        raise HTTPException(status_code=400, detail="Invalid report.")
    if target_type == "user" and target_id == uid:
        raise HTTPException(status_code=400, detail="You cannot report yourself.")

    collection = "crews" if target_type == "crew" else "users"
    target = db.collection(collection).document(target_id).get()
    if not target.exists:
        raise HTTPException(status_code=404, detail="Report target not found.")
    data = target.to_dict() or {}
    name = data.get("name") if target_type == "crew" else data.get("nickname")

    report_ref = db.collection("reports").document(f"{uid}_{target_type}_{target_id}")
    if report_ref.get().exists:
        return {"status": "already_reported"}
    report_ref.set(
        {
            "reporterUid": uid,
            "targetType": target_type,
            "targetId": target_id,
            "targetName": str(name or "")[:40],
            "reason": reason,
            "detail": (detail or "").strip()[:200],
            "status": "open",
            "createdAt": SERVER_TIMESTAMP,
        }
    )
    return {"status": "reported"}
