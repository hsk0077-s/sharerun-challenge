#!/usr/bin/env python3
"""Brand mark -> every app icon and launch image.

Source is the heart + pulse + runner mark (design team splash set). Run from
the repo root: python3 tool/gen_brand_assets.py <path to ios-launch-logo.svg>
Needs cairosvg and Pillow. The icon variant draws the runner and pulse a bit
heavier so they stay readable at 48px.
"""
import io
import re
import sys

import cairosvg
from PIL import Image

BG = (0x07, 0x0B, 0x09)
SRC = open(sys.argv[1], encoding="utf-8").read()


def heavy(svg: str) -> str:
    svg = svg.replace('stroke-width="46"', 'stroke-width="56"')
    svg = svg.replace('r="30"', 'r="36"')
    return svg


def render(svg: str, px: int) -> Image.Image:
    data = cairosvg.svg2png(bytestring=svg.encode(), output_width=px, output_height=px)
    return Image.open(io.BytesIO(data)).convert("RGBA")


def glyph(svg: str, px: int) -> Image.Image:
    """Mark cropped to its box (x 150..874, y 195..830) and scaled to ``px`` wide."""
    big = render(svg, 2048)
    box = tuple(int(v * 2) for v in (150, 195, 874, 830))
    crop = big.crop(box)
    h = round(crop.height * px / crop.width)
    return crop.resize((px, h), Image.LANCZOS)


def canvas(size: int, width_ratio: float, svg: str, bg=BG, alpha=False) -> Image.Image:
    img = Image.new("RGBA", (size, size), bg + (255,) if bg else (0, 0, 0, 0))
    g = glyph(svg, round(size * width_ratio))
    img.alpha_composite(g, ((size - g.width) // 2, (size - g.height) // 2))
    return img if alpha else img.convert("RGB")


ICON = heavy(SRC)
RES = "android/app/src/main/res"

# Android legacy launcher and adaptive foreground
for folder, legacy, fore in (
    ("mdpi", 48, 108),
    ("hdpi", 72, 162),
    ("xhdpi", 96, 216),
    ("xxhdpi", 144, 324),
    ("xxxhdpi", 192, 432),
):
    canvas(legacy, 0.72, ICON).save(f"{RES}/mipmap-{folder}/ic_launcher.png")
    canvas(fore, 0.56, ICON, bg=None, alpha=True).save(
        f"{RES}/mipmap-{folder}/ic_launcher_foreground.png"
    )

# Android 12 splash icon and pre-12 splash logo (transparent, on splash color)
for folder, icon, logo in (
    ("mdpi", 240, 200),
    ("hdpi", 360, 300),
    ("xhdpi", 480, 400),
    ("xxhdpi", 720, 600),
    ("xxxhdpi", 960, 800),
):
    canvas(icon, 0.62, SRC, bg=None, alpha=True).save(f"{RES}/drawable-{folder}/splash_icon.png")
    canvas(logo, 0.80, SRC, bg=None, alpha=True).save(f"{RES}/drawable-{folder}/splash_logo.png")

# iOS app icons: every size named in Contents.json
icon_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
contents = open(f"{icon_dir}/Contents.json", encoding="utf-8").read()
for name in sorted(set(re.findall(r'"filename"\s*:\s*"([^"]+)"', contents))):
    px = int(re.search(r"(\d+(?:\.\d+)?)x\d+(?:\.\d+)?@(\d)x", name).group(1).split(".")[0]) if False else None
    m = re.search(r"Icon-App-([\d.]+)x[\d.]+@(\d)x", name)
    px = round(float(m.group(1)) * int(m.group(2)))
    canvas(px, 0.72, ICON).save(f"{icon_dir}/{name}")

# iOS launch image (transparent logo; the storyboard supplies the background)
for scale, px in ((1, 200), (2, 400), (3, 600)):
    suffix = "" if scale == 1 else f"@{scale}x"
    canvas(px, 0.80, SRC, bg=None, alpha=True).save(
        f"ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png"
    )

# In-app logo (login header): mark on the night background
canvas(1024, 0.72, SRC).save("assets/images/sharerun_logo.png")
print("done")
