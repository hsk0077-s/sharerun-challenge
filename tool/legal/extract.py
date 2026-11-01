#!/usr/bin/env python3
"""Split site/{terms,privacy,account-deletion}.html into numbered segments.

Writes tool/legal/src/<doc>.json = {"template": "...{{s001}}...", "segments": {"s001": "<ko inner html>"}}
Translations live in tool/legal/tr/<doc>.<lang>.json ({"s001": "..."}), rendered by build.py.
"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
TAGS = ("title", "h1", "h2", "h3", "p", "li", "th", "td")
def split(html):
    segs = {}
    n = [0]
    def rep(m):
        tag, attrs, inner = m.group(1), m.group(2) or "", m.group(3)
        if not re.search(r"[가-힣]", inner):
            return m.group(0)
        n[0] += 1
        sid = f"s{n[0]:03d}"
        segs[sid] = inner.strip()
        return f"<{tag}{attrs}>{{{{{sid}}}}}</{tag}>"
    pat = re.compile(r"<(" + "|".join(TAGS) + r")(\s[^>]*)?>(.*?)</\1>", re.S)
    # li/td may contain nested tags but not nested same tags
    out = pat.sub(rep, html)
    return out, segs
for doc in ("terms", "privacy", "account-deletion"):
    html = (ROOT / "site" / f"{doc}.html").read_text(encoding="utf-8")
    tpl, segs = split(html)
    left = re.findall(r"[가-힣]+", re.sub(r"\{\{s\d+\}\}", "", tpl))
    d = ROOT / "tool/legal/src"; d.mkdir(parents=True, exist_ok=True)
    (d / f"{doc}.json").write_text(json.dumps({"template": tpl, "segments": segs}, ensure_ascii=False, indent=1), encoding="utf-8")
    print(doc, len(segs), "segments", sum(len(v) for v in segs.values()), "chars; hangul left in template:", left[:5])
