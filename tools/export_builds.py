#!/usr/bin/env python3
"""Create reproducible Desktop Pet QA exports from the shared presets."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys
import zipfile

from run_tests import PROJECT_ROOT, find_godot


TARGETS = {
    "windows": ("Windows Desktop", Path("build/windows/Desktop Pet.exe")),
    "macos": ("macOS", Path("build/macos/Desktop Pet.zip")),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--target",
        choices=["windows", "macos", "all"],
        default="all",
        help="Platform preset to export (default: all).",
    )
    parser.add_argument(
        "--godot",
        help="Godot executable. Defaults to GODOT_BIN or common platform locations.",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Create debug exports instead of release-template QA exports.",
    )
    return parser.parse_args()


def export_target(godot: str, target: str, debug: bool) -> None:
    preset, relative_output = TARGETS[target]
    output = PROJECT_ROOT / relative_output
    output.parent.mkdir(parents=True, exist_ok=True)
    export_flag = "--export-debug" if debug else "--export-release"
    command = [
        godot,
        "--headless",
        "--quiet",
        "--path",
        str(PROJECT_ROOT),
        export_flag,
        preset,
        str(output),
    ]
    completed = subprocess.run(command, cwd=PROJECT_ROOT, check=False)
    if completed.returncode != 0:
        raise SystemExit(
            f"Godot failed to export {preset!r} with exit code {completed.returncode}."
        )
    if not output.is_file() or output.stat().st_size == 0:
        raise SystemExit(f"Godot reported success but did not create {output}.")
    if target == "windows":
        package = output.with_suffix(".pck")
        if not package.is_file() or package.stat().st_size == 0:
            raise SystemExit(
                f"Windows export is missing its companion package: {package}."
            )
    elif target == "macos":
        with zipfile.ZipFile(output) as archive:
            if not any(
                name.startswith("Desktop Pet.app/") for name in archive.namelist()
            ):
                raise SystemExit(
                    f"macOS export does not contain Desktop Pet.app: {output}."
                )
    print(f"Exported {preset}: {output} ({output.stat().st_size:,} bytes)")


def main() -> int:
    args = parse_args()
    godot = find_godot(args.godot)
    targets = TARGETS if args.target == "all" else [args.target]
    for target in targets:
        export_target(godot, target, args.debug)
    return 0


if __name__ == "__main__":
    sys.exit(main())
