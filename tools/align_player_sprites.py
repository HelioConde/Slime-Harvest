#!/usr/bin/env python3
"""Build isolated, foot-aligned player spritesheets from committed 8x4 atlases.

Run at repository root: python tools/align_player_sprites.py
Requires pillow, numpy, scipy. Keeps assets/Characters/new/ unchanged.
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
SOURCE = ROOT / "assets/Characters/new"
TARGET = ROOT / "assets/Characters/aligned"
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


def prefer_smooth_idle(text: str, gender: str) -> str:
    """Wire uploaded *idle_suave* PNGs; never synthesize them from older sprites.

    Masculino: tex_1 is WALK and must remain so; install idle as tex_7.
    Feminino: tex_1 is only IDLE and can be replaced in-place.
    """
    image_name = f"player_{gender}_idle_suave.png"
    candidate = SOURCE / image_name
    if not candidate.is_file():
        print(f"INFO: {image_name} ausente: mantendo idle anterior", flush=True)
        return text

    sprite_path = f"res://assets/Characters/new/{image_name}"
    if gender == "feminino":
        pat = r'(\[ext_resource type="Texture2D" path="res://)[^"]+(" id="tex_1"\])'
        text, changed = re.subn(
            pat, lambda m: m.group(1) + sprite_path.removeprefix("res://") + m.group(2),
            text, count=1,
        )
        if changed != 1:
            raise ValueError("Female idle tex_1 not found")
    elif gender == "masculino":
        new_line = f'[ext_resource type="Texture2D" path="{sprite_path}" id="tex_7"]'
        tex7 = re.search(r'^\[ext_resource type="Texture2D" path="[^"]+" id="tex_7"\]
    pngs = {}

    def fix_texture(match: re.Match[str]) -> str:
        original = Path(match.group(1))
        if original.parent == Path("assets/Characters/aligned"):
            source = SOURCE / original.name
        elif original.parent == Path("assets/Characters/new"):
            source = ROOT / original
        else:
            raise ValueError(f"Unknown sprite source: {original}")
        if not source.is_file():
            raise FileNotFoundError(source)
        pngs[match.group(2)] = source
        return match.group(0).replace(
            str(original), f"assets/Characters/aligned/{original.name}")

    text, ext_count = TEXTURE_RE.subn(fix_texture, text)
    if ext_count not in (6, 7):
        raise ValueError(f"Unexpected source sheet count: {ext_count}")

    def fix_frame(match: re.Match[str]) -> str:
        direction, col, texture = match.group(3), int(match.group(4)), match.group(5)
        if texture not in pngs or col not in range(8):
            raise ValueError("Unexpected SpriteFrames reference")
        row = ROWS.index(direction)
        return match.group(1) + f"Rect2({col * CELL}, {row * CELL}, {CELL}, {CELL})"

    text, frame_count = FRAME_RE.subn(fix_frame, text)
    if frame_count < 6 * 32:
        raise ValueError(f"Incomplete AtlasTexture frames: {frame_count}")
    return text, pngs


def main() -> None:
    changes = {}
    for gender in ("masculino", "feminino"):
        config = ANIMATION / f"player_{gender}_frames.tres"
        content = config.read_text(encoding="utf-8")
        content = prefer_smooth_idle(content, gender)
        fixed, source_map = update_spriteframes(content)
        for source in sorted(set(source_map.values())):
            destination = TARGET / source.name
            changes[source.name] = align_sheet(source, destination)
            print(f"OK {source.name}: 8x4 at {CELL}x{CELL}", flush=True)
        if fixed != content:
            config.write_text(fixed, encoding="utf-8")
        print(f"OK {config.relative_to(ROOT)}", flush=True)

    offsets = ROOT / "scripts/player/player_motion_alignment.gd"
    offsets.write_text("""extends RefCounted
## Correcoes de deslocamento foram incorporadas nos PNGs.
## Nao aplicar compensacoes antigas nos quadros ja corrigidos.
static func frame_offset(_appearance: String, _name: StringName, _frame: int) -> Vector2:
\treturn Vector2.ZERO
""", encoding="utf-8")
    report = TARGET / "alignment_report.json"
    report.write_text(json.dumps({
        "cell": CELL, "anchor": [ANCHOR_X, ANCHOR_Y],
        "sheets": changes,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print("OK alignment_report.json")


if __name__ == "__main__":
    main()
, text, re.M)
        if tex7:
            text = text[:tex7.start()] + new_line + text[tex7.end():]
        else:
            # The seventh asset exists only if the new male idle is uploaded.
            last_tex = re.search(
                r'^\[ext_resource type="Texture2D" path="[^"]+" id="tex_6"\]
    pngs = {}

    def fix_texture(match: re.Match[str]) -> str:
        original = Path(match.group(1))
        if original.parent == Path("assets/Characters/aligned"):
            source = SOURCE / original.name
        elif original.parent == Path("assets/Characters/new"):
            source = ROOT / original
        else:
            raise ValueError(f"Unknown sprite source: {original}")
        if not source.is_file():
            raise FileNotFoundError(source)
        pngs[match.group(2)] = source
        return match.group(0).replace(
            str(original), f"assets/Characters/aligned/{original.name}")

    text, ext_count = TEXTURE_RE.subn(fix_texture, text)
    if ext_count not in (6, 7):
        raise ValueError(f"Unexpected source sheet count: {ext_count}")

    def fix_frame(match: re.Match[str]) -> str:
        direction, col, texture = match.group(3), int(match.group(4)), match.group(5)
        if texture not in pngs or col not in range(8):
            raise ValueError("Unexpected SpriteFrames reference")
        row = ROWS.index(direction)
        return match.group(1) + f"Rect2({col * CELL}, {row * CELL}, {CELL}, {CELL})"

    text, frame_count = FRAME_RE.subn(fix_frame, text)
    if frame_count < 6 * 32:
        raise ValueError(f"Incomplete AtlasTexture frames: {frame_count}")
    return text, pngs


def main() -> None:
    changes = {}
    for gender in ("masculino", "feminino"):
        config = ANIMATION / f"player_{gender}_frames.tres"
        content = config.read_text(encoding="utf-8")
        fixed, source_map = update_spriteframes(content)
        for source in sorted(set(source_map.values())):
            destination = TARGET / source.name
            changes[source.name] = align_sheet(source, destination)
            print(f"OK {source.name}: 8x4 at {CELL}x{CELL}", flush=True)
        if fixed != content:
            config.write_text(fixed, encoding="utf-8")
        print(f"OK {config.relative_to(ROOT)}", flush=True)

    offsets = ROOT / "scripts/player/player_motion_alignment.gd"
    offsets.write_text("""extends RefCounted
