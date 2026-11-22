"""Friend connections: one-time invite tokens, accept, list, remove, block.

Rules in plain words:
  * A friend invite is a random one-time token (192 bits) that lives 24 hours.
    One person can make at most 20 invites per KST day.
  * Whoever accepts a live token becomes a friend of the inviter. Both friend
    documents and the token's "used" mark are written in ONE transaction.
  * A token can be used once. The same person accepting the same token again
    gets the same answer and nothing is written again. Anyone else gets "used".
  * Nobody can have more than 50 friends (checked for both people).
  * If either person has blocked the other, accept answers 400 "invalid", the
    same as a token that does not exist, so a block is never revealed.
  * Remove deletes both friend documents. Block saves a block and deletes both
    friend documents. Neither tells the other person anything.
  * The friend list shows the nickname only. No place, route, start time or
    run record is ever returned.
  * No reward of any kind: nothing here touches a wallet, a ledger, DIA, SHARE,
    tickets or stamps.

This is separate from the referral-code feature (``referralCodes``,
``secured_action_service`` referral logic, ``twin_run``); none of it is reused.

Collections (every write is server-side; the client may only read its own
``users/{uid}/friends``):
    friendInvites/{token}               fromUid, createdAt, expiresAt, usedBy, usedAt
    friendInviteDays/{uid}_{YYYYMMDD}   count of invites made that KST day
    users/{uid}/friends/{friendUid}     createdAt
    users/{uid}/blocks/{blockedUid}     createdAt
"""

from __future__ import annotations

import re
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException, status
from google.cloud import firestore

from app.models.friends import (
    FriendAcceptResult,
    FriendBlockResult,
    FriendInviteResult,
    FriendList,
    FriendRemoveResult,
    FriendView,
)
from app.services import reports
from app.services.streak_protection import kst_today

INVITES = "friendInvites"
INVITE_DAYS = "friendInviteDays"
USERS = "users"
FRIENDS = "friends"
BLOCKS = "blocks"

MAX_FRIENDS = 50
INVITE_TTL = timedelta(hours=24)
MAX_INVITES_PER_KST_DAY = 20
QR_PREFIX = "sharerun-friend:"

# token_urlsafe(24) is 32 characters of A-Z a-z 0-9 - _
_TOKEN_RE = re.compile(r"^[A-Za-z0-9_-]{20,64}$")


def _http(code: int, detail: str) -> HTTPException:
    return HTTPException(status_code=code, detail=detail)


def _now(now: datetime | None) -> datetime:
    current = now or datetime.now(timezone.utc)
    return current if current.tzinfo else current.replace(tzinfo=timezone.utc)


def _iso(value) -> str | None:
    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, str) and value:
        return value
    return None


def _as_utc(value) -> datetime | None:
    if not isinstance(value, datetime):
        return None
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


def _clean_uid(value: str | None) -> str:
    uid = (value or "").strip()
    if not uid or "/" in uid or len(uid) > 128:
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid")
    return uid


# --- invite -----------------------------------------------------------------


def invite_in_txn(
    transaction, db, uid: str, now: datetime | None = None
) -> FriendInviteResult:
    current = _now(now)
    day_ref = db.collection(INVITE_DAYS).document(
        f"{uid}_{kst_today(current).strftime('%Y%m%d')}"
    )
    day_snap = day_ref.get(transaction=transaction)
    count = int((day_snap.to_dict() or {}).get("count") or 0) if day_snap.exists else 0
    if count >= MAX_INVITES_PER_KST_DAY:
        raise _http(status.HTTP_429_TOO_MANY_REQUESTS, "Friend invite limit reached.")

    token = secrets.token_urlsafe(24)
    expires_at = current + INVITE_TTL
    transaction.set(
        db.collection(INVITES).document(token),
        {
            "fromUid": uid,
            "createdAt": current,
            "expiresAt": expires_at,
            "usedBy": None,
            "usedAt": None,
        },
    )
    transaction.set(day_ref, {"count": count + 1, "updatedAt": current}, merge=True)
    return FriendInviteResult(
        token=token,
        qr_payload=f"{QR_PREFIX}{token}",
        expires_at=expires_at.isoformat(),
    )


@firestore.transactional
def _invite_tx(transaction, db, uid: str, now):
    return invite_in_txn(transaction, db, uid, now)


def create_invite(db, uid: str, now: datetime | None = None) -> FriendInviteResult:
    return _invite_tx(db.transaction(), db, uid, now)


# --- accept -----------------------------------------------------------------


def _friend_count(transaction, db, uid: str) -> int:
    snaps = (
        db.collection(USERS)
        .document(uid)
        .collection(FRIENDS)
        .limit(MAX_FRIENDS)
        .get(transaction=transaction)
    )
    return len(list(snaps))


