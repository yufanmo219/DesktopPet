#!/usr/bin/env python3
"""Prepare the approved Siamese previews as transparent fixed-canvas assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from prepare_biscuit_assets import PET_CANVAS, WALK_CANVAS, WIDE_CANVAS, grid_edges
from prepare_golden_munchkin_assets import (
    component_cutout,
    connected_components,
    normalized_sprite,
    resize_clean,
    save_image,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PET_ROOT = PROJECT_ROOT / "assets" / "pets" / "siamese"
SOURCE_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "siamese" / "source"

SUCCESS_X_OFFSETS = [4, 42, 81, -5, 42, 88]
SUCCESS_Y_OFFSETS = [0, 0, 0, 70, 70, 70]
SUCCESS_SOURCE_ORDER = [0, 1, 2, 3, 4, 4, 5, 5]

TREAT_X_RANGES = [(0, 378), (389, 762), (774, 1145), (1157, 1536)]
TREAT_Y_RANGES = [(0, 337), (348, 679), (690, 1024)]
TREAT_PAW_MEDIANS = [157, 156, 153, 153, 156, 154, 154, 153, 154, 152, 152, 149]
TREAT_BASELINES = [332, 332, 332, 332, 327, 327, 327, 327, 324, 324, 324, 324]
TREAT_PREVIEW_DURATIONS_MS = [360, 220, 270, 100, 125, 90, 125, 90, 125, 130, 250, 650]


def siamese_backdrop_pixels(source: np.ndarray) -> np.ndarray:
    """Return every pixel close to the generated cream backdrop."""
    rgb = source[:, :, :3].astype(np.float32)
    border = np.concatenate(
        (rgb[0, :, :], rgb[-1, :, :], rgb[:, 0, :], rgb[:, -1, :]), axis=0
    )
    backdrop = np.median(border, axis=0)
    distance = np.sqrt(np.sum((rgb - backdrop) ** 2, axis=2))
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    return (distance < 12.0) & (luminance > 214.0)


def siamese_background(source: np.ndarray) -> np.ndarray:
    """Flood only edge-connected pixels close to the cream backdrop.

    The Siamese's body is much paler than the other cats, so a luminance-only
    key can leak through its cream fur. Comparing against the actual border
    color keeps the fur opaque while still following the backdrop gradient.
    """
    passable = siamese_backdrop_pixels(source)
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


def siamese_main_cutout(source: Image.Image) -> Image.Image:
    components = connected_components(
        ~siamese_background(np.asarray(source.convert("RGB"))), 200
    )
    if not components:
        raise ValueError("Siamese artwork contains no visible subject")
    return component_cutout(source, max(components, key=lambda item: item["size"]))


def trim_pearl_floor_shadow(image: Image.Image) -> Image.Image:
    """Remove Pearl's pale generated floor shadow without moving the sprite.

    Pearl's cream coat is close to the source backdrop, so removing every pale
    pixel would also erase real fur.  Instead, find the last trustworthy piece
    of the cat in each column (brown outline/fur or a chromatic edge), keep two
    antialiasing rows below it, and clear only the residue farther down.
    """
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    alpha = pixels[:, :, 3]
    visible = alpha > 8
    visible_bbox = Image.fromarray((visible * 255).astype(np.uint8), "L").getbbox()
    if visible_bbox is None:
        raise ValueError("Pearl floor-shadow cleanup received an empty image")

    rgb = pixels[:, :, :3].astype(np.float32)
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    subject_contour = (alpha >= 64) & ((luminance < 160.0) | (chroma > 90.0))
    floor_start = round(visible_bbox[1] + (visible_bbox[3] - visible_bbox[1]) * 0.50)

    for x in range(image.width):
        visible_y = np.where(visible[:, x])[0]
        if visible_y.size == 0 or visible_y[-1] < floor_start:
            continue
        contour_y = np.where(subject_contour[:, x])[0]
        if contour_y.size == 0:
            alpha[visible_y[visible_y >= floor_start], x] = 0
            continue
        alpha[int(contour_y[-1]) + 3 :, x] = 0

    pixels[:, :, 3] = alpha
    pixels[alpha == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def siamese_walk_cutout(source: Image.Image) -> Image.Image:
    """Extract a walking cat without retaining backdrop trapped between legs."""
    rgb = np.asarray(source.convert("RGB"))
    edge_background = siamese_background(rgb)
    mask = ~edge_background
    enclosed_backdrop = siamese_backdrop_pixels(rgb) & ~edge_background
    # Only clear sizeable trapped backdrop regions. Individual cream-fur
    # highlights can match the backdrop color, but form tiny textured islands.
    for component in connected_components(enclosed_backdrop, 80):
        for x, y in component["pixels"]:
            mask[y, x] = False
    # Close only hairline transparency leaks inside the pale coat. Large real
    # gaps between the legs remain open.
    mask = np.asarray(
        Image.fromarray((mask * 255).astype(np.uint8), "L")
        .filter(ImageFilter.MaxFilter(5))
        .filter(ImageFilter.MinFilter(5))
    ) > 127
    neighbor_count = np.zeros(mask.shape, dtype=np.uint8)
    padded = np.pad(mask, 3, mode="constant", constant_values=False)
    for offset_y in range(7):
        for offset_x in range(7):
            neighbor_count += padded[
                offset_y : offset_y + mask.shape[0],
                offset_x : offset_x + mask.shape[1],
            ]
    mask[(~mask) & (neighbor_count >= 32)] = True
    components = connected_components(mask, 200)
    if not components:
        raise ValueError("Siamese walk artwork contains no visible subject")
    return component_cutout(source, max(components, key=lambda item: item["size"]))


def clear_side_pose_interior_backdrop(
    side: Image.Image,
    subject: dict,
    enclosed_backdrop: np.ndarray,
) -> Image.Image:
    """Clear the two backdrop pockets enclosed by Pearl's seated silhouette."""
    left, top, right, bottom = subject["bbox"]
    holes = np.zeros((side.height, side.width), dtype=np.uint8)

    # The narrow opening between the front leg and rear paw is an exact patch
    # of the source backdrop.  Select that enclosed component instead of using
    # a broad pale-color key that could eat into Pearl's cream belly.
    for component in connected_components(enclosed_backdrop, 100):
        centroid_x, centroid_y = component["centroid"]
        if not (
            component["size"] >= 500
            and left <= centroid_x < left + (right - left) * 0.45
            and top + (bottom - top) * 0.65 < centroid_y < bottom
        ):
            continue
        for source_x, source_y in component["pixels"]:
            holes[source_y - top, source_x - left] = 255

    # The tail/body opening contains a warmer baked floor shadow as well as the
    # backdrop.  Bound the authored gap, then flood only its connected pale
    # pixels so the brown tail and rear paw remain untouched.
    tail_region = Image.new("L", side.size, 0)
    ImageDraw.Draw(tail_region).polygon(
        [
            (220, 838),
            (300, 838),
            (370, 836),
            (430, 835),
            (485, 842),
            (525, 852),
            (520, 870),
            (490, 875),
            (455, 872),
            (420, 872),
            (380, 878),
            (335, 888),
            (290, 902),
            (240, 910),
            (220, 910),
        ],
        fill=255,
    )
    pixels = np.asarray(side.convert("RGBA"), dtype=np.uint8)
    rgb = pixels[:, :, :3].astype(np.float32)
    alpha = pixels[:, :, 3]
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    tail_candidates = (
        (np.asarray(tail_region) > 0)
        & (alpha > 8)
        & (luminance > 135.0)
        & (chroma < 110.0)
    )
    tail_components = connected_components(tail_candidates, 1)
    tail_seed = (450, 850)
    selected_tail = next(
        (component for component in tail_components if tail_seed in component["pixels"]),
        None,
    )
    if selected_tail is None:
        raise ValueError("Could not find Pearl's enclosed tail/body backdrop")
    for gap_x, gap_y in selected_tail["pixels"]:
        holes[gap_y, gap_x] = 255

    # Extend the transparent holes a single pixel into the old cream fringe,
    # then restore a soft antialiased edge at the real fur contour.
    hole_alpha = (
        Image.fromarray(holes, "L")
        .filter(ImageFilter.MaxFilter(3))
        .filter(ImageFilter.GaussianBlur(0.65))
    )
    cleaned = pixels.copy()
    cleaned_alpha = cleaned[:, :, 3].astype(np.float32)
    cleaned[:, :, 3] = np.clip(
        cleaned_alpha * (1.0 - np.asarray(hole_alpha, dtype=np.float32) / 255.0),
        0,
        255,
    ).astype(np.uint8)
    cleaned[cleaned[:, :, 3] == 0, :3] = 0
    return Image.fromarray(cleaned, "RGBA")


