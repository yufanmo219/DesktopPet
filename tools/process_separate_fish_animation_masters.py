#!/usr/bin/env python3
"""Build safe aquarium sprite sheets from separate 4x2 swim and idle masters."""

from __future__ import annotations

import argparse
from collections import deque
import json
from pathlib import Path

import numpy as np
from PIL import Image

from process_fish_animation_masters import (
    FISH_IDS,
    FISH_ROOT,
    FRAME_HEIGHT,
    FRAME_WIDTH,
    REPORT_ROOT,
    SOURCE_FISH_ROOT,
    _compose_sheet,
)


MASTER_COLUMNS = 4
MASTER_ROWS = 2
FRAME_COUNT = MASTER_COLUMNS * MASTER_ROWS
TARGET_MAX_SUBJECT_DIMENSION = 280
# Row-level component extraction only needs a small transparent separator
# between neighboring complete fish. Final normalized frames enforce the much
# larger gameplay gutter independently.
MINIMUM_SOURCE_GUTTER = 4


def _master_cells(master: Image.Image) -> list[Image.Image]:
    cells: list[Image.Image] = []
    for row in range(MASTER_ROWS):
        top = round(row * master.height / MASTER_ROWS)
        bottom = round((row + 1) * master.height / MASTER_ROWS)
        for column in range(MASTER_COLUMNS):
            left = round(column * master.width / MASTER_COLUMNS)
            right = round((column + 1) * master.width / MASTER_COLUMNS)
            cells.append(master.crop((left, top, right, bottom)))
    return cells


def _row_subjects(
    master: Image.Image,
) -> tuple[list[Image.Image], list[dict[str, int]]]:
    """Extract four complete fish from each row without trusting column cuts.

    Image generation often spaces the four subjects evenly but not precisely on
    quarter-image centers. Detecting connected subjects across a whole row keeps
    mouths, tails, and fins that cross an assumed column boundary intact.
    """
    rgba = np.asarray(master.convert("RGBA")).copy()
    extracted: list[Image.Image] = []
    reports: list[dict[str, int]] = []

    for row in range(MASTER_ROWS):
        top = round(row * master.height / MASTER_ROWS)
        bottom = round((row + 1) * master.height / MASTER_ROWS)
        row_rgba = rgba[top:bottom].copy()
        mask = row_rgba[:, :, 3] > 8
        height, width = mask.shape
        labels = np.zeros(mask.shape, dtype=np.int32)
        components: list[dict[str, int]] = []
        next_label = 1

        for y in range(height):
            for x in range(width):
                if not mask[y, x] or labels[y, x] != 0:
                    continue
                queue = deque([(x, y)])
                labels[y, x] = next_label
                count = 0
                min_x = max_x = x
                min_y = max_y = y
                while queue:
                    current_x, current_y = queue.popleft()
                    count += 1
                    min_x = min(min_x, current_x)
                    max_x = max(max_x, current_x)
                    min_y = min(min_y, current_y)
                    max_y = max(max_y, current_y)
                    for neighbor_x, neighbor_y in (
                        (current_x - 1, current_y),
                        (current_x + 1, current_y),
                        (current_x, current_y - 1),
                        (current_x, current_y + 1),
                        (current_x - 1, current_y - 1),
                        (current_x + 1, current_y - 1),
                        (current_x - 1, current_y + 1),
                        (current_x + 1, current_y + 1),
                    ):
                        if (
                            0 <= neighbor_x < width
                            and 0 <= neighbor_y < height
                            and mask[neighbor_y, neighbor_x]
                            and labels[neighbor_y, neighbor_x] == 0
                        ):
                            labels[neighbor_y, neighbor_x] = next_label
                            queue.append((neighbor_x, neighbor_y))
                components.append(
                    {
                        "label": next_label,
                        "count": count,
                        "left": min_x,
                        "right": max_x,
                        "top": min_y,
                        "bottom": max_y,
                    }
                )
                next_label += 1

        if len(components) < MASTER_COLUMNS:
            raise ValueError(
                f"Expected four fish components in source row {row}, "
                f"found {len(components)}"
            )

        subjects = sorted(
            sorted(components, key=lambda component: component["count"], reverse=True)[
                :MASTER_COLUMNS
            ],
            key=lambda component: component["left"],
        )
        subject_labels = {component["label"] for component in subjects}
        removed_pixels = sum(
            component["count"]
            for component in components
            if component["label"] not in subject_labels
        )

        for index, component in enumerate(subjects):
            component_mask = labels == component["label"]
            isolated = row_rgba.copy()
            isolated[~component_mask] = 0
            bounds = (
                component["left"],
                component["top"],
                component["right"] + 1,
                component["bottom"] + 1,
            )
            extracted.append(Image.fromarray(isolated, "RGBA").crop(bounds))

            cell_left = (
                0
                if index == 0
                else (subjects[index - 1]["right"] + component["left"]) // 2
            )
            cell_right = (
                width
                if index == MASTER_COLUMNS - 1
                else (component["right"] + subjects[index + 1]["left"] + 1) // 2
            )
            reports.append(
                {
                    "component_count_before_cleanup": len(components),
                    "removed_detached_pixels": removed_pixels,
                    "source_left_gutter": component["left"] - cell_left,
                    "source_right_gutter": cell_right - 1 - component["right"],
                    "source_top_gutter": component["top"],
                    "source_bottom_gutter": height - 1 - component["bottom"],
                }
            )

    return extracted, reports


