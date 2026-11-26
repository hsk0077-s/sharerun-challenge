"""Friend cheers: a friend's recent verified runs and fixed one-tap cheers.

Rules in plain words:
  * Only a VERIFIED run leaves a small friend record: distance, time and the
    KST date. No route, place, start time, pace graph or heart rate.
  * A person sees the verified runs of their friends from the last 7 KST days.
    Friends who are blocked (either way) or deleted are left out.
  * A cheer is one of five fixed reactions. No text. One cheer per run, one
    cheer per friend per KST day, 20 cheers per KST day.
  * A friend who is not a friend, is blocked, has no such run, or has only an
    old run all answer 404 "not_found", so a block is never revealed.
  * If the receiver muted cheers, the sender still gets "sent". The cheer is
    stored in the inbox either way; only a later notification step may skip it.
  * No reward of any kind. Nothing here touches a wallet, a ledger, ranking,
    donation or run verification.

Collections (server-written; every client read and write is denied):
    users/{uid}/friendRuns/{activityId}     distanceKm, durationSeconds, kstDate, createdAt
    friendCheers/{activityId}_{fromUid}     fromUid, toUid, activityId, reaction, createdAt
    friendCheerPairDays/{from}_{to}_{YYYYMMDD}   createdAt
    friendCheerDays/{from}_{YYYYMMDD}       count
    users/{uid}/cheersInbox/{activityId}_{fromUid}   fromUid, activityId, reaction, createdAt
    cheerSettings/{uid}                     muteAll, mutedFriends, seenAt
"""

from __future__ import annotations

from datetime import date, datetime, timedelta

from fastapi import status
from google.cloud import firestore

from app.models.friend_cheers import (
    CheerInbox,
    CheerSeenResult,
    CheerSendResult,
    CheerSettings,
    CheerView,
    FriendRunList,
    FriendRunView,
)
from app.services.friends import (
    BLOCKS,
    FRIENDS,
    INVITE_DAYS,
    INVITES,
    MAX_FRIENDS,
    USERS,
    _as_utc,
    _clean_uid,
    _http,
    _iso,
    _now,
)
from app.services.streak_protection import kst_today

FRIEND_RUNS = "friendRuns"
CHEERS = "friendCheers"
PAIR_DAYS = "friendCheerPairDays"
DAYS = "friendCheerDays"
INBOX = "cheersInbox"
SETTINGS = "cheerSettings"

REACTIONS = {"clap", "fire", "muscle", "heart", "thumbs"}
RUN_WINDOW_DAYS = 7  # today and the 6 KST days before it
INBOX_DAYS = 30
MAX_RUNS_PER_FRIEND = 3
MAX_RUNS = 50
MAX_INBOX = 50
MAX_CHEERS_PER_KST_DAY = 20
MAX_MUTED_FRIENDS = 50


def _ymd(current: datetime) -> str:
    return kst_today(current).strftime("%Y%m%d")


def _in_window(kst_date, current: datetime) -> bool:
    try:
        day = date.fromisoformat(str(kst_date))
    except ValueError:
        return False
    today = kst_today(current)
    return today - timedelta(days=RUN_WINDOW_DAYS - 1) <= day <= today


# --- record a verified run --------------------------------------------------


def record_friend_run(
    db,
    uid: str,
    activity_id: str,
    distance_km: float,
    duration_seconds: int,
    now: datetime | None = None,
) -> None:
    """Call only after the run was verified. The same id twice is one document."""
    current = _now(now)
    activity_id = (activity_id or "").strip()
    if not uid or not activity_id or "/" in activity_id:
        return
    db.collection(USERS).document(uid).collection(FRIEND_RUNS).document(
        activity_id
    ).set(
        {
            "distanceKm": float(distance_km),
            "durationSeconds": int(duration_seconds),
            "kstDate": kst_today(current).isoformat(),
            "createdAt": current,
        }
    )


# --- who counts as a visible friend ------------------------------------------


def _visible_friends(db, uid: str) -> dict[str, str]:
    """uid -> nickname for friends who are not blocked either way or deleted."""
    me = db.collection(USERS).document(uid)
    my_blocks = {snap.id for snap in me.collection(BLOCKS).get()}
    visible: dict[str, str] = {}
    for snap in list(me.collection(FRIENDS).get())[:MAX_FRIENDS]:
        friend_uid = snap.id
        if friend_uid in my_blocks:
            continue
        friend = db.collection(USERS).document(friend_uid)
        if friend.collection(BLOCKS).document(uid).get().exists:
            continue
        user_snap = friend.get()
        data = (user_snap.to_dict() or {}) if user_snap.exists else {}
        if data.get("accountStatus") == "deleted":
            continue
        visible[friend_uid] = str(data.get("nickname") or "")
    return visible


