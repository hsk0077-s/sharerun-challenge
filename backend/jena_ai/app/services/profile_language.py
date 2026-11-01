"""The app language a user chose, kept on ``users/{uid}`` for the admin.

``language`` is one of the 11 languages the app ships. ``countryCode`` is the
phone's two-letter region when it has one. Neither field is money or a reward:
this only tells the admin which language a runner uses. A user document that
does not exist yet is left alone, so this never creates a half-empty account.
"""

from google.cloud.firestore_v1 import SERVER_TIMESTAMP

SUPPORTED_LANGUAGES = ("ko", "en", "ja", "zh", "es", "pt", "de", "fr", "vi", "th", "id")


def record_language(db, uid: str, language: str, country_code: str | None) -> dict:
    ref = db.collection("users").document(uid)
    snapshot = ref.get()
    if not snapshot.exists:
        return {"status": "no_user"}
    current = snapshot.to_dict() or {}
    if current.get("language") == language and (
        country_code is None or current.get("countryCode") == country_code
    ):
        return {"status": "unchanged", "language": language}
    fields: dict = {"language": language, "languageUpdatedAt": SERVER_TIMESTAMP}
    if country_code is not None:
        fields["countryCode"] = country_code
    ref.update(fields)
    return {"status": "saved", "language": language}
