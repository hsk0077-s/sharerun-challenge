"""Crew membership: list, join, leave, who is in my crew, sub-leaders.

A crew doc keeps ``memberCount``; each member also has ``crews/{id}/members/{uid}``.
A member's user doc carries ``crewId`` (the owner's carries ``ownedCrewId``). A user is in
at most one crew.

Joining is ``open`` (anyone, at once) or ``approval`` (a request the leader or a sub-leader
accepts). Disbanding removes every member, the leader included; the leader may instead hand
the crew to a member and then leave like anyone else (the way Strava clubs work).
"""

from __future__ import annotations

import os

from fastapi import HTTPException
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.services import content_filter
from app.services.social_items import member_crew_id

def _run(tx_func, transaction, *args):
    """Run a transactional function. Tests swap this for the plain wrapped function."""
    return tx_func(transaction, *args)


DEFAULT_MAX_MEMBERS = 50
LIST_LIMIT = 200
RESULT_LIMIT = 30


def max_members() -> int:
    raw = os.environ.get("CREW_MAX_MEMBERS", "").strip()
    try:
        return max(1, int(raw)) if raw else DEFAULT_MAX_MEMBERS
    except ValueError:
        return DEFAULT_MAX_MEMBERS


def crew_max(crew: dict) -> int:
    """This crew's member limit: the base limit plus every expansion it bought."""
    raw = crew.get("memberCapBonus")
    bonus = int(raw) if isinstance(raw, (int, float)) and not isinstance(raw, bool) else 0
    return max_members() + max(0, bonus)


def next_expansion(crew: dict) -> dict:
    """What the next seat purchase is: ``add`` seats for ``cost_dia``, and its ``state``.

    ``ok`` can be bought now, ``needs_full`` waits until every seat is taken, ``max`` is the end.
    """
    cap = crew_max(crew)
    if cap >= EXPAND_MAX:
        return {"add": 0, "cost_dia": 0, "state": "max"}
    if cap < 300:
        return {"add": min(50, 300 - cap), "cost_dia": 300, "state": "ok"}
    state = "ok" if _count(crew) >= cap else "needs_full"
    if cap < 500:
        return {"add": 100, "cost_dia": 500, "state": state}
    return {"add": EXPAND_MAX - cap, "cost_dia": 1000, "state": state}


def _count(crew: dict) -> int:
    raw = crew.get("memberCount")
    return int(raw) if isinstance(raw, (int, float)) and not isinstance(raw, bool) else 0


RENAME_DIA = 300
# Seat steps. The base limit is 50. Up to 300 anyone can buy +50 for 300 DIA. From 300 up
# to 500 the crew must be full first: +100 for 500 DIA. From 500 to 1,000 it must be full
# again: +500 for 1,000 DIA, and 1,000 is the end.
EXPAND_MAX = 1000
# One CPR ticket plus one Safeguard for one member. The leader pays per member.
GIFT_DIA_PER_MEMBER = 30
GIFT_ITEMS = (
    ("record_cpr_ticket", "기록 심폐소생권"),
    ("record_safe_guard", "기록 마감 세이프 가드"),
)
NAME_MIN, NAME_MAX = 2, 20


def _changes(crew: dict) -> int:
    raw = crew.get("nameChanges")
    return int(raw) if isinstance(raw, (int, float)) and not isinstance(raw, bool) else 0


def join_mode(crew: dict) -> str:
    return "approval" if crew.get("joinMode") == "approval" else "open"


def _subs(crew: dict) -> list[str]:
    raw = crew.get("subLeaderUids")
    return [s for s in raw if isinstance(s, str)] if isinstance(raw, list) else []


def summary(crew_id: str, crew: dict) -> dict:
    count = _count(crew)
    return {
        "id": crew_id,
        "name": str(crew.get("name") or ""),
        "emblem": str(crew.get("emblem") or ""),
        "member_count": count,
        "max_members": crew_max(crew),
        "is_full": count >= crew_max(crew),
        "total_distance_km": float(crew.get("totalDistanceKm") or 0),
        "join_mode": join_mode(crew),
        # The first rename is free, every later one costs RENAME_DIA.
        "name_changes": _changes(crew),
        "rename_cost_dia": 0 if _changes(crew) < 1 else RENAME_DIA,
    }