# --- recent runs of friends --------------------------------------------------


def list_friend_runs(db, uid: str, now: datetime | None = None) -> FriendRunList:
    current = _now(now)
    friends = _visible_friends(db, uid)
    found: list[tuple[datetime, str, str, dict]] = []
    for friend_uid in friends:
        snaps = (
            db.collection(USERS)
            .document(friend_uid)
            .collection(FRIEND_RUNS)
            .order_by("createdAt", direction=firestore.Query.DESCENDING)
            .limit(MAX_RUNS_PER_FRIEND)
            .get()
        )
        for snap in snaps:
            data = snap.to_dict() or {}
            if not _in_window(data.get("kstDate"), current):
                continue
            created = _as_utc(data.get("createdAt")) or current
            found.append((created, friend_uid, snap.id, data))
    found.sort(key=lambda row: (row[0], row[2]), reverse=True)

    runs: list[FriendRunView] = []
    for _created, friend_uid, activity_id, data in found[:MAX_RUNS]:
        mine = db.collection(CHEERS).document(f"{activity_id}_{uid}").get()
        reaction = None
        if mine.exists:
            reaction = (mine.to_dict() or {}).get("reaction")
        runs.append(
            FriendRunView(
                activity_id=activity_id,
                friend_uid=friend_uid,
                nickname=friends[friend_uid],
                distance_km=float(data.get("distanceKm") or 0),
                duration_seconds=int(data.get("durationSeconds") or 0),
                kst_date=str(data.get("kstDate")),
                my_reaction=reaction,
            )
        )
    return FriendRunList(runs=runs)


# --- send a cheer ------------------------------------------------------------


def send_in_txn(
    transaction,
    db,
    uid: str,
    friend_uid: str,
    activity_id: str,
    reaction: str,
    now: datetime | None = None,
) -> CheerSendResult:
    """Every read happens before the first write."""
    current = _now(now)
    if reaction not in REACTIONS:
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid_reaction")
    friend_uid = _clean_uid(friend_uid)
    if friend_uid == uid:
        raise _http(status.HTTP_400_BAD_REQUEST, "self")
    activity_id = (activity_id or "").strip()
    if not activity_id or "/" in activity_id or len(activity_id) > 128:
        raise _http(status.HTTP_404_NOT_FOUND, "not_found")

    me = db.collection(USERS).document(uid)
    them = db.collection(USERS).document(friend_uid)
    mine = me.collection(FRIENDS).document(friend_uid).get(transaction=transaction)
    theirs = them.collection(FRIENDS).document(uid).get(transaction=transaction)
    i_blocked = me.collection(BLOCKS).document(friend_uid).get(transaction=transaction)
    they_blocked = them.collection(BLOCKS).document(uid).get(transaction=transaction)
    run = them.collection(FRIEND_RUNS).document(activity_id).get(transaction=transaction)
    cheer_ref = db.collection(CHEERS).document(f"{activity_id}_{uid}")
    cheer = cheer_ref.get(transaction=transaction)
    ymd = _ymd(current)
    pair_ref = db.collection(PAIR_DAYS).document(f"{uid}_{friend_uid}_{ymd}")
    pair = pair_ref.get(transaction=transaction)
    day_ref = db.collection(DAYS).document(f"{uid}_{ymd}")
    day = day_ref.get(transaction=transaction)

    if (
        not (mine.exists and theirs.exists)
        or i_blocked.exists
        or they_blocked.exists
        or not run.exists
        or not _in_window((run.to_dict() or {}).get("kstDate"), current)
    ):
        raise _http(status.HTTP_404_NOT_FOUND, "not_found")
    if cheer.exists:
        raise _http(status.HTTP_409_CONFLICT, "already_cheered")
    if pair.exists:
        raise _http(status.HTTP_429_TOO_MANY_REQUESTS, "friend_daily_limit")
    count = int((day.to_dict() or {}).get("count") or 0) if day.exists else 0
    if count >= MAX_CHEERS_PER_KST_DAY:
        raise _http(status.HTTP_429_TOO_MANY_REQUESTS, "daily_limit")

    transaction.set(
        cheer_ref,
        {
            "fromUid": uid,
            "toUid": friend_uid,
            "activityId": activity_id,
            "reaction": reaction,
            "createdAt": current,
        },
    )
    transaction.set(pair_ref, {"createdAt": current})
    transaction.set(day_ref, {"count": count + 1, "updatedAt": current}, merge=True)
    transaction.set(
        them.collection(INBOX).document(f"{activity_id}_{uid}"),
        {
            "fromUid": uid,
            "activityId": activity_id,
            "reaction": reaction,
            "createdAt": current,
        },
    )
    return CheerSendResult(status="sent")