def accept_in_txn(
    transaction, db, uid: str, token: str, now: datetime | None = None
) -> FriendAcceptResult:
    """Every read happens before the first write."""
    current = _now(now)
    token = (token or "").strip()
    if not _TOKEN_RE.match(token):
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid")

    invite_ref = db.collection(INVITES).document(token)
    invite_snap = invite_ref.get(transaction=transaction)
    if not invite_snap.exists:
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid")
    invite = invite_snap.to_dict() or {}
    from_uid = str(invite.get("fromUid") or "")
    if not from_uid:
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid")
    if from_uid == uid:
        raise _http(status.HTTP_400_BAD_REQUEST, "self")

    me_ref = db.collection(USERS).document(uid)
    them_ref = db.collection(USERS).document(from_uid)
    i_blocked = me_ref.collection(BLOCKS).document(from_uid).get(transaction=transaction)
    they_blocked = them_ref.collection(BLOCKS).document(uid).get(transaction=transaction)
    if i_blocked.exists or they_blocked.exists:
        # Same answer as a token that does not exist.
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid")

    my_friend_ref = me_ref.collection(FRIENDS).document(from_uid)
    their_friend_ref = them_ref.collection(FRIENDS).document(uid)
    mine = my_friend_ref.get(transaction=transaction)
    theirs = their_friend_ref.get(transaction=transaction)
    already_friends = mine.exists and theirs.exists

    used_by = invite.get("usedBy")
    if used_by == uid:
        # The same person again: same answer, nothing written. If they have
        # since removed the friend, the token stays spent.
        if already_friends:
            return FriendAcceptResult(status="added", friend_uid=from_uid)
        raise _http(status.HTTP_410_GONE, "used")
    if used_by:
        raise _http(status.HTTP_410_GONE, "used")

    expires_at = _as_utc(invite.get("expiresAt"))
    if expires_at is None or current >= expires_at:
        raise _http(status.HTTP_410_GONE, "expired")

    if already_friends:
        transaction.set(
            invite_ref, {"usedBy": uid, "usedAt": current}, merge=True
        )
        return FriendAcceptResult(status="already_friends", friend_uid=from_uid)

    if (
        _friend_count(transaction, db, uid) >= MAX_FRIENDS
        or _friend_count(transaction, db, from_uid) >= MAX_FRIENDS
    ):
        raise _http(status.HTTP_409_CONFLICT, "friend_limit")

    transaction.set(my_friend_ref, {"createdAt": current})
    transaction.set(their_friend_ref, {"createdAt": current})
    transaction.set(invite_ref, {"usedBy": uid, "usedAt": current}, merge=True)
    return FriendAcceptResult(status="added", friend_uid=from_uid)


@firestore.transactional
def _accept_tx(transaction, db, uid: str, token: str, now):
    return accept_in_txn(transaction, db, uid, token, now)


def accept(db, uid: str, token: str, now: datetime | None = None) -> FriendAcceptResult:
    return _accept_tx(db.transaction(), db, uid, token, now)


# --- list -------------------------------------------------------------------


def list_friends(db, uid: str) -> FriendList:
    """Nickname only. No place, route, start time or run record."""
    rows: list[FriendView] = []
    for snap in db.collection(USERS).document(uid).collection(FRIENDS).get():
        friend_uid = snap.id
        user_snap = db.collection(USERS).document(friend_uid).get()
        nickname = ""
        if user_snap.exists:
            nickname = str((user_snap.to_dict() or {}).get("nickname") or "")
        rows.append(
            FriendView(
                uid=friend_uid,
                nickname=nickname,
                created_at=_iso((snap.to_dict() or {}).get("createdAt")),
            )
        )
    rows.sort(key=lambda row: (row.created_at or "", row.uid))
    return FriendList(friends=rows)


# --- remove -----------------------------------------------------------------


def remove_in_txn(transaction, db, uid: str, friend_uid: str) -> FriendRemoveResult:
    friend_uid = _clean_uid(friend_uid)
    mine_ref = db.collection(USERS).document(uid).collection(FRIENDS).document(friend_uid)
    theirs_ref = db.collection(USERS).document(friend_uid).collection(FRIENDS).document(uid)
    mine = mine_ref.get(transaction=transaction)
    theirs = theirs_ref.get(transaction=transaction)
    if not mine.exists and not theirs.exists:
        return FriendRemoveResult(status="not_friends")
    transaction.delete(mine_ref)
    transaction.delete(theirs_ref)
    return FriendRemoveResult(status="removed")


@firestore.transactional
def _remove_tx(transaction, db, uid: str, friend_uid: str):
    return remove_in_txn(transaction, db, uid, friend_uid)


def remove(db, uid: str, friend_uid: str) -> FriendRemoveResult:
    return _remove_tx(db.transaction(), db, uid, friend_uid)


# --- block ------------------------------------------------------------------


def block_in_txn(
    transaction, db, uid: str, target_uid: str, now: datetime | None = None
) -> FriendBlockResult:
    target_uid = _clean_uid(target_uid)
    if target_uid == uid:
        raise _http(status.HTTP_400_BAD_REQUEST, "self")
    current = _now(now)
    block_ref = db.collection(USERS).document(uid).collection(BLOCKS).document(target_uid)
    mine_ref = db.collection(USERS).document(uid).collection(FRIENDS).document(target_uid)
    theirs_ref = db.collection(USERS).document(target_uid).collection(FRIENDS).document(uid)
    existing = block_ref.get(transaction=transaction)
    mine_ref.get(transaction=transaction)
    theirs_ref.get(transaction=transaction)
    if not existing.exists:
        transaction.set(block_ref, {"createdAt": current})
    transaction.delete(mine_ref)
    transaction.delete(theirs_ref)
    return FriendBlockResult(status="blocked")


@firestore.transactional
def _block_tx(transaction, db, uid: str, target_uid: str, now):
    return block_in_txn(transaction, db, uid, target_uid, now)


def block(
    db,
    uid: str,
    target_uid: str,
    report_reason: str | None = None,
    now: datetime | None = None,
) -> FriendBlockResult:
    target_uid = _clean_uid(target_uid)
    if target_uid == uid:
        raise _http(status.HTTP_400_BAD_REQUEST, "self")
    if report_reason is not None and report_reason not in reports.REASONS:
        # Refuse before anything is written.
        raise _http(status.HTTP_400_BAD_REQUEST, "invalid_report_reason")
    result = _block_tx(db.transaction(), db, uid, target_uid, now)
    if report_reason:
        try:
            reports.submit_report(db, uid, "user", target_uid, report_reason, "")
        except HTTPException as error:
            # The block already stands. A missing target or an earlier report
            # of the same person must not undo or fail it.
            if error.status_code not in (400, 404):
                raise
    return result
