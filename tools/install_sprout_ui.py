#!/usr/bin/env python3
"""Instala UI Sprout Lands no Godot a partir dos ZIPs obtidos pelo dono do projeto.

Os PNGs originais nao sao enviados ao repositorio publico. O importador gera
assets/ui/sprout_lands/ e adapta o Theme do addon para o projeto.
Uso: python tools/install_sprout_ui.py "UI Pack.zip" "Sprout-Lands-UI-0.2.0.zip"
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path
from zipfile import BadZipFile, ZipFile


# Chaves sao caminhos internos unicos do ZIP oficial. Arquivos de demonstracao
# nao sao copiados para economizar espaco e evitar uso acidental como sprites.
UI_FILES = {
    "Sprite sheets/Sprite sheet for Basic Pack.png": "ui_atlas.png",
    "emojis-free/emoji style ui/Inventory_Spritesheet.png": "inventory_atlas.png",
    "emojis-free/emoji style ui/Inventory_Blocks_Spritesheet.png": "inventory_blocks.png",
    "emojis-free/emoji style ui/weather/Weather_Icons_smal_freel.png": "weather_icons.png",
    "emojis-free/Emoji_Spritesheet_Free.png": "emojis.png",
    "Sprite sheets/Icons/All Icons.png": "icons.png",
    "Sprite sheets/Dialouge UI/Premade dialog box  big.png": "dialogue_box.png",
    "Sprite sheets/Setting menu.png": "settings_menu.png",
    "Sprite sheets/buttons/Small Square Buttons.png": "small_buttons.png",
    "Sprite sheets/UI Settings Buttons.png": "settings_buttons.png",
    "Sprite sheets/UI Big Play Button.png": "play_button.png",
}
THEME_SUFFIX = "addons/sprout_lands_ui/content/sprout_lands_theme.tres"
ORIGINAL_TEXTURE_PATH = (
    "res://addons/sprout_lands_ui/content/assets/Sprite sheet for Basic Pack.png"
)
NEW_TEXTURE_PATH = "res://assets/ui/sprout_lands/ui_atlas.png"


def _entry(zipped: ZipFile, suffix: str) -> bytes:
    normalized = suffix.replace("\\", "/")
    names = [
        name for name in zipped.namelist()
        if not name.endswith("/") and (name == normalized or name.endswith("/" + normalized))
    ]
    if len(names) != 1:
        raise ValueError(f"Esperado 1 arquivo para {suffix!r}; encontrados: {len(names)}")
    return zipped.read(names[0])


def plan(ui_zip: Path, theme_zip: Path, project: Path) -> dict[Path, bytes]:
    if not (project / "project.godot").is_file():
        raise ValueError(f"Pasta nao e um projeto Godot: {project}")
    with ZipFile(ui_zip) as ui, ZipFile(theme_zip) as addon:
        result = {}
        destination = project / "assets" / "ui" / "sprout_lands"
        for name, output_name in UI_FILES.items():
            png = _entry(ui, name)
            if not png.startswith(bytes((137, 80, 78, 71, 13, 10, 26, 10))):
                raise ValueError(f"Imagem PNG invalida: {name}")
            result[destination / output_name] = png
        theme = _entry(addon, THEME_SUFFIX).decode("utf-8-sig")
        if ORIGINAL_TEXTURE_PATH not in theme:
            raise ValueError("Tema do addon nao possui o atlas esperado.")
        theme = theme.replace(ORIGINAL_TEXTURE_PATH, NEW_TEXTURE_PATH)
        # UID da instalacao original nao pertence ao projeto local.
        theme = re.sub(r' uid="uid://[^"]+"', "", theme)
        result[destination / "sprout_theme.tres"] = theme.encode("utf-8")
        return result


def install(files: dict[Path, bytes], replace: bool = False, dry_run: bool = False) -> None:
    conflicts = [
        str(path) for path, payload in files.items()
        if path.exists() and path.read_bytes() != payload and not replace
    ]
    if conflicts:
        raise ValueError(
            "Arquivos locais diferentes encontrados. Para substitui-los use --replace:\\n"
            + chr(10).join(conflicts)
        )
    for path, payload in files.items():
        action = "igual" if path.exists() and path.read_bytes() == payload else "instalar"
        print(f"[{action}] {path}")
        if dry_run or action == "igual":
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(payload)
    if dry_run:
        print("Simulacao concluida; nenhum arquivo foi alterado.")
    else:
        print("UI Sprout Lands instalada. Abra o projeto no Godot e aguarde a importacao.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ui_zip", type=Path, help="Sprout Lands - UI Pack - Basic pack.zip")
    parser.add_argument("theme_zip", type=Path, help="Sprout-Lands-UI-0.2.0.zip")
    parser.add_argument(
        "--project", type=Path, default=Path(__file__).resolve().parents[1],
        help="Pasta onde fica project.godot (padrao: raiz deste repositorio)"
    )
    parser.add_argument("--replace", action="store_true", help="Permite atualizar assets existentes")
    parser.add_argument("--dry-run", action="store_true", help="Confere sem gravar arquivos")
    args = parser.parse_args()
    try:
        files = plan(args.ui_zip.expanduser(), args.theme_zip.expanduser(), args.project.resolve())
        install(files, replace=args.replace, dry_run=args.dry_run)
        return 0
    except (OSError, BadZipFile, ValueError) as exc:
        parser.exit(1, f"ERRO: {exc}" + chr(10))


if __name__ == "__main__":
    raise SystemExit(main())
