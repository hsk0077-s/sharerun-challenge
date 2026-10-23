"""Server-side word filter for names other players see (nicknames, crew names).

The app already filters nicknames on the phone, but a phone can be bypassed, and
crew names had no filter at all. This runs on the server so both are covered.
"""

import re
import unicodedata

_BANNED = (
    "시발",
    "씨발",
    "씨바",
    "병신",
    "지랄",
    "좆",
    "존나",
    "개새끼",
    "새끼",
    "씹",
    "니미",
    "느금",
    "썅",
    "개년",
    "창녀",
    "섹스",
    "야동",
    "포르노",
    "성인물",
    "fuck",
    "shit",
    "bitch",
    "asshole",
    "dick",
    "porn",
    "cunt",
    "nigger",
    "nigga",
    "faggot",
)

# Spaces, punctuation, zero-width characters and emoji are dropped before matching,
# so "씨 발" or "f.u.c.k" do not slip through.
_NOT_LETTER_OR_DIGIT = re.compile(r"[^0-9a-z가-힣ㄱ-ㅎㅏ-ㅣ]")


def _normalize(text: str) -> str:
    folded = unicodedata.normalize("NFKC", text or "").lower()
    return _NOT_LETTER_OR_DIGIT.sub("", folded)


def contains_banned_word(text: str) -> bool:
    flat = _normalize(text)
    return any(word in flat for word in _BANNED)


def has_control_characters(text: str) -> bool:
    return any(unicodedata.category(ch) in {"Cc", "Cf", "Cs"} for ch in text or "")
