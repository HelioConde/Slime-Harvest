#!/usr/bin/env python3
"""Instala somente o protagonista Sprout Sorry do ZIP original do usuario."""
from __future__ import annotations

import argparse
from pathlib import Path
from zipfile import BadZipFile, ZipFile

SOURCE_NAME = "Sprout Sorry pack/Tests/free_character_spritesheet_by-cupnooble.png"
DESTINATION = "assets/Characters/sprout_sorry/free_character_spritesheet_by-cupnooble.png"
PNG_SIGNATURE = bytes((137, 80, 78, 71, 13, 10, 26, 10))


def get_sprite(zip_path: Path) -> bytes:
    with ZipFile(zip_path) as archive:
        try:
            raw = archive.read(SOURCE_NAME)
        except KeyError as error:
            raise ValueError("Arquivo do personagem Sprout Sorry nao encontrado no ZIP.") from error
    if len(raw) < 24 or not raw.startswith(PNG_SIGNATURE):
        raise ValueError("Imagem PNG invalida.")
    width = int.from_bytes(raw[16:20], "big")
    height = int.from_bytes(raw[20:24], "big")
    if (width, height) != (128, 96):
        raise ValueError(f"Atlas inesperado: {width}x{height}; esperado 128x96.")
    return raw


def install(zip_path: Path, project: Path, *, replace: bool = False,
            dry_run: bool = False) -> Path:
    if not (project / "project.godot").exists():
        raise ValueError(f"Diretorio do Godot nao encontrado: {project}")
    content = get_sprite(zip_path)
    output = project / DESTINATION
    if output.exists() and output.read_bytes() != content and not replace:
        raise ValueError(f"Arquivo diferente no destino: {output}. Use --replace para substituir.")
    action = "Ja instalado" if output.exists() and output.read_bytes() == content else "Instalar"
    print(f"{action}: {output}")
    if not dry_run and action != "Ja instalado":
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(content)
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sprout_sorry_zip", type=Path)
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    try:
        install(args.sprout_sorry_zip.expanduser(), args.project.resolve(),
                replace=args.replace, dry_run=args.dry_run)
        return 0
    except (OSError, ValueError, BadZipFile) as error:
        parser.exit(1, f"ERRO: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
