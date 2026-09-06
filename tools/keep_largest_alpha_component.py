#!/usr/bin/env python3
"""Remove isolated chroma-key speckles while preserving the main sprite alpha."""

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--threshold", type=int, default=4)
    args = parser.parse_args()

    image = Image.open(args.input).convert("RGBA")
    width, height = image.size
    alpha = image.getchannel("A").tobytes()
    visited = bytearray(width * height)
    largest: list[int] = []

    for start, value in enumerate(alpha):
        if value <= args.threshold or visited[start]:
            continue
        visited[start] = 1
        queue = deque([start])
        component: list[int] = []
        while queue:
            current = queue.popleft()
            component.append(current)
            x = current % width
            y = current // width
            for nx, ny in (
                (x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1),
                (x - 1, y - 1), (x + 1, y - 1),
                (x - 1, y + 1), (x + 1, y + 1),
            ):
                if nx < 0 or ny < 0 or nx >= width or ny >= height:
                    continue
                neighbor = ny * width + nx
                if not visited[neighbor] and alpha[neighbor] > args.threshold:
                    visited[neighbor] = 1
                    queue.append(neighbor)
        if len(component) > len(largest):
            largest = component

    cleaned_alpha = bytearray(width * height)
    for index in largest:
        cleaned_alpha[index] = alpha[index]
    image.putalpha(Image.frombytes("L", (width, height), bytes(cleaned_alpha)))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output)
    print(f"Kept {len(largest)} connected sprite pixels in {args.output}")


if __name__ == "__main__":
    main()