def list_crews(db, query: str = "", uid: str = "") -> dict:
    """Crews matching a name fragment, biggest first, plus the crew I have asked to join."""
    needle = query.strip().lower()
    out = []
    for snapshot in db.collection("crews").limit(LIST_LIMIT).get():
        crew = snapshot.to_dict() or {}
        name = str(crew.get("name") or "")
        if needle and needle not in name.lower():
            continue
        row = summary(snapshot.id, crew)
        # A crew that turned me down is closed to me for good.
        row["rejected"] = bool(
            uid and db.collection("crews").document(snapshot.id).collection("rejected").document(uid).get().exists
        )
        out.append(row)
    out.sort(key=lambda c: (-c["member_count"], c["name"]))
    pending = ""
    if uid:
        user_snapshot = db.collection("users").document(uid).get()
        raw = (user_snapshot.to_dict() or {}).get("pendingCrewId") if user_snapshot.exists else ""
        pending = raw if isinstance(raw, str) else ""
    return {"crews": out[:RESULT_LIMIT], "pending_crew_id": pending}


def my_crew(db, uid: str) -> dict:
    """The crew I am in, my role and the members. ``crew`` is null without one."""
    user_snapshot = db.collection("users").document(uid).get()
    user = user_snapshot.to_dict() if user_snapshot.exists else {}
    crew_id = member_crew_id(user or {})
    if not crew_id:
        return {"crew": None, "role": "none", "members": [], "pending_requests": 0}
    crew_snapshot = db.collection("crews").document(crew_id).get()
    if not crew_snapshot.exists:
        return {"crew": None, "role": "none", "members": [], "pending_requests": 0}
    crew = crew_snapshot.to_dict() or {}
    subs = crew.get("subLeaderUids") if isinstance(crew.get("subLeaderUids"), list) else []
    role = "leader" if crew.get("ownerUid") == uid else "sub" if uid in subs else "member"
    members = []
    for snapshot in db.collection("crews").document(crew_id).collection("members").get():
        member_uid = snapshot.id
        profile_snapshot = db.collection("users").document(member_uid).get()
        profile = profile_snapshot.to_dict() if profile_snapshot.exists else {}
        member_role = (
            "leader" if crew.get("ownerUid") == member_uid
            else "sub" if member_uid in subs else "member"
        )
        members.append(
            {
                "uid": member_uid,
                "nickname": str((profile or {}).get("nickname") or "러너"),
                "role": member_role,
            }
        )
    order = {"leader": 0, "sub": 1, "member": 2}
    owner = crew.get("ownerUid")
    if isinstance(owner, str) and owner and all(m["uid"] != owner for m in members):
        # Crews founded before member docs existed still show their leader.
        owner_snapshot = db.collection("users").document(owner).get()
        owner_profile = owner_snapshot.to_dict() if owner_snapshot.exists else {}
        members.append(
            {"uid": owner, "nickname": str((owner_profile or {}).get("nickname") or "러너"), "role": "leader"}
        )
    members.sort(key=lambda m: (order[m["role"]], m["nickname"]))
    requests = 0
    if role in {"leader", "sub"}:
        requests = len(db.collection("crews").document(crew_id).collection("joinRequests").get())
    return {
        "crew": {
            **summary(crew_id, crew),
            "owner_uid": crew.get("ownerUid"),
            "expand": next_expansion(crew),
        },
        "role": role,
        "members": members,
        "pending_requests": requests,
    }


def join(db, uid: str, crew_id: str) -> dict:
    crew_id = (crew_id or "").strip()
    if not crew_id or "/" in crew_id:
        raise HTTPException(status_code=400, detail="Invalid crew.")
    transaction = db.transaction()
    return _join_tx(
        transaction,
        db,
        uid,
        db.collection("users").document(uid),
        db.collection("crews").document(crew_id),
    )


