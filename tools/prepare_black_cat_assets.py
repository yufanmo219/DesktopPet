#!/usr/bin/env python3
"""Prepare the approved black-cat artwork as fixed-canvas Godot assets."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

from prepare_biscuit_assets import (
    PET_CANVAS,
    WALK_CANVAS,
    WIDE_CANVAS,
    connected_components,
    grid_edges,
    remove_tiny_components,
    visible_bbox,
)


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PET_ROOT = PROJECT_ROOT / "assets" / "pets" / "black_cat"
SOURCE_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "black_cat" / "source"
STATION_ROOT = PROJECT_ROOT / "assets" / "ui" / "desktop_station" / "black_cat"


def remove_light_background(source: Image.Image) -> Image.Image:
    """Remove cream or baked checkerboard backgrounds without changing the cat."""
    image = source.convert("RGBA")
    pixels = np.asarray(image, dtype=np.float32).copy()
    red = pixels[:, :, 0]
    green = pixels[:, :, 1]
    blue = pixels[:, :, 2]
    original_alpha = pixels[:, :, 3] / 255.0

    # Every approved source uses a very light neutral/cream backdrop while the
    # cat, whiskers and blanket are substantially darker. A soft luminance key
    # keeps antialiased outlines and the pale sigh cloud while fully removing
    # both shades of the baked checkerboard.
    luminance = red * 0.299 + green * 0.587 + blue * 0.114
    keyed_alpha = np.clip((238.0 - luminance) / 48.0, 0.0, 1.0)
    keyed_alpha[keyed_alpha < 0.055] = 0.0

    # The black cat's blue and gold irises contain pale painted highlights. A
    # global luminance key used to turn those enclosed details partly
    # transparent, so gray desktop pixels showed through the eyes. Protect only
    # the immediate neighborhood of strongly blue/gold iris pixels before
    # removing the cream backdrop.
    blue_iris = (
        (blue > red + 32.0)
        & (green > red + 14.0)
        & (blue > 95.0)
    )
    gold_iris = (
        (red > blue + 62.0)
        & (green > blue + 24.0)
        & (red > 135.0)
        & (blue < 118.0)
    )
    eye_detail_region = dilated(blue_iris | gold_iris, 10)
    keyed_alpha[eye_detail_region] = 1.0

    # Recover the original edge color from the light matte. Keeping the source
    # RGB on partially transparent pixels would produce a bright fringe around
    # black fur in the transparent Desktop companion window.
    background_samples = pixels[luminance >= 238.0, :3]
    background_color = (
        np.median(background_samples, axis=0)
        if background_samples.size
        else np.array([250.0, 247.0, 242.0], dtype=np.float32)
    )
    partial = (keyed_alpha > 0.0) & (keyed_alpha < 0.985)
    safe_alpha = np.maximum(keyed_alpha[partial, None], 0.055)
    pixels[partial, :3] = np.clip(
        (
            pixels[partial, :3]
            - background_color[None, :] * (1.0 - safe_alpha)
        )
        / safe_alpha,
        0.0,
        255.0,
    )
    pixels[:, :, 3] = original_alpha * keyed_alpha * 255.0
    transparent = pixels[:, :, 3] <= 0.5
    pixels[transparent, :3] = 0.0
    return remove_tiny_components(
        Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGBA"),
        28,
    )


def save_normalized(
    source: Image.Image,
    destination: Path,
    canvas: tuple[int, int],
    maximum: tuple[int, int],
    bottom_padding: int = 12,
) -> Image.Image:
    destination.parent.mkdir(parents=True, exist_ok=True)
    cutout = source.crop(visible_bbox(source))
    scale = min(maximum[0] / cutout.width, maximum[1] / cutout.height)
    resized = resize_rgba_clean(
        cutout,
        (
            max(1, round(cutout.width * scale)),
            max(1, round(cutout.height * scale)),
        ),
    )
    output = Image.new("RGBA", canvas, (0, 0, 0, 0))
    output.alpha_composite(
        resized,
        (
            (canvas[0] - resized.width) // 2,
            canvas[1] - bottom_padding - resized.height,
        ),
    )
    output.save(destination, optimize=True)
    return output


def resize_rgba_clean(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Resize premultiplied RGBA so matte colors cannot ring around the edge."""
    # Bilinear avoids Lanczos' negative-lobe overshoot, which can turn a dark
    # antialiased edge into isolated white pixels after unpremultiplication.
    resized = image.convert("RGBa").resize(size, Image.Resampling.BILINEAR).convert("RGBA")
    pixels = np.asarray(resized, dtype=np.uint8).copy()
    pixels[pixels[:, :, 3] == 0, :3] = 0
    pixels = bleed_opaque_edge_color(pixels, 8)
    pixels = neutralize_light_matte_outline(pixels)
    return Image.fromarray(pixels, "RGBA")


