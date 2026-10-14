#!/usr/bin/env python3
"""Reject oversized blobs stored directly in Git instead of Git LFS."""

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
        ["git", "ls-tree", "-lr", "-z", "--full-tree", "HEAD"],
        cwd=PROJECT_ROOT,
        check=True,
        capture_output=True,
    )
    oversized: list[tuple[int, Path]] = []
    for record in result.stdout.split(b"\0"):
        if not record:
            continue
        metadata, raw_path = record.split(b"\t", 1)
        fields = metadata.split()
        if len(fields) != 4 or fields[1] != b"blob":
            continue
        blob_size = int(fields[3])
        if blob_size > maximum_bytes:
            relative_path = Path(raw_path.decode(errors="surrogateescape"))
            oversized.append((blob_size, relative_path))
    if oversized:
        print(
            f"Direct Git blobs exceed the {args.max_mib:g} MiB limit:",
        )
        for size, path in sorted(oversized, reverse=True):
            print(f"  {size / 1024 / 1024:.2f} MiB  {path}")
        print("Move approved binary assets to Git LFS or optimize the file.")
        return 1
    print(f"Direct Git blob size check passed ({args.max_mib:g} MiB maximum).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
