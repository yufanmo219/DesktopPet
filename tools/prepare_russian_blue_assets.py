#!/usr/bin/env python3
"""Prepare approved Russian Blue concept sheets as fixed-canvas Godot assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image

from prepare_biscuit_assets import (
    PET_CANVAS,
    WALK_CANVAS,
    WIDE_CANVAS,
    extract_main_subject_with_overflow,
    grid_edges,
    normalized_sprite,
    remove_tiny_components,
    visible_bbox,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PET_ROOT = PROJECT_ROOT / "assets" / "pets" / "russian_blue"
SOURCE_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "russian_blue" / "concepts"
STATION_ROOT = PROJECT_ROOT / "assets" / "ui" / "desktop_station" / "luna"


def _connected_chroma_mask(pixels: np.ndarray, color: str) -> np.ndarray:
    red = pixels[:, :, 0]
    green = pixels[:, :, 1]
    blue = pixels[:, :, 2]
    if color == "green":
        dominance = green - np.maximum(red, blue)
        candidate = (green > 75.0) & (dominance > 6.0)
    elif color == "magenta":
        dominance = np.minimum(red, blue) - green
        candidate = (red > 90.0) & (blue > 90.0) & (dominance > 18.0)
    else:
        raise ValueError(f"Unsupported chroma color: {color}")

    height, width = candidate.shape
    connected = np.zeros((height, width), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        if candidate[y, x] and not connected[y, x]:
            connected[y, x] = True
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)
    return connected


def remove_connected_chroma(source: Image.Image, color: str = "green") -> Image.Image:
    """Key only border-connected chroma so Luna's enclosed green eyes survive."""
    image = source.convert("RGBA")
    pixels = np.asarray(image, dtype=np.float32).copy()
    red = pixels[:, :, 0]
    green = pixels[:, :, 1]
    blue = pixels[:, :, 2]
    alpha = pixels[:, :, 3]
    connected = _connected_chroma_mask(pixels, color)

    if color == "green":
        dominance = green - np.maximum(red, blue)
        opacity = np.clip((52.0 - dominance) / 45.0, 0.0, 1.0)
        alpha[connected] *= opacity[connected]
        partial = connected & (alpha > 0.0)
        green[partial] = np.minimum(green[partial], np.maximum(red, blue)[partial] + 8.0)
    else:
        dominance = np.minimum(red, blue) - green
        opacity = np.clip((56.0 - dominance) / 42.0, 0.0, 1.0)
        alpha[connected] *= opacity[connected]
        partial = connected & (alpha > 0.0)
        neutral = green + 10.0
        red[partial] = np.minimum(red[partial], neutral[partial])
        blue[partial] = np.minimum(blue[partial], neutral[partial])

    pixels[:, :, 3] = alpha
    return remove_tiny_components(
        Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGBA"),
        minimum_pixels=24,
    )


def remove_lower_green_residue(source: Image.Image, start_ratio: float = 0.55) -> Image.Image:
    """Remove enclosed floor chroma while preserving Luna's green eyes.

    Border-connected keying deliberately protects enclosed green details, but the
    seated masters also enclose small pieces of the green screen between the paws,
    tail, and body. Those pieces only occur in the lower part of these two static
    poses, safely below the eyes.
    """
    image = source.convert("RGBA")
    pixels = np.asarray(image, dtype=np.float32).copy()
    red = pixels[:, :, 0]
    green = pixels[:, :, 1]
    blue = pixels[:, :, 2]
    alpha = pixels[:, :, 3]
    dominance = green - np.maximum(red, blue)
    lower_region = np.indices(alpha.shape)[0] >= round(alpha.shape[0] * start_ratio)
    residue = lower_region & (alpha > 0.0) & (green > 75.0) & (dominance > 6.0)
    # These pixels are enclosed pieces of the chroma floor, not subject detail.
    # Clear them completely so resampling cannot leave a faint green halo.
    alpha[residue] = 0.0
    pixels[:, :, 3] = alpha
    pixels[alpha <= 1.0, :3] = 0.0
    return remove_tiny_components(
        Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGBA"),
        minimum_pixels=24,
    )


