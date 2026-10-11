"""Builds assets/faq/snail_bot_faq.json from docs/snail-bot-faq.csv.

Left out on purpose:
- rows marked [미정]: the answer is not decided yet (spec: leave out).
- rows that need personal values ({...}): they wait for the server lookup.
The app name is written 쉐어런 in answers (docs/naming-rules.md).
Run:  python3 tool/build_snail_faq.py
"""
import csv
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
rows = list(csv.DictReader(open(ROOT / "docs/snail-bot-faq.csv", encoding="utf-8-sig")))
out, skipped_undecided, skipped_personal = [], 0, 0
for row in rows:
    if row["미정"].strip():
        skipped_undecided += 1
        continue
    if row["개인값 필요 여부"].strip() != "없음":
        skipped_personal += 1
        continue
    answer = row["답변"].replace("쉐어 런", "쉐어런").strip()
    aliases = [a.strip() for a in row["비슷한 표현"].split("|") if a.strip()]
    question = row["대표 질문"].strip()
    if row["id"].startswith("SYS-"):
        # System lines have a description instead of a question; only their
        # example inputs are used for matching.
        question = ""
        if row["id"] == "SYS-FALLBACK":
            aliases = []
    out.append(
        {
            "id": row["id"],
            "category": row["category"],
            "question": question,
            "aliases": aliases,
            "answer": answer,
        }
    )
dest = ROOT / "assets/faq/snail_bot_faq.json"
dest.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
print(f"{len(out)} answers written, {skipped_undecided} undecided and {skipped_personal} personal-value rows left out")
