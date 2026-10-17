#!/usr/bin/env python3
"""액세서리 v7 납품본(잘라낸 PNG + 오프셋)을 1024x1024 전체 캔버스로 되돌린다.

사용법:
  python3 tool/restore_accessories_v7.py compare <납품 폴더들의 부모> [동물...]
      기존 assets/images/accessories 와 픽셀 단위로 비교한다(쓰지 않음).
  python3 tool/restore_accessories_v7.py write <납품 폴더들의 부모> <동물...>
      지정한 동물의 레이어를 webp 로 assets 에 쓴다.

납품 폴더들은 p1, p2 ... 처럼 이름이 p숫자인 폴더이고, 각각 png-v7-cropped/ 와
png-v7-offsets.json 을 가진다.
"""
import json
import os
import re
import sys

from PIL import Image
import numpy as np

CANVAS = 1024
ASSETS = os.path.join(os.path.dirname(__file__), '..', 'assets', 'images', 'accessories')


def load_parts(root):
    offsets, files = {}, {}
    for name in sorted(os.listdir(root), key=lambda n: int(n[1:]) if re.fullmatch(r'p\d+', n) else 0):
        if not re.fullmatch(r'p\d+', name):
            continue
        part = os.path.join(root, name)
        with open(os.path.join(part, 'png-v7-offsets.json'), encoding='utf8') as f:
            offsets.update(json.load(f))
        base = os.path.join(part, 'png-v7-cropped')
        for r, _, fs in os.walk(base):
            for fn in fs:
                if fn.endswith('.png'):
                    files[os.path.relpath(os.path.join(r, fn), base)] = os.path.join(r, fn)
    missing = set(offsets) - set(files)
    extra = set(files) - set(offsets)
    if missing or extra:
        raise SystemExit(f'오프셋과 파일이 맞지 않음: 파일 없음 {sorted(missing)[:5]}, 오프셋 없음 {sorted(extra)[:5]}')
    return offsets, files


def restore(path, off):
    crop = Image.open(path).convert('RGBA')
    if crop.size != (off['w'], off['h']):
        raise SystemExit(f'{path}: 크기 {crop.size} != 오프셋 {(off["w"], off["h"])}')
    canvas = Image.new('RGBA', (CANVAS, CANVAS), (0, 0, 0, 0))
    canvas.paste(crop, (off['x'], off['y']))
    return canvas


def animal_of(rel):
    m = re.search(r'-(turtle|beagle|wolf|zebra|cheetah)\.png$', rel)
    return m.group(1) if m else None


def old_path(rel):
    return os.path.join(ASSETS, rel[:-4] + '.webp')


def compare(root, animals):
    offsets, files = load_parts(root)
    rows = []
    for rel in sorted(files):
        a = animal_of(rel)
        if animals and a not in animals:
            continue
        op = old_path(rel)
        if not os.path.exists(op):
            rows.append((rel, 'NEW', None, None))
            continue
        new = np.asarray(restore(files[rel], offsets[rel])).astype(int)
        old = np.asarray(Image.open(op).convert('RGBA')).astype(int)
        na, oa = new[..., 3] > 8, old[..., 3] > 8
        union = (na | oa).sum()
        iou = 1.0 if union == 0 else (na & oa).sum() / union
        both = na & oa
        diff = float(np.abs(new[both][:, :3] - old[both][:, :3]).mean()) if both.any() else 0.0
        rows.append((rel, 'same' if iou > 0.999 and diff < 3 else 'DIFF', iou, diff))
    return rows


def write(root, animals):
    offsets, files = load_parts(root)
    n = 0
    for rel in sorted(files):
        if animal_of(rel) not in animals or rel.startswith('fist/'):
            continue  # fist 는 손 소품에 이미 합쳐져 있어 앱에 넣지 않는다
        img = restore(files[rel], offsets[rel])
        out = old_path(rel)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        img.save(out, 'WEBP', quality=90, alpha_quality=100, method=4)
        n += 1
    print(f'{n}개 webp 기록')


if __name__ == '__main__':
    cmd, root, *animals = sys.argv[1:]
    if cmd == 'compare':
        rows = compare(root, set(animals))
        kinds = {}
        for rel, k, iou, diff in rows:
            kinds[k] = kinds.get(k, 0) + 1
            if k != 'same':
                print(k, rel, '' if iou is None else f'iou={iou:.4f} rgb={diff:.2f}')
        print(kinds)
    elif cmd == 'write':
        write(root, set(animals))
