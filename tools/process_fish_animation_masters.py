#!/usr/bin/env python3
"""Split, clean, normalize, and mirror generated aquarium fish masters."""

from __future__ import annotations

from collections import deque
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FISH_ROOT = PROJECT_ROOT / "assets" / "ui" / "aquarium" / "fish"
SOURCE_FISH_ROOT = (
    PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "ui" / "aquarium" / "fish"
)
REPORT_ROOT = PROJECT_ROOT / "dev_only" / "outputs" / "validation"
FISH_IDS = (
    "coral_angelfish",
    "golden_ribbonfish",
    "blue_small_fish",
    "yellow_striped_fish",
    "pink_salmon",
    "blue_tang",
    "peach_goby",
    "silver_blue_mackerel",
    "turquoise_guppy",
    "clownfish",
    "red_cardinalfish",
    "mint_catfish",
    "yellow_boxfish",
    "red_white_koi",
    "purple_butterfly_fish",
    "round_pufferfish",
    "lavender_moonfish",
    "deep_blue_tuna",
    "lionfish",
    "starlight_fish",
    "brown_anglerfish",
    "ruby_betta",
    "neon_tetra",
    "sapphire_discus",
    "sunset_swordtail",
    "black_molly",
    "zebra_danio",
    "mandarin_dragonet",
    "fire_dartfish",
    "royal_gramma",
    "rainbow_parrotfish",
    "picasso_triggerfish",
    "moorish_idol",
    "spotted_frogfish",
    "silver_flyingfish",
    "glass_knifefish",
    "electric_eel",
    "emerald_seahorse",
    "leafy_seadragon",
    "blue_spotted_stingray",
    "golden_manta_ray",
    "moray_eel",
    "spotted_gar",
    "red_arowana",
    "baby_whale_shark",
    "hammerhead_shark",
    "giant_arapaima",
    "ancient_sturgeon",
    "ocean_sunfish",
    "sawfish",
    "coelacanth",
)

MASTER_COLUMNS = 4
MASTER_ROWS = 4
OUTPUT_COLUMNS = 4
OUTPUT_ROWS = 2
FRAME_WIDTH = 384
FRAME_HEIGHT = 512
MAX_SUBJECT_WIDTH = 280
MAX_SUBJECT_HEIGHT = 280
ALPHA_THRESHOLD = 8
MINIMUM_SOURCE_GUTTER = 4

# Image generation repeatedly shortened the swordtail during the dedicated
# idle rows. Reusing the gentlest complete swim poses preserves the species'
# defining lower sword while still producing a small looping tail sway.
IDLE_FROM_SWIM_FRAME_INDICES = {
    "sapphire_discus": (0, 1, 2, 3, 2, 1, 0, 1),
    "sunset_swordtail": (0, 1, 2, 1, 0, 1, 2, 1),
    "black_molly": (0, 1, 2, 3, 2, 1, 0, 1),
    "picasso_triggerfish": (0, 1, 2, 3, 2, 1, 0, 1),
    "glass_knifefish": (0, 1, 2, 3, 2, 1, 0, 1),
    "ocean_sunfish": (0, 1, 2, 3, 2, 1, 0, 1),
}


def _largest_component(image: Image.Image) -> tuple[Image.Image, dict[str, int]]:
    rgba = np.asarray(image.convert("RGBA")).copy()
    mask = rgba[:, :, 3] > ALPHA_THRESHOLD
    height, width = mask.shape
    visited = np.zeros(mask.shape, dtype=bool)
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            queue = deque([(x, y)])
            visited[y, x] = True
            component: list[tuple[int, int]] = []
            while queue:
                current_x, current_y = queue.popleft()
                component.append((current_x, current_y))
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
                        and not visited[neighbor_y, neighbor_x]
                    ):
                        visited[neighbor_y, neighbor_x] = True
                        queue.append((neighbor_x, neighbor_y))
            components.append(component)

    if not components:
        raise ValueError("Generated frame contains no visible fish pixels")

    components.sort(key=len, reverse=True)
    keep = components[0]
    keep_x = [point[0] for point in keep]
    keep_y = [point[1] for point in keep]
    keep_mask = np.zeros(mask.shape, dtype=bool)
    for x, y in keep:
        keep_mask[y, x] = True
    removed_pixels = int(mask.sum() - keep_mask.sum())
    rgba[~keep_mask] = 0

    cleaned = Image.fromarray(rgba, "RGBA")
    bounds = cleaned.getbbox()
    if bounds is None:
        raise ValueError("Fish disappeared during detached-pixel cleanup")
    return cleaned.crop(bounds), {
        "component_count_before_cleanup": len(components),
        "removed_detached_pixels": removed_pixels,
        "source_left_gutter": min(keep_x),
        "source_right_gutter": width - 1 - max(keep_x),
        "source_top_gutter": min(keep_y),
        "source_bottom_gutter": height - 1 - max(keep_y),
    }


