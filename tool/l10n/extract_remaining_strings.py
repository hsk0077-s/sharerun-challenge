#!/usr/bin/env python3
"""Pull user-visible Korean that is not already in the 11-locale catalogs.

Writes docs/l10n/remaining-ko-strings.json. Does not translate.
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib"
ADMIN = ROOT / "admin"
OUT = ROOT / "docs" / "l10n" / "remaining-ko-strings.json"

HANGUL = re.compile(r"[\uac00-\ud7a3]")
PARTICLES = {
    "이", "가", "을", "를", "은", "는", "과", "와", "으로", "로",
    "아", "야", "이랑", "랑",
}
LOG_CALLS = (
    "debugPrint",
    "debugPrintStack",
    "print",
    "developer.log",
    "log(",
    "logger.",
    "Logger(",
    "fine(",
    "info(",
    "warning(",
    "severe(",
    "crashlytics",
)
LOCALES = ["en", "ja", "zh-TW", "es", "pt-BR", "de", "fr", "vi", "th", "id"]
SECTION = re.compile(r"//\s*──+\s*(.+)")
DECL_NAME = re.compile(
    r"^\s*(?:static\s+)?(?:const|final)\s+([A-Za-z_][A-Za-z0-9_]*)\s*="
)
FUNC_DECL = re.compile(
    r"^\s*(?:static\s+)?String\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?:\(|=>)"
)
GETTER_DECL = re.compile(
    r"^\s*(?:static\s+)?String\s+get\s+([A-Za-z_][A-Za-z0-9_]*)\b"
)


_SIMPLE_ESCAPE = {
    "n": "\n",
    "r": "\r",
    "t": "\t",
    "b": "\b",
    "f": "\f",
    "v": "\v",
    "\\": "\\",
    "'": "'",
    '"': '"',
    "$": "$",
}


def _dart_escape(text: str, j: int) -> tuple[str, int, bool]:
    """Decode one Dart escape at text[j] == backslash.

    Returns the decoded text, the index after the escape, and whether the
    source line ended (a backslash before a real newline).
    """
    nxt = text[j + 1]
    if nxt == "\n":
        return "", j + 2, True
    if nxt in _SIMPLE_ESCAPE:
        return _SIMPLE_ESCAPE[nxt], j + 2, False
    if nxt == "x" and j + 3 < len(text) and re.fullmatch(r"[0-9a-fA-F]{2}", text[j + 2:j + 4]):
        return chr(int(text[j + 2:j + 4], 16)), j + 4, False
    if nxt == "u" and j + 2 < len(text) and text[j + 2] == "{":
        end = text.find("}", j + 3)
        hexpart = text[j + 3:end] if end != -1 else ""
        if end != -1 and re.fullmatch(r"[0-9a-fA-F]+", hexpart):
            return chr(int(hexpart, 16)), end + 1, False
    if nxt == "u" and j + 5 < len(text) and re.fullmatch(r"[0-9a-fA-F]{4}", text[j + 2:j + 6]):
        return chr(int(text[j + 2:j + 6], 16)), j + 6, False
    return text[j:j + 2], j + 2, False


def dart_strings(text: str) -> list[tuple[int, str, int]]:
    """Return (line, literal source including quotes-stripped value, start index)."""
    out: list[tuple[int, str, int]] = []
    i = 0
    n = len(text)
    line = 1
    while i < n:
        ch = text[i]
        if ch == "\n":
            line += 1
            i += 1
            continue
        if ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if ch == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                if text[i] == "\n":
                    line += 1
                i += 1
            i = min(n, i + 2)
            continue
        if text.startswith(("r'''", "r\"\"\"", "'''", "\"\"\""), i) or (
            ch in "'\"" and (i == 0 or text[i - 1] != "\\")
        ):
            raw = text.startswith(("r'''", "r\"\"\"", "r'", 'r"'), i)
            if text.startswith(("r'''", "'''"), i):
                quote = "'''"
                start = i + (4 if raw and text.startswith("r'''", i) else 3)
            elif text.startswith(('r"""', '"""'), i):
                quote = '"""'
                start = i + (4 if raw and text.startswith('r"""', i) else 3)
            elif text.startswith(("r'", 'r"'), i):
                quote = text[i + 1]
                start = i + 2
                raw = True
            else:
                quote = ch
                start = i + 1
                raw = False
            j = start
            buf: list[str] = []
            while j < n:
                if text.startswith(quote, j):
                    j += len(quote)
                    break
                if not raw and text[j] == "\\" and j + 1 < n:
                    decoded, j, broke = _dart_escape(text, j)
                    if broke:
                        line += 1
                    buf.append(decoded)
                    continue
                if text[j] == "\n":
                    line += 1
                buf.append(text[j])
                j += 1
            out.append((line, "".join(buf), i))
            i = j
            continue
        i += 1
    return out