def _load_clean_frames(
    master_path: Path,
    animation_name: str,
) -> tuple[list[Image.Image], list[dict[str, int | str]]]:
    master = Image.open(master_path).convert("RGBA")
    frames, raw_reports = _row_subjects(master)
    reports: list[dict[str, int | str]] = []
    for frame_index, (cleaned, report) in enumerate(zip(frames, raw_reports)):
        report.update({"animation": animation_name, "frame": frame_index})
        reports.append(report)
    return frames, reports


def _normalize_frames(frames: list[Image.Image]) -> list[Image.Image]:
    widest = max(frame.width for frame in frames)
    tallest = max(frame.height for frame in frames)
    scale = min(
        TARGET_MAX_SUBJECT_DIMENSION / widest,
        TARGET_MAX_SUBJECT_DIMENSION / tallest,
    )
    normalized: list[Image.Image] = []
    for frame in frames:
        resized = frame.resize(
            (
                max(1, round(frame.width * scale)),
                max(1, round(frame.height * scale)),
            ),
            Image.Resampling.LANCZOS,
        )
        output = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
        output.alpha_composite(
            resized,
            (
                (FRAME_WIDTH - resized.width) // 2,
                (FRAME_HEIGHT - resized.height) // 2,
            ),
        )
        normalized.append(output)
    return normalized


def _alpha_gutters(frame: Image.Image) -> dict[str, int]:
    alpha = np.asarray(frame.getchannel("A"))
    ys, xs = np.where(alpha > 8)
    if len(xs) == 0:
        raise ValueError("Normalized frame contains no visible fish pixels")
    return {
        "left": int(xs.min()),
        "right": int(frame.width - 1 - xs.max()),
        "top": int(ys.min()),
        "bottom": int(frame.height - 1 - ys.max()),
    }


def _save_pair(
    fish_directory: Path,
    fish_id: str,
    animation_name: str,
    left_frames: list[Image.Image],
    version: str,
) -> tuple[Path, Path]:
    right_frames = [
        frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for frame in left_frames
    ]
    left_path = fish_directory / f"{fish_id}_{animation_name}_left_8f_{version}.png"
    right_path = fish_directory / f"{fish_id}_{animation_name}_right_8f_{version}.png"
    _compose_sheet(left_frames).save(left_path)
    _compose_sheet(right_frames).save(right_path)
    return left_path, right_path


def _verify_exact_mirrors(left_path: Path, right_path: Path) -> bool:
    left = np.asarray(Image.open(left_path).convert("RGBA"))
    right = np.asarray(Image.open(right_path).convert("RGBA"))
    left_frames = _master_cells(Image.fromarray(left, "RGBA"))
    right_frames = _master_cells(Image.fromarray(right, "RGBA"))
    return all(
        np.array_equal(
            np.asarray(left_frame)[:, ::-1],
            np.asarray(right_frame),
        )
        for left_frame, right_frame in zip(left_frames, right_frames)
    )