def _normalize_frame(
    frame: Image.Image,
    scale_multiplier: float = 1.0,
) -> tuple[Image.Image, dict[str, int]]:
    cleaned, report = _largest_component(frame)
    scale = min(
        MAX_SUBJECT_WIDTH / cleaned.width,
        MAX_SUBJECT_HEIGHT / cleaned.height,
        scale_multiplier,
    )
    resized_size = (
        max(1, round(cleaned.width * scale)),
        max(1, round(cleaned.height * scale)),
    )
    cleaned = cleaned.resize(resized_size, Image.Resampling.LANCZOS)
    output = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    paste_position = (
        (FRAME_WIDTH - cleaned.width) // 2,
        (FRAME_HEIGHT - cleaned.height) // 2,
    )
    output.alpha_composite(cleaned, paste_position)
    report.update(
        {
            "subject_width": cleaned.width,
            "subject_height": cleaned.height,
            "left_gutter": paste_position[0],
            "right_gutter": FRAME_WIDTH - paste_position[0] - cleaned.width,
            "top_gutter": paste_position[1],
            "bottom_gutter": FRAME_HEIGHT - paste_position[1] - cleaned.height,
        }
    )
    return output, report


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


def _component_grid_frames(master: Image.Image) -> list[Image.Image]:
    """Recover complete frames when generated columns are not mathematically even.

    Image generation can produce four visually regular columns whose centers do
    not sit at exact quarter-width coordinates. Splitting those images at fixed
    quarters can cut a long tail even though every creature is fully visible in
    the master. This fallback extracts the sixteen complete connected subjects,
    sorts them into four visual rows, and pads each crop before normalization.
    """

    rgba = np.asarray(master.convert("RGBA")).copy()
    mask = rgba[:, :, 3] > ALPHA_THRESHOLD
    height, width = mask.shape
    visited = np.zeros(mask.shape, dtype=bool)
    components: list[list[tuple[int, int]]] = []

    for y in range(height):
        for x in range(width):
            if not mask[y, x] or visited[y, x]:
                continue
            queue = deque([(x, y)])
            visited[y, x] = True
            component: list[tuple[int, int]] = []
            while queue:
                current_x, current_y = queue.popleft()
                component.append((current_x, current_y))
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
                        and not visited[neighbor_y, neighbor_x]
                    ):
                        visited[neighbor_y, neighbor_x] = True
                        queue.append((neighbor_x, neighbor_y))
            components.append(component)

    components.sort(key=len, reverse=True)
    if len(components) < MASTER_COLUMNS * MASTER_ROWS:
        raise ValueError(
            "Could not find sixteen complete connected subjects in animation master"
        )
    components = components[: MASTER_COLUMNS * MASTER_ROWS]

    def center(component: list[tuple[int, int]]) -> tuple[float, float]:
        return (
            sum(point[0] for point in component) / len(component),
            sum(point[1] for point in component) / len(component),
        )

    components.sort(key=lambda component: center(component)[1])
    ordered_components: list[list[tuple[int, int]]] = []
    for row in range(MASTER_ROWS):
        row_components = components[
            row * MASTER_COLUMNS : (row + 1) * MASTER_COLUMNS
        ]
        row_components.sort(key=lambda component: center(component)[0])
        ordered_components.extend(row_components)

    padding = 8
    frames: list[Image.Image] = []
    for component in ordered_components:
        component_x = np.fromiter((point[0] for point in component), dtype=np.int32)
        component_y = np.fromiter((point[1] for point in component), dtype=np.int32)
        left = int(component_x.min())
        right = int(component_x.max()) + 1
        top = int(component_y.min())
        bottom = int(component_y.max()) + 1
        if min(left, top, width - right, height - bottom) < MINIMUM_SOURCE_GUTTER:
            raise ValueError("A generated subject touches the outer master boundary")
        crop = np.zeros((bottom - top, right - left, 4), dtype=np.uint8)
        crop[component_y - top, component_x - left] = rgba[component_y, component_x]
        subject = Image.fromarray(crop, "RGBA")
        padded = Image.new(
            "RGBA",
            (subject.width + padding * 2, subject.height + padding * 2),
            (0, 0, 0, 0),
        )
        padded.alpha_composite(subject, (padding, padding))
        frames.append(padded)
    return frames