def merge_adjacent(text: str, found: list[tuple[int, str, int]]) -> list[tuple[int, str, int]]:
    if not found:
        return []
    merged = [found[0]]
    for line, value, start in found[1:]:
        prev_line, prev_value, prev_start = merged[-1]
        gap = text[prev_start:start]
        # previous literal end is unknown; use the gap between start indexes
        # only when the gap is whitespace plus the closing/opening quotes.
        between = text[found_end(text, prev_start):start]
        if re.fullmatch(r"\s*", between):
            merged[-1] = (prev_line, prev_value + value, prev_start)
        else:
            merged.append((line, value, start))
    return merged


def found_end(text: str, start: int) -> int:
    raw = text.startswith(("r'''", "r\"\"\"", "r'", 'r"'), start)
    if text.startswith(("r'''", "'''"), start):
        quote = "'''"
        i = start + (4 if text.startswith("r'''", start) else 3)
    elif text.startswith(('r"""', '"""'), start):
        quote = '"""'
        i = start + (4 if text.startswith('r"""', start) else 3)
    elif text.startswith(("r'", 'r"'), start):
        quote = text[start + 1]
        i = start + 2
    else:
        quote = text[start]
        i = start + 1
    while i < len(text):
        if text.startswith(quote, i):
            return i + len(quote)
        if not raw and text[i] == "\\" and i + 1 < len(text):
            i += 2
            continue
        i += 1
    return len(text)


def placeholders(value: str) -> list[dict]:
    found = []
    for match in re.finditer(r"\$\{([^{}]+)\}|\$([A-Za-z_][A-Za-z0-9_]*)|\{([A-Za-z_][A-Za-z0-9_]*)\}", value):
        if match.group(1) is not None:
            expr = match.group(1).strip()
            found.append({"name": expr, "format": "${" + expr + "}"})
        elif match.group(2) is not None:
            name = match.group(2)
            found.append({"name": name, "format": "$" + name})
        else:
            name = match.group(3)
            found.append({"name": name, "format": "{" + name + "}"})
    return found


def screen_from_path(path: Path) -> str:
    stem = path.stem
    for suffix in ("_screen", "_page", "_sheet", "_dialog", "_card"):
        if stem.endswith(suffix):
            stem = stem[: -len(suffix)]
            break
    if path.name == "app_strings.dart":
        return "app_strings"
    parts = path.parts
    if "screens" in parts:
        return stem
    if "features" in parts:
        idx = parts.index("features")
        feature = parts[idx + 1] if idx + 1 < len(parts) else stem
        return f"{feature}.{stem}" if stem != feature else feature
    if "widgets" in parts:
        return f"widget.{stem}"
    return stem


def section_at(lines: list[str], line_no: int) -> str | None:
    for index in range(line_no - 1, -1, -1):
        match = SECTION.search(lines[index])
        if match:
            title = match.group(1).strip()
            title = re.sub(r"\(Screen\s+\d+\)", "", title).strip(" ─-")
            return title
        if line_no - index > 80:
            break
    return None


