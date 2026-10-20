#!/usr/bin/env python3
"""Instala ambos os pacotes Sprout Lands e os 2 plugins oficiais (sem afetar saves).

Uso:
  py -3 tools/install_sprout_collection.py "UI Pack.zip" "Sprites Basic.zip" \
      "Sprout-Lands-UI-0.2.0.zip" "Sprout-Lands-Tilemap-0.2.0.zip"

O repositorio nao inclui os arquivos de arte; os ZIPs sao do usuario.
Plugins ficam presentes em addons/ mas NAO sao habilitados automaticamente.
"""
from __future__ import annotations

import argparse
from pathlib import Path, PurePosixPath
import re
from zipfile import BadZipFile, ZipFile

from install_sprout_ui import plan as plan_existing_ui


ART_PACKS = {
    "Sprout Lands - UI Pack - Basic pack/": "assets/sprout_lands/ui_pack",
    "Sprout Lands - Sprites - Basic pack/": "assets/sprout_lands/sprites",
}

ADDONS = {
    "sprout_lands_ui": "addons/sprout_lands_ui/",
    "sprout_lands_tilemap": "addons/sprout_lands_tilemap/",
}

ZIP_TYPES = (".png", ".gif", ".ttf", ".otf", ".aseprite", ".txt", ".md")


def _safe_relative(name: str) -> Path:
    candidate = PurePosixPath(name)
    if (not name or name.startswith("/") or "\\" in name
            or ".." in candidate.parts or "." in candidate.parts):
        raise ValueError(f"Caminho inseguro no ZIP: {name!r}")
    return Path(*candidate.parts)


def _add(result: dict[Path, bytes], path: Path, payload: bytes) -> None:
    if path in result and result[path] != payload:
        raise ValueError(f"Conflito de destinos entre pacotes: {path}")
    result[path] = payload


def _copy_art_pack(zipped: ZipFile, prefix: str, output: Path,
                   result: dict[Path, bytes]) -> int:
    count = 0
    for member in zipped.infolist():
        if member.is_dir() or not member.filename.startswith(prefix):
            continue
        rel = member.filename[len(prefix):]
        candidate = _safe_relative(rel)
        if candidate.suffix.lower() not in ZIP_TYPES:
            continue
        _add(result, output / candidate, zipped.read(member))
        count += 1
    if count < 5:
        raise ValueError(f"Pacote incompleto ou pasta incorreta: {prefix}")
    return count


def _copy_addon(zipped: ZipFile, addon_name: str, result: dict[Path, bytes],
                project: Path) -> int:
    anchor = ADDONS[addon_name]
    count = 0
    for member in zipped.infolist():
        if member.is_dir() or anchor not in member.filename:
            continue
        before, rel = member.filename.split(anchor, 1)
        if not before or "/" not in before:
            # Espera o diretorio raiz do ZIP que envolve addons/.
            continue
        candidate = _safe_relative(rel)
        if (candidate.suffix == ".import" or candidate.name == ".DS_Store"
                or "media" in candidate.parts or candidate.suffix == ".gdignore"):
            continue
        payload = zipped.read(member)
        if candidate.suffix in (".tscn", ".tres"):
            # UIDs pertencem ao projeto original; manter caminhos res://.
            body = payload.decode("utf-8-sig")
            body = re.sub(r' uid="uid://[^"]+"', "", body)
            payload = body.encode("utf-8")
        _add(result, project / anchor / candidate, payload)
        count += 1
    if count < 6 or not (project / anchor / "plugin.cfg") in result:
        raise ValueError(f"Plugin nao encontrado ou incompleto: {addon_name}")
    return count


def plan(ui_pack: Path, sprite_pack: Path, ui_addon: Path,
         tilemap_addon: Path, project: Path) -> dict[Path, bytes]:
    if not (project / "project.godot").is_file():
        raise ValueError(f"Nao encontrei project.godot em {project}")
    files = plan_existing_ui(ui_pack, ui_addon, project)
    with ZipFile(ui_pack) as ui, ZipFile(sprite_pack) as sprites:
        with ZipFile(ui_addon) as ui_plugin, ZipFile(tilemap_addon) as tile_plugin:
            _copy_art_pack(ui, list(ART_PACKS)[0],
                           project / ART_PACKS[list(ART_PACKS)[0]], files)
            _copy_art_pack(sprites, list(ART_PACKS)[1],
                           project / ART_PACKS[list(ART_PACKS)[1]], files)
            _copy_addon(ui_plugin, "sprout_lands_ui", files, project)
            _copy_addon(tile_plugin, "sprout_lands_tilemap", files, project)
    return files


def install(files: dict[Path, bytes], *, replace: bool = False,
            dry_run: bool = False) -> tuple[int, int]:
    conflicting = [
        path for path, data in files.items()
        if path.exists() and path.read_bytes() != data and not replace
    ]
    if conflicting:
        details = "\n".join(str(path) for path in conflicting[:20])
        raise ValueError(
            "Existem arquivos locais diferentes; nenhum arquivo foi alterado. "
            "Use --replace apenas se deseja atualizar esses arquivos:\n" + details
        )
    created, unchanged = 0, 0
    for path, data in sorted(files.items(), key=lambda pair: str(pair[0])):
        if path.exists() and path.read_bytes() == data:
            unchanged += 1
            continue
        created += 1
        if not dry_run:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
    return created, unchanged


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ui_pack", type=Path)
    parser.add_argument("sprite_pack", type=Path)
    parser.add_argument("ui_plugin", type=Path)
    parser.add_argument("tilemap_plugin", type=Path)
    parser.add_argument(
        "--project", type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Diretorio contendo project.godot",
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--replace", action="store_true")
    args = parser.parse_args()
    try:
        all_files = plan(
            args.ui_pack.expanduser(), args.sprite_pack.expanduser(),
            args.ui_plugin.expanduser(), args.tilemap_plugin.expanduser(),
            args.project.resolve(),
        )
        changed, unchanged = install(
            all_files, replace=args.replace, dry_run=args.dry_run
        )
        print(f"Arquivos detectados: {len(all_files)}")
        print(f"{'Simulacao: instalaria' if args.dry_run else 'Instalados/atualizados'}: {changed}")
        print(f"Ja iguais: {unchanged}")
        if not args.dry_run:
            print("Proximo passo: abra o Godot e teste SproutShowcase.tscn (F6).")
            print("Os plugins nao foram habilitados e o mapa principal nao foi alterado.")
        return 0
    except (OSError, BadZipFile, ValueError, UnicodeError) as error:
        parser.exit(1, f"ERRO: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
