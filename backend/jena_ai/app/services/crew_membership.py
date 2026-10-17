"""Crew membership: list, join, leave, who is in my crew, sub-leaders.

A crew doc keeps ``memberCount``; each member also has ``crews/{id}/members/{uid}``.
A member's user doc carries ``crewId`` (the owner's carries ``ownedCrewId``). A user is in
at most one crew. Joining is open: no approval step.
"""

from __future__ import annotations

import os

from fastapi import HTTPException
from google.cloud import firestore
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.services.social_items import member_crew_id

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
    }


def list_crews(db, query: str = "") -> list[dict]:
    """Crews matching a name fragment, biggest first. Public information only."""
    needle = query.strip().lower()
    out = []
    for snapshot in db.collection("crews").limit(LIST_LIMIT).get():
        crew = snapshot.to_dict() or {}
        name = str(crew.get("name") or "")
        if needle and needle not in name.lower():
            continue
        out.append(summary(snapshot.id, crew))
    out.sort(key=lambda c: (-c["member_count"], c["name"]))
    return out[:RESULT_LIMIT]


def my_crew(db, uid: str) -> dict:
    """The crew I am in, my role and the members. ``crew`` is null without one."""
    user_snapshot = db.collection("users").document(uid).get()
    user = user_snapshot.to_dict() if user_snapshot.exists else {}
    crew_id = member_crew_id(user or {})
    if not crew_id:
        return {"crew": None, "role": "none", "members": []}
    crew_snapshot = db.collection("crews").document(crew_id).get()
    if not crew_snapshot.exists:
        return {"crew": None, "role": "none", "members": []}
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
    return {"crew": {**summary(crew_id, crew), "owner_uid": crew.get("ownerUid")}, "role": role, "members": members}


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
    transaction.set(
        crew_ref.collection("members").document(uid),
        {"uid": uid, "joinedAt": SERVER_TIMESTAMP},
    )
    transaction.update(user_ref, {"crewId": crew_ref.id, "updatedAt": SERVER_TIMESTAMP})
    transaction.update(crew_ref, {"memberCount": firestore.Increment(1)})
    return {"status": "joined", "crew_id": crew_ref.id}


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