@firestore.transactional
def _join_tx(transaction, db, uid, user_ref, crew_ref) -> dict:
    user_snapshot = user_ref.get(transaction=transaction)
    crew_snapshot = crew_ref.get(transaction=transaction)
    if not user_snapshot.exists:
        raise HTTPException(status_code=404, detail="User not found.")
    if not crew_snapshot.exists:
        raise HTTPException(status_code=404, detail="Crew not found.")
    user = user_snapshot.to_dict() or {}
    crew = crew_snapshot.to_dict() or {}
    current = member_crew_id(user)
    if current == crew_ref.id:
        return {"status": "already_member", "crew_id": crew_ref.id}
    if crew_ref.collection("rejected").document(user_ref.id).get(transaction=transaction).exists:
        raise HTTPException(status_code=403, detail="This crew turned your request down.")
    if current:
        raise HTTPException(status_code=409, detail="Already in a crew.")
    if _count(crew) >= crew_max(crew):
        raise HTTPException(status_code=409, detail="The crew is full.")
    if join_mode(crew) == "approval":
        pending = user.get("pendingCrewId")
        if pending == crew_ref.id:
            return {"status": "already_requested", "crew_id": crew_ref.id}
        if pending:
            raise HTTPException(status_code=409, detail="You already asked another crew.")
        transaction.set(
            crew_ref.collection("joinRequests").document(uid),
            {"uid": uid, "requestedAt": SERVER_TIMESTAMP},
        )
        transaction.update(user_ref, {"pendingCrewId": crew_ref.id, "updatedAt": SERVER_TIMESTAMP})
        return {"status": "requested", "crew_id": crew_ref.id}
    _add_member(transaction, crew_ref, user_ref, uid)
    return {"status": "joined", "crew_id": crew_ref.id}


def _add_member(transaction, crew_ref, user_ref, uid: str) -> None:
    transaction.set(
        crew_ref.collection("members").document(uid),
        {"uid": uid, "joinedAt": SERVER_TIMESTAMP},
    )
    transaction.update(
        user_ref,
        {"crewId": crew_ref.id, "pendingCrewId": firestore.DELETE_FIELD, "updatedAt": SERVER_TIMESTAMP},
    )
    transaction.update(crew_ref, {"memberCount": firestore.Increment(1)})


def leave(db, uid: str) -> dict:
    transaction = db.transaction()
    return _leave_tx(transaction, db, uid, db.collection("users").document(uid))


@firestore.transactional
def _leave_tx(transaction, db, uid, user_ref) -> dict:
    user_snapshot = user_ref.get(transaction=transaction)
    user = user_snapshot.to_dict() if user_snapshot.exists else {}
    crew_id = (user or {}).get("crewId")
    if not isinstance(crew_id, str) or not crew_id:
        if (user or {}).get("ownedCrewId"):
            raise HTTPException(status_code=400, detail="The leader cannot leave the crew.")
        raise HTTPException(status_code=404, detail="You are not in a crew.")
    crew_ref = db.collection("crews").document(crew_id)
    crew_snapshot = crew_ref.get(transaction=transaction)
    crew = crew_snapshot.to_dict() if crew_snapshot.exists else None
    member_ref = crew_ref.collection("members").document(uid)
    transaction.delete(member_ref)
    transaction.update(user_ref, {"crewId": firestore.DELETE_FIELD, "updatedAt": SERVER_TIMESTAMP})
    if crew is not None:
        subs = crew.get("subLeaderUids") if isinstance(crew.get("subLeaderUids"), list) else []
        updates: dict = {"memberCount": firestore.Increment(-1)}
        if uid in subs:
            updates["subLeaderUids"] = [s for s in subs if s != uid]
        transaction.update(crew_ref, updates)
    return {"status": "left", "crew_id": crew_id}


def set_role(db, uid: str, target_uid: str, role: str) -> dict:
    """Leader only: make a member a sub-leader, or back to a plain member."""
    if role not in {"sub", "member"}:
        raise HTTPException(status_code=400, detail="Invalid role.")
    user_snapshot = db.collection("users").document(uid).get()
    crew_id = (user_snapshot.to_dict() or {}).get("ownedCrewId") if user_snapshot.exists else None
    if not isinstance(crew_id, str) or not crew_id:
        raise HTTPException(status_code=403, detail="Only the crew leader can do this.")
    crew_ref = db.collection("crews").document(crew_id)
    crew = (crew_ref.get().to_dict() or {}) if crew_ref.get().exists else {}
    if crew.get("ownerUid") != uid:
        raise HTTPException(status_code=403, detail="Only the crew leader can do this.")
    if target_uid == uid:
        raise HTTPException(status_code=400, detail="The leader is already the leader.")
    if not crew_ref.collection("members").document(target_uid).get().exists:
        raise HTTPException(status_code=404, detail="Not a member of this crew.")
    subs = [s for s in (crew.get("subLeaderUids") or []) if isinstance(s, str)]
    subs = [s for s in subs if s != target_uid]
    if role == "sub":
        subs.append(target_uid)
    crew_ref.set({"subLeaderUids": subs, "updatedAt": SERVER_TIMESTAMP}, merge=True)
    return {"status": "updated", "role": role}



