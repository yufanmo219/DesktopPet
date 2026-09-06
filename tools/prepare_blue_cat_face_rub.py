#!/usr/bin/env python3
"""Prepare the approved British Blue face-rub sleep sheet for Godot."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

from prepare_biscuit_assets import (
    WIDE_CANVAS,
    remove_green_screen,
    remove_tiny_components,
    split_fixed_grid,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_SHEET = (
    PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "animations" / "blue-cat-face-rub-12frames-v2.png"
)
OUTPUT_DIR = (
    PROJECT_ROOT / "assets" / "pets" / "blue_british" / "sleep" / "face_rub"
)
PREVIEW_PATH = PROJECT_ROOT / "dev_only" / "outputs" / "previews" / "blue-cat-face-rub-preview.gif"
FRAME_DURATIONS_MS = [220, 140, 140, 170, 160, 160, 180, 160, 160, 170, 180, 300]


def clean_resampled_chroma(frame: Image.Image) -> Image.Image:
    """Remove green spill introduced when transparent keyed edges are resized."""
    cleaned = remove_tiny_components(remove_green_screen(frame), minimum_pixels=24)
    pixels = np.asarray(cleaned, dtype=np.uint8).copy()
    # This cat contains no green details. Neutralize the remaining premultiplied
    # green fringe without hard-clipping the antialiased outline.
    neutral_green = np.maximum(pixels[:, :, 0], pixels[:, :, 2])
    pixels[:, :, 1] = np.minimum(pixels[:, :, 1], neutral_green)
    transparent = pixels[:, :, 3] <= 1
    pixels[transparent, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def main() -> None:
    frames = split_fixed_grid(
        SOURCE_SHEET,
        OUTPUT_DIR,
        columns=4,
        rows=3,
        canvas_size=WIDE_CANVAS,
        preserve_cell_layout=False,
    )
    cleaned_frames: list[Image.Image] = []
    for index, frame in enumerate(frames, start=1):
        cleaned = clean_resampled_chroma(frame)
        cleaned.save(OUTPUT_DIR / f"frame_{index:02d}.png", optimize=True)
        cleaned_frames.append(cleaned)

    # The preview is deliberately opaque so GIF transparency/disposal cannot
    # display black flashes. Game frames remain transparent PNGs.
    preview_frames: list[Image.Image] = []
    for frame in cleaned_frames:
        preview = Image.new("RGBA", WIDE_CANVAS, "#f5efe4")
        preview.alpha_composite(frame)
        preview_frames.append(preview.convert("RGB"))
    preview_frames[0].save(
        PREVIEW_PATH,
        save_all=True,
        append_images=preview_frames[1:],
        duration=FRAME_DURATIONS_MS,
        loop=0,
        disposal=2,
    )
    print(f"Prepared {len(frames)} British Blue face-rub sleep frames in {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
