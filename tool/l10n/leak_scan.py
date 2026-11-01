import re,sys,pathlib,collections,json,os
ROOT=pathlib.Path(__file__).resolve().parents[2]
os.chdir(ROOT)
H=re.compile(r'[가-힣]')
LIT=re.compile(r"""(r?)('''|\"\"\"|'|")((?:\\.|(?!\2).)*?)\2""",re.S)
SKIP_FILES=('lib/l10n/',)
# statement-level: find literal; look back to statement start for translation wrappers
WRAP=re.compile(r'(RemainingSurface\.(tr|trNow)|\.tr\(|trNow\(|_tr\(|\btr\()')
res=collections.defaultdict(list)
CALLEE=re.compile(r'(RemainingSurface\s*\.\s*(?:tr|trNow)|\btrNow|\.tr|\b_tr|\btr)\s*$')
def enclosed_in_tr(txt,pos):
    """True when the literal at pos sits inside the argument list of a tr()/trNow() call."""
    depth=0;i=pos-1
    while i>=0:
        c=txt[i]
        if c in ')]}': depth+=1
        elif c in '([{':
            if depth==0:
                if c=='(' and CALLEE.search(txt[max(0,i-40):i]): return True
            else: depth-=1
        elif c==';' and depth==0: return False
        i-=1
    return False
for p in sorted(pathlib.Path('lib').rglob('*.dart')):
    s=str(p)
    if any(k in s for k in SKIP_FILES): continue
    src=p.read_text(encoding='utf-8')
    # strip comments (keep strings): crude line-based
    lines=src.split('\n')
    clean=[]
    for l in lines:
        # remove // comments not inside quotes
        out='';q=None;i=0
        while i<len(l):
            c=l[i]
            if q:
                out+=c
                if c=='\\': out+=l[i+1:i+2]; i+=1
                elif c==q: q=None
            else:
                if c in '\'"': q=c; out+=c
                elif l[i:i+2]=='//': break
                else: out+=c
            i+=1
        clean.append(out)
    txt='\n'.join(clean)
    for m in LIT.finditer(txt):
        body=m.group(3)
        if not H.search(body): continue
        start=m.start()
        # statement start = last ';' or '{' or '}' before
        a=max(txt.rfind(';',0,start),txt.rfind('{',0,start),txt.rfind('}',0,start))
        ctx=txt[a+1:start]
        ln=txt.count('\n',0,start)+1
        wrapped=enclosed_in_tr(txt,start)
        res[s].append((ln,wrapped,body[:70].replace('\n',' '),ctx.strip()[-60:].replace('\n',' ')))
BASE = ROOT / "docs/l10n/hangul-baseline.json"
counts = {f: len([u for u in items if not u[1]]) for f, items in res.items()}
counts = {f: n for f, n in counts.items() if n}
if "--update" in sys.argv:
    BASE.write_text(json.dumps(dict(sorted(counts.items())), ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print("baseline written:", sum(counts.values()), "literals in", len(counts), "files")
elif "--check" in sys.argv:
    base = json.loads(BASE.read_text(encoding="utf-8"))
    bad = [(f, n, base.get(f, 0)) for f, n in counts.items() if n > base.get(f, 0)]
    for f, n, b in bad:
        print(f"{f}: {n} Korean literals not wrapped in RemainingSurface.tr/trNow (baseline {b})")
        for ln, _w, body, _c in [u for u in res[f] if not u[1]][b:]:
            print(f"   line {ln}: {body}")
    if bad:
        print("\nWrap new user-visible Korean with RemainingSurface.tr/trNow and add translations "
              "(tool/l10n/wire.py), or run `python3 tool/l10n/leak_scan.py --update` if it is intentionally Korean-only.")
        sys.exit(1)
    print("ok: no new untranslated Korean (", sum(counts.values()), "known )")
else:
    tot = sum(counts.values())
    print("files with unwrapped hangul literals:", len(counts), "literals:", tot)
    for f, n in sorted(counts.items(), key=lambda x: -x[1])[:60]: print(n, f)
    if len(sys.argv) > 1 and not sys.argv[1].startswith("--"):
        json.dump({f: [u for u in v if not u[1]] for f, v in res.items() if counts.get(f)}, open(sys.argv[1], "w", encoding="utf-8"), ensure_ascii=False, indent=0)