def remove_enclosed_neon_green(source: Image.Image) -> Image.Image:
    """Clear sizeable enclosed green-screen islands without touching green eyes."""
    image = source.convert("RGBA")
    pixels = np.asarray(image, dtype=np.float32).copy()
    red = pixels[:, :, 0]
    green = pixels[:, :, 1]
    blue = pixels[:, :, 2]
    alpha = pixels[:, :, 3]
    height, width = alpha.shape
    neon_core = (
        (alpha > 8.0)
        & (green >= 170.0)
        & (red < 70.0)
        & (blue < 70.0)
    )
    visited = np.zeros((height, width), dtype=bool)
    removable_core = np.zeros((height, width), dtype=bool)
    for start_y, start_x in np.argwhere(neon_core):
        if visited[start_y, start_x]:
            continue
        visited[start_y, start_x] = True
        queue: deque[tuple[int, int]] = deque([(start_x, start_y)])
        component: list[tuple[int, int]] = []
        while queue:
            x, y = queue.popleft()
            component.append((x, y))
            for neighbor_x, neighbor_y in (
                (x - 1, y),
                (x + 1, y),
                (x, y - 1),
                (x, y + 1),
            ):
                if (
                    0 <= neighbor_x < width
                    and 0 <= neighbor_y < height
                    and neon_core[neighbor_y, neighbor_x]
                    and not visited[neighbor_y, neighbor_x]
                ):
                    visited[neighbor_y, neighbor_x] = True
                    queue.append((neighbor_x, neighbor_y))
        if len(component) >= 8:
            for x, y in component:
                removable_core[y, x] = True

    # Any isolated neon pixel in the bottom gutter is also chroma, never an eye.
    removable_core[round(height * 0.78):, :] |= neon_core[round(height * 0.78):, :]
    expanded = removable_core.copy()
    for _step in range(2):
        padded = np.pad(expanded, 1, mode="constant", constant_values=False)
        expanded = (
            padded[1:-1, 1:-1]
            | padded[:-2, 1:-1]
            | padded[2:, 1:-1]
            | padded[1:-1, :-2]
            | padded[1:-1, 2:]
        )
    dominance = green - np.maximum(red, blue)
    spill = expanded & (alpha > 0.0) & (green > 75.0) & (dominance > 6.0)
    alpha[spill] = 0.0
    pixels[:, :, 3] = alpha
    pixels[alpha <= 1.0, :3] = 0.0
    return remove_tiny_components(
        Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGBA"),
        minimum_pixels=24,
    )


def keyed(path: Path, clear_lower_residue: bool = False) -> Image.Image:
    image = remove_connected_chroma(Image.open(path), "green")
    return remove_lower_green_residue(image) if clear_lower_residue else image


def save_static(
    source_name: str,
    destination: Path,
    canvas: tuple[int, int],
    maximum: tuple[int, int],
    clear_lower_residue: bool = False,
) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    prepared = normalized_sprite(
        keyed(SOURCE_ROOT / source_name, clear_lower_residue),
        canvas,
        maximum,
    )
    if clear_lower_residue:
        prepared = remove_lower_green_residue(prepared)
    prepared.save(destination, optimize=True)


