#!/usr/bin/env python3
"""Report or archive media that the current Godot runtime does not reference.

Direct `res://assets/...` references are retained, as are Aquarium's dynamically
composed fish-sheet paths and page textures used by referenced bitmap fonts.
`--move` preserves every archived file's original relative path under
`dev_only/unused_assets/` and appends it to the manifest. `--restore` reverses
that move.
"""

from __future__ import annotations

import argparse
import re
import shutil
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
ASSET_ROOT = PROJECT_ROOT / "assets"
ARCHIVE_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets"
MANIFEST_PATH = PROJECT_ROOT / "dev_only" / "unused_assets_manifest.txt"
RUNTIME_TEXT_FILES = (
    *sorted((PROJECT_ROOT / "src").rglob("*.gd")),
    *sorted((PROJECT_ROOT / "src").rglob("*.tscn")),
    *sorted((PROJECT_ROOT / "src").rglob("*.tres")),
    PROJECT_ROOT / "main.tscn",
    PROJECT_ROOT / "project.godot",
    PROJECT_ROOT / "default_bus_layout.tres",
)
ARCHIVABLE_SUFFIXES = {
    ".png",
    ".jpg",
    ".jpeg",
    ".webp",
    ".gif",
    ".svg",
    ".json",
    ".md",
    ".gdshader",
    ".wav",
    ".ogg",
    ".mp3",
    ".flac",
    ".ttf",
    ".otf",
    ".fnt",
}


def _runtime_references() -> set[str]:
    references: set[str] = set()
    for path in RUNTIME_TEXT_FILES:
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for match in re.finditer(r'res://assets/[^"\r\n]+', text):
            project_path = match.group(0).removeprefix("res://")
            # Formatted path templates are covered by their explicit dynamic
            # expansion below; they are not real files themselves.
            if "%" not in project_path and "{" not in project_path:
                references.add(project_path)
    references.update(_dynamic_aquarium_references())
    references.update(_referenced_bitmap_font_pages(references))
    return references


def _referenced_bitmap_font_pages(references: set[str]) -> set[str]:
    pages: set[str] = set()
    for project_path in references:
        if not project_path.lower().endswith(".fnt"):
            continue
        font_path = PROJECT_ROOT / project_path
        if not font_path.is_file():
            continue
        source = font_path.read_text(encoding="utf-8", errors="ignore")
        for page_name in re.findall(r'page\s+id=\d+\s+file="([^"]+)"', source):
            pages.add((font_path.parent / page_name).relative_to(PROJECT_ROOT).as_posix())
    return pages


def _string_map(source: str, constant_name: str) -> dict[str, str]:
    match = re.search(
        rf"const {re.escape(constant_name)}\s*:=\s*\{{(.*?)\n\}}",
        source,
        re.DOTALL,
    )
    if match is None:
        raise RuntimeError(f"Could not parse {constant_name}")
    return dict(re.findall(r'"([^"]+)"\s*:\s*"([^"]+)"', match.group(1)))


def _dynamic_aquarium_references() -> set[str]:
    catalog_source = (PROJECT_ROOT / "src" / "fish_catalog.gd").read_text()
    aquarium_source = (PROJECT_ROOT / "src" / "aquarium_screen.gd").read_text()
    fish_ids = re.findall(r'"id"\s*:\s*"([^"]+)"', catalog_source)
    stem_overrides = _string_map(aquarium_source, "FISH_ASSET_STEM_OVERRIDES")
    version_overrides = _string_map(aquarium_source, "FISH_ASSET_VERSION_OVERRIDES")
    references: set[str] = set()
    for fish_id in fish_ids:
        stem = stem_overrides.get(fish_id, fish_id)
        base = f"assets/ui/aquarium/fish/{stem}/{stem}"
        if fish_id == "green":
            suffixes = (
                "swim_left_8f_v2",
                "swim_right_8f_v4",
                "idle_tail_left_8f_v1",
                "idle_tail_right_8f_v1",
            )
        else:
            version = version_overrides.get(fish_id, "v1")
            suffixes = (
                f"swim_left_8f_{version}",
                f"swim_right_8f_{version}",
                f"idle_tail_left_8f_{version}",
                f"idle_tail_right_8f_{version}",
            )
        references.update(f"{base}_{suffix}.png" for suffix in suffixes)
    return references


def _unused_assets() -> list[Path]:
    references = _runtime_references()
    unused: list[Path] = []
    for path in sorted(ASSET_ROOT.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in ARCHIVABLE_SUFFIXES:
            continue
        project_path = path.relative_to(PROJECT_ROOT).as_posix()
        if project_path not in references:
            unused.append(path)
    return unused


def _move_unused(paths: list[Path]) -> None:
    manifest_lines = (
        MANIFEST_PATH.read_text(encoding="utf-8").splitlines()
        if MANIFEST_PATH.is_file()
        else []
    )
    manifest_entries = set(manifest_lines)
    for source in paths:
        relative_path = source.relative_to(PROJECT_ROOT)
        destination = ARCHIVE_ROOT / relative_path
        if destination.exists():
            raise FileExistsError(f"Archive destination already exists: {destination}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(source, destination)
        relative_text = relative_path.as_posix()
        if relative_text not in manifest_entries:
            manifest_lines.append(relative_text)
            manifest_entries.add(relative_text)
        import_sidecar = Path(f"{source}.import")
        if import_sidecar.exists():
            import_destination = Path(f"{destination}.import")
            shutil.move(import_sidecar, import_destination)
    MANIFEST_PATH.write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")


def _restore() -> None:
    if not MANIFEST_PATH.is_file():
        raise FileNotFoundError(f"Missing manifest: {MANIFEST_PATH}")
    for relative_text in MANIFEST_PATH.read_text(encoding="utf-8").splitlines():
        if not relative_text:
            continue
        destination = PROJECT_ROOT / relative_text
        source = ARCHIVE_ROOT / relative_text
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(source, destination)
        import_source = Path(f"{source}.import")
        if import_source.exists():
            shutil.move(import_source, Path(f"{destination}.import"))


def main() -> None:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--move", action="store_true")
    mode.add_argument("--restore", action="store_true")
    args = parser.parse_args()
    if args.restore:
        _restore()
        print("Restored archived assets from the manifest.")
        return
    references = _runtime_references()
    missing = sorted(
        project_path
        for project_path in references
        if project_path.startswith("assets/")
        and not (PROJECT_ROOT / project_path).is_file()
    )
    if missing:
        print(f"Missing runtime assets: {len(missing)}")
        for project_path in missing:
            print(f"  {project_path}")
        raise SystemExit(1)
    unused = _unused_assets()
    total_bytes = sum(path.stat().st_size for path in unused)
    print(f"Runtime asset references: {len(references)} (all present)")
    print(f"Unused files: {len(unused)} ({total_bytes / 1024 / 1024:.1f} MiB)")
    if args.move:
        _move_unused(unused)
        print(f"Archived under: {ARCHIVE_ROOT}")
        print(f"Manifest: {MANIFEST_PATH}")


if __name__ == "__main__":
    main()
