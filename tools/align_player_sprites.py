#!/usr/bin/env python3
"""Build isolated, foot-aligned player spritesheets from committed 8x4 atlases.

Run at repository root: python tools/align_player_sprites.py
Requires pillow, numpy, scipy. Keeps the original source PNGs in masculino/ and feminino/ unchanged.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage as ndi

ROOT = Path(__file__).resolve().parents[1]
ANIMATION = ROOT / "assets/Characters/animation"
SOURCE = ROOT / "assets/Characters"
TARGET = ROOT / "assets/Characters"
CELL = 320
ANCHOR_X = 160
ANCHOR_Y = 260
ROWS = ("down", "up", "right", "left")
COLUMNS = 8
TEXTURE_RE = re.compile(r'\[ext_resource type="Texture2D" path="res://([^\"]+\.png)" id="(tex_\d+)"\]')
FRAME_RE = re.compile(r'(\[sub_resource type="AtlasTexture" id="f_([a-z]+)_(down|up|right|left)_(\d+)"\]\s*atlas = ExtResource\("(tex_\d+)"\)\s*region = )Rect2\([^)]*\)')


def boundary(index: int, total: int, slices: int) -> int:
    """Replicate the original 1774/8 and 887/4 round-half-up grid."""
    return (index * total * 2 + slices) // (2 * slices)


def isolate_frame(rgba: np.ndarray, row: int, col: int) -> tuple[Image.Image, dict]:
    height, width = rgba.shape[:2]
    x0, x1 = boundary(col, width, 8), boundary(col + 1, width, 8)
    y0, y1 = boundary(row, height, 4), boundary(row + 1, height, 4)
    tile = rgba[y0:y1, x0:x1].copy()
    opaque = tile[:, :, 3] >= 55
    labels, n = ndi.label(opaque, structure=np.ones((3, 3), dtype=np.uint8))
    if not n:
        raise ValueError(f"Empty source frame row={row} col={col}")
    counts = np.bincount(labels.ravel())
    counts[0] = 0
    main_label = int(np.argmax(counts))
    main = labels == main_label
    py, px = np.nonzero(main)
    l, t, r, b = int(px.min()), int(py.min()), int(px.max()), int(py.max())

    # Discard disconnected portions of nearby sprites while retaining droplets
    # and detached tool fragments adjacent to the current main silhouette.
    keep = main.copy()
    discarded = 0
    objects = ndi.find_objects(labels)
    for ident, bounds in enumerate(objects, start=1):
        if ident == main_label or bounds is None:
            continue
        area = int(counts[ident])
        if area < 6:
            discarded += area
            continue
        ys, xs = bounds
        xl, xr, yt, yb = xs.start, xs.stop - 1, ys.start, ys.stop - 1
        gap_x = max(l - xr, xl - r, 0)
        gap_y = max(t - yb, yt - b, 0)
        if gap_x <= 14 and gap_y <= 14:
            keep[ys, xs] |= labels[ys, xs] == ident
        else:
            discarded += area

    # Keep original colors and soft alpha only around the retained silhouette.
    halo = ndi.binary_dilation(keep, iterations=2)
    tile[~halo] = (0, 0, 0, 0)
    tile[(tile[:, :, 3] < 10) & ~keep] = (0, 0, 0, 0)

    rgb = tile[:, :, :3].astype(np.int16)
    R, G, B = (rgb[:, :, i] for i in range(3))
    yy, xx = np.indices(opaque.shape)
    # Anchor torso by stable green fabric, not bounding box of axe/water jet.
    vest = (keep & (tile[:, :, 3] > 100) & (G > R + 13) &
            (G > B + 10) & (xx >= 28) & (xx < 200) &
            (yy >= 75) & (yy <= 205))
    center_x = int(np.median(xx[vest])) if np.count_nonzero(vest) >= 25 else int(np.median(px))
    # Ground point from boots; exclude turquoise water and distant tool tip.
    boot = (keep & (tile[:, :, 3] > 120) & (xx >= center_x - 66) &
            (xx <= center_x + 66) & (yy >= 135) & (R >= 53) &
            (R <= 180) & (R > G + 8) & (B < R + 15))
    ground_y = int(np.max(yy[boot])) if np.any(boot) else b
    dx, dy = ANCHOR_X - center_x, ANCHOR_Y - ground_y
    visible = tile[:, :, 3] > 10
    vy, vx = np.nonzero(visible)
    if (not len(vx) or vx.min() + dx < 0 or vx.max() + dx >= CELL
            or vy.min() + dy < 0 or vy.max() + dy >= CELL):
        raise ValueError(f"Frame would clip: row={row} col={col}; dx={dx}, dy={dy}")
    result = Image.new("RGBA", (CELL, CELL))
    result.paste(Image.fromarray(tile, "RGBA"), (dx, dy))
    return result, {
        "row": ROWS[row], "frame": col,
        "original_cell": [x0, y0, x1 - x0, y1 - y0],
        "center_x": center_x, "ground_y": ground_y,
        "move": [dx, dy], "removed_stray_pixels": discarded,
        "reference": [ANCHOR_X, ANCHOR_Y],
    }


def align_sheet(source: Path, destination: Path) -> list[dict]:
    rgba = np.asarray(Image.open(source).convert("RGBA"))
    if rgba.shape[1] != 1774 or rgba.shape[0] != 887:
        raise ValueError(f"Unexpected sprite size: {source}: {rgba.shape}")
    target = Image.new("RGBA", (CELL * COLUMNS, CELL * len(ROWS)))
    stats = []
    for row in range(len(ROWS)):
        for col in range(COLUMNS):
            frame, data = isolate_frame(rgba, row, col)
            target.paste(frame, (col * CELL, row * CELL))
            stats.append(data)
    destination.parent.mkdir(parents=True, exist_ok=True)
    target.save(destination, optimize=True)
    return stats


ACTIONS = ("idle", "walk", "run", "axe", "pick", "hoe", "watering")
SOURCE_NAMES = ("idle_suave", "andando", "correndo", "machado", "picareta", "enxada", "regando")


def main() -> None:
    for gender in ("masculino", "feminino"):
        config = ANIMATION / f"player_{gender}_frames.tres"
        data = config.read_text(encoding="utf-8")
        matched = list(TEXTURE_RE.finditer(data))
        if len(matched) != 7:
            raise ValueError(f"{gender}: expected 7 SpriteFrames textures, got {len(matched)}")
        report = {}
        for index, (action, name) in enumerate(zip(ACTIONS, SOURCE_NAMES), start=1):
            filename = f"player_{gender}_{name}.png"
            src = SOURCE / gender / filename
            dst = TARGET / gender / "alinhados" / filename
            if not src.is_file():
                raise FileNotFoundError(src)
            report[action] = align_sheet(src, dst)
            print(f"OK {gender}/{action}: 8x4 aligned to {CELL}px", flush=True)
            old_texture = matched[index - 1].group(0)
            if matched[index - 1].group(2) != f"tex_{index}":
                raise ValueError(f"Unexpected texture order: {gender} tex_{index}")
            new_texture = f'[ext_resource type="Texture2D" path="res://assets/Characters/{gender}/alinhados/{filename}" id="tex_{index}"]'
            if old_texture not in data:
                raise ValueError(f"Missing old texture in {config}: {old_texture}")
            data = data.replace(old_texture, new_texture, 1)

        def update_region(match: re.Match[str]) -> str:
            direction = match.group(3)
            col = int(match.group(4))
            if col < 0 or col >= COLUMNS:
                raise ValueError(f"Invalid frame index {col}")
            row = ROWS.index(direction)
            return match.group(1) + f"Rect2({col * CELL}, {row * CELL}, {CELL}, {CELL})"

        data, count = FRAME_RE.subn(update_region, data)
        if count != 224:
            raise ValueError(f"Expected 224 AtlasTexture frames in {gender}; got {count}")
        config.write_text(data, encoding="utf-8")
        report_path = TARGET / gender / "alinhados" / "relatorio.json"
        report_path.write_text(json.dumps({
            "grid": [8, 4], "cell": CELL, "anchor": [ANCHOR_X, ANCHOR_Y],
            "actions": {key: len(value) for key, value in report.items()},
        }, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"OK SpriteFrames {gender}: 28 animations / 224 atlas regions", flush=True)


if __name__ == "__main__":
    main()
