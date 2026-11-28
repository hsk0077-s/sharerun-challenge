"""Once-a-day bundled push for friend cheers.

A scheduler calls the ops endpoint once a day. For each person who received
cheers, this sends at most one push: "N friends cheered for you". Rules:

  * Nothing is sent between 21:00 and 08:00 KST. A call in those hours sends
    nothing and reports 0.
  * One push per person per KST day. ``cheerPushDays/{uid}_{YYYYMMDD}`` is
    created before sending, so a second call on the same day sends nothing.
  * Only cheers newer than both the last time the inbox was opened (``seenAt``)
    and the last bundled push (``pushedAt``) count, so the same cheers are not
    announced twice.
  * ``muteAll`` sends nothing. Friends in ``mutedFriends``, blocked people
    (either way) and deleted accounts are not counted.
  * Activity notifications only. ``users/{uid}.pushNotificationsEnabled`` must
    be exactly true. Missing or false is skipped (``push_disabled``) and no
    ``cheerPushDays`` record is written, so turning notifications on later
    the same day still allows that day's push.
  * The push holds only a count. No nickname, run or place is put in it.
  * The text follows the language saved on ``users/{uid}.language``; Korean when
    there is none.
  * A token Firebase reports as no longer valid is removed. One person's
    failure never stops the others.

Collection (server-written; every client read and write is denied):
    cheerPushDays/{uid}_{YYYYMMDD}   uid, kstDate, friendCount, sentAt
"""

from __future__ import annotations

from datetime import datetime, timedelta
from typing import Callable

from google.cloud import firestore

from app.services.friend_cheers import (
    INBOX,
    PUSH_DAYS,
    SETTINGS,
    USERS,
    _visible_friends,
)
from app.services.friends import _as_utc, _now
from app.services.streak_protection import kst_today

LOOKBACK_DAYS = 7
QUIET_START_HOUR = 21  # KST, inclusive
QUIET_END_HOUR = 8  # KST, exclusive
CHEER_INBOX_ROUTE = "/friends/cheers"
PUSH_TYPE = "friend_cheers"

_KST = timedelta(hours=9)

# title, body with {count}. Keys are the app language codes and the long forms.
_COPY: dict[str, tuple[str, str, str]] = {
    # language: (title, body for one friend, body for several friends)
    "ko": ("응원이 도착했어요", "친구 1명이 응원을 보냈어요", "친구 {count}명이 응원을 보냈어요"),
    "en": ("You got cheers", "1 friend cheered for you", "{count} friends cheered for you"),
    "ja": ("応援が届きました", "友だち1人が応援してくれました", "友だち{count}人が応援してくれました"),
    "zh-TW": ("收到加油了", "有 1 位朋友為你加油", "有 {count} 位朋友為你加油"),
    "es": ("Te llegaron ánimos", "1 amigo te envió ánimos", "{count} amigos te enviaron ánimos"),
    "pt-BR": ("Você recebeu torcida", "1 amigo torceu por você", "{count} amigos torceram por você"),
    "de": ("Du wurdest angefeuert", "1 Freund hat dich angefeuert", "{count} Freunde haben dich angefeuert"),
    "fr": ("Des encouragements pour vous", "1 ami vous a encouragé", "{count} amis vous ont encouragé"),
    "vi": ("Bạn nhận được cổ vũ", "1 người bạn đã cổ vũ bạn", "{count} người bạn đã cổ vũ bạn"),
    "th": ("มีกำลังใจส่งมาถึงแล้ว", "เพื่อน 1 คนส่งกำลังใจให้คุณ", "เพื่อน {count} คนส่งกำลังใจให้คุณ"),
    "id": ("Ada semangat untukmu", "1 teman menyemangatimu", "{count} teman menyemangatimu"),
}
_ALIASES = {"zh": "zh-TW", "pt": "pt-BR"}


def copy_for(language: object, count: int) -> tuple[str, str]:
    """Title and body in the user's language. Unknown or empty -> Korean."""
    code = str(language or "").strip()
    code = _ALIASES.get(code, code)
    if code not in _COPY:
        base = code.split("-")[0].split("_")[0]
        code = _ALIASES.get(base, base)
    title, one, many = _COPY.get(code, _COPY["ko"])
    return title, (one if count == 1 else many.format(count=count))


def _kst_hour(current: datetime) -> int:
    offset = current.utcoffset() or timedelta(0)
    return (current.replace(tzinfo=None) - offset + _KST).hour


def is_quiet_hour(current: datetime) -> bool:
    """21:00-08:00 KST: no cheer push is sent."""
    hour = _kst_hour(current)
    return hour >= QUIET_START_HOUR or hour < QUIET_END_HOUR


def recent_receivers(db, since: datetime) -> set[str]:
    """People who got any cheer since ``since`` (one indexed range query)."""
    from google.cloud.firestore_v1.base_query import FieldFilter

    query = db.collection("friendCheers").where(
        filter=FieldFilter("createdAt", ">=", since)
    )
    return {
        str((snap.to_dict() or {}).get("toUid") or "")
        for snap in query.get()
    } - {""}


