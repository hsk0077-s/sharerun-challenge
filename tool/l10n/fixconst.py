#!/usr/bin/env python3
"""Remove `const` that became invalid after wiring Korean literals to RemainingSurface.

Runs `dart analyze --format=machine`, and for each const-related error strips the
nearest enclosing `const`. A `const` field/top-level declaration becomes a getter
(a `final` would freeze the first locale). Repeats until no such errors remain.
"""
import re, subprocess, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
CODES = {"CONST_WITH_NON_CONSTANT_ARGUMENT","NON_CONSTANT_LIST_ELEMENT","NON_CONSTANT_MAP_ELEMENT","NON_CONSTANT_MAP_KEY",
 "NON_CONSTANT_MAP_VALUE","NON_CONSTANT_SET_ELEMENT","INVALID_CONSTANT","CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE",
 "NON_CONSTANT_DEFAULT_VALUE","CONST_EVAL_METHOD_INVOCATION","CONST_EVAL_TYPE_BOOL","NON_CONSTANT_ANNOTATION_ARGUMENT",
 "CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER","NON_CONST_GENERATIVE_ENUM_CONSTRUCTOR","CONST_WITH_NON_CONST",
 "NON_CONSTANT_CASE_EXPRESSION","CONST_EVAL_THROWS_EXCEPTION","CONST_WITH_NON_TYPE","INVALID_CONSTANT"}

def balanced_end(src,i):
    """end index of the expression starting at i (after `const `): through first balanced group."""
    n=len(src); depth=0; q=None; j=i; seen=False
    while j<n:
        c=src[j]
        if q:
            if c=="\\": j+=2; continue
            if c==q: q=None
        elif c in "'\"": q=c
        elif c in "([{": depth+=1; seen=True
        elif c in ")]}":
            depth-=1
            if depth==0 and seen: return j+1
        elif c==";" and depth==0: return j
        elif c=="," and depth==0 and not seen: return j
        j+=1
    return n

def fix_one(path,line,col):
    p=ROOT/path if not Path(path).is_absolute() else Path(path)
    src=p.read_text(encoding="utf-8")
    off=sum(len(x)+1 for x in src.split("\n")[:line-1])+col-1
    for m in reversed(list(re.finditer(r"\bconst\b",src[:off+1]))):
        s=m.start(); e=m.end()
        rest=src[e:e+200]
        decl=re.match(r"\s+(?:[A-Za-z_<>?,\s.\[\]]+?\s+)?[A-Za-z_]\w*\s*=",rest)
        is_decl = bool(decl) and not re.match(r"\s*[A-Z]\w*\s*[(<.]",rest[:60]) or bool(re.match(r"\s+[A-Za-z_]\w*\s*=",rest))
        end = src.index(";",e) if is_decl else balanced_end(src,e)
        if end<off: continue
        line_start=src.rfind("\n",0,s)+1
        before=src[line_start:s]
        if is_decl:
            mm=re.match(r"\s+([^=;]*?)\s*=\s*",rest)
            head=mm.group(1).strip()
            parts=head.rsplit(None,1)
            name=parts[-1]; typ=parts[0] if len(parts)>1 else "String"
            rhs_start=e+mm.end()
            if re.search(r"\bstatic\s*$",before) or before.strip()=="" and re.match(r"\s*(abstract|final|class)",""):
                pass
            top=(before=="")
            stat=re.search(r"\bstatic\s*$",before)
            if top or stat:
                new=f"{typ} get {name} => "
                src=src[:s]+new+src[rhs_start:]
                p.write_text(src,encoding="utf-8"); return f"getter {name}"
            src=src[:s]+"final "+src[e:].lstrip() if False else src[:s]+"final"+src[e:]
            p.write_text(src,encoding="utf-8"); return "final"
        rest2=src[e:]
        ws=len(rest2)-len(rest2.lstrip())
        src=src[:s]+src[e+ws:] if before.endswith(" ") or True else src
        p.write_text(src,encoding="utf-8"); return "const removed"
    return None

def main():
    for rnd in range(60):
        r = subprocess.run(["dart","analyze","--format=machine","lib"],cwd=ROOT,capture_output=True,text=True)
        rows=[l.split("|") for l in (r.stdout+r.stderr).splitlines() if l.startswith("ERROR|")]
        rows=[x for x in rows if len(x)>=8 and (x[2] in CODES or "constant" in x[7].lower())]
        if not rows:
            print("const clean after",rnd,"rounds"); return
        perfile={}
        for x in rows: perfile.setdefault(x[3],[]).append((int(x[4]),int(x[5])))
        for f,locs in perfile.items():
            line,col=sorted(locs,reverse=True)[0]
            print(rnd,f,line,fix_one(f,line,col))
    print("giving up; const errors remain")

main()
