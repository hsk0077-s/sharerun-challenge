"""Crew emblem: one shape and one color, stored as ``shape:color``.

The app shows 44 shapes and 6 colors. The server keeps the same list so a
crafted request cannot store anything else on a crew doc.
"""

from fastapi import HTTPException

CREW_EMBLEM_SHAPES = frozenset(
    {
        "moon", "bolt", "fire", "star", "heart", "shield",
        "sun", "rocket", "paw", "crown", "leaf", "wave",
        "peak", "anchor", "flag", "diamond", "trophy", "run",
        "lotus", "snow", "wing", "bike", "sail", "target",
        "walk", "hike", "swim", "speed", "timer", "dumbbell", "ball", "hoops",
        "tennis", "skate", "tree", "drop", "flower", "cloud", "globe", "medal",
        "spark", "bird", "bunny", "bee",
    }
)
CREW_EMBLEM_COLORS = frozenset({"lime", "gold", "sky", "pink", "violet", "white"})
DEFAULT_CREW_EMBLEM = "moon:lime"


def normalize_crew_emblem(value: str | None) -> str:
    """The emblem to store. Empty means the default; an unknown value is refused."""
    if value is None or not value.strip():
        return DEFAULT_CREW_EMBLEM
    parts = value.strip().split(":")
    if len(parts) != 2 or parts[0] not in CREW_EMBLEM_SHAPES or parts[1] not in CREW_EMBLEM_COLORS:
        raise HTTPException(status_code=400, detail="Invalid crew emblem.")
    return f"{parts[0]}:{parts[1]}"