def process_fish(
    fish_id: str,
    version: str,
    allow_unsafe_source: bool = False,
) -> dict[str, object]:
    fish_directory = FISH_ROOT / fish_id
    fish_directory.mkdir(parents=True, exist_ok=True)
    source_fish_directory = SOURCE_FISH_ROOT / fish_id
    all_clean_frames: list[Image.Image] = []
    source_reports: list[dict[str, int | str]] = []
    clean_by_animation: dict[str, list[Image.Image]] = {}

    for animation_name in ("swim", "idle_tail"):
        master_path = (
            source_fish_directory
            / f"{fish_id}_{animation_name}_master_transparent_{version}.png"
        )
        frames, reports = _load_clean_frames(master_path, animation_name)
        clean_by_animation[animation_name] = frames
        all_clean_frames.extend(frames)
        source_reports.extend(reports)

    unsafe_frames = [
        report
        for report in source_reports
        if min(
            int(report["source_left_gutter"]),
            int(report["source_right_gutter"]),
            int(report["source_top_gutter"]),
            int(report["source_bottom_gutter"]),
        )
        < MINIMUM_SOURCE_GUTTER
    ]
    if unsafe_frames and not allow_unsafe_source:
        details = ", ".join(
            f"{report['animation']}[{report['frame']}]"
            for report in unsafe_frames
        )
        raise ValueError(f"{fish_id} has source frames too close to a split: {details}")

    normalized = _normalize_frames(all_clean_frames)
    normalized_by_animation = {
        "swim": normalized[:FRAME_COUNT],
        "idle_tail": normalized[FRAME_COUNT:],
    }
    output_reports: list[dict[str, int | str]] = []
    mirror_checks: dict[str, bool] = {}
    for animation_name, frames in normalized_by_animation.items():
        left_path, right_path = _save_pair(
            fish_directory,
            fish_id,
            animation_name,
            frames,
            version,
        )
        mirror_checks[animation_name] = _verify_exact_mirrors(left_path, right_path)
        for frame_index, frame in enumerate(frames):
            gutters = _alpha_gutters(frame)
            output_reports.append(
                {"animation": animation_name, "frame": frame_index, **gutters}
            )

    if not all(mirror_checks.values()):
        raise ValueError(f"{fish_id} right-facing frames are not exact mirrors")

    return {
        "fish_id": fish_id,
        "version": version,
        "minimum_source_gutter": min(
            min(
                int(report["source_left_gutter"]),
                int(report["source_right_gutter"]),
                int(report["source_top_gutter"]),
                int(report["source_bottom_gutter"]),
            )
            for report in source_reports
        ),
        "minimum_output_gutter": min(
            min(
                int(report["left"]),
                int(report["right"]),
                int(report["top"]),
                int(report["bottom"]),
            )
            for report in output_reports
        ),
        "removed_detached_pixels": sum(
            int(report["removed_detached_pixels"]) for report in source_reports
        ),
        "exact_mirrors": mirror_checks,
        "unsafe_source_frames": unsafe_frames,
        "source_frames": source_reports,
        "output_frames": output_reports,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fish-id", choices=FISH_IDS, action="append")
    parser.add_argument("--version", default="v3")
    parser.add_argument("--allow-unsafe-source", action="store_true")
    args = parser.parse_args()
    fish_ids = tuple(args.fish_id) if args.fish_id else FISH_IDS
    reports = [
        process_fish(fish_id, args.version, args.allow_unsafe_source)
        for fish_id in fish_ids
    ]
    REPORT_ROOT.mkdir(parents=True, exist_ok=True)
    report_path = REPORT_ROOT / f"animation_validation_report_{args.version}.json"
    report_path.write_text(json.dumps(reports, indent=2), encoding="utf-8")
    for report in reports:
        print(
            f"{report['fish_id']}: source gutter >= {report['minimum_source_gutter']} px; "
            f"output gutter >= {report['minimum_output_gutter']} px; "
            f"unsafe frames={len(report['unsafe_source_frames'])}; "
            f"exact mirrors={report['exact_mirrors']}"
        )
    print(f"Wrote {report_path}")


if __name__ == "__main__":
    main()
