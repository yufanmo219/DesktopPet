#!/usr/bin/env python3
"""Prepare the approved Biscuit artwork as fixed-canvas Godot assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
BISCUIT_ROOT = PROJECT_ROOT / "assets" / "pets" / "biscuit"
DEV_ASSET_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets" / "assets"
SOURCE_ROOT = DEV_ASSET_ROOT / "pets" / "biscuit" / "source"
STATION_ROOT = PROJECT_ROOT / "assets" / "ui" / "desktop_station" / "biscuit"
STATION_SOURCE_ROOT = DEV_ASSET_ROOT / "ui" / "desktop_station" / "biscuit" / "source"

PET_CANVAS = (512, 512)
WIDE_CANVAS = (640, 512)
WALK_CANVAS = (704, 512)


def remove_green_screen(source: Image.Image) -> Image.Image:
    """Key the generated green backdrop while keeping a soft antialiased edge."""
    image = source.convert("RGBA")
    pixels = np.asarray(image, dtype=np.float32).copy()
    red = pixels[:, :, 0]
    green = pixels[:, :, 1]
    blue = pixels[:, :, 2]
    alpha = pixels[:, :, 3]
    dominance = green - np.maximum(red, blue)
    green_candidate = (green > 80.0) & (dominance > 7.0)
    opacity = np.clip((52.0 - dominance) / 45.0, 0.0, 1.0)
    alpha[green_candidate] *= opacity[green_candidate]

    # Remove residual green spill from partially transparent edge pixels.
    partial = green_candidate & (alpha > 0.0)
    neutral_green = np.maximum(red, blue) + 8.0
    green[partial] = np.minimum(green[partial], neutral_green[partial])
    pixels[:, :, 3] = alpha
    return Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGBA")


def remove_tiny_components(image: Image.Image, minimum_pixels: int = 36) -> Image.Image:
    """Drop isolated keying speckles while preserving cats and small butterflies."""
    alpha = np.asarray(image.getchannel("A"))
    height, width = alpha.shape
    visited = bytearray(width * height)
    keep = bytearray(width * height)
    for start_y in range(height):
        for start_x in range(width):
            start = start_y * width + start_x
            if visited[start] or alpha[start_y, start_x] <= 8:
                continue
            visited[start] = 1
            queue: deque[int] = deque([start])
            component: list[int] = []
            while queue:
                index = queue.popleft()
                component.append(index)
                y, x = divmod(index, width)
                for offset_y in (-1, 0, 1):
                    neighbor_y = y + offset_y
                    if neighbor_y < 0 or neighbor_y >= height:
                        continue
                    for offset_x in (-1, 0, 1):
                        if offset_x == 0 and offset_y == 0:
                            continue
                        neighbor_x = x + offset_x
                        if neighbor_x < 0 or neighbor_x >= width:
                            continue
                        neighbor = neighbor_y * width + neighbor_x
                        if visited[neighbor] or alpha[neighbor_y, neighbor_x] <= 8:
                            continue
                        visited[neighbor] = 1
                        queue.append(neighbor)
            if len(component) >= minimum_pixels:
                for index in component:
                    keep[index] = 255
    keep_mask = np.frombuffer(bytes(keep), dtype=np.uint8).reshape((height, width))
    output = image.copy()
    output.putalpha(Image.fromarray(np.where(keep_mask, alpha, 0).astype(np.uint8), "L"))
    return output


def connected_components(image: Image.Image) -> list[dict]:
    alpha = np.asarray(image.getchannel("A"))
    height, width = alpha.shape
    visited = bytearray(width * height)
    components: list[dict] = []
    for start_y in range(height):
        for start_x in range(width):
            start = start_y * width + start_x
            if visited[start] or alpha[start_y, start_x] <= 8:
                continue
            visited[start] = 1
            queue: deque[int] = deque([start])
            pixels: list[int] = []
            min_x = max_x = start_x
            min_y = max_y = start_y
            sum_x = 0
            sum_y = 0
            while queue:
                index = queue.popleft()
                pixels.append(index)
                y, x = divmod(index, width)
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
                sum_x += x
                sum_y += y
                for offset_y in (-1, 0, 1):
                    neighbor_y = y + offset_y
                    if neighbor_y < 0 or neighbor_y >= height:
                        continue
                    for offset_x in (-1, 0, 1):
                        if offset_x == 0 and offset_y == 0:
                            continue
                        neighbor_x = x + offset_x
                        if neighbor_x < 0 or neighbor_x >= width:
                            continue
                        neighbor = neighbor_y * width + neighbor_x
                        if visited[neighbor] or alpha[neighbor_y, neighbor_x] <= 8:
                            continue
                        visited[neighbor] = 1
                        queue.append(neighbor)
            if len(pixels) >= 20:
                components.append(
                    {
                        "pixels": pixels,
                        "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                        "centroid": (sum_x / len(pixels), sum_y / len(pixels)),
                        "size": len(pixels),
                    }
                )
    return components


def isolate_cell_components(cell: Image.Image, keep_pink_extras: bool) -> Image.Image:
    """Keep the current cat and optional butterfly, not neighboring-cell fragments."""
    components = connected_components(cell)
    if not components:
        raise ValueError("Animation cell contains no visible subject")
    main = max(components, key=lambda component: component["size"])
    selected = [main]
    source_pixels = np.asarray(cell)
    if keep_pink_extras:
        for component in components:
            if component is main:
                continue
            sample_indices = component["pixels"]
            ys = np.asarray(sample_indices) // cell.width
            xs = np.asarray(sample_indices) % cell.width
            colors = source_pixels[ys, xs, :3]
            pink_ratio = np.mean(
                (colors[:, 0] > 200)
                & (colors[:, 1] > 95)
                & (colors[:, 2] > 115)
                & (colors[:, 0] > colors[:, 1] + 12)
            )
            left, top, right, bottom = component["bbox"]
            does_not_touch_cell_edge = (
                left > 3 and top > 3 and right < cell.width - 3 and bottom < cell.height - 3
            )
            if component["size"] >= 45 and pink_ratio >= 0.12 and does_not_touch_cell_edge:
                selected.append(component)
    mask = np.zeros((cell.height, cell.width), dtype=np.uint8)
    for component in selected:
        indices = np.asarray(component["pixels"])
        mask[indices // cell.width, indices % cell.width] = 255
    output = cell.copy()
    original_alpha = np.asarray(cell.getchannel("A"))
    output.putalpha(Image.fromarray(np.where(mask, original_alpha, 0).astype(np.uint8), "L"))
    return output


def extract_main_subject_with_overflow(
    sheet: Image.Image,
    column: int,
    row: int,
    columns: int,
    rows: int,
) -> Image.Image:
    x_edges = grid_edges(sheet.width, columns)
    y_edges = grid_edges(sheet.height, rows)
    left, right = x_edges[column], x_edges[column + 1]
    top, bottom = y_edges[row], y_edges[row + 1]
    margin_x = round((right - left) * 0.30)
    margin_y = round((bottom - top) * 0.22)
    expanded_left = max(0, left - margin_x)
    expanded_top = max(0, top - margin_y)
    expanded_right = min(sheet.width, right + margin_x)
    expanded_bottom = min(sheet.height, bottom + margin_y)
    expanded = sheet.crop((expanded_left, expanded_top, expanded_right, expanded_bottom))
    components = [component for component in connected_components(expanded) if component["size"] >= 400]
    if not components:
        raise ValueError(f"No cat found in cell ({column}, {row})")
    target_x = (left + right) * 0.5 - expanded_left
    target_y = (top + bottom) * 0.5 - expanded_top
    main = min(
        components,
        key=lambda component: (
            (component["centroid"][0] - target_x) ** 2
            + (component["centroid"][1] - target_y) ** 2
        ),
    )
    mask = np.zeros((expanded.height, expanded.width), dtype=np.uint8)
    indices = np.asarray(main["pixels"])
    mask[indices // expanded.width, indices % expanded.width] = 255
    output = expanded.copy()
    original_alpha = np.asarray(expanded.getchannel("A"))
    output.putalpha(Image.fromarray(np.where(mask, original_alpha, 0).astype(np.uint8), "L"))
    return output.crop(main["bbox"])


def keyed(path: Path) -> Image.Image:
    return remove_tiny_components(remove_green_screen(Image.open(path)))


def visible_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A").point(lambda value: 255 if value > 8 else 0)
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("Artwork contains no visible pixels")
    return bbox


def normalized_sprite(
    image: Image.Image,
    canvas_size: tuple[int, int],
    maximum_size: tuple[int, int],
    bottom_padding: int = 12,
) -> Image.Image:
    cutout = image.crop(visible_bbox(image))
    scale = min(maximum_size[0] / cutout.width, maximum_size[1] / cutout.height)
    resized = cutout.resize(
        (max(1, round(cutout.width * scale)), max(1, round(cutout.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (canvas_size[0] - resized.width) // 2
    y = canvas_size[1] - bottom_padding - resized.height
    canvas.alpha_composite(resized, (x, y))
    return canvas


def grid_edges(length: int, divisions: int) -> list[int]:
    return [round(index * length / divisions) for index in range(divisions + 1)]


def split_fixed_grid(
    source_path: Path,
    output_dir: Path,
    columns: int,
    rows: int,
    canvas_size: tuple[int, int],
    preserve_cell_layout: bool,
) -> list[Image.Image]:
    sheet = keyed(source_path)
    x_edges = grid_edges(sheet.width, columns)
    y_edges = grid_edges(sheet.height, rows)
    cells = [
        isolate_cell_components(
            sheet.crop((x_edges[column], y_edges[row], x_edges[column + 1], y_edges[row + 1])),
            keep_pink_extras=columns == 4 and rows == 4,
        )
        for row in range(rows)
        for column in range(columns)
    ]
    frames: list[Image.Image] = []
    if preserve_cell_layout:
        scale = min(canvas_size[0] / cells[0].width, canvas_size[1] / cells[0].height)
        for cell in cells:
            resized = cell.resize(
                (round(cell.width * scale), round(cell.height * scale)),
                Image.Resampling.LANCZOS,
            )
            frame = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
            frame.alpha_composite(
                resized,
                ((canvas_size[0] - resized.width) // 2, (canvas_size[1] - resized.height) // 2),
            )
            frames.append(frame)
    else:
        cutouts = [cell.crop(visible_bbox(cell)) for cell in cells]
        shared_scale = min(
            (canvas_size[0] - 24) / max(cutout.width for cutout in cutouts),
            (canvas_size[1] - 28) / max(cutout.height for cutout in cutouts),
        )
        for cutout in cutouts:
            resized = cutout.resize(
                (round(cutout.width * shared_scale), round(cutout.height * shared_scale)),
                Image.Resampling.LANCZOS,
            )
            frame = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
            frame.alpha_composite(
                resized,
                ((canvas_size[0] - resized.width) // 2, canvas_size[1] - 14 - resized.height),
            )
            frames.append(frame)

    output_dir.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(frames, start=1):
        frame.save(output_dir / f"frame_{index:02d}.png", optimize=True)
    return frames


def split_walk_grid(source_path: Path, output_dir: Path) -> list[Image.Image]:
    sheet = keyed(source_path)
    cutouts = [
        extract_main_subject_with_overflow(sheet, index % 4, index // 4, 4, 3)
        for index in range(12)
    ]
    shared_scale = min(
        (WALK_CANVAS[0] - 24) / max(cutout.width for cutout in cutouts),
        (WALK_CANVAS[1] - 28) / max(cutout.height for cutout in cutouts),
    )
    frames: list[Image.Image] = []
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, cutout in enumerate(cutouts, start=1):
        resized = cutout.resize(
            (round(cutout.width * shared_scale), round(cutout.height * shared_scale)),
            Image.Resampling.LANCZOS,
        )
        frame = Image.new("RGBA", WALK_CANVAS, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            ((WALK_CANVAS[0] - resized.width) // 2, WALK_CANVAS[1] - 14 - resized.height),
        )
        frame.save(output_dir / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def split_fishing_reaction_grid(source_path: Path, output_dir: Path) -> list[Image.Image]:
    """Extract a fixed-position 4x2 reaction sheet without clipping either row."""
    sheet = keyed(source_path)
    cutouts = [
        extract_main_subject_with_overflow(sheet, index % 4, index // 4, 4, 2)
        for index in range(8)
    ]
    shared_scale = min(
        (PET_CANVAS[0] - 24) / max(cutout.width for cutout in cutouts),
        (PET_CANVAS[1] - 40) / max(cutout.height for cutout in cutouts),
    )
    frames: list[Image.Image] = []
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, cutout in enumerate(cutouts, start=1):
        resized = cutout.resize(
            (round(cutout.width * shared_scale), round(cutout.height * shared_scale)),
            Image.Resampling.LANCZOS,
        )
        frame = Image.new("RGBA", PET_CANVAS, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            ((PET_CANVAS[0] - resized.width) // 2, PET_CANVAS[1] - 20 - resized.height),
        )
        frame.save(output_dir / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def prepare_static_assets() -> None:
    specifications = [
        (
            SOURCE_ROOT / "biscuit_side_sitting_chroma.png",
            BISCUIT_ROOT / "home" / "biscuit_side_sitting.png",
            PET_CANVAS,
            (458, 472),
        ),
        (
            SOURCE_ROOT / "biscuit_front_sitting_chroma.png",
            BISCUIT_ROOT / "fishing" / "default" / "biscuit_fishing_default.png",
            PET_CANVAS,
            (452, 472),
        ),
        (
            SOURCE_ROOT / "biscuit_store_portrait_chroma.png",
            BISCUIT_ROOT / "store" / "biscuit_store_portrait.png",
            PET_CANVAS,
            (474, 474),
        ),
        (
            SOURCE_ROOT / "biscuit_sleep_chroma.png",
            BISCUIT_ROOT / "sleep" / "biscuit_sleep.png",
            WIDE_CANVAS,
            (602, 438),
        ),
        (
            SOURCE_ROOT / "biscuit_fishing_failure_chroma.png",
            BISCUIT_ROOT / "fishing" / "failure" / "biscuit_fishing_failure.png",
            PET_CANVAS,
            (452, 472),
        ),
    ]
    for source_path, destination, canvas, maximum in specifications:
        destination.parent.mkdir(parents=True, exist_ok=True)
        normalized_sprite(keyed(source_path), canvas, maximum).save(destination, optimize=True)


def prepare_station() -> None:
    source = keyed(STATION_SOURCE_ROOT / "biscuit_cardboard_station_chroma.png")
    bbox = visible_bbox(source)
    padding = 8
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(source.width, bbox[2] + padding)
    bottom = min(source.height, bbox[3] + padding)
    source.crop((left, top, right, bottom)).save(
        STATION_ROOT / "biscuit_cardboard_station.png",
        optimize=True,
    )


def main() -> None:
    prepare_static_assets()
    split_walk_grid(
        SOURCE_ROOT / "biscuit_walk_left_chroma.png",
        BISCUIT_ROOT / "walk_left",
    )
    split_walk_grid(
        SOURCE_ROOT / "biscuit_walk_right_chroma.png",
        BISCUIT_ROOT / "walk_right",
    )
    split_fixed_grid(
        SOURCE_ROOT / "biscuit_butterfly_chroma.png",
        BISCUIT_ROOT / "desktop" / "butterfly",
        4,
        4,
        PET_CANVAS,
        True,
    )
    split_fixed_grid(
        SOURCE_ROOT / "biscuit_sleep_tail_swing_chroma.png",
        BISCUIT_ROOT / "sleep" / "tail_swing",
        3,
        3,
        WIDE_CANVAS,
        True,
    )
    split_fishing_reaction_grid(
        SOURCE_ROOT / "biscuit_fishing_wink_chroma.png",
        BISCUIT_ROOT / "fishing" / "success_wink",
    )
    prepare_station()
    print("Prepared Biscuit static art, 57 animation frames, and Desktop Station")


if __name__ == "__main__":
    main()