# ---- join mode, requests -------------------------------------------------------
def _managed_crew(db, uid: str, *, leader_only: bool = False):
    """The crew this user may manage: (crew_id, crew_ref, crew). 403 otherwise."""
    user_snapshot = db.collection("users").document(uid).get()
    user = user_snapshot.to_dict() if user_snapshot.exists else {}
    crew_id = member_crew_id(user or {})
    crew_ref = db.collection("crews").document(crew_id) if crew_id else None
    snapshot = crew_ref.get() if crew_ref is not None else None
    crew = (snapshot.to_dict() or {}) if snapshot is not None and snapshot.exists else {}
    is_leader = bool(crew) and crew.get("ownerUid") == uid
    is_sub = bool(crew) and uid in _subs(crew)
    if not (is_leader or (is_sub and not leader_only)):
        raise HTTPException(status_code=403, detail="Not allowed.")
    return crew_id, crew_ref, crew


def set_join_mode(db, uid: str, mode: str) -> dict:
    if mode not in {"open", "approval"}:
        raise HTTPException(status_code=400, detail="Invalid join mode.")
    _id, crew_ref, _crew = _managed_crew(db, uid, leader_only=True)
    crew_ref.set({"joinMode": mode, "updatedAt": SERVER_TIMESTAMP}, merge=True)
    return {"status": "updated", "join_mode": mode}


def list_requests(db, uid: str) -> dict:
    _id, crew_ref, _crew = _managed_crew(db, uid)
    out = []
    for snapshot in crew_ref.collection("joinRequests").get():
        profile = db.collection("users").document(snapshot.id).get()
        data = profile.to_dict() if profile.exists else {}
        out.append({"uid": snapshot.id, "nickname": str((data or {}).get("nickname") or "러너")})
    out.sort(key=lambda r: r["nickname"])
    return {"requests": out}


def decide_request(db, uid: str, target_uid: str, approve: bool) -> dict:
    crew_id, crew_ref, _crew = _managed_crew(db, uid)
    transaction = db.transaction()
    return _run(
        _decide_tx,
        transaction,
        crew_ref,
        db.collection("users").document(target_uid),
        target_uid,
        approve,
    )


@firestore.transactional
def _decide_tx(transaction, crew_ref, user_ref, target_uid, approve) -> dict:
    request_ref = crew_ref.collection("joinRequests").document(target_uid)
    if not request_ref.get(transaction=transaction).exists:
        raise HTTPException(status_code=404, detail="No such request.")
    user_snapshot = user_ref.get(transaction=transaction)
    crew = crew_ref.get(transaction=transaction).to_dict() or {}
    user = user_snapshot.to_dict() if user_snapshot.exists else {}
    transaction.delete(request_ref)
    if not approve:
        if user_snapshot.exists:
            transaction.update(user_ref, {"pendingCrewId": firestore.DELETE_FIELD})
        transaction.set(
            crew_ref.collection("rejected").document(target_uid),
            {"uid": target_uid, "rejectedAt": SERVER_TIMESTAMP},
        )
        return {"status": "rejected"}
    if member_crew_id(user or {}):
        if user_snapshot.exists:
            transaction.update(user_ref, {"pendingCrewId": firestore.DELETE_FIELD})
        raise HTTPException(status_code=409, detail="Already in a crew.")
    if _count(crew) >= crew_max(crew):
        raise HTTPException(status_code=409, detail="The crew is full.")
    _add_member(transaction, crew_ref, user_ref, target_uid)
    return {"status": "approved"}


def cancel_request(db, uid: str) -> dict:
    user_ref = db.collection("users").document(uid)
    snapshot = user_ref.get()
    pending = (snapshot.to_dict() or {}).get("pendingCrewId") if snapshot.exists else None
    if not isinstance(pending, str) or not pending:
        raise HTTPException(status_code=404, detail="No pending request.")
    db.collection("crews").document(pending).collection("joinRequests").document(uid).delete()
    user_ref.update({"pendingCrewId": firestore.DELETE_FIELD})
    return {"status": "cancelled"}


