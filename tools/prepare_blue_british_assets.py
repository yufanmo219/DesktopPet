#!/usr/bin/env python3
"""Prepare the approved blue British Shorthair (Poppy) artwork for Godot."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

from prepare_biscuit_assets import (
    PET_CANVAS,
    WALK_CANVAS,
    WIDE_CANVAS,
    connected_components,
    extract_main_subject_with_overflow,
    grid_edges,
    keyed,
    normalized_sprite,
    remove_tiny_components,
    visible_bbox,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PET_ROOT = PROJECT_ROOT / "assets" / "pets" / "blue_british"
SOURCE_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "blue_british" / "source"
TEASER_CANVAS = (640, 640)
TEASER_CELL_SCALE = 1.80
WALK_COMPLETE_TAIL_SCALE = 0.89


def remove_connected_near_white(image: Image.Image, tolerance: int = 78) -> Image.Image:
    """Remove the generated checkerboard without erasing enclosed white paws."""
    result = image.convert("RGBA")
    pixels = result.load()
    width, height = result.size
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def is_background(x: int, y: int) -> bool:
        red, green, blue, alpha = pixels[x, y]
        return alpha == 0 or min(red, green, blue) >= 255 - tolerance

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if not visited[index] and is_background(x, y):
            visited[index] = 1
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
    for y in range(height):
        for x in range(width):
            if visited[y * width + x]:
                red, green, blue, _alpha = pixels[x, y]
                pixels[x, y] = (red, green, blue, 0)
    return remove_tiny_components(result, 80)


def save_normalized(source: Image.Image, destination: Path, canvas, maximum) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    normalized_sprite(source, canvas, maximum).save(destination, optimize=True)


def prepare_static_assets() -> None:
    poses = keyed(SOURCE_ROOT / "blue_british_front_side_sitting_chroma.png")
    # The two tails cross the simple halfway crop: a center cut steals the
    # side pose's tail and leaves that fragment on the front pose. Select each
    # cat's connected painted silhouette from an overlapping cell instead.
    front = extract_main_subject_with_overflow(poses, 0, 0, 2, 1)
    side = extract_main_subject_with_overflow(poses, 1, 0, 2, 1)
    save_normalized(side, PET_ROOT / "home" / "poppy_side_sitting.png", PET_CANVAS, (458, 472))
    save_normalized(front, PET_ROOT / "fishing" / "default" / "poppy_fishing_default.png", PET_CANVAS, (452, 472))
    save_normalized(
        keyed(SOURCE_ROOT / "blue_british_store_portrait_chroma.png"),
        PET_ROOT / "store" / "poppy_store_portrait.png",
        PET_CANVAS,
        (474, 474),
    )
    save_normalized(side, PET_ROOT / "store" / "poppy_store_detail.png", PET_CANVAS, (440, 462))
    save_normalized(
        keyed(SOURCE_ROOT / "blue_british_sleep_chroma.png"),
        PET_ROOT / "sleep" / "poppy_sleep.png",
        WIDE_CANVAS,
        (602, 438),
    )
    save_normalized(
        keyed(SOURCE_ROOT / "blue_british_fishing_failure_chroma.png"),
        PET_ROOT / "fishing" / "failure" / "poppy_fishing_failure.png",
        PET_CANVAS,
        (452, 472),
    )


def split_shared_bottom_aligned(sheet: Image.Image, columns: int, rows: int, output: Path, canvas) -> list[Image.Image]:
    x_edges = grid_edges(sheet.width, columns)
    y_edges = grid_edges(sheet.height, rows)
    cutouts = []
    for row in range(rows):
        for column in range(columns):
            cell = sheet.crop((x_edges[column], y_edges[row], x_edges[column + 1], y_edges[row + 1]))
            cutouts.append(cell.crop(visible_bbox(cell)))
    scale = min(
        (canvas[0] - 24) / max(item.width for item in cutouts),
        (canvas[1] - 28) / max(item.height for item in cutouts),
    )
    frames = []
    output.mkdir(parents=True, exist_ok=True)
    for index, cutout in enumerate(cutouts, start=1):
        resized = cutout.resize(
            (round(cutout.width * scale), round(cutout.height * scale)),
            Image.Resampling.LANCZOS,
        )
        frame = Image.new("RGBA", canvas, (0, 0, 0, 0))
        frame.alpha_composite(resized, ((canvas[0] - resized.width) // 2, canvas[1] - 14 - resized.height))
        frame.save(output / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def split_walk_with_complete_tails(
    sheet: Image.Image,
    columns: int,
    rows: int,
    output: Path,
    canvas,
) -> list[Image.Image]:
    """Extract each complete cat beyond fixed cells without neighboring tails.

    Several Poppy tails cross the mathematical 4x3 grid boundary. A plain cell
    crop both clips that tail and carries the neighboring tail tip into the next
    frame. Selecting the centered connected cat from an expanded cell keeps the
    complete silhouette while dropping every neighboring fragment.
    """
    cutouts = [
        extract_main_subject_with_overflow(sheet, column, row, columns, rows)
        for row in range(rows)
        for column in range(columns)
    ]
    scale = min(
        (canvas[0] - 24) / max(item.width for item in cutouts),
        (canvas[1] - 28) / max(item.height for item in cutouts),
    ) * WALK_COMPLETE_TAIL_SCALE
    frames = []
    output.mkdir(parents=True, exist_ok=True)
    for index, cutout in enumerate(cutouts, start=1):
        resized = cutout.resize(
            (round(cutout.width * scale), round(cutout.height * scale)),
            Image.Resampling.LANCZOS,
        )
        frame = Image.new("RGBA", canvas, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            ((canvas[0] - resized.width) // 2, canvas[1] - 14 - resized.height),
        )
        frame.save(output / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def prepare_walk() -> None:
    sheet = remove_connected_near_white(Image.open(SOURCE_ROOT / "blue_british_walk_left_sheet_v2.png"))
    left_frames = split_walk_with_complete_tails(
        sheet,
        4,
        3,
        PET_ROOT / "walk_left",
        WALK_CANVAS,
    )
    right_dir = PET_ROOT / "walk_right"
    right_dir.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(left_frames, start=1):
        ImageOps.mirror(frame).save(right_dir / f"frame_{index:02d}.png", optimize=True)


def prepare_fishing_success() -> None:
    sheet = Image.open(SOURCE_ROOT / "blue_british_fishing_success_head_tilt_sheet_v1.png").convert("RGBA")
    split_shared_bottom_aligned(sheet, 4, 2, PET_ROOT / "fishing" / "success", PET_CANVAS)


def isolate_teaser_cell(cell: Image.Image) -> Image.Image:
    """Keep Poppy and the pink wand while dropping neighboring-row fragments."""
    components = connected_components(cell)
    if not components:
        raise ValueError("Poppy teaser cell contains no visible artwork")
    main = max(components, key=lambda component: component["size"])
    selected = [main]
    pixels = np.asarray(cell)
    for component in components:
        if component is main or component["size"] < 100:
            continue
        indices = np.asarray(component["pixels"])
        ys = indices // cell.width
        xs = indices % cell.width
        colors = pixels[ys, xs, :3]
        pink_pixels = np.count_nonzero(
            (colors[:, 0] >= 170)
            & (colors[:, 0] >= colors[:, 2] + 35)
        )
        blue_pixels = np.count_nonzero(
            (colors[:, 2] >= colors[:, 0] + 8)
            & (colors[:, 2] >= colors[:, 1])
        )
        _left, top, _right, bottom = component["bbox"]
        top_cat_fragment = top <= 10 and bottom <= 12 and blue_pixels > pink_pixels * 2
        if not top_cat_fragment:
            selected.append(component)

    mask = np.zeros((cell.height, cell.width), dtype=np.uint8)
    for component in selected:
        indices = np.asarray(component["pixels"])
        mask[indices // cell.width, indices % cell.width] = 255
    output = cell.copy()
    original_alpha = np.asarray(cell.getchannel("A"))
    output.putalpha(Image.fromarray(np.where(mask, original_alpha, 0).astype(np.uint8), "L"))
    return output


def neutralize_teaser_green_spill(image: Image.Image) -> Image.Image:
    """Remove the chroma hue from antialiased edges without changing alpha."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    red = pixels[:, :, 0]
    green = pixels[:, :, 1]
    blue = pixels[:, :, 2]
    neutral = np.maximum(red, blue)
    green[:] = np.minimum(green, neutral)
    return Image.fromarray(pixels, "RGBA")


