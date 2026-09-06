#!/usr/bin/env python3
"""Build a stable shy animation by moving only frame 1's tail."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


OUTPUT_SIZE = 512
TAIL_PIVOT = (151, 336)
TAIL_ANGLES = (0, 2, 4, 2, 0, -2)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_frame", type=Path, help="The approved fixed cat frame")
    parser.add_argument("output_dir", type=Path, help="Directory for six stable frames")
    parser.add_argument("--sheet", type=Path, help="Optional 6x1 preview spritesheet")
    return parser.parse_args()


def polygon_mask(points: list[tuple[int, int]]) -> Image.Image:
    mask = Image.new("L", (OUTPUT_SIZE, OUTPUT_SIZE), 0)
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return mask


def main() -> None:
    args = parse_args()
    base = Image.open(args.base_frame).convert("RGBA")
    if base.size != (OUTPUT_SIZE, OUTPUT_SIZE):
        raise ValueError(f"Expected a 512x512 base frame, got {base.size}")

    # The movable mask ends above the hip; the source mask extends farther down
    # so the rotating tail overlaps the fixed root without opening a seam.
    erase_mask = polygon_mask(
        [(54, 168), (192, 168), (192, 267), (170, 296), (158, 331), (54, 331)]
    )
    tail_source_mask = polygon_mask(
        [(54, 168), (192, 168), (192, 267), (174, 302), (164, 351), (54, 351)]
    )
    base_alpha = base.getchannel("A")

    body = base.copy()
    body.putalpha(ImageChops.subtract(base_alpha, ImageChops.multiply(base_alpha, erase_mask)))
    tail = base.copy()
    tail.putalpha(ImageChops.multiply(base_alpha, tail_source_mask))

    args.output_dir.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (OUTPUT_SIZE * len(TAIL_ANGLES), OUTPUT_SIZE), (0, 0, 0, 0))
    for index, angle in enumerate(TAIL_ANGLES):
        rotated_tail = tail.rotate(
            angle,
            resample=Image.Resampling.BICUBIC,
            center=TAIL_PIVOT,
            expand=False,
        )
        frame = Image.new("RGBA", base.size, (0, 0, 0, 0))
        frame.alpha_composite(rotated_tail)
        frame.alpha_composite(body)
        output_path = args.output_dir / f"frame_{index + 1:02d}.png"
        frame.save(output_path, optimize=True)
        sheet.alpha_composite(frame, (index * OUTPUT_SIZE, 0))

    if args.sheet:
        args.sheet.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(args.sheet, optimize=True)


if __name__ == "__main__":
    main()