@firestore.transactional
def _send_tx(transaction, db, uid, friend_uid, activity_id, reaction, now):
    return send_in_txn(transaction, db, uid, friend_uid, activity_id, reaction, now)


def send(
    db,
    uid: str,
    friend_uid: str,
    activity_id: str,
    reaction: str,
    now: datetime | None = None,
) -> CheerSendResult:
    return _send_tx(db.transaction(), db, uid, friend_uid, activity_id, reaction, now)


# --- inbox -------------------------------------------------------------------


def _seen_at(db, uid: str) -> datetime | None:
    snap = db.collection(SETTINGS).document(uid).get()
    if not snap.exists:
        return None
    return _as_utc((snap.to_dict() or {}).get("seenAt"))


def list_inbox(db, uid: str, now: datetime | None = None) -> CheerInbox:
    current = _now(now)
    friends = _visible_friends(db, uid)
    cutoff = current - timedelta(days=INBOX_DAYS)
    rows: list[tuple[datetime, str, dict]] = []
    for snap in db.collection(USERS).document(uid).collection(INBOX).get():
        data = snap.to_dict() or {}
        created = _as_utc(data.get("createdAt"))
        if created is None or created < cutoff:
            continue
        if str(data.get("fromUid") or "") not in friends:
            continue
        rows.append((created, snap.id, data))
    rows.sort(key=lambda row: (row[0], row[1]), reverse=True)

    seen = _seen_at(db, uid)
    unread = sum(1 for created, _id, _data in rows if seen is None or created > seen)
    cheers = [
        CheerView(
            from_uid=str(data["fromUid"]),
            nickname=friends[str(data["fromUid"])],
            activity_id=str(data.get("activityId") or ""),
            reaction=str(data.get("reaction") or ""),
            created_at=_iso(created),
        )
        for created, _id, data in rows[:MAX_INBOX]
    ]
    return CheerInbox(cheers=cheers, unread_count=unread)


def mark_seen(db, uid: str, now: datetime | None = None) -> CheerSeenResult:
    db.collection(SETTINGS).document(uid).set({"seenAt": _now(now)}, merge=True)
    return CheerSeenResult(status="ok")


# --- settings ----------------------------------------------------------------


def get_settings(db, uid: str) -> CheerSettings:
    snap = db.collection(SETTINGS).document(uid).get()
    data = (snap.to_dict() or {}) if snap.exists else {}
    return CheerSettings(
        mute_all=bool(data.get("muteAll")),
        muted_friends=[str(item) for item in (data.get("mutedFriends") or [])],
    )


def update_settings_in_txn(
    transaction,
    db,
    uid: str,
    mute_all: bool | None,
    friend_uid: str | None,
    muted: bool | None,
    now: datetime | None = None,
) -> CheerSettings:
    current = _now(now)
    change_friend = friend_uid is not None and muted is not None
    if (friend_uid is None) != (muted is None):
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid")
    if mute_all is None and not change_friend:
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid")

    ref = db.collection(SETTINGS).document(uid)
    snap = ref.get(transaction=transaction)
    data = (snap.to_dict() or {}) if snap.exists else {}
    muted_friends = [str(item) for item in (data.get("mutedFriends") or [])]
    new_mute_all = bool(data.get("muteAll")) if mute_all is None else bool(mute_all)

    if change_friend:
        friend_uid = _clean_uid(friend_uid)
        is_friend = (
            db.collection(USERS)
            .document(uid)
            .collection(FRIENDS)
            .document(friend_uid)
            .get(transaction=transaction)
            .exists
        )
        if muted:
            if not is_friend:
                raise _http(status.HTTP_400_BAD_REQUEST, "invalid")
            if friend_uid not in muted_friends:
                if len(muted_friends) >= MAX_MUTED_FRIENDS:
                    raise _http(status.HTTP_400_BAD_REQUEST, "invalid")
                muted_friends.append(friend_uid)
        else:
            muted_friends = [item for item in muted_friends if item != friend_uid]

    transaction.set(
        ref,
        {"muteAll": new_mute_all, "mutedFriends": muted_friends, "updatedAt": current},
        merge=True,
    )
    return CheerSettings(mute_all=new_mute_all, muted_friends=muted_friends)