def const_name_at(lines: list[str], line_no: int) -> str | None:
    for index in range(line_no - 1, max(-1, line_no - 12), -1):
        line = lines[index]
        if not line.strip() or line.strip().startswith(("'", '"', "r'", 'r"')):
            continue
        for pattern in (DECL_NAME, GETTER_DECL, FUNC_DECL):
            match = pattern.match(line)
            if match and not match.group(1).startswith("_"):
                return match.group(1)
        if line.strip().endswith("{") or line.strip().startswith("}"):
            break
    return None


def role_and_limit(before: str, after: str) -> tuple[str, str]:
    blob = before[-240:] + after[:160]
    if re.search(r"\b(hintText|helperText|hint:|labelText)\b", blob):
        return "hint", "입력란 힌트 또는 보조 문구. 한 줄. 길면 잘립니다."
    if re.search(r"\b(SnackBar|showSnackBar|_toast|toast)\b", blob):
        return "toast", "잠깐 뜨는 안내. 두 줄 이내."
    if re.search(r"\b(FilledButton|OutlinedButton|TextButton|ElevatedButton|IconButton|onPressed)\b", blob):
        return "button", "버튼. 한 줄. 한국어 12자 안팎을 넘기지 마세요."
    if re.search(r"\b(AppBar|title:)\b", blob):
        return "title", "제목. 한 줄. 길면 말줄임입니다."
    if re.search(r"\b(tooltip|semanticLabel|Semantics)\b", blob):
        return "accessibility", "스크린 리더 또는 툴팁. 한 문장."
    if re.search(r"\b(AlertDialog|showDialog|content:)\b", blob):
        return "dialog", "대화상자 본문. 짧은 문단. 줄바꿈은 유지합니다."
    if re.search(r"maxLines:\s*1", blob):
        return "label", "한 줄 라벨. 길면 잘립니다."
    return "body", "화면 본문. 줄바꿈이 있으면 유지합니다."


def is_log(text: str, start: int) -> bool:
    line_start = text.rfind("\n", 0, start) + 1
    stmt = text[line_start:start]
    semi = stmt.rfind(";")
    if semi >= 0:
        stmt = stmt[semi + 1:]
    compact = stmt.replace(" ", "")
    if "kDebugMode" in stmt and "debugPrint" in text[start:start + 80]:
        return True
    return any(call.replace(" ", "") in compact.replace(" ", "") or call in stmt for call in LOG_CALLS)


def is_regexp(text: str, start: int) -> bool:
    line_start = text.rfind("\n", 0, start) + 1
    stmt = text[line_start:start]
    return "RegExp" in stmt or "Pattern" in stmt or "_NICKNAME" in stmt


def load_localized_korean() -> set[str]:
    known: set[str] = set()
    l10n = LIB / "l10n"
    for path in l10n.glob("*.dart"):
        text = path.read_text(encoding="utf-8")
        for _line, value, _start in dart_strings(text):
            if HANGUL.search(value):
                known.add(value.strip(" "))
    wear = ROOT / "wear_app" / "lib" / "l10n"
    if wear.exists():
        for path in wear.glob("*.dart"):
            text = path.read_text(encoding="utf-8")
            for _line, value, _start in dart_strings(text):
                if HANGUL.search(value):
                    known.add(value.strip(" "))
    return known


def normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def walk_dart(root: Path) -> list[Path]:
    skip = {"l10n", ".dart_tool"}
    paths = []
    for path in root.rglob("*.dart"):
        if any(part in skip for part in path.parts):
            continue
        if path.name.endswith(".g.dart"):
            continue
        paths.append(path)
    return paths


def count_admin() -> int:
    if not ADMIN.exists():
        return 0
    seen: set[str] = set()
    for path in ADMIN.rglob("*"):
        if path.suffix.lower() not in {".ts", ".tsx", ".js", ".jsx", ".vue", ".html"}:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        # rough string grab
        for match in re.finditer(r"(['\"`])((?:\\.|(?!\1).)*)\1", text):
            value = match.group(2)
            if HANGUL.search(value):
                seen.add(normalize(value))
    return len(seen)


