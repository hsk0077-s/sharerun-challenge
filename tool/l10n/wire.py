#!/usr/bin/env python3
"""Wire hard-coded Korean in lib/ to RemainingSurface and register its translations.

Spec = JSON list of items (see docs/l10n/README or the examples used in PRs):
  {"file": "lib/x.dart", "old": "'거북이'", "key": "tier.turtle", "ko": "거북이",
   "ctx": "티어 이름", "tr": {"en": ..., "ja": ..., "zh-TW": ..., "es": ..., "pt-BR": ...,
   "de": ..., "fr": ..., "vi": ..., "th": ..., "id": ...}}
Optional: "new" (full replacement source, for args), "reuse": existing key (no new entry),
"member": "NAME" (turn `static const NAME = EXPR;` into a getter), "all": false,
"ph": ["name"].
  python3 tool/l10n/wire.py spec.json
"""
import json, os, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
STR = ROOT / "docs/l10n/remaining-ko-strings.json"
LANGS = ["en", "ja", "zh-TW", "es", "pt-BR", "de", "fr", "vi", "th", "id"]
H = re.compile("[가-힣]")

def ensure_import(src, path):
    rel = os.path.relpath(ROOT / "lib/l10n/remaining_surface.dart", (ROOT / path).parent)
    if "remaining_surface.dart" in src:
        return src
    line = f"import '{rel}';\n"
    imps = list(re.finditer(r"^import .*;\n", src, re.M))
    if imps:
        i = imps[-1].end()
        return src[:i] + line + src[i:]
    return line + src

def main(specs):
    data = json.loads(STR.read_text(encoding="utf-8"))
    have = {e["key"] for e in data["strings"]}
    files = {}
    problems = []
    for s in specs:
        path = s["file"]
        src = files.get(path) or (ROOT / path).read_text(encoding="utf-8")
        key = s.get("reuse") or s["key"]
        if "member" in s:
            m = re.search(r"static const (?:String )?" + re.escape(s["member"]) + r"\s*=\s*", src)
            if not m:
                problems.append(f"no member {s['member']} in {path}"); continue
            end = src.index(";", m.end())
            rhs = src[m.end():end]
            new = f"static String get {s['member']} => RemainingSurface.trNow('{key}', {rhs.strip()})"
            src = src[:m.start()] + new + src[end:]
        else:
            old = s["old"]
            n = src.count(old)
            if n == 0:
                problems.append(f"missing {old[:40]!r} in {path}"); continue
            if n > 1 and s.get("all", True) is False:
                problems.append(f"ambiguous {old[:40]!r} in {path}"); continue
            new = s.get("new") or f"RemainingSurface.trNow('{key}', {old})"
            src = src.replace(old, new)
        files[path] = ensure_import(src, path)
        if not s.get("reuse") and key not in have:
            tr = s["tr"]
            miss = [l for l in LANGS if not tr.get(l)]
            if miss: problems.append(f"{key}: missing {miss}"); continue
            bad = [l for l in LANGS if H.search(tr[l])]
            if bad: problems.append(f"{key}: Hangul in {bad}"); continue
            entry = {"key": key, "ko": s["ko"], "file": path, "screen": s.get("screen", key.split(".")[0]),
                     "context": s.get("ctx", ""), "placeholders": s.get("ph", [])}
            entry.update({l: tr[l] for l in LANGS}); entry["native_review"] = "pending"
            data["strings"].append(entry); have.add(key)
    if problems:
        print("\n".join(problems)); sys.exit(1)
    for p, src in files.items():
        (ROOT / p).write_text(src, encoding="utf-8")
    STR.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"wired {len(specs)} items in {len(files)} files")

if __name__ == "__main__":
    specs = []
    for a in sys.argv[1:]:
        specs += json.loads(Path(a).read_text(encoding="utf-8"))
    main(specs)