def _compose_sheet(frames: list[Image.Image]) -> Image.Image:
    if len(frames) != OUTPUT_COLUMNS * OUTPUT_ROWS:
        raise ValueError(f"Expected 8 frames, received {len(frames)}")
    sheet = Image.new(
        "RGBA",
        (FRAME_WIDTH * OUTPUT_COLUMNS, FRAME_HEIGHT * OUTPUT_ROWS),
        (0, 0, 0, 0),
    )
    for index, frame in enumerate(frames):
        sheet.alpha_composite(
            frame,
            ((index % OUTPUT_COLUMNS) * FRAME_WIDTH, (index // OUTPUT_COLUMNS) * FRAME_HEIGHT),
        )
    return sheet


def _save_animation_pair(
    fish_directory: Path,
    fish_id: str,
    animation_name: str,
    left_frames: list[Image.Image],
    version: str,
) -> None:
    right_frames = [frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for frame in left_frames]
    _compose_sheet(left_frames).save(
        fish_directory / f"{fish_id}_{animation_name}_left_8f_{version}.png"
    )
    _compose_sheet(right_frames).save(
        fish_directory / f"{fish_id}_{animation_name}_right_8f_{version}.png"
    )


def process_fish(
    fish_id: str,
    version: str = "v1",
    scale_multiplier: float = 1.0,
) -> dict[str, object]:
    fish_directory = FISH_ROOT / fish_id
    fish_directory.mkdir(parents=True, exist_ok=True)
    master_path = SOURCE_FISH_ROOT / fish_id / f"{fish_id}_master_transparent_{version}.png"
    master = Image.open(master_path).convert("RGBA")
    extraction_mode = "fixed_grid"

    def normalize_cells(cells: list[Image.Image]) -> tuple[list[Image.Image], list[dict[str, int]]]:
        normalized_results: list[Image.Image] = []
        reports: list[dict[str, int]] = []
        for frame_index, cell in enumerate(cells):
            normalized, report = _normalize_frame(cell, scale_multiplier)
            report["frame"] = frame_index
            normalized_results.append(normalized)
            reports.append(report)
        return normalized_results, reports

    normalized_frames, frame_reports = normalize_cells(_master_cells(master))

    minimum_source_gutter = min(
        min(
            report["source_left_gutter"],
            report["source_right_gutter"],
            report["source_top_gutter"],
            report["source_bottom_gutter"],
        )
        for report in frame_reports
    )
    if minimum_source_gutter < MINIMUM_SOURCE_GUTTER:
        extraction_mode = "connected_components"
        normalized_frames, frame_reports = normalize_cells(
            _component_grid_frames(master)
        )
        minimum_source_gutter = min(
            min(
                report["source_left_gutter"],
                report["source_right_gutter"],
                report["source_top_gutter"],
                report["source_bottom_gutter"],
            )
            for report in frame_reports
        )

    swim_frames = normalized_frames[:8]
    if fish_id in IDLE_FROM_SWIM_FRAME_INDICES:
        idle_frames = [
            swim_frames[index]
            for index in IDLE_FROM_SWIM_FRAME_INDICES[fish_id]
        ]
    else:
        idle_frames = normalized_frames[8:]
    _save_animation_pair(fish_directory, fish_id, "swim", swim_frames, version)
    _save_animation_pair(fish_directory, fish_id, "idle_tail", idle_frames, version)

    return {
        "fish_id": fish_id,
        "version": version,
        "extraction_mode": extraction_mode,
        "master_size": list(master.size),
        "frames": frame_reports,
        "minimum_source_gutter": minimum_source_gutter,
        "minimum_horizontal_gutter": min(
            min(report["left_gutter"], report["right_gutter"])
            for report in frame_reports
        ),
        "minimum_vertical_gutter": min(
            min(report["top_gutter"], report["bottom_gutter"])
            for report in frame_reports
        ),
        "total_removed_detached_pixels": sum(
            report["removed_detached_pixels"] for report in frame_reports
        ),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fish-id", choices=FISH_IDS, action="append")
    parser.add_argument("--version", default="v1")
    parser.add_argument("--scale-multiplier", type=float, default=1.0)
    args = parser.parse_args()
    fish_ids = tuple(args.fish_id) if args.fish_id else FISH_IDS
    reports = [
        process_fish(fish_id, args.version, args.scale_multiplier)
        for fish_id in fish_ids
    ]
    REPORT_ROOT.mkdir(parents=True, exist_ok=True)
    report_path = REPORT_ROOT / f"animation_validation_report_{args.version}.json"
    report_path.write_text(json.dumps(reports, indent=2), encoding="utf-8")
    for report in reports:
        print(
            f"{report['fish_id']}: min gutters "
            f"source={report['minimum_source_gutter']} "
            f"x={report['minimum_horizontal_gutter']} "
            f"y={report['minimum_vertical_gutter']}; "
            f"removed detached pixels={report['total_removed_detached_pixels']}"
        )
    print(f"Wrote {report_path}")


if __name__ == "__main__":
    main()
