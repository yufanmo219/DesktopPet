#!/usr/bin/env python3
"""Split 3x3 idle sheets without clipping artwork that crosses a cell edge."""

from collections import deque
from pathlib import Path

from PIL import Image, ImageChops


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SPRITES_ROOT = PROJECT_ROOT / "assets" / "pets" / "current" / "sprites"
SOURCE_SPRITES_ROOT = (
    PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "current" / "sprites"
)
SHEET_SIZE = (1254, 1254)
GRID_SIZE = 3
FRAME_SIZE = SHEET_SIZE[0] // GRID_SIZE
OVERFLOW_MARGIN = 96
FRAME_PADDING = 6
RIGHT_EAR_PATCH = (350, 245, 418, 360)

ANIMATIONS = {
    "desktop_wink": SOURCE_SPRITES_ROOT / "processed" / "desktop_idle_wink_transparent.png",
    "desktop_roll": SOURCE_SPRITES_ROOT / "processed" / "desktop_idle_roll_transparent.png",
    "desktop_biscuit": SOURCE_SPRITES_ROOT / "processed" / "desktop_biscuit_transparent.png",
}


def _connected_components(alpha: Image.Image) -> list[dict]:
    width, height = alpha.size
    alpha_pixels = alpha.load()
    visited = bytearray(width * height)
    components: list[dict] = []
    neighbor_offsets = (
        (-1, -1), (0, -1), (1, -1),
        (-1, 0), (1, 0),
        (-1, 1), (0, 1), (1, 1),
    )

    for y in range(height):
        for x in range(width):
            start_index = y * width + x
            if visited[start_index] or alpha_pixels[x, y] == 0:
                continue
            visited[start_index] = 1
            queue = deque([start_index])
            pixels: list[int] = []
            min_x = max_x = x
            min_y = max_y = y
            sum_x = 0
            sum_y = 0
            while queue:
                pixel_index = queue.popleft()
                pixel_y, pixel_x = divmod(pixel_index, width)
                pixels.append(pixel_index)
                min_x = min(min_x, pixel_x)
                max_x = max(max_x, pixel_x)
                min_y = min(min_y, pixel_y)
                max_y = max(max_y, pixel_y)
                sum_x += pixel_x
                sum_y += pixel_y
                for offset_x, offset_y in neighbor_offsets:
                    neighbor_x = pixel_x + offset_x
                    neighbor_y = pixel_y + offset_y
                    if not (0 <= neighbor_x < width and 0 <= neighbor_y < height):
                        continue
                    neighbor_index = neighbor_y * width + neighbor_x
                    if visited[neighbor_index] or alpha_pixels[neighbor_x, neighbor_y] == 0:
                        continue
                    visited[neighbor_index] = 1
                    queue.append(neighbor_index)
            if len(pixels) >= 64:
                components.append({
                    "pixels": pixels,
                    "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                    "centroid": (sum_x / len(pixels), sum_y / len(pixels)),
                })
    return components


def _extract_cutout_with_overflow(sheet: Image.Image, column: int, row: int) -> Image.Image:
    cell_left = column * FRAME_SIZE
    cell_top = row * FRAME_SIZE
    expanded_left = max(0, cell_left - OVERFLOW_MARGIN)
    expanded_top = max(0, cell_top - OVERFLOW_MARGIN)
    expanded_right = min(sheet.width, cell_left + FRAME_SIZE + OVERFLOW_MARGIN)
    expanded_bottom = min(sheet.height, cell_top + FRAME_SIZE + OVERFLOW_MARGIN)
    expanded = sheet.crop((expanded_left, expanded_top, expanded_right, expanded_bottom))
    components = _connected_components(expanded.getchannel("A"))
    if not components:
        raise ValueError(f"No subject found in cell ({column}, {row})")

    target_x = cell_left + FRAME_SIZE * 0.5 - expanded_left
    target_y = cell_top + FRAME_SIZE * 0.5 - expanded_top
    subject = min(
        components,
        key=lambda component: (
            (component["centroid"][0] - target_x) ** 2
            + (component["centroid"][1] - target_y) ** 2
        ),
    )
    mask_data = bytearray(expanded.width * expanded.height)
    for pixel_index in subject["pixels"]:
        mask_data[pixel_index] = 255
    component_mask = Image.frombytes("L", expanded.size, bytes(mask_data))
    bbox = subject["bbox"]
    cutout = expanded.crop(bbox)
    cutout.putalpha(ImageChops.multiply(cutout.getchannel("A"), component_mask.crop(bbox)))
    return cutout


def _translate_frame(frame: Image.Image, offset_x: int, offset_y: int) -> Image.Image:
    translated = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    translated.alpha_composite(frame, (offset_x, offset_y))
    return translated


def _repair_biscuit_right_ears(frames: list[Image.Image]) -> None:
    # The generated sheet's rightmost column ended at the source-image edge, so
    # frames 3, 6 and 9 lost the tip of the screen-right ear. Their preceding
    # frames have the same locked head pose and provide the complete ear art.
    repairs = {
        2: (1, -7, 1),
        5: (4, -7, 1),
        8: (7, -5, -1),
    }
    for target_index, (donor_index, offset_x, offset_y) in repairs.items():
        target = _translate_frame(frames[target_index], offset_x, offset_y)
        donor_patch = frames[donor_index].crop(RIGHT_EAR_PATCH)
        target.paste(donor_patch, RIGHT_EAR_PATCH[:2])
        frames[target_index] = target


def split_sheet(animation_name: str, sheet_path: Path) -> None:
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.size != SHEET_SIZE:
        raise ValueError(f"{sheet_path} must be {SHEET_SIZE}, got {sheet.size}")

    output_dir = SPRITES_ROOT / animation_name
    output_dir.mkdir(parents=True, exist_ok=True)
    cutouts: list[Image.Image] = []
    for index in range(GRID_SIZE * GRID_SIZE):
        column = index % GRID_SIZE
        row = index // GRID_SIZE
        cutouts.append(_extract_cutout_with_overflow(sheet, column, row))

    available_size = FRAME_SIZE - FRAME_PADDING * 2
    common_scale = min(
        1.0,
        available_size / max(cutout.width for cutout in cutouts),
        available_size / max(cutout.height for cutout in cutouts),
    )
    frames: list[Image.Image] = []
    for cutout in cutouts:
        if common_scale < 1.0:
            cutout = cutout.resize(
                (round(cutout.width * common_scale), round(cutout.height * common_scale)),
                Image.Resampling.LANCZOS,
            )
        frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
        destination_x = (FRAME_SIZE - cutout.width) // 2
        destination_y = FRAME_SIZE - FRAME_PADDING - cutout.height
        frame.alpha_composite(cutout, (destination_x, destination_y))
        frames.append(frame)

    if animation_name == "desktop_biscuit":
        _repair_biscuit_right_ears(frames)

    for index, frame in enumerate(frames):
        if frame.getbbox() is None:
            raise ValueError(f"Frame {index + 1} in {sheet_path} is empty")
        frame.save(output_dir / f"frame_{index + 1:02d}.png", optimize=True)


def main() -> None:
    for animation_name, sheet_path in ANIMATIONS.items():
        split_sheet(animation_name, sheet_path)
        print(f"Prepared 9 fixed-canvas frames for {animation_name}")


if __name__ == "__main__":
    main()
