#!/usr/bin/env python3
"""Dry-run validation for importing both uploaded smooth-idle sprite atlases."""
from __future__ import annotations

import tempfile
from pathlib import Path

import align_player_sprites as align


def check(gender: str) -> None:
    original = (align.ANIMATION / f"player_{gender}_frames.tres").read_text(encoding="utf-8")
    filename = f"player_{gender}_idle_suave.png"
    with tempfile.TemporaryDirectory() as tmp:
        old_source = align.SOURCE
        try:
            align.SOURCE = Path(tmp)
            (align.SOURCE / filename).write_bytes(b"test-placeholder")
            updated = align.prefer_smooth_idle(original, gender)
            again = align.prefer_smooth_idle(updated, gender)
            assert updated == again, f"{gender}: importer is not idempotent"
            if gender == "masculino":
                assert updated.count('atlas = ExtResource("tex_7")') == 32
                assert updated.count('id="tex_7"') == 1
                assert ('[sub_resource type="AtlasTexture" id="f_walk_down_0"]\n'
                        'atlas = ExtResource("tex_1")') in updated
            else:
                assert updated.count(filename) == 1
                assert '[ext_resource type="Texture2D" path="res://assets/Characters/new/player_feminino_idle_suave.png" id="tex_1"]' in updated
            assert ('[sub_resource type="AtlasTexture" id="f_idle_up_7"]'
                    in updated)
            print(f"PASS {gender}: idle suave importer, mapping and repeatability")
        finally:
            align.SOURCE = old_source


if __name__ == "__main__":
    check("masculino")
    check("feminino")