def two_pose_cutouts(sheet: Image.Image) -> tuple[Image.Image, Image.Image]:
    """Return the two largest cats ordered front pose, then side pose."""
    rgb = np.asarray(sheet.convert("RGB"))
    background = siamese_background(rgb)
    components = connected_components(~background, 1000)
    subjects = sorted(components, key=lambda item: item["size"], reverse=True)[:2]
    if len(subjects) != 2:
        raise ValueError(f"Expected two Siamese poses, found {len(subjects)}")
    subjects.sort(key=lambda item: item["centroid"][0])
    front = component_cutout(sheet, subjects[0])
    side = component_cutout(sheet, subjects[1])
    side = clear_side_pose_interior_backdrop(
        side,
        subjects[1],
        siamese_backdrop_pixels(rgb) & ~background,
    )
    return front, side


def prepare_static_art() -> None:
    poses = Image.open(SOURCE_ROOT / "siamese_pose_sheet.png").convert("RGB")
    front, side = two_pose_cutouts(poses)
    portrait = siamese_main_cutout(Image.open(SOURCE_ROOT / "siamese_head_portrait.png"))
    sleeping = siamese_main_cutout(Image.open(SOURCE_ROOT / "siamese_sleep.png"))
    failure = siamese_main_cutout(Image.open(SOURCE_ROOT / "siamese_fishing_failure.png"))

    idle = trim_pearl_floor_shadow(normalized_sprite(side, PET_CANVAS, (462, 480)))
    fishing_default = trim_pearl_floor_shadow(
        normalized_sprite(front, PET_CANVAS, (444, 480))
    )
    store_portrait = trim_pearl_floor_shadow(
        normalized_sprite(portrait, PET_CANVAS, (470, 470), 18)
    )
    sleep = trim_pearl_floor_shadow(
        normalized_sprite(sleeping, WIDE_CANVAS, (612, 450), 18)
    )
    fishing_failure = trim_pearl_floor_shadow(
        normalized_sprite(failure, PET_CANVAS, (450, 480))
    )

    save_image(idle, PET_ROOT / "home" / "siamese_side_sitting.png")
    save_image(idle, PET_ROOT / "store" / "siamese_store_detail.png")
    save_image(store_portrait, PET_ROOT / "store" / "siamese_store_portrait.png")
    save_image(sleep, PET_ROOT / "sleep" / "siamese_sleep.png")
    save_image(
        fishing_default,
        PET_ROOT / "fishing" / "default" / "siamese_fishing_default.png",
    )
    save_image(
        fishing_failure,
        PET_ROOT / "fishing" / "failure" / "siamese_fishing_failure.png",
    )