def split_subject_grid(
    source_name: str,
    output_dir: Path,
    columns: int,
    rows: int,
    canvas: tuple[int, int],
    bottom_padding: int,
    clear_enclosed_chroma: bool = False,
) -> list[Image.Image]:
    sheet = keyed(SOURCE_ROOT / source_name)
    cutouts = [
        extract_main_subject_with_overflow(
            sheet,
            index % columns,
            index // columns,
            columns,
            rows,
        )
        for index in range(columns * rows)
    ]
    shared_scale = min(
        (canvas[0] - 24) / max(cutout.width for cutout in cutouts),
        (canvas[1] - bottom_padding - 14) / max(cutout.height for cutout in cutouts),
    )
    output_dir.mkdir(parents=True, exist_ok=True)
    frames: list[Image.Image] = []
    for index, cutout in enumerate(cutouts, start=1):
        resized = cutout.resize(
            (round(cutout.width * shared_scale), round(cutout.height * shared_scale)),
            Image.Resampling.LANCZOS,
        )
        frame = Image.new("RGBA", canvas, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            ((canvas[0] - resized.width) // 2, canvas[1] - bottom_padding - resized.height),
        )
        if clear_enclosed_chroma:
            frame = remove_enclosed_neon_green(frame)
        frame.save(output_dir / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def prepare_station() -> None:
    source = remove_connected_chroma(
        Image.open(SOURCE_ROOT / "russian_blue_iridescent_velvet_station_v2.png"),
        "magenta",
    )
    # The generated backdrop leaves a few enclosed magenta islands underneath
    # the cushion shadow. The station itself contains no magenta, so remove the
    # remaining strongly magenta pixels globally after the conservative
    # border-connected pass.
    station_pixels = np.asarray(source, dtype=np.float32).copy()
    red = station_pixels[:, :, 0]
    green = station_pixels[:, :, 1]
    blue = station_pixels[:, :, 2]
    alpha = station_pixels[:, :, 3]
    magenta_dominance = np.minimum(red, blue) - green
    magenta_residue = (
        (red > 105.0)
        & (blue > 105.0)
        & (np.abs(red - blue) < 95.0)
        & (magenta_dominance > 8.0)
    )
    alpha[magenta_residue] = 0.0
    station_pixels[:, :, 3] = alpha
    source = remove_tiny_components(
        Image.fromarray(np.clip(station_pixels, 0, 255).astype(np.uint8), "RGBA"),
        minimum_pixels=24,
    )
    clean_pixels = np.asarray(source, dtype=np.uint8).copy()
    clean_pixels[clean_pixels[:, :, 3] <= 1, :3] = 0
    source = Image.fromarray(clean_pixels, "RGBA")
    bbox = visible_bbox(source)
    padding = 8
    crop = source.crop(
        (
            max(0, bbox[0] - padding),
            max(0, bbox[1] - padding),
            min(source.width, bbox[2] + padding),
            min(source.height, bbox[3] + padding),
        )
    )
    STATION_ROOT.mkdir(parents=True, exist_ok=True)
    crop.save(STATION_ROOT / "luna_iridescent_velvet_station.png", optimize=True)


def main() -> None:
    save_static(
        "russian_blue_side_sitting_v1.png",
        PET_ROOT / "home" / "luna_side_sitting.png",
        PET_CANVAS,
        (452, 472),
        clear_lower_residue=True,
    )
    save_static(
        "russian_blue_front_sitting_v1.png",
        PET_ROOT / "fishing" / "default" / "luna_fishing_default.png",
        PET_CANVAS,
        (452, 472),
        clear_lower_residue=True,
    )
    save_static(
        "russian_blue_portrait_v1.png",
        PET_ROOT / "store" / "luna_store_portrait.png",
        PET_CANVAS,
        (474, 474),
    )
    save_static(
        "russian_blue_sleeping_v1.png",
        PET_ROOT / "sleep" / "luna_sleep.png",
        WIDE_CANVAS,
        (602, 438),
    )

    # The approved failure art already has transparency; normalize it to the
    # same fixed canvas used by every fishing cat.
    failure_source = Image.open(
        PET_ROOT / "fishing" / "failure" / "russian_blue_fishing_failure_sigh.png"
    ).convert("RGBA")
    failure_destination = PET_ROOT / "fishing" / "failure" / "luna_fishing_failure.png"
    failure_destination.parent.mkdir(parents=True, exist_ok=True)
    normalized_sprite(failure_source, PET_CANVAS, (452, 472)).save(
        failure_destination,
        optimize=True,
    )

    split_subject_grid(
        "russian_blue_walk_left_sheet_v2.png",
        PET_ROOT / "walk_left",
        4,
        3,
        WALK_CANVAS,
        14,
    )
    split_subject_grid(
        "russian_blue_walk_right_sheet_v2.png",
        PET_ROOT / "walk_right",
        4,
        3,
        WALK_CANVAS,
        14,
    )
    split_subject_grid(
        "russian_blue_desktop_stretch_yawn_sheet_v1.png",
        PET_ROOT / "desktop" / "stretch_yawn",
        4,
        3,
        WALK_CANVAS,
        14,
        clear_enclosed_chroma=True,
    )
    split_subject_grid(
        "russian_blue_sleep_idle_sheet_v1.png",
        PET_ROOT / "sleep" / "idle",
        4,
        3,
        WIDE_CANVAS,
        14,
    )
    split_subject_grid(
        "russian_blue_fishing_success_sheet_v1.png",
        PET_ROOT / "fishing" / "success",
        4,
        2,
        PET_CANVAS,
        20,
    )
    prepare_station()
    print("Prepared Luna static art, 56 animation frames, and Desktop Station")


if __name__ == "__main__":
    main()