def prepare_teaser_play() -> None:
    sheet = keyed(SOURCE_ROOT / "blue_british_teaser_play_sheet_v1.png")
    x_edges = grid_edges(sheet.width, 4)
    y_edges = grid_edges(sheet.height, 4)
    output = PET_ROOT / "desktop" / "teaser_play"
    output.mkdir(parents=True, exist_ok=True)
    for index in range(16):
        row, column = divmod(index, 4)
        cell = sheet.crop(
            (x_edges[column], y_edges[row], x_edges[column + 1], y_edges[row + 1])
        )
        cell = neutralize_teaser_green_spill(isolate_teaser_cell(cell))
        resized = cell.resize(
            (
                round(cell.width * TEASER_CELL_SCALE),
                round(cell.height * TEASER_CELL_SCALE),
            ),
            Image.Resampling.LANCZOS,
        )
        resized = neutralize_teaser_green_spill(resized)
        frame = Image.new("RGBA", TEASER_CANVAS, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            (
                (TEASER_CANVAS[0] - resized.width) // 2,
                TEASER_CANVAS[1] - 14 - resized.height,
            ),
        )
        frame.save(output / f"frame_{index + 1:02d}.png", optimize=True)


def main() -> None:
    prepare_static_assets()
    prepare_walk()
    prepare_fishing_success()
    prepare_teaser_play()
    print(
        "Prepared Poppy static art, 24 walking frames, 8 fishing-success frames, "
        "and 16 teaser-play frames"
    )


if __name__ == "__main__":
    main()