def heal_vertical_dividers(image: Image.Image) -> Image.Image:
    """Inpaint thin dark panel-divider artifacts that cross pale torso fur."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    rgb = pixels[:, :, :3].astype(np.float32)
    alpha = pixels[:, :, 3]
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    for x in range(5, image.width - 5):
        candidate = (
            (alpha[:, x] > 50)
            & (alpha[:, x - 4] > 160)
            & (alpha[:, x + 4] > 160)
            & (luminance[:, x] < 135.0)
            & (luminance[:, x - 4] > 155.0)
            & (luminance[:, x + 4] > 155.0)
        )
        marked_y = np.where(candidate)[0]
        if marked_y.size < 20 or marked_y[-1] - marked_y[0] < 30:
            continue
        top = max(0, int(marked_y[0]) - 2)
        bottom = min(image.height, int(marked_y[-1]) + 3)
        fill_rows = (
            (alpha[top:bottom, x - 4] > 160)
            & (alpha[top:bottom, x + 4] > 160)
            & (luminance[top:bottom, x - 4] > 150.0)
            & (luminance[top:bottom, x + 4] > 150.0)
        )
        for fill_x in range(x - 2, x + 3):
            mix = (fill_x - (x - 4)) / 8.0
            blended = (
                pixels[top:bottom, x - 4].astype(np.float32) * (1.0 - mix)
                + pixels[top:bottom, x + 4].astype(np.float32) * mix
            )
            pixels[top:bottom, fill_x][fill_rows] = np.clip(
                blended[fill_rows], 0, 255
            ).astype(np.uint8)
    return Image.fromarray(pixels, "RGBA")


def heal_alpha_pinholes(image: Image.Image) -> Image.Image:
    """Fill small enclosed transparency leaks with neighboring fur colors."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    weak_alpha = pixels[:, :, 3] < 245
    height, width = weak_alpha.shape

    # Mark every weak-alpha pixel connected to the outside. Those pixels are
    # the intentional antialiased silhouette and must remain untouched.
    outside = np.zeros_like(weak_alpha, dtype=bool)
    queue: deque[tuple[int, int]] = deque()
    for x in range(width):
        for y in (0, height - 1):
            if weak_alpha[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((x, y))
    for y in range(height):
        for x in (0, width - 1):
            if weak_alpha[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if (
                0 <= next_x < width
                and 0 <= next_y < height
                and weak_alpha[next_y, next_x]
                and not outside[next_y, next_x]
            ):
                outside[next_y, next_x] = True
                queue.append((next_x, next_y))

    enclosed = weak_alpha & ~outside
    repair = np.zeros_like(enclosed, dtype=bool)
    for component in connected_components(enclosed, 1):
        left, top, right, bottom = component["bbox"]
        if (
            component["size"] > 700
            or right - left > 35
            or bottom - top > 35
        ):
            continue
        for component_x, component_y in component["pixels"]:
            repair[component_y, component_x] = True

    # Grow surrounding opaque fur inward one pixel at a time. This restores
    # the natural local color instead of leaving a flat cream patch in the hole.
    known = (pixels[:, :, 3] >= 245) & ~repair
    remaining = repair.copy()
    for _iteration in range(50):
        if not remaining.any():
            break
        color_sum = np.zeros((height, width, 3), dtype=np.float32)
        neighbor_count = np.zeros((height, width), dtype=np.uint8)
        for offset_x, offset_y in (
            (-1, 0),
            (1, 0),
            (0, -1),
            (0, 1),
            (-1, -1),
            (1, -1),
            (-1, 1),
            (1, 1),
        ):
            destination_y = slice(max(0, offset_y), min(height, height + offset_y))
            destination_x = slice(max(0, offset_x), min(width, width + offset_x))
            source_y = slice(max(0, -offset_y), min(height, height - offset_y))
            source_x = slice(max(0, -offset_x), min(width, width - offset_x))
            shifted_known = np.zeros_like(known, dtype=bool)
            shifted_rgb = np.zeros((height, width, 3), dtype=np.float32)
            shifted_known[destination_y, destination_x] = known[source_y, source_x]
            shifted_rgb[destination_y, destination_x] = pixels[source_y, source_x, :3]
            color_sum += shifted_rgb * shifted_known[:, :, None]
            neighbor_count += shifted_known
        fill = remaining & (neighbor_count > 0)
        pixels[fill, :3] = (
            color_sum[fill] / neighbor_count[fill, None]
        ).astype(np.uint8)
        pixels[fill, 3] = 255
        known[fill] = True
        remaining[fill] = False
    return Image.fromarray(pixels, "RGBA")


def heal_dark_specks(image: Image.Image) -> Image.Image:
    """Replace isolated divider/speck pixels surrounded by much lighter fur."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    median = np.asarray(image.convert("RGBA").filter(ImageFilter.MedianFilter(9)))
    rgb = pixels[:, :, :3].astype(np.float32)
    median_rgb = median[:, :, :3].astype(np.float32)
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    median_luminance = (
        0.2126 * median_rgb[:, :, 0]
        + 0.7152 * median_rgb[:, :, 1]
        + 0.0722 * median_rgb[:, :, 2]
    )
    repair = (
        (pixels[:, :, 3] > 30)
        & (median[:, :, 3] > 220)
        & (median_luminance > 105.0)
        & (luminance + 65.0 < median_luminance)
    )
    pixels[repair] = median[repair]
    return Image.fromarray(pixels, "RGBA")


def repair_left_walk_frame_two(image: Image.Image) -> Image.Image:
    """Replace the authored orange paw smear with the same leg's brown fur."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    rgb = pixels[:, :, :3].astype(np.float32)
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    last_y = min(300, image.height)
    for y in range(238, last_y):
        if y <= 270:
            center = 104.0 - float(y - 240) * 0.25
        elif y <= 280:
            center = 96.5 - float(y - 270) * 1.05
        elif y <= 290:
            center = 86.0 - float(y - 280) * 0.15
        else:
            center = 84.5 + float(y - 290) * 0.30
        center_x = round(center)
        brown_fur = (
            (pixels[y, :, 3] > 8)
            & ((luminance[y] < 165.0) | (chroma[y] > 90.0))
        )
        left_candidates = np.where(brown_fur[45 : min(center_x + 1, 110)])[0]
        if left_candidates.size == 0:
            continue
        left_x = int(left_candidates[0]) + 45
        right_x = min(image.width - 1, 2 * center_x - left_x)
        for x in range(center_x + 1, right_x + 1):
            pixels[y, x] = pixels[y, 2 * center_x - x]
        pixels[y, right_x + 1 : min(135, image.width)] = 0
    return Image.fromarray(pixels, "RGBA")


def remove_walk_floor_artifacts(
    image: Image.Image,
    repair_red_smudge: bool = False,
) -> Image.Image:
    """Remove only the authored ground strip beneath a walking Pearl."""
    cleaned = repair_left_walk_frame_two(image) if repair_red_smudge else image
    cleaned = heal_vertical_dividers(cleaned)
    pixels = np.asarray(cleaned.convert("RGBA"), dtype=np.uint8).copy()
    rgb = pixels[:, :, :3].astype(np.float32)
    alpha = pixels[:, :, 3]
    y = np.indices((cleaned.height, cleaned.width))[0]
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    pale_floor = (
        (y > round(cleaned.height * 0.88))
        & (alpha > 8)
        & (luminance > 170.0)
        & (chroma < 85.0)
    )
    pixels[pale_floor] = 0
    pixels[pixels[:, :, 3] == 0, :3] = 0
    components = connected_components(pixels[:, :, 3] > 8, 1)
    if not components:
        raise ValueError("Walk cleanup removed the Siamese")
    subject = max(components, key=lambda item: item["size"])
    keep = np.zeros((cleaned.height, cleaned.width), dtype=bool)
    for component_x, component_y in subject["pixels"]:
        keep[component_y, component_x] = True
    pixels[~keep] = 0
    return Image.fromarray(pixels, "RGBA").crop(subject["bbox"])


def prepare_walk(source_name: str, destination_name: str) -> None:
    sheet = Image.open(SOURCE_ROOT / source_name).convert("RGB")
    edges = grid_edges(sheet.width, 4)
    cutouts = []
    for column in range(4):
        cell = sheet.crop((edges[column], 0, edges[column + 1], sheet.height))
        cutouts.append(
            remove_walk_floor_artifacts(
                siamese_walk_cutout(cell),
                destination_name == "walk_left" and column == 1,
            )
        )

    shared_scale = min(
        (WALK_CANVAS[0] - 24) / max(item.width for item in cutouts),
        (WALK_CANVAS[1] - 28) / max(item.height for item in cutouts),
    )
    for index, cutout in enumerate(cutouts, start=1):
        resized = resize_clean(
            cutout,
            (
                max(1, round(cutout.width * shared_scale)),
                max(1, round(cutout.height * shared_scale)),
            ),
        )
        frame = Image.new("RGBA", WALK_CANVAS, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            ((WALK_CANVAS[0] - resized.width) // 2, WALK_CANVAS[1] - 14 - resized.height),
        )
        frame = heal_alpha_pinholes(
            heal_dark_specks(heal_vertical_dividers(frame))
        )
        save_image(frame, PET_ROOT / destination_name / f"frame_{index:02d}.png")


def selected_components_rgba(cell: Image.Image, keep_props: bool) -> Image.Image:
    """Key a cream cell while preserving the separate pink treat when requested."""
    rgb = np.asarray(cell.convert("RGB"))
    components = connected_components(~siamese_background(rgb), 20)
    if not components:
        raise ValueError("Animation cell contains no visible subject")
    largest = max(components, key=lambda item: item["size"])
    selected = [largest]
    if keep_props:
        for component in components:
            if component is largest or component["size"] < 100:
                continue
            sample = np.asarray([rgb[y, x] for x, y in component["pixels"]], dtype=np.float32)
            luminance = float(
                np.mean(0.2126 * sample[:, 0] + 0.7152 * sample[:, 1] + 0.0722 * sample[:, 2])
            )
            chroma = float(np.mean(sample.max(axis=1) - sample.min(axis=1)))
            if luminance < 195.0 or chroma > 28.0:
                selected.append(component)

    mask = np.zeros((cell.height, cell.width), dtype=np.uint8)
    for component in selected:
        for x, y in component["pixels"]:
            mask[y, x] = 255
    alpha = Image.fromarray(mask, "L").filter(ImageFilter.GaussianBlur(0.65))
    rgba = cell.convert("RGBA")
    rgba.putalpha(alpha)
    pixels = np.asarray(rgba, dtype=np.uint8).copy()
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def prepare_fishing_success() -> None:
    sheet = Image.open(SOURCE_ROOT / "siamese_fishing_success_sheet.png").convert("RGB")
    x_edges = grid_edges(sheet.width, 3)
    y_ranges = [(0, 594), (594, sheet.height)]
    registered = []
    for index in range(6):
        row = index // 3
        column = index % 3
        cell = sheet.crop(
            (x_edges[column], y_ranges[row][0], x_edges[column + 1], y_ranges[row][1])
        )
        keyed = selected_components_rgba(cell, False)
        frame = Image.new("RGBA", (468, 594), (0, 0, 0, 0))
        frame.alpha_composite(
            keyed,
            (SUCCESS_X_OFFSETS[index], SUCCESS_Y_OFFSETS[index]),
        )
        registered.append(frame)

    scale = min((PET_CANVAS[0] - 24) / 468.0, (PET_CANVAS[1] - 20) / 594.0)
    resized_size = (round(468 * scale), round(594 * scale))
    destination = PET_ROOT / "fishing" / "success"
    for output_index, source_index in enumerate(SUCCESS_SOURCE_ORDER, start=1):
        resized = resize_clean(registered[source_index], resized_size)
        frame = Image.new("RGBA", PET_CANVAS, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            (round(256 - 284 * scale), round(500 - 586 * scale)),
        )
        frame = trim_pearl_floor_shadow(frame)
        save_image(frame, destination / f"frame_{output_index:02d}.png")


def alpha_component_layer(image: Image.Image, component: dict) -> Image.Image:
    """Keep one alpha component without changing its registered canvas position."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    keep = np.zeros((image.height, image.width), dtype=bool)
    for x, y in component["pixels"]:
        keep[y, x] = True
    pixels[~keep] = 0
    return Image.fromarray(pixels, "RGBA")


def clean_treat_layer(image: Image.Image) -> Image.Image:
    """Remove cream floor residue and pull the alpha edge inside the subject."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    rgb = pixels[:, :, :3].astype(np.float32)
    alpha = pixels[:, :, 3]
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    y = np.indices((image.height, image.width))[0]
    floor = (
        (y > round(image.height * 0.88))
        & (alpha > 8)
        & (luminance > 170.0)
        & (chroma < 95.0)
    )
    alpha[floor] = 0
    inward_alpha = (
        Image.fromarray(alpha, "L")
        .filter(ImageFilter.MinFilter(3))
        .filter(ImageFilter.GaussianBlur(0.45))
    )
    pixels[:, :, 3] = np.asarray(inward_alpha, dtype=np.uint8)
    pixels[pixels[:, :, 3] < 4] = 0
    return Image.fromarray(pixels, "RGBA")


def pink_tube_mask(image: Image.Image) -> np.ndarray:
    """Find the large pink tube while ignoring the cat's much smaller tongue."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8)
    red = pixels[:, :, 0].astype(np.int16)
    green = pixels[:, :, 1].astype(np.int16)
    blue = pixels[:, :, 2].astype(np.int16)
    x = np.indices((image.height, image.width))[1]
    pink = (
        (pixels[:, :, 3] > 8)
        & (x > round(image.width * 0.52))
        & (red > 185)
        & (green > 105)
        & (blue > 125)
        & (red - green > 25)
        & (red - green < 125)
        & (red - blue < 80)
    )
    components = []
    for component in connected_components(pink, 30):
        left, top, right, bottom = component["bbox"]
        if (right - left) >= max(70, round((bottom - top) * 1.8)):
            components.append(component)
    if not components:
        raise ValueError("Treat frame contains no detectable pink tube")
    tube = max(components, key=lambda component: component["size"])
    mask = np.zeros((image.height, image.width), dtype=bool)
    for component_x, component_y in tube["pixels"]:
        mask[component_y, component_x] = True
    return mask


def pink_tube_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    mask = pink_tube_mask(image)
    bbox = Image.fromarray((mask * 255).astype(np.uint8), "L").getbbox()
    if bbox is None:
        raise ValueError("Treat frame contains no detectable pink tube")
    return bbox


def fixed_treat_layer(registered_frames: list[Image.Image]) -> Image.Image:
    """Extract one complete lick-contact treat and keep it fixed in every beat."""
    source = registered_frames[3]
    source_pixels = np.asarray(source.convert("RGBA"), dtype=np.uint8).copy()
    tube_seed = pink_tube_mask(source)
    tube_region = np.asarray(
        Image.fromarray((tube_seed * 255).astype(np.uint8), "L").filter(
            ImageFilter.MaxFilter(17)
        )
    ) > 0
    source_pixels[~tube_region] = 0
    tube_bbox = pink_tube_bbox(source)
    # Do not retain the tongue/cheek immediately beside the tube's end cap.
    source_pixels[:, : max(0, tube_bbox[0] - 6)] = 0
    template = clean_treat_layer(Image.fromarray(source_pixels, "RGBA"))
    fixed = Image.new("RGBA", source.size, (0, 0, 0, 0))
    fixed.alpha_composite(template, (-6, 0))
    return fixed


def fixed_treat_body(registered_frames: list[Image.Image]) -> Image.Image:
    """Use the exact same torso, legs, paws, hips, and tail in every frame."""
    first = registered_frames[10]
    components = connected_components(np.asarray(first.getchannel("A")) > 8, 20)
    cat = alpha_component_layer(first, max(components, key=lambda item: item["size"]))
    pixels = np.asarray(
        trim_pearl_floor_shadow(clean_treat_layer(cat)), dtype=np.uint8
    ).copy()
    # Start the fixed torso below the neck with a hard opaque handoff. The old
    # broad cross-fade mixed two different cream-fur textures and rendered as a
    # dark horizontal shadow while the heads changed.
    body_start = round(cat.height * 0.43)
    pixels[:body_start] = 0
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def dynamic_treat_head(frame: Image.Image) -> Image.Image:
    """Keep only the changing head/eyes/mouth while removing the authored tube."""
    pixels = np.asarray(frame.convert("RGBA"), dtype=np.uint8).copy()
    try:
        tube_seed = pink_tube_mask(frame)
        tube_region = np.asarray(
            Image.fromarray((tube_seed * 255).astype(np.uint8), "L").filter(
                ImageFilter.MaxFilter(17)
            )
        ) > 0
        # Clear only the authored strip silhouette. Clearing its rectangular
        # bounding box also erased the cheek and neck, leaving square holes.
        pixels[tube_region] = 0
    except ValueError:
        pass

    # Some authored frames retained detached pieces of the cream panel. Keep
    # only the connected cat before cropping the animated head region.
    components = connected_components(pixels[:, :, 3] > 8, 20)
    if components:
        subject = max(components, key=lambda item: item["size"])
        keep = np.zeros((frame.height, frame.width), dtype=bool)
        for component_x, component_y in subject["pixels"]:
            keep[component_y, component_x] = True
        pixels[~keep] = 0

    alpha = pixels[:, :, 3].astype(np.float32)
    x_grid = np.indices((frame.height, frame.width))[1]
    alpha[
        (x_grid < round(frame.width * 0.34))
        | (x_grid > round(frame.width * 0.70))
    ] = 0.0
    # End the moving layer along a shallow neckline curve instead of a hard
    # horizontal torso slice. This prevents the changing shoulder silhouettes
    # from forming a visible step or shadow against the fixed body underneath.
    center_x = frame.width * 0.55
    half_neck_width = frame.width * 0.22
    distance = np.minimum(np.abs(x_grid - center_x) / half_neck_width, 1.0)
    head_end_by_x = frame.height * 0.44 + frame.height * 0.05 * (1.0 - distance)
    y_grid = np.indices((frame.height, frame.width))[0]
    head_blend_start = head_end_by_x - 4.0
    alpha[y_grid >= head_end_by_x] = 0.0
    blend = (y_grid > head_blend_start) & (y_grid < head_end_by_x)
    alpha[blend] *= (
        (head_end_by_x - y_grid)[blend]
        / (head_end_by_x - head_blend_start)[blend]
    )
    pixels[:, :, 3] = np.clip(alpha, 0, 255).astype(np.uint8)
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return clean_treat_layer(Image.fromarray(pixels, "RGBA"))


def prepare_treat_interaction() -> None:
    source_frames = [
        Image.open(
            SOURCE_ROOT / "treat_original_frames" / f"frame_{index:02d}.png"
        ).convert("RGBA")
        for index in range(1, 13)
    ]
    # Two generated cells retained almost their full cream panel. Neighboring
    # clean poses express the same beats without reintroducing that backdrop.
    head_source_order = [0, 2, 2, 3, 4, 6, 7, 3, 4, 10, 10, 11]
    body = fixed_treat_body(source_frames)
    treat = fixed_treat_layer(source_frames)
    fixed_frames = []
    for frame_index, source_index in enumerate(head_source_order):
        fixed = body.copy()
        if frame_index < 9:
            fixed.alpha_composite(treat)
        fixed.alpha_composite(dynamic_treat_head(source_frames[source_index]))
        fixed_frames.append(clean_treat_layer(fixed))

    destination = PET_ROOT / "desktop" / "treat"
    for frame_index, frame in enumerate(fixed_frames, start=1):
        save_image(frame, destination / f"frame_{frame_index:02d}.png")


def save_treat_preview() -> None:
    """Render the transparent frames over a checkerboard for visual QA."""
    y_grid, x_grid = np.indices((PET_CANVAS[1], 640))
    alternate = ((x_grid // 24 + y_grid // 24) % 2).astype(bool)
    background_pixels = np.empty((PET_CANVAS[1], 640, 4), dtype=np.uint8)
    background_pixels[alternate] = (73, 77, 86, 255)
    background_pixels[~alternate] = (92, 97, 107, 255)
    background = Image.fromarray(background_pixels, "RGBA")
    frames = []
    for index in range(1, 13):
        preview = background.copy()
        preview.alpha_composite(
            Image.open(PET_ROOT / "desktop" / "treat" / f"frame_{index:02d}.png")
        )
        frames.append(preview.convert("RGB"))
    output = PROJECT_ROOT / "outputs" / "siamese_treat_fixed_body_preview.gif"
    output.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        output,
        save_all=True,
        append_images=frames[1:],
        duration=TREAT_PREVIEW_DURATIONS_MS,
        loop=0,
        disposal=2,
    )


def main() -> None:
    prepare_static_art()
    prepare_walk("siamese_walk_left_sheet.png", "walk_left")
    prepare_walk("siamese_walk_right_sheet.png", "walk_right")
    prepare_fishing_success()
    prepare_treat_interaction()
    save_treat_preview()
    print(
        "Prepared Siamese Home/store/sleep/fishing art, 8 walking frames, "
        "8 fishing-success frames, and 12 treat-interaction frames"
    )


if __name__ == "__main__":
    main()
