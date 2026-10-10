"""Per-account privacy settings. The server value is the only truth.

`privacySettings/{uid}` holds the current value (default: off).
`privacySettingLog` is append-only: one row per real change, never edited.
"""

from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

SETTINGS = "privacySettings"
LOG = "privacySettingLog"


def settings_view(data: dict | None) -> dict:
    return {"ai_learning": bool((data or {}).get("aiLearning") is True)}


def read_settings(db, uid: str) -> dict:
    snapshot = db.collection(SETTINGS).document(uid).get()
    return settings_view(snapshot.to_dict() if snapshot.exists else None)


def apply_ai_learning(transaction, db, uid: str, enabled: bool) -> dict:
    ref = db.collection(SETTINGS).document(uid)
    snapshot = ref.get(transaction=transaction)
    before = settings_view(snapshot.to_dict() if snapshot.exists else None)
    if before["ai_learning"] == enabled:
        return before  # same value again: no new log row
    transaction.set(
        ref,
        {"uid": uid, "aiLearning": enabled, "updatedAt": SERVER_TIMESTAMP},
        merge=True,
    )
    transaction.set(
        db.collection(LOG).document(),
        {
            "uid": uid,
            "setting": "aiLearning",
            "before": before["ai_learning"],
            "after": enabled,
            "createdAt": SERVER_TIMESTAMP,
        },
    )
    return {"ai_learning": enabled}


@firestore.transactional
def _apply_tx(transaction, db, uid: str, enabled: bool) -> dict:
    return apply_ai_learning(transaction, db, uid, enabled)


def set_ai_learning(db, uid: str, enabled: bool) -> dict:
    return _apply_tx(db.transaction(), db, uid, enabled)
