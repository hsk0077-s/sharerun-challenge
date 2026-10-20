#!/usr/bin/env python3
"""앱의 소품 목록(lib/features/accessories/accessory_catalog.dart)을 서버용 표로 옮긴다.

실행: python3 tool/gen_accessory_catalog.py  → backend/jena_ai/app/services/accessory_catalog.py
서버 테스트가 두 파일이 어긋났는지 매번 확인한다.
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "lib/features/accessories/accessory_catalog.dart"
OUT = ROOT / "backend/jena_ai/app/services/accessory_catalog.py"


def parse(text: str) -> list[dict]:
    body = text[text.index("const accessoryCatalog"):]
    items = []
    for block in re.findall(r"Accessory\((.*?)\n  \),", body, re.S):
        def field(name):
            m = re.search(rf"\b{name}:\s*([^,\n]+)", block)
            return m.group(1).strip() if m else None

        items.append(
            {
                "id": field("id").strip("'"),
                "slot": field("slot").split(".")[1],
                "rarity": field("rarity").split(".")[1],
                "currency": field("currency").split(".")[1],
                "price": int(field("price")) if field("price") else None,
                "tier_lock": field("tierLock").split(".")[1] if field("tierLock") else None,
                "ready": field("ready") != "false",
                "provisional": field("provisional") == "true",
            }
        )
    return items


def main() -> None:
    items = parse(SRC.read_text(encoding="utf-8"))
    rows = ",\n".join(f"    {item!r}" for item in items)
    OUT.write_text(
        '"""소품·스킨 목록. tool/gen_accessory_catalog.py 로 앱 목록에서 만든 파일이다. 손으로 고치지 않는다."""\n\n'
        f"ACCESSORIES: tuple[dict, ...] = (\n{rows},\n)\n",
        encoding="utf-8",
    )
    print(f"{len(items)} items -> {OUT}")


if __name__ == "__main__":
    main()
