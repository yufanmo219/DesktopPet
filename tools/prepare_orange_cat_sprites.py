#!/usr/bin/env python3
"""Normalize generated orange-cat art into Godot-ready 512 px sprites."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / "assets" / "pets" / "current" / "sprites"
PROCESSED = ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "current" / "sprites" / "processed"
CANVAS_SIZE = 512


def visible_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    thresholded = alpha.point(lambda value: 255 if value > 8 else 0)
    bbox = thresholded.getbbox()
    if bbox is None:
        raise ValueError("Image has no visible pixels")
    return bbox


def normalized_sprite(
    image: Image.Image,
    scale: float,
    baseline: int = 456,
) -> Image.Image:
    bbox = visible_bbox(image)
    cropped = image.crop(bbox)
    new_size = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    resized = cropped.resize(new_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    x = (CANVAS_SIZE - resized.width) // 2
    y = baseline - resized.height
    canvas.alpha_composite(resized, (x, y))
    return canvas


def save_sleep() -> None:
    source = Image.open(PROCESSED / "orange_cat_sleep_cutout.png").convert("RGBA")
    bbox = visible_bbox(source)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]
    scale = min(452 / width, 370 / height)
    output = normalized_sprite(source, scale, baseline=446)
    output.save(SPRITES / "orange_cat_sleep.png")


def save_walk_cycle() -> None:
    sheet = Image.open(PROCESSED / "orange_cat_walk_left_cutout.png").convert("RGBA")
    alpha = sheet.getchannel("A")
    occupied_columns = [
        any(alpha.getpixel((x, y)) > 32 for y in range(sheet.height))
        for x in range(sheet.width)
    ]
    horizontal_runs: list[tuple[int, int]] = []
    run_start: int | None = None
    for x, occupied in enumerate(occupied_columns + [False]):
        if occupied and run_start is None:
            run_start = x
        elif not occupied and run_start is not None:
            horizontal_runs.append((run_start, x))
            run_start = None
    if len(horizontal_runs) != 6:
        raise ValueError(f"Expected six separated walk frames, found {len(horizontal_runs)}")

    cells: list[Image.Image] = []
    bboxes: list[tuple[int, int, int, int]] = []
    for left, right in horizontal_runs:
        cell = sheet.crop((left, 0, right, sheet.height))
        cells.append(cell)
        bboxes.append(visible_bbox(cell))

    max_width = max(right - left for left, _top, right, _bottom in bboxes)
    max_height = max(bottom - top for _left, top, _right, bottom in bboxes)
    shared_scale = min(438 / max_width, 388 / max_height)

    left_frames: list[Image.Image] = []
    right_frames: list[Image.Image] = []
    for frame_index, cell in enumerate(cells, start=1):
        left = normalized_sprite(cell, shared_scale)
        right = ImageOps.mirror(left)
        left.save(SPRITES / "walk_left" / f"frame_{frame_index:02d}.png")
        right.save(SPRITES / "walk_right" / f"frame_{frame_index:02d}.png")
        left_frames.append(left)
        right_frames.append(right)

    for name, frames in (
        ("orange_cat_walk_left_spritesheet.png", left_frames),
        ("orange_cat_walk_right_spritesheet.png", right_frames),
    ):
        output = Image.new("RGBA", (CANVAS_SIZE * 6, CANVAS_SIZE), (0, 0, 0, 0))
        for index, frame in enumerate(frames):
            output.alpha_composite(frame, (index * CANVAS_SIZE, 0))
        output.save(SPRITES / name)


def main() -> None:
    (SPRITES / "walk_left").mkdir(parents=True, exist_ok=True)
    (SPRITES / "walk_right").mkdir(parents=True, exist_ok=True)
    save_sleep()
    save_walk_cycle()
    print("Prepared one sleep sprite and twelve walk frames at 512x512")


if __name__ == "__main__":
    main()
