#!/usr/bin/env python3
"""Importa os 19 ZIPs fornecidos pelo jogador, SEM publicar arte no Git.

Comando: py -3 tools/install_all_art_packs.py --source-dir "C:\\Meus Packs"
Opcoes: --dry-run, --replace, --project <pasta com project.godot>.
Nao inclui conteudo de "assets_premium_preview" do SuperRetroRanch.
"""
from __future__ import annotations

import argparse
from pathlib import Path, PurePosixPath
from zipfile import BadZipFile, ZipFile

from install_sprout_collection import plan as sprout_plan
from install_sprout_sorry import get_sprite, DESTINATION as SORRY_DESTINATION

# "slug": nome original e exato do ZIP.
EXTRA_PACKS: dict[str, str] = {
    "tiny_animals": "FREE 64 Tiny Animals – 32x32 Pixel Art Pack.zip",
    "mana_character": "FREE Mana Seed Character Base Demo 2.0.zip",
    "ranch": "SuperRetroRanch_FreeTier_v34.zip",
    "post_apocalypse": "PostApocalypse_AssetPack_v1.1.2.zip",
    "char_free": "char free.zip",
    "dreamyland": "Little Dreamyland - Free Pack.zip",
    "season_winter": "mana seed seasonal forest sample (winter).zip",
    "mana_farmer": "Mana Seed Farmer Sprite Free Sample.zip",
    "treasure_chests": "19.07c - Treasure Chests 1.2a.zip",
    "season_autumn": "mana seed seasonal forest sample (autumn).zip",
    "season_spring": "mana seed seasonal forest sample (spring).zip",
    "season_summer": "mana seed seasonal forest sample (summer).zip",
    "gentle_forest": "19.07a - Gentle Forest 3.0a ($0 palettes).zip",
    "breakable_pots": "20.05b - Breakable Pots 1.1a.zip",
}
SPROUT_PACKS = (
    "Sprout Lands - UI Pack - Basic pack.zip",
    "Sprout Lands - Sprites - Basic pack.zip",
    "Sprout-Lands-UI-0.2.0.zip",
    "Sprout-Lands-Tilemap-0.2.0.zip",
)
SPROUT_SORRY = "Sprout Sorry pack.zip"
ALLOWED = {".png", ".gif", ".webp", ".ase", ".aseprite", ".wav",
           ".ogg", ".ttf", ".otf", ".json", ".txt", ".md"}
MAX_SINGLE_FILE = 24 * 1024 * 1024
MAX_TOTAL_BYTES = 160 * 1024 * 1024


def safe_path(filename: str) -> PurePosixPath:
    if not filename or filename.startswith("/") or "\\" in filename:
        raise ValueError(f"Nome inseguro no ZIP: {filename!r}")
    parts = PurePosixPath(filename)
    if ".." in parts.parts or "." in parts.parts or ":" in filename:
        raise ValueError(f"Arquivo bloqueado: {filename!r}")
    return parts


def strip_root(names: list[str]) -> bool:
    """Remove so a raiz comum quando ela e realmente um envelope do pack."""
    files = [safe_path(n) for n in names if not n.endswith("/")]
    return bool(files and all(len(n.parts) > 1 and n.parts[0] == files[0].parts[0] for n in files))


def plan_extra(pack: Path, slug: str, project: Path) -> dict[Path, bytes]:
    result: dict[Path, bytes] = {}
    with ZipFile(pack) as zipped:
        infos = [entry for entry in zipped.infolist() if not entry.is_dir()]
        remove_root = strip_root([entry.filename for entry in infos])
        for info in infos:
            candidate = safe_path(info.filename)
            parts = candidate.parts[1:] if remove_root else candidate.parts
            if not parts or info.file_size > MAX_SINGLE_FILE:
                if info.file_size > MAX_SINGLE_FILE:
                    raise ValueError(f"Arquivo muito grande: {info.filename}")
                continue
            if any(part.startswith("__MACOSX") for part in parts):
                continue
            if slug == "ranch" and parts[0] != "assets" and parts[0] != "info":
                # Pasta assets_premium_preview NAO e parte dos sprites Free Tier.
                continue
            if candidate.suffix.lower() not in ALLOWED:
                continue
            destination = project / "assets" / "expansion_packs" / slug / Path(*parts)
            result[destination] = zipped.read(info)
    if not result:
        raise ValueError(f"ZIP sem recursos utilizaveis: {pack}")
    return result


def plan_all(source: Path, project: Path) -> dict[Path, bytes]:
    if not (project / "project.godot").is_file():
        raise ValueError(f"Projeto Godot nao encontrado: {project}")
    required = [*EXTRA_PACKS.values(), *SPROUT_PACKS, SPROUT_SORRY]
    missing = [filename for filename in required if not (source / filename).is_file()]
    if missing:
        raise ValueError("ZIP(s) ausente(s): " + ", ".join(missing))
    outputs: dict[Path, bytes] = {}
    for slug, filename in EXTRA_PACKS.items():
        outputs.update(plan_extra(source / filename, slug, project))
    outputs.update(sprout_plan(*(source / filename for filename in SPROUT_PACKS), project))
    outputs[project / SORRY_DESTINATION] = get_sprite(source / SPROUT_SORRY)
    # Conteudo complementar do Sprout Sorry: animais, efeitos e audio.
    outputs.update(plan_extra(source / SPROUT_SORRY, "sprout_sorry_extra", project))
    if sum(map(len, outputs.values())) > MAX_TOTAL_BYTES:
        raise ValueError("Os pacotes excedem o limite de seguranca de 160 MB.")
    return outputs


def install(plan: dict[Path, bytes], replace: bool = False, dry_run: bool = False) -> tuple[int, int]:
    conflicts = [
        path for path, payload in plan.items()
        if path.exists() and path.read_bytes() != payload and not replace
    ]
    if conflicts:
        raise ValueError(
            "Instalacao cancelada: arquivos locais personalizados seriam alterados. "
            "Use --replace apenas se deseja atualizar seus assets:\n"
            + "\n".join(str(x) for x in conflicts[:20])
        )
    changed = 0
    same = 0
    for path, content in sorted(plan.items(), key=lambda pair: str(pair[0])):
        if path.exists() and path.read_bytes() == content:
            same += 1
            continue
        changed += 1
        if not dry_run:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
    return changed, same


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, required=True,
                        help="Pasta dos 19 ZIPs originais, nao um ZIP ja extraido.")
    parser.add_argument("--project", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--replace", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    try:
        project = args.project.resolve()
        planned = plan_all(args.source_dir.resolve(), project)
        changed, unchanged = install(planned, args.replace, args.dry_run)
        print(f"19 pacotes catalogados | {len(planned)} arquivos | "
              f"{sum(map(len, planned.values())) // 1024} KiB")
        print(f"{'Simularia' if args.dry_run else 'Instalados'}: {changed} | Ja iguais: {unchanged}")
        print("Arquivos licenciados nao devem ser enviados ao GitHub publico.")
        print("Abra scenes/world/AssetPackGallery.tscn no Godot com F6.")
        return 0
    except (OSError, ValueError, BadZipFile, UnicodeError) as error:
        parser.exit(1, f"ERRO: {error}\n")


if __name__ == "__main__":
    raise SystemExit(main())
