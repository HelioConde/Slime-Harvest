#!/usr/bin/env python3
"""Generate throwaway solid-color PNGs ONLY for the Godot CI sprite-path test.

No Cup Nooble/third-party artwork is included here. Never run this against
an installed user's sprite files: existing images are left untouched.
"""
from pathlib import Path
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
FIXTURES = (
    ("assets/Characters/sprout_sorry/free_character_spritesheet_by-cupnooble.png", 128, 96),
    ("assets/ui/sprout_lands/inventory_atlas.png", 368, 336),
    # Testar as cenas opcionais do World sem redistribuir arte real.
    ("assets/expansion_packs/tiny_animals/Farm Animals/chicken.png", 32, 32),
    ("assets/expansion_packs/tiny_animals/Farm Animals/cow.png", 32, 32),
    ("assets/expansion_packs/tiny_animals/Farm Animals/sheep.png", 32, 32),
    ("assets/expansion_packs/tiny_animals/Forest Animals/fox.png", 32, 32),
    ("assets/expansion_packs/tiny_animals/Birds/duck.png", 32, 32),
    ("assets/expansion_packs/tiny_animals/Pets/cat.png", 32, 32),
    ("assets/expansion_packs/treasure_chests/treasure chests.png", 160, 192),
    ("assets/expansion_packs/breakable_pots/breakable pots.png", 128, 128),
)


def _chunk(name: bytes, payload: bytes) -> bytes:
    return (
        struct.pack(">I", len(payload))
        + name + payload
        + struct.pack(">I", zlib.crc32(name + payload) & 0xFFFFFFFF)
    )


def _png(width: int, height: int) -> bytes:
    scanline = b"\x00" + bytes((209, 171, 115, 255)) * width
    return (
        bytes((137, 80, 78, 71, 13, 10, 26, 10))
        + _chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + _chunk(b"IDAT", zlib.compress(scanline * height))
        + _chunk(b"IEND", b"")
    )


def main() -> None:
    for relative, width, height in FIXTURES:
        target = ROOT / relative
        if target.exists():
            raise SystemExit(f"Refusing to overwrite an installed asset: {target}")
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(_png(width, height))
        print(f"CI generated synthetic {width}x{height} fixture: {relative}")


if __name__ == "__main__":
    main()