def bleed_opaque_edge_color(pixels: np.ndarray, iterations: int) -> np.ndarray:
    """Pull nearby solid subject colors into only the antialiased boundary."""
    output = pixels.copy()
    rank = output[:, :, 3].astype(np.int16)
    target = (rank > 0) & (rank < 250)
    height, width = rank.shape
    for _iteration in range(iterations):
        best_rank = rank.copy()
        best_colors = output[:, :, :3].copy()
        for offset_y in (-1, 0, 1):
            for offset_x in (-1, 0, 1):
                if offset_x == 0 and offset_y == 0:
                    continue
                shifted_rank = np.full_like(rank, -1)
                shifted_colors = np.zeros_like(best_colors)
                source_y = slice(max(0, -offset_y), min(height, height - offset_y))
                source_x = slice(max(0, -offset_x), min(width, width - offset_x))
                target_y = slice(max(0, offset_y), min(height, height + offset_y))
                target_x = slice(max(0, offset_x), min(width, width + offset_x))
                shifted_rank[target_y, target_x] = rank[source_y, source_x]
                shifted_colors[target_y, target_x] = output[source_y, source_x, :3]
                use_neighbor = target & (shifted_rank > best_rank)
                best_rank[use_neighbor] = shifted_rank[use_neighbor]
                best_colors[use_neighbor] = shifted_colors[use_neighbor]
        changed = target & (best_rank > rank)
        output[changed, :3] = best_colors[changed]
        rank[changed] = np.maximum(0, best_rank[changed] - 1)
    return output


def dilated(mask: np.ndarray, radius: int) -> np.ndarray:
    output = mask.copy()
    height, width = mask.shape
    for _iteration in range(radius):
        expanded = output.copy()
        for offset_y in (-1, 0, 1):
            for offset_x in (-1, 0, 1):
                source_y = slice(max(0, -offset_y), min(height, height - offset_y))
                source_x = slice(max(0, -offset_x), min(width, width - offset_x))
                target_y = slice(max(0, offset_y), min(height, height + offset_y))
                target_x = slice(max(0, offset_x), min(width, width + offset_x))
                expanded[target_y, target_x] |= output[source_y, source_x]
        output = expanded
    return output


def neutralize_light_matte_outline(pixels: np.ndarray) -> np.ndarray:
    """Darken only the neutral baked rim next to the black silhouette."""
    output = pixels.copy()
    alpha = output[:, :, 3]
    colors = output[:, :, :3].astype(np.float32)
    luminance = colors[:, :, 0] * 0.299 + colors[:, :, 1] * 0.587 + colors[:, :, 2] * 0.114
    neutral = colors.max(axis=2) - colors.min(axis=2) <= 24.0
    dark_subject = (alpha >= 220) & (luminance < 145.0)
    near_subject = dilated(dark_subject, 10)
    near_transparency = dilated(alpha == 0, 2)
    matte_rim = (
        (alpha > 0)
        & neutral
        & (luminance > 90.0)
        & near_subject
        & near_transparency
    )
    output[matte_rim, :3] = np.clip(colors[matte_rim] * 0.14, 0, 255).astype(np.uint8)
    return output


