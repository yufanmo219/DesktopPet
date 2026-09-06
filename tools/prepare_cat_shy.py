#!/usr/bin/env python3
"""Split the six-frame shy-cat cutout into Godot-ready 512px frames."""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter


FRAME_COUNT = 6
OUTPUT_SIZE = 512
SOURCE_FRAME_WIDTH = 362
DESTINATION_X_MARGIN = 75
DESTINATION_Y_OFFSET = -122
OPAQUE_SEED_THRESHOLD = 128


def find_component(alpha: Image.Image, center_x: int, center_y: int) -> Image.Image:
    """Return the connected opaque component nearest an expected cat center."""
    width, height = alpha.size
    alpha_bytes = alpha.tobytes()
    best_index = -1
    best_alpha = -1
    for y in range(max(0, center_y - 80), min(height, center_y + 81)):
        row = y * width
        for x in range(max(0, center_x - 80), min(width, center_x + 81)):
            index = row + x
            if alpha_bytes[index] > best_alpha:
                best_index = index
                best_alpha = alpha_bytes[index]
    if best_alpha <= OPAQUE_SEED_THRESHOLD:
        raise ValueError(f"Could not find an opaque seed near ({center_x}, {center_y})")

    component = bytearray(width * height)
    component[best_index] = 255
    queue: deque[int] = deque([best_index])
    while queue:
        index = queue.popleft()
        x = index % width
        y = index // width
        for offset_y in (-1, 0, 1):
            neighbor_y = y + offset_y
            if neighbor_y < 0 or neighbor_y >= height:
                continue
            row = neighbor_y * width
            for offset_x in (-1, 0, 1):
                if offset_x == 0 and offset_y == 0:
                    continue
                neighbor_x = x + offset_x
                if neighbor_x < 0 or neighbor_x >= width:
                    continue
                neighbor = row + neighbor_x
                if component[neighbor] or alpha_bytes[neighbor] <= OPAQUE_SEED_THRESHOLD:
                    continue
                component[neighbor] = 255
                queue.append(neighbor)

    # Restore the source's soft antialiased edge around the opaque component.
    return Image.frombytes("L", (width, height), bytes(component)).filter(ImageFilter.MaxFilter(5))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path, help="Transparent six-frame source strip")
    parser.add_argument("output_dir", type=Path, help="Directory for frame_01.png ... frame_06.png")
    parser.add_argument("--sheet", type=Path, help="Optional 6x1 512px spritesheet output")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    source = Image.open(args.input).convert("RGBA")
    if source.width != SOURCE_FRAME_WIDTH * FRAME_COUNT:
        raise ValueError(
            f"Expected a {SOURCE_FRAME_WIDTH * FRAME_COUNT}px strip, got {source.width}px"
        )
    args.output_dir.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (OUTPUT_SIZE * FRAME_COUNT, OUTPUT_SIZE), (0, 0, 0, 0))
    source_alpha = source.getchannel("A")

    for index in range(FRAME_COUNT):
        expected_center_x = index * SOURCE_FRAME_WIDTH + SOURCE_FRAME_WIDTH // 2
        component_mask = find_component(source_alpha, expected_center_x, 390)
        isolated_alpha = ImageChops.multiply(source_alpha, component_mask)
        isolated_cat = source.copy()
        isolated_cat.putalpha(isolated_alpha)

        frame = Image.new("RGBA", (OUTPUT_SIZE, OUTPUT_SIZE), (0, 0, 0, 0))
        frame.alpha_composite(
            isolated_cat,
            (
                DESTINATION_X_MARGIN - index * SOURCE_FRAME_WIDTH,
                DESTINATION_Y_OFFSET,
            ),
        )
        output_path = args.output_dir / f"frame_{index + 1:02d}.png"
        frame.save(output_path, optimize=True)
        sheet.alpha_composite(frame, (index * OUTPUT_SIZE, 0))

    if args.sheet:
        args.sheet.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(args.sheet, optimize=True)


if __name__ == "__main__":
    main()
