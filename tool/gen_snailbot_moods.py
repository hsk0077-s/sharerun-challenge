#!/usr/bin/env python3
"""달팽이봇 표정 4장을 워킹 챌린지의 웃는 달팽이로 만든다.

기본·듣는 중·기쁨은 같은 웃는 달팽이에 표시만 다르게 얹고(소리 물결, 반짝임),
실망은 한숨 쉬는 달팽이 그림을 쓴다. 모두 투명 바탕, 오른쪽을 본다.
실행: python3 tool/gen_snailbot_moods.py   (저장소 맨 위에서)
"""
import math
from PIL import Image, ImageDraw

S = 4  # 안티앨리어싱용 배율
SIZE = 512
LIME = (212, 255, 74, 255)
GOLD = (255, 207, 74, 255)
PINK = (255, 134, 160, 255)


def load(name: str) -> Image.Image:
    img = Image.open(f"assets/images/characters/{name}.png").convert("RGBA")
    box = img.getbbox()
    img = img.crop(box)
    scale = (SIZE * 0.78) / max(img.size)
    return img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)


def stage(snail: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 0))
    x = (SIZE - snail.width) // 2
    y = SIZE - snail.height - 14
    canvas.alpha_composite(snail, (x, y))
    return canvas


def overlay() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    layer = Image.new("RGBA", (SIZE * S, SIZE * S), (0, 0, 0, 0))
    return layer, ImageDraw.Draw(layer)


def finish(base: Image.Image, layer: Image.Image) -> Image.Image:
    layer = layer.resize((SIZE, SIZE), Image.LANCZOS)
    base.alpha_composite(layer)
    return base


def star(draw, cx, cy, r, color):
    pts = []
    for i in range(8):
        ang = math.pi / 4 * i - math.pi / 2
        rad = r if i % 2 == 0 else r * 0.28
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    draw.polygon(pts, fill=color)


def heart(draw, cx, cy, r, color):
    draw.ellipse([cx - r, cy - r, cx, cy], fill=color)
    draw.ellipse([cx, cy - r, cx + r, cy], fill=color)
    draw.polygon([(cx - r, cy - r * 0.35), (cx + r, cy - r * 0.35), (cx, cy + r * 1.05)], fill=color)


def listening(snail: Image.Image) -> Image.Image:
    base = stage(snail)
    layer, d = overlay()
    # 얼굴 오른쪽에서 퍼지는 소리 물결 세 겹
    cx, cy = (SIZE * 0.66) * S, (SIZE * 0.40) * S
    for k, r in enumerate((80, 110, 140)):
        w = (13 - k * 2) * S
        box = [cx - r * S, cy - r * S, cx + r * S, cy + r * S]
        d.arc(box, -45, 45, fill=LIME, width=w)
    return finish(base, layer)


def joy(snail: Image.Image) -> Image.Image:
    base = stage(snail)
    layer, d = overlay()
    star(d, SIZE * 0.86 * S, SIZE * 0.22 * S, 52 * S, GOLD)
    star(d, SIZE * 0.12 * S, SIZE * 0.30 * S, 38 * S, LIME)
    star(d, SIZE * 0.93 * S, SIZE * 0.52 * S, 26 * S, LIME)
    heart(d, SIZE * 0.08 * S, SIZE * 0.58 * S, 22 * S, PINK)
    return finish(base, layer)


def main() -> None:
    smiling = load("chibi_snail_smiling")
    sad = load("chibi_snail_disappointed")
    out = {
        "face_smiling": stage(smiling),
        "face_listening": listening(smiling),
        "face_joy": joy(smiling),
        "face_disappointed": stage(sad),
    }
    for name, img in out.items():
        img.save(f"assets/images/snailbot/{name}.png")
    print("done")


if __name__ == "__main__":
    main()