def claim_day(db, uid: str, ymd: str, data: dict) -> bool:
    """Create today's push record. False when it already exists."""
    from google.api_core.exceptions import AlreadyExists

    try:
        db.collection(PUSH_DAYS).document(f"{uid}_{ymd}").create(data)
    except AlreadyExists:
        return False
    return True


def unseen_friend_count(db, uid: str, current: datetime) -> int:
    """Distinct friends whose new cheers this person has not been told about."""
    settings_snap = db.collection(SETTINGS).document(uid).get()
    settings = (settings_snap.to_dict() or {}) if settings_snap.exists else {}
    if settings.get("muteAll"):
        return 0
    muted = {str(item) for item in (settings.get("mutedFriends") or [])}
    since = current - timedelta(days=LOOKBACK_DAYS)
    for key in ("seenAt", "pushedAt"):
        moment = _as_utc(settings.get(key))
        if moment is not None and moment > since:
            since = moment
    friends = _visible_friends(db, uid)
    senders = set()
    for snap in db.collection(USERS).document(uid).collection(INBOX).get():
        data = snap.to_dict() or {}
        created = _as_utc(data.get("createdAt"))
        sender = str(data.get("fromUid") or "")
        if created is None or created <= since:
            continue
        if sender not in friends or sender in muted:
            continue
        senders.add(sender)
    return len(senders)


def _tokens(db, uid: str) -> list[tuple[object, str]]:
    """(document ref, token) pairs: each signed-in device, then the profile."""
    user_ref = db.collection(USERS).document(uid)
    pairs: list[tuple[object, str]] = []
    seen: set[str] = set()
    for snap in user_ref.collection("loginDevices").get():
        token = (snap.to_dict() or {}).get("fcmToken")
        if isinstance(token, str) and token and token not in seen:
            seen.add(token)
            pairs.append((snap.reference, token))
    user = user_ref.get()
    token = (user.to_dict() or {}).get("fcmToken") if user.exists else None
    if isinstance(token, str) and token and token not in seen:
        pairs.append((user_ref, token))
    return pairs


def _language(db, uid: str) -> object:
    snap = db.collection(USERS).document(uid).get()
    return (snap.to_dict() or {}).get("language") if snap.exists else None


def _push_opted_in(db, uid: str) -> bool:
    """True only when the activity-notification toggle is exactly on.

    Missing, false, or any other value means the person did not opt in.
    """
    snap = db.collection(USERS).document(uid).get()
    if not snap.exists:
        return False
    return (snap.to_dict() or {}).get("pushNotificationsEnabled") is True


def _note_skip(result: dict, reason: str | None = None) -> None:
    result["skipped"] += 1
    if not reason:
        return
    reasons = result["skip_reasons"]
    reasons[reason] = reasons.get(reason, 0) + 1


def send_daily_cheer_pushes(
    db,
    send: Callable[[str, str, str, dict], None],
    is_invalid_token: Callable[[Exception], bool],
    now: datetime | None = None,
) -> dict[str, int | bool | dict[str, int]]:
    """Send today's bundled cheer pushes. Safe to call more than once a day.

    ``send(token, title, body, data)`` raises on failure; ``is_invalid_token``
    tells whether that failure means the token should be removed.
    """
    current = _now(now)
    result: dict[str, int | bool | dict[str, int]] = {
        "quiet_hours": False,
        "candidates": 0,
        "sent": 0,
        "skipped": 0,
        "failed": 0,
        "tokens_removed": 0,
        "skip_reasons": {},
    }
    if is_quiet_hour(current):
        result["quiet_hours"] = True
        return result

    ymd = kst_today(current).strftime("%Y%m%d")
    receivers = recent_receivers(db, current - timedelta(days=LOOKBACK_DAYS))
    result["candidates"] = len(receivers)
    for uid in sorted(receivers):
        try:
            # Before the day record, so opting in later today can still send.
            if not _push_opted_in(db, uid):
                _note_skip(result, "push_disabled")
                continue
            count = unseen_friend_count(db, uid, current)
            tokens = _tokens(db, uid) if count else []
            if not count or not tokens:
                _note_skip(result)
                continue
            if not claim_day(
                db,
                uid,
                ymd,
                {
                    "uid": uid,
                    "kstDate": kst_today(current).isoformat(),
                    "friendCount": count,
                    "sentAt": current,
                },
            ):
                _note_skip(result)
                continue
            title, body = copy_for(_language(db, uid), count)
            data = {"type": PUSH_TYPE, "route": CHEER_INBOX_ROUTE}
            delivered = False
            for ref, token in tokens:
                try:
                    send(token, title, body, data)
                    delivered = True
                except Exception as error:  # noqa: BLE001 - one token never stops the rest
                    if is_invalid_token(error):
                        ref.update({"fcmToken": firestore.DELETE_FIELD})
                        result["tokens_removed"] += 1
            db.collection(SETTINGS).document(uid).set({"pushedAt": current}, merge=True)
            result["sent" if delivered else "failed"] += 1
        except Exception:  # noqa: BLE001 - one person never stops the others
            result["failed"] += 1
    return result