@firestore.transactional
def _settings_tx(transaction, db, uid, mute_all, friend_uid, muted, now):
    return update_settings_in_txn(transaction, db, uid, mute_all, friend_uid, muted, now)


def update_settings(
    db,
    uid: str,
    mute_all: bool | None,
    friend_uid: str | None,
    muted: bool | None,
    now: datetime | None = None,
) -> CheerSettings:
    return _settings_tx(db.transaction(), db, uid, mute_all, friend_uid, muted, now)


# --- account deletion --------------------------------------------------------


def delete_user_cheer_data(db, uid: str) -> None:
    """Remove this person's own friend runs, inbox and cheer settings."""
    user_ref = db.collection(USERS).document(uid)
    for collection in (FRIEND_RUNS, INBOX):
        for snap in user_ref.collection(collection).get():
            snap.reference.delete()
    db.collection(SETTINGS).document(uid).delete()


def _ids_with_prefix(db, collection: str, prefix: str) -> list[str]:
    """Ids of documents in ``collection`` whose id starts with ``prefix``.

    The counter documents are named ``{uid}_...``, so a document-id range
    finds them without a separate index.
    """
    from google.cloud.firestore_v1.field_path import FieldPath
    from google.cloud.firestore_v1.base_query import FieldFilter

    ref = db.collection(collection)
    query = ref.where(
        filter=FieldFilter(FieldPath.document_id(), ">=", ref.document(prefix))
    ).where(
        filter=FieldFilter(
            FieldPath.document_id(), "<", ref.document(prefix + "\uf8ff")
        )
    )
    return [snap.id for snap in query.get()]


def purge_friend_data(db, uid: str) -> dict[str, int]:
    """Remove everything about friends and cheers that involves ``uid``.

    Used when an account is deleted (and again by the daily purge, so accounts
    deleted before this existed are cleaned too). It is safe to run twice.

    Removed:
      * the friend link on both sides (``users/{friend}/friends/{uid}``) and
        ``uid`` from each friend's muted list
      * ``uid``'s own friends, blocks, friend runs, cheers inbox and settings
      * every ``friendCheers`` document sent or received by ``uid``, and the
        copies of the sent cheers in other people's inboxes
      * friend invites made by ``uid`` (an invite ``uid`` used keeps working as
        "used" but no longer names ``uid``)
      * the per-day counters named after ``uid``

    Not removed: another person's own block of ``uid`` (it lives on their side
    and holds only the id and a time) and the pair-day counter whose id ends
    with ``uid`` (it holds only a time).
    """
    counts = {
        "friends": 0,
        "cheers": 0,
        "invites": 0,
        "counters": 0,
    }
    user_ref = db.collection(USERS).document(uid)

    for snap in list(user_ref.collection(FRIENDS).get()):
        friend_uid = snap.id
        friend_ref = db.collection(USERS).document(friend_uid)
        friend_ref.collection(FRIENDS).document(uid).delete()
        settings_ref = db.collection(SETTINGS).document(friend_uid)
        settings = settings_ref.get()
        if settings.exists:
            muted = list((settings.to_dict() or {}).get("mutedFriends") or [])
            if uid in muted:
                settings_ref.set(
                    {"mutedFriends": [item for item in muted if item != uid]},
                    merge=True,
                )
        snap.reference.delete()
        counts["friends"] += 1

    for snap in list(user_ref.collection(BLOCKS).get()):
        snap.reference.delete()

    for snap in list(db.collection(CHEERS).where("fromUid", "==", uid).get()):
        data = snap.to_dict() or {}
        to_uid = str(data.get("toUid") or "")
        activity_id = str(data.get("activityId") or "")
        if to_uid and activity_id:
            db.collection(USERS).document(to_uid).collection(INBOX).document(
                f"{activity_id}_{uid}"
            ).delete()
        snap.reference.delete()
        counts["cheers"] += 1
    for snap in list(db.collection(CHEERS).where("toUid", "==", uid).get()):
        snap.reference.delete()
        counts["cheers"] += 1

    for snap in list(db.collection(INVITES).where("fromUid", "==", uid).get()):
        snap.reference.delete()
        counts["invites"] += 1
    for snap in list(db.collection(INVITES).where("usedBy", "==", uid).get()):
        snap.reference.set({"usedBy": "deleted"}, merge=True)

    for collection in (INVITE_DAYS, DAYS, PAIR_DAYS):
        for doc_id in _ids_with_prefix(db, collection, f"{uid}_"):
            db.collection(collection).document(doc_id).delete()
            counts["counters"] += 1

    delete_user_cheer_data(db, uid)
    return counts
