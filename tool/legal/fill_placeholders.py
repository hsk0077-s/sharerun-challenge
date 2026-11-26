#!/usr/bin/env python3
"""Fill the {{...}} placeholders of the legal pages in one go.

  python3 tool/legal/fill_placeholders.py --list
  python3 tool/legal/fill_placeholders.py 시행일=2026-12-10 최종수정일=2026-12-10 대표자명=홍길동 ...
  python3 tool/legal/build.py --check-filled     # fails while a placeholder is left

It replaces {{KEY}} in site/*.html and in tool/legal/src + tool/legal/tr, so the pages
and the files they are generated from stay the same. Dates use the same ISO form in
every language page (2026-12-10); the Korean pages show the same text.
"""
import re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FILES = [*(ROOT / "site").glob("*.html"), *(ROOT / "tool/legal/src").glob("*.json"), *(ROOT / "tool/legal/tr").glob("*.json")]
PH = re.compile(r"\{\{(?!s\d{3}\}\})([^{}]+)\}\}")


def found():
    seen = {}
    for f in FILES:
        for key in PH.findall(f.read_bytes().decode("utf-8")):
            seen.setdefault(key, set()).add(f.name)
    return seen


def main(argv):
    if not argv or argv == ["--list"]:
        for key, files in sorted(found().items()):
            print(f"{{{{{key}}}}}  ({len(files)} files)")
        return 0
    values = {}
    for item in argv:
        key, sep, value = item.partition("=")
        if not sep or not value.strip():
            print(f"bad argument: {item!r} (use KEY=VALUE)")
            return 2
        values[key] = value.strip()
    unknown = [k for k in values if k not in found()]
    if unknown:
        print("no such placeholder:", ", ".join(unknown))
        return 2
    for f in FILES:
        text = f.read_bytes().decode("utf-8")
        new = text
        for key, value in values.items():
            safe = value.replace("&", "&amp;").replace("<", "&lt;")
            if f.suffix == ".json":
                safe = safe.replace("\\", "\\\\").replace('"', '\\"')
            new = new.replace("{{" + key + "}}", safe)
        if new != text:
            f.write_bytes(new.encode("utf-8"))
    left = found()
    print("filled:", ", ".join(values))
    print("still empty:", ", ".join(sorted(left)) or "none")
    return 0


sys.exit(main(sys.argv[1:]))
