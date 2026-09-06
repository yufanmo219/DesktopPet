#!/usr/bin/env python3
"""Prepare the approved Maine Coon artwork as transparent Godot assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

from prepare_biscuit_assets import PET_CANVAS, WALK_CANVAS, WIDE_CANVAS, grid_edges


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PET_ROOT = PROJECT_ROOT / "assets" / "pets" / "maine_coon"
SOURCE_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "maine_coon" / "source"
STATION_ROOT = PROJECT_ROOT / "assets" / "ui" / "desktop_station" / "maine_coon"

SLEEP_CELL_X = (28, 404, 781, 1158)
SLEEP_CELL_Y = (22, 524)
SLEEP_CELL_WIDTH = 348
SLEEP_CELL_HEIGHT = 475
SLEEP_REGISTERED_CROP = 348
SLEEP_TARGET_LEFT = 20
SLEEP_TARGET_BOTTOM = 258

# The seventh right-walk source cell has a very pale extended foreleg whose
# outer outline briefly opens into the pale backdrop. Close only its authored
# interior so background extraction cannot hollow the leg out again.
WALK_RIGHT_FORELEG_REPAIR_POLYGONS = {
    6: (
        (228, 165),
        (250, 168),
        (264, 184),
        (278, 204),
        (291, 226),
        (305, 248),
        (327, 266),
        (331, 276),
        (324, 282),
        (311, 279),
        (298, 263),
        (284, 244),
        (271, 226),
        (258, 209),
        (245, 192),
        (232, 181),
    ),
}


def flood_background(
    cell: np.ndarray,
    minimum_luminance: float = 225.0,
    floor_luminance: float | None = None,
    floor_start_ratio: float = 0.65,
) -> np.ndarray:
    """Find the pale generated backdrop connected to the edge of a cell."""
    rgb = cell[:, :, :3].astype(np.float32)
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    warm = (rgb[:, :, 0] - rgb[:, :, 2]) > 2.0
    luminance_floor = np.full(luminance.shape, minimum_luminance, dtype=np.float32)
    if floor_luminance is not None:
        floor_start = round(cell.shape[0] * floor_start_ratio)
        luminance_floor[floor_start:, :] = floor_luminance
    passable = (luminance > luminance_floor) & (warm | (luminance > 249.0))
    height, width = passable.shape
    background = np.zeros_like(passable, dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        for y in (0, height - 1):
            if passable[y, x] and not background[y, x]:
                background[y, x] = True
                queue.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if passable[y, x] and not background[y, x]:
                background[y, x] = True
                queue.append((x, y))

    while queue:
        x, y = queue.popleft()
        for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (
                0 <= next_x < width
                and 0 <= next_y < height
                and passable[next_y, next_x]
                and not background[next_y, next_x]
            ):
                background[next_y, next_x] = True
                queue.append((next_x, next_y))
    return background


def largest_component(mask: np.ndarray) -> np.ndarray:
    """Keep one authored cat and discard shadows or neighboring-cell fragments."""
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    best: list[tuple[int, int]] = []
    for start_y, start_x in zip(*np.where(mask & ~seen)):
        if seen[start_y, start_x]:
            continue
        queue: deque[tuple[int, int]] = deque([(int(start_x), int(start_y))])
        seen[start_y, start_x] = True
        component: list[tuple[int, int]] = []
        while queue:
            x, y = queue.popleft()
            component.append((x, y))
            for next_x, next_y in (
                (x - 1, y),
                (x + 1, y),
                (x, y - 1),
                (x, y + 1),
            ):
                if (
                    0 <= next_x < width
                    and 0 <= next_y < height
                    and mask[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_x, next_y))
        if len(component) > len(best):
            best = component

    result = np.zeros_like(mask, dtype=np.uint8)
    for x, y in best:
        result[y, x] = 255
    return result


def subject_rgba(
    cell: Image.Image,
    crop_to_subject: bool = True,
    background_luminance: float = 225.0,
    floor_luminance: float | None = None,
    floor_start_ratio: float = 0.65,
) -> tuple[Image.Image, tuple[int, int, int, int]]:
    source = np.asarray(cell.convert("RGB"))
    component = largest_component(
        ~flood_background(
            source,
            minimum_luminance=background_luminance,
            floor_luminance=floor_luminance,
            floor_start_ratio=floor_start_ratio,
        )
    )
    # Blur inward from the detected silhouette. Expanding the binary mask first
    # would preserve a one-pixel strip of the baked cream backdrop and create a
    # bright halo in the transparent Desktop companion window.
    alpha = Image.fromarray(component, "L").filter(ImageFilter.GaussianBlur(0.65))
    alpha_array = np.asarray(alpha)
    ys, xs = np.where(alpha_array > 8)
    if xs.size == 0:
        raise ValueError("Artwork cell contains no visible cat")
    bbox = (
        max(0, int(xs.min()) - 2),
        max(0, int(ys.min()) - 2),
        min(source.shape[1], int(xs.max() + 3)),
        min(source.shape[0], int(ys.max() + 3)),
    )
    rgba = cell.convert("RGBA")
    rgba.putalpha(alpha)
    return (rgba.crop(bbox) if crop_to_subject else rgba), bbox


def resize_clean(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    resized = image.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    pixels = np.asarray(resized, dtype=np.uint8).copy()
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def remove_detached_pixels(image: Image.Image) -> Image.Image:
    """Discard isolated backdrop flecks while retaining the cat's soft edge."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    subject = largest_component(pixels[:, :, 3] > 8) > 0
    soft_edge_area = np.asarray(
        Image.fromarray(subject.astype(np.uint8) * 255, "L").filter(
            ImageFilter.MaxFilter(5)
        )
    ) > 0
    # Only sub-threshold antialias pixels may use the two-pixel allowance.
    # A visible yellow island must belong to the main subject component even
    # when an almost invisible alpha bridge happens to touch it.
    keep = subject | ((pixels[:, :, 3] <= 8) & soft_edge_area)
    pixels[~keep] = 0
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def visible_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
    if bbox is None:
        raise ValueError("Artwork contains no visible pixels")
    return bbox


