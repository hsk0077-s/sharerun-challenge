"""Seed Firebase Emulator with MVP demo documents."""

from __future__ import annotations

import os
import sys
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import firestore

ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

os.environ.setdefault("GOOGLE_CLOUD_PROJECT", os.getenv("GOOGLE_CLOUD_PROJECT", "demo-src-local"))
os.environ.setdefault(
    "FIRESTORE_EMULATOR_HOST",
    os.getenv("FIRESTORE_EMULATOR_HOST", "127.0.0.1:8085"),
)

db = firestore.Client()
now = datetime.now(timezone.utc)


def seed() -> None:
    tournaments = {
        "rookie-3k-unicef": {
            "title": "루키 3K 유니세프 런",
            "targetDistanceKm": 3,
            "entryFeeShare": 100,
            "winnerRewardValue": 500,
            "donationValue": 200,
            "minParticipantsBep": 10,
            "maxParticipants": 100,
            "participantCount": 0,
            "requiredTier": 1,
            "status": "recruiting",
            "sponsorName": "유니세프 파트너",
            "createdAt": now,
        },
        "neon-5k-sprint": {
            "title": "네온 5K 스프린트",
            "targetDistanceKm": 5,
            "entryFeeShare": 200,
            "winnerRewardValue": 800,
            "donationValue": 350,
            "minParticipantsBep": 8,
            "maxParticipants": 50,
            "participantCount": 0,
            "requiredTier": 1,
            "status": "recruiting",
            "sponsorName": "쉐어런 스폰서",
            "createdAt": now,
        },
    }

    for doc_id, payload in tournaments.items():
        db.collection("tournaments").document(doc_id).set(payload, merge=True)
        print(f"Seeded tournaments/{doc_id}")

    db.collection("diamondBoxes").document("park-gate").set(
        {
            "title": "공원 입구 다이아",
            "latitude": 37.5665,
            "longitude": 126.9780,
            "rewardDiamond": 3,
            "active": True,
        },
        merge=True,
    )
    print("Seeded diamondBoxes/park-gate")

    db.collection("crewRankings").document("neon-runners").set(
        {
            "name": "네온 러너스",
            "totalValue": 3200,
            "memberCount": 12,
        },
        merge=True,
    )
    print("Seeded crewRankings/neon-runners")
    print("Emulator seed complete.")


if __name__ == "__main__":
    try:
        seed()
    except Exception as error:  # noqa: BLE001
        print(f"Seed failed: {error}", file=sys.stderr)
        sys.exit(1)
