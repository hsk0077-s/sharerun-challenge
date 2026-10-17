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

from app.services.social_items import member_crew_id

def _run(tx_func, transaction, *args):
    """Run a transactional function. Tests swap this for the plain wrapped function."""
    return tx_func(transaction, *args)


DEFAULT_MAX_MEMBERS = 100
LIST_LIMIT = 200
RESULT_LIMIT = 30


def max_members() -> int:
    raw = os.environ.get("CREW_MAX_MEMBERS", "").strip()
    try:
        return max(1, int(raw)) if raw else DEFAULT_MAX_MEMBERS
    except ValueError:
        return DEFAULT_MAX_MEMBERS


def _count(crew: dict) -> int:
    raw = crew.get("memberCount")
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
        "max_members": max_members(),
        "is_full": count >= max_members(),
        "total_distance_km": float(crew.get("totalDistanceKm") or 0),
        "join_mode": join_mode(crew),
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
        out.append(summary(snapshot.id, crew))
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
        "crew": {**summary(crew_id, crew), "owner_uid": crew.get("ownerUid")},
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
    if current:
        raise HTTPException(status_code=409, detail="Already in a crew.")
    if _count(crew) >= max_members():
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
        return {"status": "rejected"}
    if member_crew_id(user or {}):
        if user_snapshot.exists:
            transaction.update(user_ref, {"pendingCrewId": firestore.DELETE_FIELD})
        raise HTTPException(status_code=409, detail="Already in a crew.")
    if _count(crew) >= max_members():
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
    crew_ref.delete()
    return {"status": "disbanded", "members_released": len(members)}