def trim_floor_shadow(image: Image.Image) -> Image.Image:
    """Remove the baked floor shadow while preserving each paw's bottom outline."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    alpha = pixels[:, :, 3]
    rgb = pixels[:, :, :3].astype(np.float32)
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    floor_start = round(image.height * 0.60)

    for x in range(image.width):
        visible_y = np.where(alpha[:, x] > 8)[0]
        if visible_y.size == 0 or visible_y[-1] < floor_start:
            continue

        # Inspect the contiguous bottom run instead of the full visible span.
        # In columns between two legs the cat's body is visible much higher up,
        # so measuring the whole column allowed a thin yellow floor fragment to
        # survive. A real paw remains a deep continuous run; the baked floor is
        # only a few pixels tall.
        bottom_y = int(visible_y[-1])
        run_top_y = bottom_y
        while run_top_y > floor_start and alpha[run_top_y - 1, x] > 8:
            run_top_y -= 1
        if bottom_y - run_top_y + 1 <= 12:
            alpha[run_top_y : bottom_y + 1, x] = 0
            continue

        contour_start = max(floor_start, bottom_y - 16)
        dark_contour = np.where(
            (alpha[contour_start : bottom_y + 1, x] >= 64)
            & (luminance[contour_start : bottom_y + 1, x] < 175.0)
        )[0]
        if dark_contour.size == 0:
            continue
        paw_bottom_y = contour_start + int(dark_contour[-1])
        alpha[paw_bottom_y + 1 :, x] = 0

    pixels[:, :, 3] = alpha
    pixels[alpha == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def normalized_sprite(
    image: Image.Image,
    canvas: tuple[int, int],
    maximum: tuple[int, int],
    bottom_padding: int = 12,
) -> Image.Image:
    cutout = image.crop(visible_bbox(image))
    scale = min(maximum[0] / cutout.width, maximum[1] / cutout.height)
    resized = resize_clean(
        cutout,
        (max(1, round(cutout.width * scale)), max(1, round(cutout.height * scale))),
    )
    output = Image.new("RGBA", canvas, (0, 0, 0, 0))
    output.alpha_composite(
        resized,
        ((canvas[0] - resized.width) // 2, canvas[1] - bottom_padding - resized.height),
    )
    return output


def save_normalized(
    image: Image.Image,
    destination: Path,
    canvas: tuple[int, int],
    maximum: tuple[int, int],
    bottom_padding: int = 12,
) -> Image.Image:
    destination.parent.mkdir(parents=True, exist_ok=True)
    output = normalized_sprite(image, canvas, maximum, bottom_padding)
    output.save(destination, optimize=True)
    return output


def split_shared_bottom_aligned(
    source_path: Path,
    columns: int,
    rows: int,
    destination: Path,
    canvas: tuple[int, int],
    side_padding: int,
    bottom_padding: int,
    background_luminance: float = 225.0,
    floor_luminance: float | None = None,
    floor_start_ratio: float = 0.65,
    remove_floor_shadow: bool = False,
    foreground_repair_polygons: dict[int, tuple[tuple[int, int], ...]] | None = None,
) -> list[Image.Image]:
    sheet = Image.open(source_path).convert("RGB")
    x_edges = grid_edges(sheet.width, columns)
    y_edges = grid_edges(sheet.height, rows)
    cutouts = []
    for row in range(rows):
        for column in range(columns):
            frame_index = row * columns + column
            cell = sheet.crop(
                (x_edges[column], y_edges[row], x_edges[column + 1], y_edges[row + 1])
            )
            extracted = subject_rgba(
                cell,
                crop_to_subject=False,
                background_luminance=background_luminance,
                floor_luminance=floor_luminance,
                floor_start_ratio=floor_start_ratio,
            )[0]
            repair_alpha = None
            if foreground_repair_polygons and frame_index in foreground_repair_polygons:
                repair_alpha = Image.new("L", cell.size, 0)
                ImageDraw.Draw(repair_alpha).polygon(
                    foreground_repair_polygons[frame_index],
                    fill=255,
                )
                repair_alpha = repair_alpha.filter(ImageFilter.GaussianBlur(0.65))
                extracted.putalpha(
                    ImageChops.lighter(extracted.getchannel("A"), repair_alpha)
                )
            cutout_bbox = visible_bbox(extracted)
            cutout = extracted.crop(cutout_bbox)
            if remove_floor_shadow:
                trimmed = trim_floor_shadow(cutout)
                # Floor-shadow trimming follows dark paw contours. In the
                # repaired pale foreleg, an internal gray stroke can resemble
                # that contour, so restore the authored leg after trimming.
                if repair_alpha is not None:
                    cutout = Image.composite(
                        cutout,
                        trimmed,
                        repair_alpha.crop(cutout_bbox),
                    )
                else:
                    cutout = trimmed
            cutouts.append(cutout)

    scale = min(
        (canvas[0] - side_padding * 2) / max(item.width for item in cutouts),
        (canvas[1] - bottom_padding - 12) / max(item.height for item in cutouts),
    )
    destination.mkdir(parents=True, exist_ok=True)
    frames = []
    for index, cutout in enumerate(cutouts, start=1):
        resized = resize_clean(
            cutout,
            (max(1, round(cutout.width * scale)), max(1, round(cutout.height * scale))),
        )
        frame = Image.new("RGBA", canvas, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            ((canvas[0] - resized.width) // 2, canvas[1] - bottom_padding - resized.height),
        )
        frame = remove_detached_pixels(frame)
        frame.save(destination / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def split_registered_reaction(
    source_path: Path,
    destination: Path,
    baseline_aligned: bool,
    scale: float = 0.92,
    target_bottom: int = 462,
    mirror_output: bool = False,
) -> list[Image.Image]:
    sheet = Image.open(source_path).convert("RGB")
    x_edges = grid_edges(sheet.width, 4)
    y_edges = grid_edges(sheet.height, 2)
    source_anchor_x = (x_edges[1] - x_edges[0]) // 2
    source_baseline_y = 495
    destination.mkdir(parents=True, exist_ok=True)
    frames = []
    for index in range(8):
        column = index % 4
        row = index // 4
        cell = sheet.crop(
            (x_edges[column], y_edges[row], x_edges[column + 1], y_edges[row + 1])
        )
        cutout, bbox = subject_rgba(cell)
        resized = resize_clean(
            cutout,
            (max(1, round(cutout.width * scale)), max(1, round(cutout.height * scale))),
        )
        frame = Image.new("RGBA", PET_CANVAS, (0, 0, 0, 0))
        paste_x = 256 + round((bbox[0] - source_anchor_x) * scale)
        paste_y = (
            target_bottom + round((bbox[1] - source_baseline_y) * scale)
            if baseline_aligned
            else target_bottom - resized.height
        )
        frame.alpha_composite(resized, (paste_x, paste_y))
        if mirror_output:
            frame = ImageOps.mirror(frame)
        frame.save(destination / f"frame_{index + 1:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def edge_crop(array: np.ndarray, left: int, top: int, size: int) -> np.ndarray:
    padding = size
    padded = np.pad(array, ((padding, padding), (padding, padding), (0, 0)), mode="edge")
    return padded[
        top + padding : top + padding + size,
        left + padding : left + padding + size,
    ]


def prepare_sleep() -> None:
    sheet = np.asarray(Image.open(SOURCE_ROOT / "maine_coon_sleep_paw_lick_sheet.png").convert("RGB"))
    destination = PET_ROOT / "sleep" / "paw_lick"
    destination.mkdir(parents=True, exist_ok=True)
    frames = []
    for row, cell_y in enumerate(SLEEP_CELL_Y):
        for column, cell_x in enumerate(SLEEP_CELL_X):
            cell = sheet[
                cell_y : cell_y + SLEEP_CELL_HEIGHT,
                cell_x : cell_x + SLEEP_CELL_WIDTH,
            ]
            rgb = cell.astype(np.float32)
            luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
            ys, xs = np.where(luminance < 215.0)
            crop_left = int(xs.min()) - SLEEP_TARGET_LEFT
            crop_top = int(ys.max() + 1) - SLEEP_TARGET_BOTTOM
            registered = Image.fromarray(
                edge_crop(cell, crop_left, crop_top, SLEEP_REGISTERED_CROP)
            )
            transparent, _bbox = subject_rgba(registered, crop_to_subject=False)
            transparent = resize_clean(transparent, PET_CANVAS)
            frame = Image.new("RGBA", WIDE_CANVAS, (0, 0, 0, 0))
            frame.alpha_composite(transparent, ((WIDE_CANVAS[0] - PET_CANVAS[0]) // 2, 0))
            frame.save(
                destination / f"frame_{row * 4 + column + 1:02d}.png",
                optimize=True,
            )
            frames.append(frame)
    frames[-1].save(PET_ROOT / "sleep" / "maine_coon_sleep.png", optimize=True)


def prepare_static_assets() -> None:
    concept = Image.open(SOURCE_ROOT / "maine_coon_pose_sheet.png").convert("RGB")
    front = trim_floor_shadow(subject_rgba(concept.crop((80, 10, 620, 725)))[0])
    side = trim_floor_shadow(subject_rgba(concept.crop((630, 10, 1165, 745)))[0])
    save_normalized(
        side,
        PET_ROOT / "home" / "maine_coon_side_sitting.png",
        PET_CANVAS,
        (452, 472),
    )
    save_normalized(
        front,
        PET_ROOT / "fishing" / "default" / "maine_coon_fishing_default.png",
        PET_CANVAS,
        (438, 472),
    )
    save_normalized(
        side,
        PET_ROOT / "store" / "maine_coon_store_detail.png",
        PET_CANVAS,
        (440, 462),
    )
    portrait = subject_rgba(Image.open(SOURCE_ROOT / "maine_coon_head_portrait.png"))[0]
    save_normalized(
        portrait,
        PET_ROOT / "store" / "maine_coon_store_portrait.png",
        PET_CANVAS,
        (474, 474),
        18,
    )
    failure = subject_rgba(Image.open(SOURCE_ROOT / "maine_coon_fishing_failure.png"))[0]
    save_normalized(
        failure,
        PET_ROOT / "fishing" / "failure" / "maine_coon_fishing_failure.png",
        PET_CANVAS,
        (452, 472),
    )


def prepare_station() -> None:
    source = Image.open(SOURCE_ROOT / "maine_coon_forest_wool_station.png").convert("RGBA")
    bbox = visible_bbox(source)
    padding = 10
    crop = source.crop(
        (
            max(0, bbox[0] - padding),
            max(0, bbox[1] - padding),
            min(source.width, bbox[2] + padding),
            min(source.height, bbox[3] + padding),
        )
    )
    STATION_ROOT.mkdir(parents=True, exist_ok=True)
    crop.save(STATION_ROOT / "maine_coon_forest_wool_station.png", optimize=True)


def main() -> None:
    prepare_static_assets()
    prepare_sleep()
    split_shared_bottom_aligned(
        SOURCE_ROOT / "maine_coon_walk_left_sheet.png",
        4,
        3,
        PET_ROOT / "walk_left",
        WALK_CANVAS,
        12,
        12,
        225.0,
        180.0,
        0.65,
        True,
    )
    split_shared_bottom_aligned(
        SOURCE_ROOT / "maine_coon_walk_right_sheet.png",
        4,
        3,
        PET_ROOT / "walk_right",
        WALK_CANVAS,
        12,
        12,
        225.0,
        180.0,
        0.65,
        True,
        WALK_RIGHT_FORELEG_REPAIR_POLYGONS,
    )
    split_registered_reaction(
        SOURCE_ROOT / "maine_coon_fishing_success_sheet.png",
        PET_ROOT / "fishing" / "success",
        True,
    )
    split_registered_reaction(
        SOURCE_ROOT / "maine_coon_double_click_nuzzle_sheet.png",
        PET_ROOT / "desktop" / "nuzzle",
        False,
        1.10,
        500,
        True,
    )
    prepare_station()
    print(
        "Prepared Maine Coon Home/store/fishing art, 8 sleep frames, "
        "24 walking frames, 8 success frames, 8 double-click frames, and Station"
    )


if __name__ == "__main__":
    main()
