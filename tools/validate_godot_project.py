#!/usr/bin/env python3
"""Check resources and essential scene wiring without requiring the Godot editor.

Run from the repository root:
    py -3 tools/validate_godot_project.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESOURCE = re.compile(r'path="res://([^"]+)"')
LITERAL_SCRIPT_PATH = re.compile(r'\b(?:preload|load)\(\s*["\']res://([^"\']+)["\']\s*\)')
MAIN_SCENE = re.compile(r'^run/main_scene="res://([^"]+)"', re.MULTILINE)

CORE_SCRIPTS = (
    "scripts/player/player.gd",
    "scripts/ui/tool_hotbar.gd",
    "scripts/ui/tool_icon.gd",
    "scripts/items/tool_inventory.gd",
    "scripts/farming/farm_field.gd",
    "scripts/farming/plant_growth.gd",
    "scripts/trees/choppable_tree.gd",
    "scripts/trees/tree_fall.gd",
    "scripts/trees/tree_persistence.gd",
    "scripts/core/game_calendar.gd",
)
REQUIRED_SCENES = (
    "scenes/world/World.tscn",
    "scenes/objects/ObjectCatalog.tscn",
    "scenes/trees/TreeChopDemo.tscn",
    "scenes/farming/FarmingToolDemo.tscn",
    "scenes/ui/ToolHotbar.tscn",
)


def check() -> list[str]:
    errors: list[str] = []
    project_file = ROOT / "project.godot"
    if not project_file.is_file():
        return ["project.godot not found"]

    scenes = sorted((ROOT / "scenes").rglob("*.tscn"))
    scripts = sorted((ROOT / "scripts").rglob("*.gd"))
    if not scenes:
        errors.append("No .tscn scenes found")
    for scene in scenes:
        source = scene.read_text(encoding="utf-8-sig")
        if not source.startswith("[gd_scene"):
            errors.append(f"{scene.relative_to(ROOT)}: invalid scene header")
        for match in RESOURCE.finditer(source):
            resource_path = match.group(1)
            if not (ROOT / resource_path).is_file():
                errors.append(
                    f"{scene.relative_to(ROOT)}: missing resource res://{resource_path}"
                )

    for script in scripts:
        source = script.read_text(encoding="utf-8-sig")
        for match in LITERAL_SCRIPT_PATH.finditer(source):
            path = match.group(1)
            if not (ROOT / path).is_file():
                errors.append(f"{script.relative_to(ROOT)}: missing res://{path}")
        # Mixed tab/space indentation was a previous Godot compilation failure.
        if script.relative_to(ROOT).as_posix() in CORE_SCRIPTS:
            for lineno, line in enumerate(source.splitlines(), 1):
                if line.startswith(" ") and line.lstrip():
                    errors.append(f"{script.relative_to(ROOT)}:{lineno}: use tabs, not spaces")

    project = project_file.read_text(encoding="utf-8-sig")
    main = MAIN_SCENE.search(project)
    if main is None or not (ROOT / main.group(1)).is_file():
        errors.append("project.godot: main scene is missing")
    for required in REQUIRED_SCENES + CORE_SCRIPTS:
        if not (ROOT / required).is_file():
            errors.append(f"Required project component missing: {required}")

    catalog = (ROOT / "scenes/objects/ObjectCatalog.tscn").read_text(encoding="utf-8-sig")
    scene_paths = re.findall(
        r'\[ext_resource type="PackedScene"[^\n]*path="res://([^"]+)"',
        catalog,
    )
    if len(scene_paths) < 78:
        errors.append(f"ObjectCatalog: expected at least 78 original objects, got {len(scene_paths)}")
    if len(scene_paths) != len(set(scene_paths)):
        errors.append("ObjectCatalog: duplicate PackedScene references")

    choppable = (ROOT / "scripts/trees/choppable_tree.gd").read_text(encoding="utf-8-sig")
    if "axe_hits_required: int = 5" not in choppable:
        errors.append("ChoppableTree: default must require five axe hits")

    player = (ROOT / "scripts/player/player.gd").read_text(encoding="utf-8-sig")
    if "_axe_animating" in player:
        errors.append("Player: obsolete _axe_animating reference")
    if "tool_action_requested" not in player:
        errors.append("Player: equipment action signal missing")

    return errors


def main() -> int:
    problems = check()
    if problems:
        print(f"FAILED: {len(problems)} project integrity errors:")
        for problem in problems:
            print(f" - {problem}")
        return 1
    scene_count = len(list((ROOT / "scenes").rglob("*.tscn")))
    print(f"PASS: {scene_count} Godot scenes, tool wiring and resource paths checked.")
    print("Note: structural checks only; run Godot for runtime and visual testing.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
