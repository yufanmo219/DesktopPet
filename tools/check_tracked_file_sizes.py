#!/usr/bin/env python3
"""Reject newly tracked files that need the repository's future LFS policy."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--max-mib",
        type=float,
        default=20.0,
        help="Maximum tracked file size in MiB (default: 20).",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    maximum_bytes = int(args.max_mib * 1024 * 1024)
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=PROJECT_ROOT,
        check=True,
        capture_output=True,
    )
    oversized: list[tuple[int, Path]] = []
    for raw_path in result.stdout.split(b"\0"):
        if not raw_path:
            continue
        relative_path = Path(raw_path.decode(errors="surrogateescape"))
        absolute_path = PROJECT_ROOT / relative_path
        if absolute_path.is_file() and absolute_path.stat().st_size > maximum_bytes:
            oversized.append((absolute_path.stat().st_size, relative_path))
    if oversized:
        print(
            f"Tracked files exceed the {args.max_mib:g} MiB pre-LFS limit:",
        )
        for size, path in sorted(oversized, reverse=True):
            print(f"  {size / 1024 / 1024:.2f} MiB  {path}")
        print("Optimize the asset or complete the coordinated Git LFS migration.")
        return 1
    print(f"Tracked file size check passed ({args.max_mib:g} MiB maximum).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
