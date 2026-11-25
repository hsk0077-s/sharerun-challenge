"""One-time move of World Tour progress from egypt_pyramids to uk_big_ben.

The Pyramids mission was replaced by Big Ben. The server already shows old
progress on Big Ben without this script (see LEGACY_MISSION_ALIASES in
app/services/world_tour.py), so running it is tidy-up, not a requirement. It
also writes the new catalog documents.

What it does:
  1. For every users/{uid}/worldTour/egypt_pyramids document, copies
     progressKm, state, completedAt and stampId to users/{uid}/worldTour/uk_big_ben
     when that document does not exist yet. The old document is left in place.
  2. Writes the 13 catalog documents (worldTourMissions/*) from MISSION_SEED.
  3. Sets worldTourMissions/egypt_pyramids to active: False when it exists.

It is a dry run unless --apply is given. Run from backend/jena_ai:

    python scripts/migrate_world_tour_pyramids_to_big_ben.py            # dry run
    python scripts/migrate_world_tour_pyramids_to_big_ben.py --apply    # writes

Needs Google application-default credentials for the production project.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.services import world_tour  # noqa: E402

OLD_ID = "egypt_pyramids"
NEW_ID = "uk_big_ben"
COPY_FIELDS = ("progressKm", "state", "completedAt", "stampId")


def plan(db) -> dict:
    """What would change. Reads only."""
    to_copy: list[tuple[str, dict]] = []
    skipped_existing: list[str] = []
    for snap in db.collection_group(world_tour.PROGRESS).get():
        if snap.id != OLD_ID:
            continue
        parts = snap.reference.path.split("/")
        if len(parts) != 4 or parts[0] != world_tour.USERS:
            continue
        uid = parts[1]
        target = (
            db.collection(world_tour.USERS)
            .document(uid)
            .collection(world_tour.PROGRESS)
            .document(NEW_ID)
            .get()
        )
        if target.exists:
            skipped_existing.append(uid)
            continue
        old = snap.to_dict() or {}
        data = {field: old[field] for field in COPY_FIELDS if field in old}
        data["missionId"] = NEW_ID
        to_copy.append((uid, data))
    old_catalog = db.collection(world_tour.MISSIONS).document(OLD_ID).get()
    return {
        "copy": to_copy,
        "skipped_existing": skipped_existing,
        "deactivate_old_catalog": bool(old_catalog.exists),
        "seed_missions": len(world_tour.MISSION_SEED),
    }


def apply(db, planned: dict) -> None:
    for uid, data in planned["copy"]:
        db.collection(world_tour.USERS).document(uid).collection(
            world_tour.PROGRESS
        ).document(NEW_ID).set(data, merge=True)
    world_tour.seed_missions(db)
    if planned["deactivate_old_catalog"]:
        db.collection(world_tour.MISSIONS).document(OLD_ID).set(
            {"active": False}, merge=True
        )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--apply", action="store_true", help="write the changes (default: dry run)"
    )
    args = parser.parse_args(argv)

    from app.services.firebase_service import FirebaseService

    db = FirebaseService().db
    planned = plan(db)
    print(f"progress documents to copy to {NEW_ID}: {len(planned['copy'])}")
    print(f"users who already have {NEW_ID} (left alone): {len(planned['skipped_existing'])}")
    print(f"catalog documents to write: {planned['seed_missions']}")
    print(f"deactivate catalog {OLD_ID}: {planned['deactivate_old_catalog']}")
    if not args.apply:
        print("dry run: nothing was written. Add --apply to write.")
        return 0
    apply(db, planned)
    print("applied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
