"""Crew emblem, stored as one string.

Two forms are accepted:

* v1 ``shape:color`` (44 icon shapes + 30 drawn glyphs, 6 colors). Existing crews keep it.
* v2 ``frame:glyph:pattern:frameColor:glyphColor`` from the design pack: 8 frames x
  30 glyphs x 4 patterns (or ``none``) x 12 colors. Only frame/glyph colour pairs with
  contrast >= 3:1 are allowed (``color-pairs.csv``), so a crafted request cannot store
  anything else on a crew doc. A sixth part may name an unlock border (``distance-2``).
* paid ``paid:<id>``: an illustrated emblem the crew bought.

Whether the crew has earned a border or bought a paid emblem is checked by the service.
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
        "g_bolt",
        "g_cheetah",
        "g_chevrons",
        "g_city",
        "g_clock",
        "g_compass",
        "g_crown",
        "g_droplet",
        "g_ecg",
        "g_flag",
        "g_flame",
        "g_footprints",
        "g_hands",
        "g_heart",
        "g_horse",
        "g_infinity",
        "g_laurel",
        "g_maltese",
        "g_map_pin",
        "g_mountain",
        "g_shoe",
        "g_sprout",
        "g_star",
        "g_sun",
        "g_tree",
        "g_trophy",
        "g_turtle",
        "g_wave",
        "g_wings",
        "g_wolf",
    }
)
CREW_EMBLEM_COLORS = frozenset({"lime", "gold", "sky", "pink", "violet", "white"})
CREW_EMBLEM_FRAMES = frozenset(
    {"shield", "circle", "hexagon", "pennant", "diamond", "rounded-square", "octagon", "seal"}
)
CREW_EMBLEM_PATTERNS = frozenset({"none", "rays", "stripes", "dots", "chevrons"})
CREW_EMBLEM_COLORS_V2 = frozenset(
    {"lime", "gold", "red", "white", "orange", "sky", "blue", "purple", "pink", "mint", "navy", "charcoal"}
)
CREW_EMBLEM_COLOR_PAIRS = frozenset(
    {
        ("blue", "charcoal"),
        ("blue", "lime"),
        ("blue", "navy"),
        ("blue", "white"),
        ("charcoal", "blue"),
        ("charcoal", "gold"),
        ("charcoal", "lime"),
        ("charcoal", "mint"),
        ("charcoal", "orange"),
        ("charcoal", "pink"),
        ("charcoal", "purple"),
        ("charcoal", "red"),
        ("charcoal", "sky"),
        ("charcoal", "white"),
        ("gold", "charcoal"),
        ("gold", "navy"),
        ("lime", "blue"),
        ("lime", "charcoal"),
        ("lime", "navy"),
        ("lime", "purple"),
        ("mint", "charcoal"),
        ("mint", "navy"),
        ("navy", "blue"),
        ("navy", "gold"),
        ("navy", "lime"),
        ("navy", "mint"),
        ("navy", "orange"),
        ("navy", "pink"),
        ("navy", "purple"),
        ("navy", "red"),
        ("navy", "sky"),
        ("navy", "white"),
        ("orange", "charcoal"),
        ("orange", "navy"),
        ("pink", "charcoal"),
        ("pink", "navy"),
        ("purple", "charcoal"),
        ("purple", "lime"),
        ("purple", "navy"),
        ("purple", "white"),
        ("red", "charcoal"),
        ("red", "navy"),
        ("sky", "charcoal"),
        ("sky", "navy"),
        ("white", "blue"),
        ("white", "charcoal"),
        ("white", "navy"),
        ("white", "purple"),
    }
)
PAID_EMBLEM_IDS = frozenset({"sunrise-cheetah", "moon-wolf", "ocean-turtle", "glow-heart"})
BORDER_IDS = frozenset(
    f"{k}-{t}" for k in ("distance", "donation", "members", "ranking") for t in (1, 2, 3)
)
DEFAULT_CREW_EMBLEM = "moon:lime"


def normalize_crew_emblem(value: str | None) -> str:
    """The emblem to store. Empty means the default; an unknown value is refused."""
    if value is None or not value.strip():
        return DEFAULT_CREW_EMBLEM
    parts = value.strip().split(":")
    if len(parts) == 2 and parts[0] == "paid":
        if parts[1] in PAID_EMBLEM_IDS:
            return value.strip()
        raise HTTPException(status_code=400, detail="Invalid crew emblem.")
    if len(parts) == 2:
        if parts[0] not in CREW_EMBLEM_SHAPES or parts[1] not in CREW_EMBLEM_COLORS:
            raise HTTPException(status_code=400, detail="Invalid crew emblem.")
        return f"{parts[0]}:{parts[1]}"
    if len(parts) in (5, 6):
        frame, glyph, pattern, frame_color, glyph_color = parts[:5]
        border = parts[5] if len(parts) == 6 else None
        if (border is None or border in BORDER_IDS) and (
            frame in CREW_EMBLEM_FRAMES
            and glyph.startswith("g_")
            and glyph in CREW_EMBLEM_SHAPES
            and pattern in CREW_EMBLEM_PATTERNS
            and (frame_color, glyph_color) in CREW_EMBLEM_COLOR_PAIRS
        ):
            return ":".join(parts)
    raise HTTPException(status_code=400, detail="Invalid crew emblem.")
