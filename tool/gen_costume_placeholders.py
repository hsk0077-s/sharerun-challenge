#!/usr/bin/env python3
"""의상 스킨 1차의 자리표시 그림을 만든다. 실제 그림이 들어오면 같은 파일 이름으로 덮어쓴다.

실행: python3 tool/gen_costume_placeholders.py  (Pillow 필요)

* 동물 운동복: assets/images/accessories/outfit/<파일>-<칸>-<동물>.webp  (1024x1024, 투명 바탕 + 반투명 회색 상자와 상품 코드)
* 캐릭터 의상: assets/images/characters/costume/<파일>-<male|female>.webp (1024x1024, 회색 바탕 + 큰 글자)
화면에서 한눈에 자리표시로 보이도록 "PLACEHOLDER" 글자와 코드를 넣는다. 목록은 소품 카탈로그(앱)에서 읽는다.
"""
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "lib/features/accessories/accessory_catalog.dart"
OUTFIT_DIR = ROOT / "assets/images/accessories/outfit"
COSTUME_DIR = ROOT / "assets/images/characters/costume"
ANIMALS = ["turtle", "beagle", "wolf", "zebra", "cheetah"]
SIZE = 1024
# 칸별 상자 위치(1024 판 기준, 대략). 실제 그림에서는 몸에 맞게 다시 그려진다.
BOX = {
    "top": (290, 420, 734, 650),
    "bottom": (320, 650, 704, 800),
    "feet": (320, 800, 704, 920),
    "head": (300, 70, 724, 240),
}
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"


def font(size):
    try:
        return ImageFont.truetype(FONT, size)
    except OSError:
        return ImageFont.load_default()


def items():
    body = CATALOG.read_text(encoding="utf-8")
    body = body[body.index("const accessoryCatalog"):]
    for block in re.findall(r"Accessory\((.*?)\n  \),", body, re.S):
        def f(name):
            m = re.search(rf"\b{name}:\s*([^,\n]+)", block)
            return m.group(1).strip() if m else None

        def lst(name):
            m = re.search(rf"\b{name}:\s*\[([^\]]*)\]", block)
            return [x.strip().strip("'").split(".")[-1] for x in m.group(1).split(",") if x.strip()] if m else []

        yield {
            "id": f("id").strip("'"),
            "file": f("file").strip("'"),
            "slot": f("slot").split(".")[1],
            "gender": f("gender").split(".")[1] if f("gender") else "unisex",
            "bundle": lst("bundle"),
            "parts": lst("parts"),
        }


def centered(draw, box, text, size, fill):
    fnt = font(size)
    l, t, r, b = draw.textbbox((0, 0), text, font=fnt)
    x = box[0] + (box[2] - box[0] - (r - l)) / 2 - l
    y = box[1] + (box[3] - box[1] - (b - t)) / 2 - t
    draw.text((x, y), text, font=fnt, fill=fill)


def animal_part(code, part, animal, path):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    box = BOX[part]
    draw.rounded_rectangle(box, radius=36, fill=(150, 150, 150, 170), outline=(60, 60, 60, 230), width=8)
    mid = (box[1] + box[3]) // 2
    centered(draw, (box[0], box[1], box[2], mid), code, 70, (255, 255, 255, 255))
    centered(draw, (box[0], mid - 10, box[2], box[3]), f"{part} / {animal}", 44, (30, 30, 30, 255))
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "WEBP", quality=70, method=6)


def character(code, file, gender, path):
    img = Image.new("RGB", (SIZE, SIZE), (170, 170, 170))
    draw = ImageDraw.Draw(img)
    for x in range(-SIZE, SIZE * 2, 90):  # 사선 줄무늬
        draw.line([(x, 0), (x + SIZE, SIZE)], fill=(150, 150, 150), width=30)
    draw.rounded_rectangle((100, 280, 924, 760), radius=60, fill=(235, 235, 235), outline=(40, 40, 40), width=10)
    centered(draw, (100, 300, 924, 480), code, 190, (30, 30, 30))
    centered(draw, (100, 480, 924, 580), f"{file} / {gender}", 80, (60, 60, 60))
    centered(draw, (100, 600, 924, 720), "PLACEHOLDER", 90, (200, 40, 40))
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "WEBP", quality=70, method=6)


def main():
    made_animal = made_character = 0
    seen = set()
    for it in items():
        if it["slot"] == "outfit" and it["parts"] and not it["bundle"]:
            for part in it["parts"]:
                for animal in ANIMALS:
                    animal_part(it["id"], part, animal, OUTFIT_DIR / f"{it['file']}-{part}-{animal}.webp")
                    made_animal += 1
        elif it["slot"] == "costume" and not it["bundle"]:
            genders = ["male", "female"] if it["gender"] == "unisex" else [it["gender"]]
            for g in genders:
                if (it["file"], g) in seen:
                    continue
                seen.add((it["file"], g))
                character(it["id"], it["file"], g, COSTUME_DIR / f"{it['file']}-{g}.webp")
                made_character += 1
    print(f"animal parts: {made_animal}, character pictures: {made_character}")


if __name__ == "__main__":
    main()
