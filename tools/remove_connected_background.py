#!/usr/bin/env python3
"""Remove only a near-white background connected to the image border.

This deliberately preserves enclosed white details, such as highlights in eyes.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


def is_background(pixel: tuple[int, int, int, int], tolerance: int) -> bool:
    red, green, blue, alpha = pixel
    return alpha == 0 or min(red, green, blue) >= 255 - tolerance


def remove_connected_background(source: Path, destination: Path, tolerance: int) -> None:
    image = Image.open(source).convert("RGBA")
    pixels = image.load()
    width, height = image.size
    visited = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if not visited[index] and is_background(pixels[x, y], tolerance):
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

    transparent_count = 0
    for y in range(height):
        for x in range(width):
            if visited[y * width + x]:
                red, green, blue, _ = pixels[x, y]
                pixels[x, y] = (red, green, blue, 0)
                transparent_count += 1

    destination.parent.mkdir(parents=True, exist_ok=True)
    image.save(destination)
    print(
        f"Saved {destination} ({width}x{height}); "
        f"removed {transparent_count:,} border-connected pixels"
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--tolerance", type=int, default=45)
    args = parser.parse_args()
    remove_connected_background(args.source, args.destination, args.tolerance)


if __name__ == "__main__":
    main()
