#!/usr/bin/env python3
"""Render site/<doc>.<lang>.html from tool/legal/src + tool/legal/tr.

  python3 tool/legal/build.py            # build every doc/lang that has translations
  python3 tool/legal/build.py --check    # fail when a segment is missing, has Hangul, or numbers/links differ
The Korean page (site/<doc>.html) is the authoritative text and is never rewritten.
"""
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
SRC, TR, SITE = ROOT/"tool/legal/src", ROOT/"tool/legal/tr", ROOT/"site"
DOCS = ("terms", "privacy", "account-deletion")
LANGS = {  # app languageCode -> (html lang, native name, convenience-translation notice)
 "en": ("en", "English", "This is a convenience translation of the Korean original. If the two differ, the Korean original prevails."),
 "ja": ("ja", "日本語", "これは韓国語の原文を参考のために翻訳したものです。内容が異なる場合は韓国語の原文が優先されます。"),
 "zh": ("zh-Hant", "繁體中文", "本文為韓文原文的參考翻譯。如兩者內容有差異，以韓文原文為準。"),
 "es": ("es", "Español", "Esta es una traducción de cortesía del original en coreano. Si hay diferencias, prevalece el original en coreano."),
 "pt": ("pt-BR", "Português", "Esta é uma tradução de cortesia do original em coreano. Em caso de divergência, prevalece o original em coreano."),
 "de": ("de", "Deutsch", "Dies ist eine Übersetzung zur Orientierung. Bei Abweichungen gilt das koreanische Original."),
 "fr": ("fr", "Français", "Ceci est une traduction de courtoisie de l'original coréen. En cas de différence, l'original coréen prévaut."),
 "vi": ("vi", "Tiếng Việt", "Đây là bản dịch tham khảo của bản gốc tiếng Hàn. Nếu có khác biệt, bản gốc tiếng Hàn được ưu tiên."),
 "th": ("th", "ไทย", "นี่คือคำแปลเพื่อใช้อ้างอิงจากต้นฉบับภาษาเกาหลี หากมีความแตกต่าง ให้ถือตามต้นฉบับภาษาเกาหลี"),
 "id": ("id", "Bahasa Indonesia", "Ini adalah terjemahan sebagai referensi dari naskah asli berbahasa Korea. Jika ada perbedaan, naskah asli berbahasa Korea yang berlaku."),
}
H = re.compile("[가-힣]")
def sig(s):  # things that must survive translation untouched
    s = s.replace("제3자", "")
    toks = re.findall(r"href=\"[^\"]+\"|\d[\d,\.]*|src791004@gmail\.com|SHARE|DIA|VALUE|Health Connect", s)
    toks = [t.rstrip(",.") if t[0].isdigit() else t for t in toks]
    return sorted(t for t in toks if not (t[0].isdigit() and len(t) == 1))  # one digit may become a word
def page(doc, lang, check):
    src = json.loads((SRC/f"{doc}.json").read_text(encoding="utf-8"))
    f = TR/f"{doc}.{lang}.json"
    if not f.exists(): return None
    tr = json.loads(f.read_text(encoding="utf-8"))
    errs = []
    html = src["template"]
    for sid, ko in src["segments"].items():
        t = tr.get(sid)
        if not t: errs.append(f"{doc}.{lang} missing {sid}"); continue
        if H.search(t.replace("하상기","")): errs.append(f"{doc}.{lang} {sid} has Hangul")
        a = [x for x in sig(ko) if not x.startswith("href")]; b = [x for x in sig(t) if not x.startswith("href")]
        if [x for x in a if x not in b]: errs.append(f"{doc}.{lang} {sid} lost {[x for x in a if x not in b]}")
        if sorted(re.findall(r"href=\"[^\"]+\"", ko)) != sorted(re.findall(r"href=\"[^\"]+\"", t)):
            errs.append(f"{doc}.{lang} {sid} link changed")
        html = html.replace("{{"+sid+"}}", t)
    html = re.sub(r'href="(terms|privacy|account-deletion)\.html"', lambda m: f'href="{m.group(1)}.{lang}.html"', html)
    hl, _, note = LANGS[lang]
    html = html.replace('<html lang="ko">', f'<html lang="{hl}">')
    nav = " · ".join(('<a href="%s.html">한국어</a>' % doc) if k == "ko" else
                     (f'<a href="{doc}.{k}.html">{v[1]}</a>' if k != lang else f"<strong>{v[1]}</strong>")
                     for k, v in [("ko", None)] + list(LANGS.items()))
    html = html.replace("<main>", f'<main>\n  <p class="draft">{note}</p>\n  <nav class="muted">{nav}</nav>', 1)
    return html, errs
def main():
    check = "--check" in sys.argv
    bad = []
    for doc in DOCS:
        for lang in LANGS:
            r = page(doc, lang, check)
            if r is None: continue
            html, errs = r
            bad += errs
            if not errs and not check: (SITE/f"{doc}.{lang}.html").write_text(html, encoding="utf-8")
    print("\n".join(bad) if bad else "ok"); sys.exit(1 if bad else 0)
main()
