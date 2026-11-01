#!/usr/bin/env python3
"""Fix `String get x => <non-string>;` that fixconst produced; infer the type from the value."""
import re, subprocess, sys
from pathlib import Path
files = subprocess.run(["git","diff","--name-only"],capture_output=True,text=True).stdout.split()
pat = re.compile(r"((?:static )?)String get (\w+) => (const\s+)?([^;]*?);", re.S)
fixed = 0
def typ(rhs):
    r = rhs.lstrip()
    if r.startswith(("'", '"', "RemainingSurface", "_l.", "_shop.")): return "String"
    m = re.match(r"<\s*([^<>]+?)\s*,\s*([^<>]*(?:<[^<>]*>)?[^<>]*?)\s*>\s*\{", r)
    if m: return f"Map<{m.group(1)}, {m.group(2)}>"
    m = re.match(r"<\s*([^<>]*(?:<[^<>]*>)?[^<>]*?)\s*>\s*\[", r)
    if m: return f"List<{m.group(1)}>"
    m = re.match(r"<\s*([^<>]*(?:<[^<>]*>)?[^<>]*?)\s*>\s*\{", r)
    if m: return f"Set<{m.group(1)}>"
    m = re.match(r"([A-Z]\w*)(?:\.\w+)?\s*\(", r)
    if m: return m.group(1)
    if r.startswith("["): return "List<String>" if re.match(r"\[\s*['\"]", r) else None
    if r.startswith("{"): return None
    return None
for f in files:
    if not f.endswith(".dart"): continue
    p = Path(f); s = p.read_text(encoding="utf-8"); o = s
    # getters that already existed on main keep their type: only repair ones this run created
    base = subprocess.run(["git","show",f"origin/main:{f}"],capture_output=True,text=True).stdout
    existing = set(re.findall(r"String get (\w+)\s*=>", base))
    def rep(m):
        global fixed
        if m.group(2) in existing: return m.group(0)
        rhs = m.group(4)
        t = typ(rhs)
        if t == "String": return m.group(0)
        fixed += 1
        c = m.group(3) or ""
        return f"{m.group(1)}{t + ' ' if t else ''}get {m.group(2)} => {c}{rhs};"
    s = pat.sub(rep, s)
    if s != o: p.write_text(s, encoding="utf-8")
print("repaired", fixed)
