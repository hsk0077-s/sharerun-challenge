#!/usr/bin/env python3
"""홍보 카드 이미지를 만든다(링크 미리보기 / 인스타 스토리 / 인스타 피드).

사용법: python3 tool/gen_promo_cards.py <출력 폴더>
앱에 이미 있는 로고, 동물 본체, 마을 그림, Pretendard 글꼴만 쓴다.
스토어 주소가 정해지면 QR 칸에 넣는다(지금은 "프로필 링크에서 받기").
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), '..')
A = lambda *p: os.path.join(ROOT, 'assets', *p)
LIME = (212, 255, 74)
INK = (11, 15, 12)
WHITE = (245, 247, 242)


def font(weight, size):
    name = {'black': 'Pretendard-Black.otf', 'semi': 'Pretendard-SemiBold.otf', 'reg': 'Pretendard-Regular.otf'}[weight]
    return ImageFont.truetype(A('fonts', name), size)


def cover(img, w, h, bottom=True):
    """비율을 유지해 꽉 채우고, 세로가 남으면 아래쪽을 보여 준다."""
    s = max(w / img.width, h / img.height)
    img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    x = (img.width - w) // 2
    y = img.height - h if bottom else (img.height - h) // 2
    return img.crop((x, y, x + w, y + h))


def animal(name, height):
    im = Image.open(A('images', 'characters', f'tier_{name}.png')).convert('RGBA')
    im = im.crop(im.getbbox())
    return im.resize((round(im.width * height / im.height), height), Image.LANCZOS)


def rounded_logo(size):
    im = Image.open(A('images', 'sharerun_logo.png')).convert('RGB').resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), radius=size // 5, fill=255)
    out = Image.new('RGBA', (size, size))
    out.paste(im, (0, 0), mask)
    return out


def scrim(base, top_alpha, bottom_alpha, split=0.45):
    w, h = base.size
    g = Image.new('L', (1, h))
    for y in range(h):
        t = y / (h - 1)
        a = top_alpha + (bottom_alpha - top_alpha) * min(1, max(0, (t - (1 - split)) / split)) if t > 1 - split else top_alpha
        g.putpixel((0, y), int(a))
    layer = Image.new('RGBA', (w, h), (0, 0, 0, 255))
    layer.putalpha(g.resize((w, h)))
    return Image.alpha_composite(base.convert('RGBA'), layer)


def text_lines(d, xy, lines, fnt, fill, gap, anchor='la', shadow=True):
    x, y = xy
    for ln in lines:
        if shadow:
            d.text((x + 3, y + 4), ln, font=fnt, fill=(0, 0, 0, 150), anchor=anchor)
        d.text((x, y), ln, font=fnt, fill=fill, anchor=anchor)
        y += fnt.size + gap
    return y


def chips(d, x, y, labels, fnt, pad=(26, 14)):
    for label in labels:
        w = d.textlength(label, font=fnt)
        box = (x, y, x + w + pad[0] * 2, y + fnt.size + pad[1] * 2)
        d.rounded_rectangle(box, radius=(box[3] - box[1]) // 2, fill=(11, 15, 12, 200), outline=LIME, width=3)
        d.text((x + pad[0], y + pad[1] - 2), label, font=fnt, fill=LIME)
        x = box[2] + 16
    return x


def card(size, village, layout, out):
    w, h = size
    bg = Image.open(A('images', 'villages', f'village-{village}.jpg')).convert('RGB')
    base = cover(bg, w, h, bottom=layout != 'og')
    base = scrim(base, 150 if layout != 'og' else 120, 215)
    d = ImageDraw.Draw(base, 'RGBA')
    names = ['turtle', 'beagle', 'wolf', 'zebra', 'cheetah']
    pad = round(w * 0.075)

    if layout == 'story':          # 1080x1920
        base.alpha_composite(rounded_logo(150), (pad, 150))
        d.text((pad + 180, 190), '쉐어런', font=font('black', 64), fill=WHITE)
        d.text((pad + 182, 268), 'ShareRun', font=font('semi', 30), fill=(*LIME, 255))
        y = text_lines(d, (pad, 520), ['심장이 뛰는 한,', '나눔도 달린다'], font('black', 112), WHITE, 18)
        y = text_lines(d, (pad, y + 30), ['같이 달리고, SHARE를 모으고,', '기부로 이어가요'], font('semi', 46), (*WHITE, 235), 12)
        chips(d, pad, y + 36, ['챌린지', '크루', '기부'], font('black', 38))
        x = pad - 10
        for i, n in enumerate(names):
            a = animal(n, 250 if i != 1 else 300)
            base.alpha_composite(a, (x, 1500 - a.height + 30))
            x += a.width + 8
        d.rounded_rectangle((pad, 1640, w - pad, 1790), radius=75, fill=(*LIME, 255))
        d.text((w // 2, 1715), '프로필 링크에서 받기', font=font('black', 52), fill=INK, anchor='mm')
    elif layout == 'feed':         # 1080x1350
        base.alpha_composite(rounded_logo(120), (pad, 90))
        d.text((pad + 148, 112), '쉐어런', font=font('black', 52), fill=WHITE)
        d.text((pad + 150, 176), 'ShareRun', font=font('semi', 26), fill=(*LIME, 255))
        y = text_lines(d, (pad, 330), ['심장이 뛰는 한,', '나눔도 달린다'], font('black', 104), WHITE, 16)
        y = text_lines(d, (pad, y + 26), ['같이 달리고 SHARE를 모아', '기부로 이어가는 러닝 앱'], font('semi', 42), (*WHITE, 235), 10)
        chips(d, pad, y + 30, ['챌린지', '크루', '기부'], font('black', 34))
        x = pad - 10
        for i, n in enumerate(names):
            a = animal(n, 220 if i != 1 else 260)
            base.alpha_composite(a, (x, 1180 - a.height + 20))
            x += a.width + 8
        d.rounded_rectangle((pad, 1230, w - pad, 1310), radius=40, fill=(*LIME, 255))
        d.text((w // 2, 1270), '프로필 링크에서 받기', font=font('black', 40), fill=INK, anchor='mm')
    else:                          # og 1200x630
        base.alpha_composite(rounded_logo(110), (pad, 70))
        d.text((pad + 135, 82), '쉐어런', font=font('black', 48), fill=WHITE)
        d.text((pad + 137, 140), 'ShareRun', font=font('semi', 24), fill=(*LIME, 255))
        y = text_lines(d, (pad, 235), ['심장이 뛰는 한,', '나눔도 달린다'], font('black', 82), WHITE, 12)
        chips(d, pad, y + 22, ['챌린지', '크루', '기부'], font('black', 30), pad=(22, 11))
        x = w - pad - 5
        for i, n in enumerate(reversed(names)):
            a = animal(n, 190 if n != 'beagle' else 230)
            x -= a.width
            base.alpha_composite(a, (x, h - a.height - 20))
            x += 52
    base.convert('RGB').save(out, 'JPEG', quality=92)
    print('쓴 파일', out, base.size)


if __name__ == '__main__':
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    card((1200, 630), 'spring-park', 'og', os.path.join(out, 'promo-link-1200x630.jpg'))
    card((1080, 1920), 'night-city', 'story', os.path.join(out, 'promo-story-1080x1920.jpg'))
    card((1080, 1920), 'spring-park', 'story', os.path.join(out, 'promo-story-spring-1080x1920.jpg'))
    card((1080, 1350), 'seaside', 'feed', os.path.join(out, 'promo-feed-1080x1350.jpg'))