def main() -> None:
    known = load_localized_korean()
    excluded = {
        "logs": 0,
        "already_localized": 0,
        "particles": 0,
        "regexp": 0,
        "guide_fallback_already_localized": 0,
        "comments_skipped_by_parser": 0,
        "admin_unique": count_admin(),
    }
    grouped: dict[str, dict] = {}
    order: list[str] = []

    for path in walk_dart(LIB):
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines()
        rel = path.relative_to(ROOT).as_posix()
        found = merge_adjacent(text, dart_strings(text))
        section = None
        for line_no, value, start in found:
            if not HANGUL.search(value):
                continue
            cleaned = value.strip(" ")
            if not cleaned or not HANGUL.search(cleaned):
                continue
            if is_log(text, start):
                excluded["logs"] += 1
                continue
            if is_regexp(text, start):
                excluded["regexp"] += 1
                continue
            if normalize(cleaned) in PARTICLES or cleaned in PARTICLES:
                excluded["particles"] += 1
                continue
            if cleaned in known:
                excluded["already_localized"] += 1
                continue
            if path.name == "wearable_brand_guide_sheet.dart" and line_no < 160:
                excluded["guide_fallback_already_localized"] = (
                    excluded.get("guide_fallback_already_localized", 0) + 1
                )
                continue
            line_text = lines[line_no - 1] if line_no - 1 < len(lines) else ""
            before = text[max(0, start - 400):start]
            after = text[start:start + 220]
            role, limit = role_and_limit(before, after)
            name = const_name_at(lines, line_no)
            if path.name == "app_strings.dart":
                section_title = section_at(lines, line_no) or "app"
                screen = re.sub(r"[^A-Za-z0-9]+", "_", section_title).strip("_").lower() or "app"
            else:
                screen = screen_from_path(path)
            key_base = None
            if name and path.name == "app_strings.dart":
                key_base = f"app.{name}"
            norm = cleaned
            if norm not in grouped:
                key_base = key_base or f"{screen}.{role}"
                grouped[norm] = {
                    "key": key_base,
                    "ko": cleaned,
                    "file": rel,
                    "screen": screen,
                    "role": role,
                    "limit": limit,
                    "line": line_no,
                    "usages": [],
                    "placeholders": placeholders(cleaned),
                }
                order.append(norm)
            entry = grouped[norm]
            if name and path.name == "app_strings.dart" and entry["key"].startswith(f"{screen}."):
                entry["key"] = f"app.{name}"
                entry["file"] = rel
                entry["screen"] = screen
                entry["role"] = role
                entry["limit"] = limit
            entry["usages"].append({"file": rel, "line": line_no, "screen": screen, "role": role})

    by_screen: dict[str, int] = defaultdict(int)
    strings = []
    seen_keys: dict[str, int] = defaultdict(int)
    for norm in order:
        entry = grouped[norm]
        seen_keys[entry["key"]] += 1
        if seen_keys[entry["key"]] > 1:
            entry["key"] = f"{entry['key']}.{seen_keys[entry['key']]}"
        usages = entry["usages"]
        extra = ""
        if len(usages) > 1:
            places = ", ".join(f"{u['screen']}({u['role']})" for u in usages[:6])
            extra = f" 같은 문장이 {len(usages)}곳에 쓰입니다: {places}."
        context = f"{entry['screen']} 화면의 {entry['role']}. {entry['limit']}{extra}"
        item = {
            "key": entry["key"],
            "ko": entry["ko"],
            "file": entry["file"],
            "screen": entry["screen"],
            "context": context,
            "placeholders": entry["placeholders"],
        }
        for locale in LOCALES:
            item[locale] = ""
        strings.append(item)
        by_screen[entry["screen"]] += 1

    payload = {
        "meta": {
            "purpose": "아직 11개 로케일에 없는 화면 한국어. 번역은 이 파일을 채워서 돌려준다.",
            "doNotTranslate": [
                "SHARE", "DIA", "VALUE", "Coach+", "ShareRun", "Jena", "Health Connect", "HealthKit",
            ],
            "tone": (
                "사용자에게 말하는 문장은 해요체다. 버튼과 제목은 짧게, 본문은 한두 문장. "
                "하십시오체는 약관처럼 법 문장일 때만. 번역문은 비어 있는 로케일 칸에만 넣는다. ko는 고치지 않는다."
            ),
            "glossary": [
                {"ko": "쉐어런", "keep": "ShareRun", "note": "서비스 이름. 번역하지 않는다."},
                {"ko": "SHARE", "keep": "SHARE", "note": "걸음·러닝 재화 이름. 번역하지 않는다."},
                {"ko": "DIA", "keep": "DIA", "note": "유료·보너스 다이아 재화 이름. 번역하지 않는다."},
                {"ko": "VALUE", "keep": "VALUE", "note": "현금으로 바꾸지 않는 명예 재화. 번역하지 않는다."},
                {"ko": "거북", "en": "Turtle", "note": "가장 느린 티어 동물."},
                {"ko": "비글", "en": "Beagle", "note": "티어 동물."},
                {"ko": "늑대", "en": "Wolf", "note": "티어 동물."},
                {"ko": "얼룩말", "en": "Zebra", "note": "티어 동물."},
                {"ko": "치타", "en": "Cheetah", "note": "가장 빠른 티어 동물."},
                {"ko": "브론즈", "en": "Bronze", "note": "메달."},
                {"ko": "실버", "en": "Silver", "note": "메달."},
                {"ko": "골드", "en": "Gold", "note": "메달."},
                {"ko": "다이아", "en": "Diamond", "note": "메달. 재화 DIA와 문맥으로 구분한다."},
                {"ko": "마스터", "en": "Master", "note": "메달."},
                {"ko": "배틀런 패스", "en": "Battle Run pass", "note": "시즌 꾸미기 패스. 기록과 순위를 바꾸지 않는다."},
                {"ko": "크루", "en": "crew", "note": "같이 뛰는 모임."},
            ],
            "locales": LOCALES,
            "localeMapToApp": {
                "en": "en",
                "ja": "ja",
                "zh-TW": "zh",
                "es": "es",
                "pt-BR": "pt",
                "de": "de",
                "fr": "fr",
                "vi": "vi",
                "th": "th",
                "id": "id",
            },
            "fillRules": [
                "각 항목의 en, ja, zh-TW, es, pt-BR, de, fr, vi, th, id를 채운다. ko는 원문이다.",
                "placeholders의 format 토큰을 번역문에도 같은 철자로 남긴다. 순서는 바꿔도 된다.",
                "context의 길이 제한을 지킨다. 버튼은 한 줄이다.",
                "빈 칸이 하나라도 있으면 반영 스크립트가 거절한다.",
                "반영: python3 tool/l10n/apply_remaining_strings.py",
            ],
            "excluded": {
                "logs_and_debug": excluded["logs"],
                "admin_console_unique": excluded["admin_unique"],
                "already_in_11_locales": excluded["already_localized"],
                "korean_particles_only": excluded["particles"],
                "regexp_or_pattern": excluded["regexp"],
                "guide_fallback_already_in_guide_chrome": excluded[
                    "guide_fallback_already_localized"
                ],
                "criteria": (
                    "화면에 보이는 문구만 남겼다. debugPrint·print·log·kDebugMode 진단, "
                    "admin/ 관리자 콘솔, 주석, 이미 lib/l10n·wear_app l10n에 있는 같은 한국어, "
                    "워치 안내 시트의 한국어 폴백(GuideChrome이 11개 언어로 대신 보여 줌), "
                    "조사 한 글자, 정규식 문자 클래스는 뺐다. 서버 파이썬과 테스트 코드는 화면 원문이 아니라서 넣지 않았다."
                ),
            },
            "counts": {
                "strings": len(strings),
                "byScreen": dict(sorted(by_screen.items(), key=lambda kv: (-kv[1], kv[0]))),
            },
        },
        "strings": strings,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"strings": len(strings), "excluded": excluded, "screens": len(by_screen)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
