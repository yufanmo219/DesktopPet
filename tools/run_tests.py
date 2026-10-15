#!/usr/bin/env python3
"""Run every standalone Godot test with one cross-platform command."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time


PROJECT_ROOT = Path(__file__).resolve().parents[1]
TEST_ROOT = PROJECT_ROOT / "tests"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot",
        help="Godot executable. Defaults to GODOT_BIN or common platform locations.",
    )
    parser.add_argument(
        "--test",
        action="append",
        default=[],
        help="Run tests whose filename contains this value. May be repeated.",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=180.0,
        help="Per-test timeout in seconds (default: 180).",
    )
    parser.add_argument(
        "--import-timeout",
        type=float,
        default=600.0,
        help="Project import timeout in seconds (default: 600).",
    )
    parser.add_argument(
        "--skip-import",
        action="store_true",
        help="Skip the one-time Godot resource import performed before tests.",
    )
    parser.add_argument("--list", action="store_true", help="List selected tests and exit.")
    return parser.parse_args()


def find_godot(explicit_path: str | None) -> str:
    candidates = [
        explicit_path,
        os.environ.get("GODOT_BIN"),
        shutil.which("godot4"),
        shutil.which("godot"),
        shutil.which("godot4.exe"),
        shutil.which("godot.exe"),
        "/Applications/Godot.app/Contents/MacOS/Godot",
    ]
    for candidate in candidates:
        if not candidate:
            continue
        executable = shutil.which(candidate)
        if executable:
            return str(Path(executable).resolve())
        if Path(candidate).is_file():
            return str(Path(candidate).resolve())
    raise SystemExit(
        "Godot was not found. Pass --godot PATH or set the GODOT_BIN environment variable."
    )


def selected_tests(filters: list[str]) -> list[Path]:
    tests = sorted(TEST_ROOT.glob("*_test.gd"))
    if not filters:
        return tests
    lowered_filters = [value.lower() for value in filters]
    return [
        test
        for test in tests
        if any(value in test.name.lower() for value in lowered_filters)
    ]


def import_project(godot: str, timeout: float) -> tuple[bool, float, str]:
    command = [
        godot,
        "--headless",
        "--path",
        str(PROJECT_ROOT),
        "--import",
    ]
    started = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as error:
        elapsed = time.monotonic() - started
        output_parts: list[str] = []
        for part in [error.stdout, error.stderr]:
            if isinstance(part, bytes):
                output_parts.append(part.decode(errors="replace"))
            elif part:
                output_parts.append(part)
        return False, elapsed, (
            f"Godot project import timed out after {timeout:.1f}s.\n"
            + "".join(output_parts)
        )
    elapsed = time.monotonic() - started
    output = "\n".join(
        part.strip() for part in [completed.stdout, completed.stderr] if part.strip()
    )
    return completed.returncode == 0, elapsed, output


def run_test(godot: str, test: Path, log_directory: Path, timeout: float) -> tuple[bool, float, str]:
    log_path = log_directory / f"{test.stem}.log"
    command = [
        godot,
        "--headless",
        "--path",
        str(PROJECT_ROOT),
        "--log-file",
        str(log_path),
        "-s",
        f"res://tests/{test.name}",
        "--",
        "--test-mode",
    ]
    started = time.monotonic()
    try:
        completed = subprocess.run(
            command,
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as error:
        elapsed = time.monotonic() - started
        output_parts: list[str] = []
        for part in [error.stdout, error.stderr]:
            if isinstance(part, bytes):
                output_parts.append(part.decode(errors="replace"))
            elif part:
                output_parts.append(part)
        output = "".join(output_parts)
        return False, elapsed, f"Timed out after {timeout:.1f}s.\n{output}"
    elapsed = time.monotonic() - started
    output = "\n".join(
        part.strip() for part in [completed.stdout, completed.stderr] if part.strip()
    )
    if completed.returncode != 0 and log_path.exists():
        output = f"{output}\n\nGodot log:\n{log_path.read_text(errors='replace')}".strip()
    return completed.returncode == 0, elapsed, output


def main() -> int:
    args = parse_args()
    tests = selected_tests(args.test)
    if not tests:
        print("No tests matched the requested filters.", file=sys.stderr)
        return 2
    if args.list:
        for test in tests:
            print(test.name)
        return 0

    godot = find_godot(args.godot)
    if not args.skip_import:
        imported, import_elapsed, import_output = import_project(
            godot,
            args.import_timeout,
        )
        import_result = "PASS" if imported else "FAIL"
        print(
            f"[IMPORT] {import_result} Godot resources ({import_elapsed:.2f}s)",
            flush=True,
        )
        if not imported:
            if import_output:
                print(import_output, file=sys.stderr)
            return 1

    failures: list[tuple[Path, str]] = []
    suite_started = time.monotonic()
    with tempfile.TemporaryDirectory(prefix="desktop-pet-tests-") as temporary_directory:
        log_directory = Path(temporary_directory)
        for index, test in enumerate(tests, start=1):
            passed, elapsed, output = run_test(godot, test, log_directory, args.timeout)
            result = "PASS" if passed else "FAIL"
            print(
                f"[{index:02d}/{len(tests):02d}] {result} {test.name} ({elapsed:.2f}s)",
                flush=True,
            )
            if not passed:
                failures.append((test, output))

    for test, output in failures:
        print(f"\n--- {test.name} ---\n{output}", file=sys.stderr)
    elapsed = time.monotonic() - suite_started
    print(
        f"\n{len(tests) - len(failures)}/{len(tests)} tests passed in {elapsed:.2f}s."
    )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