# ---- kick, hand over, disband ----------------------------------------------------
def kick(db, uid: str, target_uid: str) -> dict:
    """The leader removes anyone; a sub-leader removes plain members only."""
    crew_id, crew_ref, crew = _managed_crew(db, uid)
    if target_uid == uid or target_uid == crew.get("ownerUid"):
        raise HTTPException(status_code=400, detail="Cannot remove the leader or yourself.")
    if uid != crew.get("ownerUid") and target_uid in _subs(crew):
        raise HTTPException(status_code=403, detail="A sub-leader cannot remove another sub-leader.")
    member_ref = crew_ref.collection("members").document(target_uid)
    if not member_ref.get().exists:
        raise HTTPException(status_code=404, detail="Not a member of this crew.")
    return _run(
        _kick_tx,
        db.transaction(),
        crew_ref,
        member_ref,
        db.collection("users").document(target_uid),
        target_uid,
    )


@firestore.transactional
def _kick_tx(transaction, crew_ref, member_ref, user_ref, target_uid) -> dict:
    crew = crew_ref.get(transaction=transaction).to_dict() or {}
    transaction.delete(member_ref)
    transaction.update(user_ref, {"crewId": firestore.DELETE_FIELD})
    updates: dict = {"memberCount": firestore.Increment(-1)}
    if target_uid in _subs(crew):
        updates["subLeaderUids"] = [s for s in _subs(crew) if s != target_uid]
    transaction.update(crew_ref, updates)
    return {"status": "removed"}


def transfer(db, uid: str, target_uid: str) -> dict:
    """Leader hands the crew to a member and becomes a sub-leader."""
    crew_id, crew_ref, crew = _managed_crew(db, uid, leader_only=True)
    if target_uid == uid:
        raise HTTPException(status_code=400, detail="You are already the leader.")
    if not crew_ref.collection("members").document(target_uid).get().exists:
        raise HTTPException(status_code=404, detail="Not a member of this crew.")
    return _run(
        _transfer_tx,
        db.transaction(),
        crew_ref,
        db.collection("users").document(uid),
        db.collection("users").document(target_uid),
        uid,
        target_uid,
    )


@firestore.transactional
def _transfer_tx(transaction, crew_ref, old_ref, new_ref, old_uid, new_uid) -> dict:
    crew = crew_ref.get(transaction=transaction).to_dict() or {}
    subs = [s for s in _subs(crew) if s not in {new_uid, old_uid}] + [old_uid]
    transaction.update(crew_ref, {"ownerUid": new_uid, "subLeaderUids": subs, "updatedAt": SERVER_TIMESTAMP})
    transaction.update(old_ref, {"ownedCrewId": firestore.DELETE_FIELD, "crewId": crew_ref.id})
    transaction.update(new_ref, {"crewId": firestore.DELETE_FIELD, "ownedCrewId": crew_ref.id})
    return {"status": "transferred", "new_leader": new_uid}


def disband(db, uid: str) -> dict:
    """Leader only. Everyone leaves, the leader included, and the crew is deleted.

    Paid emblems the crew bought go with it. Writes run one by one with the crew doc
    deleted last, so a half-finished run can simply be repeated.
    """
    crew_id, crew_ref, crew = _managed_crew(db, uid, leader_only=True)
    members = [snapshot.id for snapshot in crew_ref.collection("members").get()]
    for member_uid in {*members, uid}:
        user_ref = db.collection("users").document(member_uid)
        if user_ref.get().exists:
            user_ref.update(
                {
                    "crewId": firestore.DELETE_FIELD,
                    "ownedCrewId": firestore.DELETE_FIELD,
                    "updatedAt": SERVER_TIMESTAMP,
                }
            )
    for snapshot in crew_ref.collection("joinRequests").get():
        applicant = db.collection("users").document(snapshot.id)
        if applicant.get().exists:
            applicant.update({"pendingCrewId": firestore.DELETE_FIELD})
        snapshot.reference.delete()
    for member_uid in members:
        crew_ref.collection("members").document(member_uid).delete()
    for snapshot in crew_ref.collection("rejected").get():
        snapshot.reference.delete()
    crew_ref.delete()
    return {"status": "disbanded", "members_released": len(members)}