def clean_static_side_tail(image: Image.Image) -> Image.Image:
    """Remove the pale ground flecks baked into the seated cat's black tail."""
    output = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    alpha = output[:, :, 3]
    colors = output[:, :, :3].astype(np.float32)
    luminance = colors[:, :, 0] * 0.299 + colors[:, :, 1] * 0.587 + colors[:, :, 2] * 0.114
    _left, top, _right, bottom = visible_bbox(image)
    y_indices, _x_indices = np.indices(alpha.shape)
    lower_subject = y_indices >= top + round((bottom - top) * 0.76)

    # Build the lower silhouette only from opaque blue-black fur, then retain a
    # two-pixel antialiased rim around it. This removes both pale flecks and the
    # darker warm ground shadow without cutting into the tail itself.
    fur_core = (
        (alpha >= 200)
        & (colors[:, :, 2] > colors[:, :, 0] + 3.0)
        & (luminance < 90.0)
    )
    smooth_fur_region = dilated(fur_core, 2)
    ground_residue = lower_subject & (alpha > 0) & ~smooth_fur_region
    output[ground_residue] = 0

    # Any surviving warm matte pixel directly touching the fur becomes the same
    # near-black as the authored outline, keeping the tail edge continuous.
    smooth_edge = (
        lower_subject
        & (output[:, :, 3] > 0)
        & ~fur_core
        & (
            (luminance > 70.0)
            | (colors[:, :, 0] >= colors[:, :, 2])
        )
    )
    output[smooth_edge, :3] = np.array([18, 18, 28], dtype=np.uint8)
    output[output[:, :, 3] == 0, :3] = 0
    return Image.fromarray(output, "RGBA")


def clean_sleep_tail_underside(image: Image.Image) -> Image.Image:
    """Erase the complete baked floor shadow below the sleeping cat."""
    output = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    alpha = output[:, :, 3]
    colors = output[:, :, :3].astype(np.float32)
    luminance = colors[:, :, 0] * 0.299 + colors[:, :, 1] * 0.587 + colors[:, :, 2] * 0.114

    # Find the actual lower edge of the cool blue-black cat in every column. A
    # small horizontal maximum closes painted gaps without changing the cat.
    # The source sheet includes a warm beige floor shadow that touches the tail
    # and paws, so connected-component cleanup alone cannot distinguish it.
    cat_core = (
        (alpha >= 180)
        & (luminance < 130.0)
        & (colors[:, :, 2] >= colors[:, :, 0] - 6.0)
    )
    column_bottoms = np.full(output.shape[1], -1, dtype=np.int32)
    for x in range(output.shape[1]):
        visible_y = np.flatnonzero(cat_core[:, x])
        if visible_y.size:
            column_bottoms[x] = int(visible_y[-1])

    smoothed_bottoms = column_bottoms.copy()
    for x in range(output.shape[1]):
        smoothed_bottoms[x] = int(
            column_bottoms[
                max(0, x - 5) : min(output.shape[1], x + 6)
            ].max()
        )

    y_indices, _x_indices = np.indices(alpha.shape)
    lower_band = y_indices > round(output.shape[0] * 0.63)
    below_cat = (
        (smoothed_bottoms[None, :] < 0)
        | (y_indices > smoothed_bottoms[None, :] + 2)
    )
    warm_or_light_matte = (
        (luminance > 80.0)
        | (
            (colors[:, :, 0] >= colors[:, :, 2] - 1.0)
            & (luminance > 55.0)
        )
    )
    touches_lower_silhouette = (
        (smoothed_bottoms[None, :] < 0)
        | (y_indices >= smoothed_bottoms[None, :] - 6)
    )
    near_transparency = dilated(alpha == 0, 8)
    floor_residue = (
        (alpha > 0)
        & lower_band
        & (
            below_cat
            | (
                warm_or_light_matte
                & (touches_lower_silhouette | near_transparency)
            )
        )
    )
    output[floor_residue] = 0
    # The baked shadow is several pixels thick in places. Peel exposed warm
    # matte pixels repeatedly until the newly transparent boundary reaches the
    # cool fur; a one-pass proximity mask would leave a thinner ochre ring.
    for _iteration in range(64):
        current_alpha = output[:, :, 3]
        exposed_warm_matte = (
            lower_band
            & (current_alpha > 0)
            & dilated(current_alpha == 0, 1)
            & warm_or_light_matte
        )
        if not exposed_warm_matte.any():
            break
        output[exposed_warm_matte] = 0
    output[output[:, :, 3] == 0, :3] = 0
    # Pull only surviving cool fur colors into the antialiased edge. This keeps
    # the lower contour soft without retaining a beige fringe in translucent
    # pixels. Runtime linear sampling handles fractional display scales.
    output = bleed_opaque_edge_color(output, 5)
    for _iteration in range(12):
        current_alpha = output[:, :, 3]
        current_colors = output[:, :, :3].astype(np.float32)
        current_luminance = (
            current_colors[:, :, 0] * 0.299
            + current_colors[:, :, 1] * 0.587
            + current_colors[:, :, 2] * 0.114
        )
        current_warm_or_light_matte = (
            (current_luminance > 80.0)
            | (
                (current_colors[:, :, 0] >= current_colors[:, :, 2] - 1.0)
                & (current_luminance > 55.0)
            )
        )
        exposed_warm_matte = (
            lower_band
            & (current_alpha > 0)
            & dilated(current_alpha == 0, 2)
            & current_warm_or_light_matte
        )
        if not exposed_warm_matte.any():
            break
        output[exposed_warm_matte] = 0
    output[output[:, :, 3] == 0, :3] = 0
    return remove_tiny_components(Image.fromarray(output, "RGBA"), 28)


