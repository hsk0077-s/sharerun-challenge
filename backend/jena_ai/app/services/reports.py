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


STATUSES = ("open", "reviewed", "resolved", "dismissed")


def list_reports(db, status: str = "open", limit: int = 50) -> list[dict]:
    """Oldest first, so the queue is worked in the order it arrived."""
    if status not in STATUSES:
        raise HTTPException(status_code=400, detail="Invalid status.")
    rows = []
    for snap in db.collection("reports").where("status", "==", status).limit(limit).get():
        data = snap.to_dict() or {}
        created = data.get("createdAt")
        rows.append(
            {
                "id": snap.id,
                "targetType": data.get("targetType"),
                "targetId": data.get("targetId"),
                "targetName": data.get("targetName"),
                "reason": data.get("reason"),
                "detail": data.get("detail"),
                "status": data.get("status"),
                "reporterUid": data.get("reporterUid"),
                "createdAt": created.isoformat() if hasattr(created, "isoformat") else None,
            }
        )
    rows.sort(key=lambda row: row["createdAt"] or "")
    return rows


def set_report_status(db, report_id: str, new_status: str, actor_uid: str, note: str = "") -> dict:
    """Moves one report along. The audit ledger entry is written by the caller."""
    if new_status not in STATUSES or new_status == "open":
        raise HTTPException(status_code=400, detail="Invalid status.")
    ref = db.collection("reports").document(report_id)
    snap = ref.get()
    if not snap.exists:
        raise HTTPException(status_code=404, detail="Report not found.")
    previous = (snap.to_dict() or {}).get("status")
    ref.update(
        {
            "status": new_status,
            "reviewedBy": actor_uid,
            "reviewNote": (note or "").strip()[:300],
            "reviewedAt": SERVER_TIMESTAMP,
        }
    )
    return {"id": report_id, "before": previous, "status": new_status}