# ---- rename --------------------------------------------------------------------------
def rename(service, uid: str, name: str, request_id: str) -> dict:
    """Leader only. The first rename is free; each later one costs 300 DIA (bonus first)."""
    from app.services.streak_protection import require_request_id

    trimmed = (name or "").strip()
    if not NAME_MIN <= len(trimmed) <= NAME_MAX:
        raise HTTPException(status_code=400, detail="Invalid crew name.")
    if content_filter.has_control_characters(
        trimmed
    ) or content_filter.contains_banned_word(trimmed):
        raise HTTPException(status_code=400, detail="Inappropriate crew name.")
    request_id = require_request_id(request_id)
    db = service.firebase_service.db
    crew_id, crew_ref, _crew = _managed_crew(db, uid, leader_only=True)
    return _run(
        _rename_tx,
        db.transaction(),
        db,
        uid,
        trimmed,
        request_id,
        db.collection("users").document(uid),
        crew_ref,
    )


@firestore.transactional
def _rename_tx(transaction, db, uid, name, request_id, user_ref, crew_ref) -> dict:
    from app.services.wallet_funding import move_currency

    ledger_ref = db.collection("walletTransactions").document(f"crew_rename_{uid}_{request_id}")
    user_snapshot = user_ref.get(transaction=transaction)
    crew = crew_ref.get(transaction=transaction).to_dict() or {}
    wallet = ((user_snapshot.to_dict() or {}).get("wallet") or {}) if user_snapshot.exists else {}
    if ledger_ref.get(transaction=transaction).exists:
        return {"status": "already_renamed", "name": crew.get("name", ""), "charged_dia": 0, "diamond_balance": int(wallet.get("diamondBalance") or 0)}
    if crew.get("ownerUid") != uid:
        raise HTTPException(status_code=403, detail="Only the crew leader can do this.")
    if name == crew.get("name"):
        raise HTTPException(status_code=400, detail="That is already the crew name.")
    cost = 0 if _changes(crew) < 1 else RENAME_DIA
    balance_before = int(wallet.get("diamondBalance") or 0)
    updates: dict = {}
    ledger: dict = {}
    if cost:
        if int(wallet.get("diamondBalance") or 0) < cost:
            raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")
        moved = move_currency(wallet, diamond=-cost)
        updates.update(moved["updates"])
        ledger.update(moved["ledger"])
        transaction.update(user_ref, {**updates, "updatedAt": SERVER_TIMESTAMP})
    transaction.set(
        crew_ref,
        {"name": name, "nameChanges": _changes(crew) + 1, "updatedAt": SERVER_TIMESTAMP},
        merge=True,
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "crew_rename",
            "diamondAmount": -cost,
            "crewId": crew_ref.id,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **ledger,
        },
    )
    return {
        "status": "renamed",
        "name": name,
        "charged_dia": cost,
        "diamond_balance": balance_before - cost,
    }


# ---- expand --------------------------------------------------------------------------
def expand(service, uid: str, request_id: str) -> dict:
    """Leader only. Buys the crew's next seat step (see ``next_expansion``), bonus DIA first."""
    from app.services.streak_protection import require_request_id

    request_id = require_request_id(request_id)
    db = service.firebase_service.db
    _crew_id, crew_ref, _crew = _managed_crew(db, uid, leader_only=True)
    return _run(
        _expand_tx,
        db.transaction(),
        db,
        uid,
        request_id,
        db.collection("users").document(uid),
        crew_ref,
    )


@firestore.transactional
def _expand_tx(transaction, db, uid, request_id, user_ref, crew_ref) -> dict:
    from app.services.wallet_funding import move_currency

    ledger_ref = db.collection("walletTransactions").document(f"crew_expand_{uid}_{request_id}")
    user_snapshot = user_ref.get(transaction=transaction)
    crew = crew_ref.get(transaction=transaction).to_dict() or {}
    wallet = ((user_snapshot.to_dict() or {}).get("wallet") or {}) if user_snapshot.exists else {}
    balance_before = int(wallet.get("diamondBalance") or 0)
    if ledger_ref.get(transaction=transaction).exists:
        return {"status": "already_expanded", "max_members": crew_max(crew), "charged_dia": 0, "diamond_balance": balance_before}
    if crew.get("ownerUid") != uid:
        raise HTTPException(status_code=403, detail="Only the crew leader can do this.")
    step = next_expansion(crew)
    if step["state"] == "max":
        raise HTTPException(status_code=409, detail="The crew is at the largest size.")
    if step["state"] == "needs_full":
        raise HTTPException(status_code=409, detail="Fill every seat before growing again.")
    cost = step["cost_dia"]
    if balance_before < cost:
        raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")
    moved = move_currency(wallet, diamond=-cost)
    transaction.update(user_ref, {**moved["updates"], "updatedAt": SERVER_TIMESTAMP})
    bonus = crew_max(crew) - max_members() + step["add"]
    transaction.set(
        crew_ref,
        {"memberCapBonus": bonus, "updatedAt": SERVER_TIMESTAMP},
        merge=True,
    )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "crew_member_expand",
            "diamondAmount": -cost,
            "addedSeats": step["add"],
            "crewId": crew_ref.id,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **moved["ledger"],
        },
    )
    return {
        "status": "expanded",
        "max_members": max_members() + bonus,
        "added": step["add"],
        "charged_dia": cost,
        "diamond_balance": balance_before - cost,
    }