## Correcoes de deslocamento foram incorporadas nos PNGs.
## Nao aplicar compensacoes antigas nos quadros ja corrigidos.
static func frame_offset(_appearance: String, _name: StringName, _frame: int) -> Vector2:
\treturn Vector2.ZERO
""", encoding="utf-8")
    report = TARGET / "alignment_report.json"
    report.write_text(json.dumps({
        "cell": CELL, "anchor": [ANCHOR_X, ANCHOR_Y],
        "sheets": changes,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print("OK alignment_report.json")


if __name__ == "__main__":
    main()
,
                text, re.M,
            )
            if last_tex is None:
                raise ValueError("Male tex_6 missing")
            text = text[:last_tex.end()] + "\n" + new_line + text[last_tex.end():]
            text = re.sub(
                r'^(\[gd_resource type="SpriteFrames" load_steps=)(\d+)',
                lambda m: m.group(1) + str(int(m.group(2)) + 1),
                text,
                count=1,
            )
        # Never overwrite the walk frames (they share tex_1 in the legacy file).
        idle_ref = re.compile(
            r'(\[sub_resource type="AtlasTexture" id="f_idle_'
            r'(?:down|up|right|left)_\d+"\]\s*atlas = ExtResource\(")'
            r'tex_\d+("\))'
        )
        text, replaced = idle_ref.subn(r'\g<1>tex_7\g<2>', text)
        if replaced != 32:
            raise ValueError(f"Expected 32 male idle regions, found {replaced}")
    else:
        raise ValueError(f"Unknown gender: {gender}")
    print(f"OK new idle asset: {image_name}", flush=True)
    return text


def update_spriteframes(text: str) -> tuple[str, dict[str, Path]]:
    pngs = {}

    def fix_texture(match: re.Match[str]) -> str:
        original = Path(match.group(1))
        if original.parent == Path("assets/Characters/aligned"):
            source = SOURCE / original.name
        elif original.parent == Path("assets/Characters/new"):
            source = ROOT / original
        else:
            raise ValueError(f"Unknown sprite source: {original}")
        if not source.is_file():
            raise FileNotFoundError(source)
        pngs[match.group(2)] = source
        return match.group(0).replace(
            str(original), f"assets/Characters/aligned/{original.name}")

    text, ext_count = TEXTURE_RE.subn(fix_texture, text)
    if ext_count not in (6, 7):
        raise ValueError(f"Unexpected source sheet count: {ext_count}")

    def fix_frame(match: re.Match[str]) -> str:
        direction, col, texture = match.group(3), int(match.group(4)), match.group(5)
        if texture not in pngs or col not in range(8):
            raise ValueError("Unexpected SpriteFrames reference")
        row = ROWS.index(direction)
        return match.group(1) + f"Rect2({col * CELL}, {row * CELL}, {CELL}, {CELL})"

    text, frame_count = FRAME_RE.subn(fix_frame, text)
    if frame_count < 6 * 32:
        raise ValueError(f"Incomplete AtlasTexture frames: {frame_count}")
    return text, pngs


def main() -> None:
    changes = {}
    for gender in ("masculino", "feminino"):
        config = ANIMATION / f"player_{gender}_frames.tres"
        content = config.read_text(encoding="utf-8")
        fixed, source_map = update_spriteframes(content)
        for source in sorted(set(source_map.values())):
            destination = TARGET / source.name
            changes[source.name] = align_sheet(source, destination)
            print(f"OK {source.name}: 8x4 at {CELL}x{CELL}", flush=True)
        if fixed != content:
            config.write_text(fixed, encoding="utf-8")
        print(f"OK {config.relative_to(ROOT)}", flush=True)

    offsets = ROOT / "scripts/player/player_motion_alignment.gd"
    offsets.write_text("""extends RefCounted
## Correcoes de deslocamento foram incorporadas nos PNGs.
## Nao aplicar compensacoes antigas nos quadros ja corrigidos.
static func frame_offset(_appearance: String, _name: StringName, _frame: int) -> Vector2:
\treturn Vector2.ZERO
""", encoding="utf-8")
    report = TARGET / "alignment_report.json"
    report.write_text(json.dumps({
        "cell": CELL, "anchor": [ANCHOR_X, ANCHOR_Y],
        "sheets": changes,
    }, indent=2, ensure_ascii=False), encoding="utf-8")
    print("OK alignment_report.json")


if __name__ == "__main__":
    main()