def keep_largest_component(image: Image.Image) -> Image.Image:
    """Keep the authored subject and discard neighboring-cell fragments."""
    components = connected_components(image)
    if not components:
        raise ValueError("Animation cell contains no visible subject")
    main = max(components, key=lambda component: component["size"])
    return keep_component(image, main)


def keep_component(image: Image.Image, component: dict) -> Image.Image:
    """Keep one connected subject without clipping it to a sheet grid line."""
    mask = np.zeros((image.height, image.width), dtype=np.uint8)
    indices = np.asarray(component["pixels"])
    mask[indices // image.width, indices % image.width] = 255
    output = image.copy()
    source_alpha = np.asarray(image.getchannel("A"))
    output.putalpha(
        Image.fromarray(np.where(mask, source_alpha, 0).astype(np.uint8), "L")
    )
    return output


def static_pose_subjects(poses: Image.Image) -> tuple[Image.Image, Image.Image]:
    """Extract the complete left and right poses from their shared source sheet."""
    components = sorted(
        (
            component
            for component in connected_components(poses)
            if component["size"] >= 10_000
        ),
        key=lambda component: component["centroid"][0],
    )
    if len(components) != 2:
        raise ValueError(f"Expected two black-cat poses, found {len(components)}")
    return (
        keep_component(poses, components[0]),
        keep_component(poses, components[1]),
    )


def split_shared_bottom_aligned(
    source_path: Path,
    columns: int,
    rows: int,
    output_dir: Path,
    canvas: tuple[int, int],
    side_padding: int = 16,
    bottom_padding: int = 12,
) -> list[Image.Image]:
    sheet = remove_light_background(Image.open(source_path))
    x_edges = grid_edges(sheet.width, columns)
    y_edges = grid_edges(sheet.height, rows)
    cutouts: list[Image.Image] = []
    for row in range(rows):
        for column in range(columns):
            cell = sheet.crop(
                (
                    x_edges[column],
                    y_edges[row],
                    x_edges[column + 1],
                    y_edges[row + 1],
                )
            )
            cell = remove_tiny_components(cell, 28)
            cell = keep_largest_component(cell)
            cutouts.append(cell.crop(visible_bbox(cell)))

    scale = min(
        (canvas[0] - side_padding * 2) / max(item.width for item in cutouts),
        (canvas[1] - bottom_padding - 12) / max(item.height for item in cutouts),
    )
    output_dir.mkdir(parents=True, exist_ok=True)
    frames: list[Image.Image] = []
    for index, cutout in enumerate(cutouts, start=1):
        resized = resize_rgba_clean(
            cutout,
            (
                max(1, round(cutout.width * scale)),
                max(1, round(cutout.height * scale)),
            ),
        )
        frame = Image.new("RGBA", canvas, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            (
                (canvas[0] - resized.width) // 2,
                canvas[1] - bottom_padding - resized.height,
            ),
        )
        frame.save(output_dir / f"frame_{index:02d}.png", optimize=True)
        frames.append(frame)
    return frames


def prepare_static_assets() -> None:
    poses = remove_light_background(Image.open(SOURCE_ROOT / "black_cat_front_side.png"))
    front, side = static_pose_subjects(poses)
    home_destination = PET_ROOT / "home" / "black_cat_side_sitting.png"
    home_side = save_normalized(
        side,
        home_destination,
        PET_CANVAS,
        (452, 472),
    )
    clean_static_side_tail(home_side).save(home_destination, optimize=True)
    save_normalized(
        front,
        PET_ROOT / "fishing" / "default" / "black_cat_fishing_default.png",
        PET_CANVAS,
        (438, 472),
    )
    save_normalized(
        remove_light_background(Image.open(SOURCE_ROOT / "black_cat_head_portrait.png")),
        PET_ROOT / "store" / "black_cat_store_portrait.png",
        PET_CANVAS,
        (474, 474),
        18,
    )
    detail_destination = PET_ROOT / "store" / "black_cat_store_detail.png"
    store_side = save_normalized(
        side,
        detail_destination,
        PET_CANVAS,
        (440, 462),
    )
    clean_static_side_tail(store_side).save(detail_destination, optimize=True)
    save_normalized(
        remove_light_background(Image.open(SOURCE_ROOT / "black_cat_fishing_failure.png")),
        PET_ROOT / "fishing" / "failure" / "black_cat_fishing_failure.png",
        PET_CANVAS,
        (452, 472),
    )


def prepare_sleep() -> None:
    frames = split_shared_bottom_aligned(
        SOURCE_ROOT / "black_cat_sleep_sheet.png",
        4,
        2,
        PET_ROOT / "sleep" / "fall_asleep",
        WIDE_CANVAS,
        18,
        12,
    )
    cleaned_frames: list[Image.Image] = []
    for index, frame in enumerate(frames, start=1):
        cleaned_frame = clean_sleep_tail_underside(frame)
        cleaned_frame.save(
            PET_ROOT / "sleep" / "fall_asleep" / f"frame_{index:02d}.png",
            optimize=True,
        )
        cleaned_frames.append(cleaned_frame)
    (PET_ROOT / "sleep").mkdir(parents=True, exist_ok=True)
    cleaned_frames[-1].save(PET_ROOT / "sleep" / "black_cat_sleep.png", optimize=True)


def prepare_walk() -> None:
    split_shared_bottom_aligned(
        SOURCE_ROOT / "black_cat_walk_left_sheet.png",
        4,
        3,
        PET_ROOT / "walk_left",
        WALK_CANVAS,
        12,
        12,
    )
    split_shared_bottom_aligned(
        SOURCE_ROOT / "black_cat_walk_right_sheet.png",
        4,
        3,
        PET_ROOT / "walk_right",
        WALK_CANVAS,
        12,
        12,
    )


def prepare_fishing_success() -> None:
    frames = split_shared_bottom_aligned(
        SOURCE_ROOT / "black_cat_fishing_success_single_paw_sheet.png",
        4,
        2,
        PET_ROOT / "fishing" / "success",
        PET_CANVAS,
        14,
        12,
    )
    for index, frame in enumerate(frames, start=1):
        clean_static_side_tail(frame).save(
            PET_ROOT / "fishing" / "success" / f"frame_{index:02d}.png",
            optimize=True,
        )


def prepare_station() -> None:
    source = remove_light_background(Image.open(SOURCE_ROOT / "black_cat_folded_blanket_station.png"))
    cutout = source.crop(visible_bbox(source))
    STATION_ROOT.mkdir(parents=True, exist_ok=True)
    cutout.save(STATION_ROOT / "black_cat_folded_blanket_station.png", optimize=True)


def main() -> None:
    prepare_static_assets()
    prepare_sleep()
    prepare_walk()
    prepare_fishing_success()
    prepare_station()
    print(
        "Prepared black-cat Home/store art, 8 sleep frames, 24 walking frames, "
        "8 fishing-success frames, fishing failure art, and Desktop blanket"
    )


if __name__ == "__main__":
    main()