# ---- gift ----------------------------------------------------------------------------
def gift(service, uid: str, target_uid: str, request_id: str) -> dict:
    """Leader only. Puts one CPR ticket and one Safeguard in a member's inventory.

    ``target_uid`` empty means every other member. The leader pays GIFT_DIA_PER_MEMBER per
    member (bonus DIA first). The same request id never pays twice.
    """
    from app.services.streak_protection import require_request_id

    request_id = require_request_id(request_id)
    db = service.firebase_service.db
    crew_id, crew_ref, _crew = _managed_crew(db, uid, leader_only=True)
    member_uids = [
        snapshot.id
        for snapshot in crew_ref.collection("members").get()
        if snapshot.id != uid
    ]
    if target_uid:
        if target_uid == uid or target_uid not in member_uids:
            raise HTTPException(status_code=404, detail="That member is not in your crew.")
        recipients = [target_uid]
    else:
        recipients = member_uids
    if not recipients:
        raise HTTPException(status_code=400, detail="There is nobody to give gifts to.")
    return _run(
        _gift_tx,
        db.transaction(),
        db,
        uid,
        recipients,
        request_id,
        db.collection("users").document(uid),
        crew_ref,
    )


@firestore.transactional
def _gift_tx(transaction, db, uid, recipients, request_id, user_ref, crew_ref) -> dict:
    from app.services.wallet_funding import move_currency

    ledger_ref = db.collection("walletTransactions").document(f"crew_gift_{uid}_{request_id}")
    user_snapshot = user_ref.get(transaction=transaction)
    wallet = ((user_snapshot.to_dict() or {}).get("wallet") or {}) if user_snapshot.exists else {}
    balance_before = int(wallet.get("diamondBalance") or 0)
    if ledger_ref.get(transaction=transaction).exists:
        return {"status": "already_gifted", "recipients": len(recipients), "charged_dia": 0, "diamond_balance": balance_before}
    cost = GIFT_DIA_PER_MEMBER * len(recipients)
    if balance_before < cost:
        raise HTTPException(status_code=400, detail="Insufficient Diamond balance.")
    # Every read comes before the first write.
    current: dict[tuple[str, str], int] = {}
    for member_uid in recipients:
        for item_id, _title in GIFT_ITEMS:
            snap = (
                db.collection("users").document(member_uid)
                .collection("shopInventory").document(item_id)
                .get(transaction=transaction)
            )
            current[(member_uid, item_id)] = (
                int((snap.to_dict() or {}).get("quantity") or 0) if snap.exists else 0
            )
    moved = move_currency(wallet, diamond=-cost)
    transaction.update(user_ref, {**moved["updates"], "updatedAt": SERVER_TIMESTAMP})
    for member_uid in recipients:
        for item_id, title in GIFT_ITEMS:
            transaction.set(
                db.collection("users").document(member_uid)
                .collection("shopInventory").document(item_id),
                {
                    "itemId": item_id,
                    "title": title,
                    "quantity": current[(member_uid, item_id)] + 1,
                    "purchasedAt": SERVER_TIMESTAMP,
                },
                merge=True,
            )
    transaction.set(
        ledger_ref,
        {
            "uid": uid,
            "type": "crew_item_gift",
            "diamondAmount": -cost,
            "itemIds": [item_id for item_id, _title in GIFT_ITEMS],
            "recipientCount": len(recipients),
            "recipients": recipients[:50],
            "crewId": crew_ref.id,
            "requestId": request_id,
            "createdAt": SERVER_TIMESTAMP,
            **moved["ledger"],
        },
    )
    return {
        "status": "gifted",
        "recipients": len(recipients),
        "charged_dia": cost,
        "diamond_balance": balance_before - cost,
    }
