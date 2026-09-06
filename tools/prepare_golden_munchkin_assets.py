#!/usr/bin/env python3
"""Prepare the approved Golden Munchkin artwork as transparent Godot assets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

from prepare_biscuit_assets import PET_CANVAS, WALK_CANVAS, WIDE_CANVAS


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PET_ROOT = PROJECT_ROOT / "assets" / "pets" / "golden_munchkin"
SOURCE_ROOT = PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "golden_munchkin" / "source"
STATION_ROOT = PROJECT_ROOT / "assets" / "ui" / "desktop_station" / "golden_munchkin"
SLEEP_TAIL_SWEEP_AMPLITUDES = [
    0.0,
    -2.0,
    -4.0,
    -6.0,
    -7.0,
    -6.0,
    -4.0,
    -2.0,
    0.0,
    2.0,
    4.0,
    7.0,
    5.0,
    2.0,
    0.0,
]

# Generated walk sheets contain pale backdrop fragments in several enclosed
# spaces between the legs.  Each tuple is a tight search region plus the
# minimum size of the background-colored seed inside that region.  Keeping the
# regions frame-specific lets us clear the matte without recoloring or
# reshaping Honey's cream paws.
WALK_LEG_GAP_ARTIFACT_REGIONS: dict[
    str, dict[int, list[tuple[int, int, int, int, int]]]
] = {
    "move_left": {
        1: [(336, 394, 406, 474, 1000)],
        4: [(335, 392, 402, 474, 1000)],
        5: [(316, 388, 412, 470, 1000)],
        6: [(296, 406, 326, 464, 300), (325, 392, 408, 474, 1000)],
        7: [(335, 388, 398, 471, 1000)],
        8: [(344, 389, 403, 469, 1000)],
    },
    "move_right": {
        1: [(312, 388, 356, 470, 800), (384, 397, 422, 482, 150)],
        2: [(334, 396, 366, 482, 300), (416, 428, 434, 478, 50)],
        3: [(307, 395, 372, 474, 900), (377, 407, 397, 484, 80)],
        4: [(258, 390, 307, 474, 900), (358, 402, 384, 462, 300)],
        5: [(334, 389, 394, 474, 1000), (397, 401, 424, 488, 150)],
        6: [(268, 386, 324, 474, 1000), (337, 390, 367, 460, 400)],
        7: [(298, 392, 357, 473, 900), (366, 407, 391, 450, 80)],
        8: [(282, 392, 363, 470, 1000), (354, 400, 382, 465, 300)],
    },
}


def flood_background(source: np.ndarray) -> np.ndarray:
    """Find the pale generated backdrop connected to the image edge."""
    rgb = source[:, :, :3].astype(np.float32)
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    warm = (rgb[:, :, 0] - rgb[:, :, 2]) > 2.0
    passable = (luminance > 225.0) & (warm | (luminance > 249.0))
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


def connected_components(mask: np.ndarray, minimum_pixels: int = 20) -> list[dict]:
    """Return connected opaque regions with their pixel indexes and bounds."""
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    components: list[dict] = []
    for start_y, start_x in zip(*np.where(mask & ~seen)):
        if seen[start_y, start_x]:
            continue
        queue: deque[tuple[int, int]] = deque([(int(start_x), int(start_y))])
        seen[start_y, start_x] = True
        pixels: list[tuple[int, int]] = []
        min_x = max_x = int(start_x)
        min_y = max_y = int(start_y)
        sum_x = 0
        sum_y = 0
        while queue:
            x, y = queue.popleft()
            pixels.append((x, y))
            min_x = min(min_x, x)
            max_x = max(max_x, x)
            min_y = min(min_y, y)
            max_y = max(max_y, y)
            sum_x += x
            sum_y += y
            for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if (
                    0 <= next_x < width
                    and 0 <= next_y < height
                    and mask[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_x, next_y))
        if len(pixels) >= minimum_pixels:
            components.append(
                {
                    "pixels": pixels,
                    "size": len(pixels),
                    "bbox": (min_x, min_y, max_x + 1, max_y + 1),
                    "centroid": (sum_x / len(pixels), sum_y / len(pixels)),
                }
            )
    return components


def remove_walk_leg_gap_artifacts(
    image: Image.Image,
    direction: str,
    frame_index: int,
) -> Image.Image:
    """Make only the pale generated matte inside Honey's leg gaps transparent."""
    regions = WALK_LEG_GAP_ARTIFACT_REGIONS.get(direction, {}).get(frame_index, [])
    if not regions:
        return image.copy()

    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    rgb = pixels[:, :, :3].astype(np.float32)
    alpha = pixels[:, :, 3]
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    red_green = rgb[:, :, 0] - rgb[:, :, 1]
    green_blue = rgb[:, :, 1] - rgb[:, :, 2]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    height, width = alpha.shape
    removal_mask = np.zeros((height, width), dtype=bool)

    for left, top, right, bottom, minimum_seed_pixels in regions:
        region_mask = np.zeros((height, width), dtype=bool)
        region_mask[top:bottom, left:right] = True
        pale_seed_mask = (
            region_mask
            & (alpha > 32)
            & (luminance > 220.0)
            & (chroma < 50.0)
        )
        components = connected_components(pale_seed_mask, 5)
        if not components:
            continue
        seed_component = max(components, key=lambda item: item["size"])
        if seed_component["size"] < minimum_seed_pixels:
            # The frame has already been cleaned.  Do not let a later run
            # reinterpret Honey's pale paw highlights as background.
            continue

        seed_points = np.asarray(seed_component["pixels"], dtype=np.int32)
        seed_y = seed_points[:, 1]
        seed_x = seed_points[:, 0]
        seed_mask = np.zeros((height, width), dtype=bool)
        seed_mask[seed_y, seed_x] = True
        median_red_green = float(np.median(red_green[seed_mask]))
        median_green_blue = float(np.median(green_blue[seed_mask]))
        median_luminance = float(np.median(luminance[seed_mask]))

        # Grow through colors matching the neutral cream matte.  Hue-distance
        # limits stop the selection at the golden/white fur boundary, even
        # where the source drawing has no continuous dark outline.
        passable = (
            region_mask
            & (alpha > 0)
            & (luminance > 175.0)
            & (rgb[:, :, 2] > 175.0)
            & (np.abs(red_green - median_red_green) <= 11.0)
            & (np.abs(green_blue - median_green_blue) <= 13.0)
            & (np.abs(luminance - median_luminance) <= 55.0)
        )
        seen = np.zeros((height, width), dtype=bool)
        queue: deque[tuple[int, int]] = deque()
        for x, y in seed_component["pixels"]:
            if passable[y, x] and not seen[y, x]:
                seen[y, x] = True
                queue.append((x, y))
        while queue:
            x, y = queue.popleft()
            for next_x, next_y in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if (
                    0 <= next_x < width
                    and 0 <= next_y < height
                    and passable[next_y, next_x]
                    and not seen[next_y, next_x]
                ):
                    seen[next_y, next_x] = True
                    queue.append((next_x, next_y))
        removal_mask |= seen

    pixels[removal_mask] = 0
    return Image.fromarray(pixels, "RGBA")


def clean_rgba(image: Image.Image) -> Image.Image:
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def visible_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    bbox = image.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()
    if bbox is None:
        raise ValueError("Artwork contains no visible pixels")
    return bbox


def trim_floor_shadow(image: Image.Image) -> Image.Image:
    """Erase the generated floor shadow while retaining paws, belly, and tail."""
    pixels = np.asarray(image.convert("RGBA"), dtype=np.uint8).copy()
    alpha = pixels[:, :, 3]
    rgb = pixels[:, :, :3].astype(np.float32)
    luminance = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]
    chroma = rgb.max(axis=2) - rgb.min(axis=2)
    # The Golden Munchkin's real lower contour is either a dark brown outline
    # or saturated golden fur. The pale, low-chroma floor shadow has neither.
    subject_contour = (alpha >= 64) & ((luminance < 160.0) | (chroma > 90.0))
    floor_start = round(image.height * 0.50)

    for x in range(image.width):
        visible_y = np.where(alpha[:, x] > 8)[0]
        if visible_y.size == 0 or visible_y[-1] < floor_start:
            continue
        contour_y = np.where(subject_contour[:, x])[0]
        if contour_y.size == 0:
            alpha[visible_y[visible_y >= floor_start], x] = 0
            continue
        # Keep two antialiasing rows below the authored outline and remove
        # everything farther down, including shadow islands between the legs.
        alpha[int(contour_y[-1]) + 3 :, x] = 0

    pixels[:, :, 3] = alpha
    pixels[alpha == 0, :3] = 0
    trimmed = Image.fromarray(pixels, "RGBA")

    # Shadow removal can leave a handful of detached antialiased dots. Keep
    # only the cat's connected silhouette so those cannot flash in animation.
    opaque_components = connected_components(np.asarray(trimmed.getchannel("A")) > 8, 1)
    if not opaque_components:
        raise ValueError("Floor-shadow cleanup removed the complete subject")
    subject = max(opaque_components, key=lambda item: item["size"])
    cleaned_subject = component_cutout(trimmed, subject)
    return cleaned_subject.crop(visible_bbox(cleaned_subject))


def resize_clean(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    resized = image.convert("RGBa").resize(size, Image.Resampling.LANCZOS).convert("RGBA")
    return clean_rgba(resized)


def component_cutout(source: Image.Image, component: dict) -> Image.Image:
    rgba = source.convert("RGBA")
    mask = np.zeros((source.height, source.width), dtype=np.uint8)
    for x, y in component["pixels"]:
        mask[y, x] = 255
    # A light inward blur keeps an antialiased silhouette without retaining the
    # baked cream background in transparent edge pixels.
    alpha = Image.fromarray(mask, "L").filter(ImageFilter.GaussianBlur(0.65))
    rgba.putalpha(alpha)
    return clean_rgba(rgba.crop(component["bbox"]))


def main_cutout(source: Image.Image) -> Image.Image:
    rgb = np.asarray(source.convert("RGB"))
    components = connected_components(~flood_background(rgb), 200)
    if not components:
        raise ValueError("Artwork contains no visible subject")
    return component_cutout(source, max(components, key=lambda item: item["size"]))


def normalized_sprite(
    image: Image.Image,
    canvas: tuple[int, int],
    maximum: tuple[int, int],
    bottom_padding: int = 12,
) -> Image.Image:
    scale = min(maximum[0] / image.width, maximum[1] / image.height)
    resized = resize_clean(
        image,
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
    )
    output = Image.new("RGBA", canvas, (0, 0, 0, 0))
    output.alpha_composite(
        resized,
        ((canvas[0] - resized.width) // 2, canvas[1] - bottom_padding - resized.height),
    )
    return output


def save_image(image: Image.Image, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    clean_rgba(image).save(destination, optimize=True)


def static_pose_cutouts(pose_sheet: Image.Image) -> tuple[Image.Image, Image.Image]:
    """Extract both complete cats even when the side-pose tail crosses the midpoint."""
    pose_components = sorted(
        connected_components(~flood_background(np.asarray(pose_sheet)), 1000),
        key=lambda component: component["centroid"][0],
    )
    if len(pose_components) != 2:
        raise ValueError(f"Expected two Golden Munchkin poses, found {len(pose_components)}")
    return (
        component_cutout(pose_sheet, pose_components[0]),
        component_cutout(pose_sheet, pose_components[1]),
    )


def prepare_static_art() -> None:
    pose_sheet = Image.open(SOURCE_ROOT / "golden_munchkin_pose_sheet.png").convert("RGB")
    front, side = static_pose_cutouts(pose_sheet)
    front = trim_floor_shadow(front)
    side = trim_floor_shadow(side)
    head = main_cutout(Image.open(SOURCE_ROOT / "golden_munchkin_head_portrait.png"))
    failure = trim_floor_shadow(
        main_cutout(Image.open(SOURCE_ROOT / "golden_munchkin_fishing_failure.png"))
    )

    idle = normalized_sprite(side, PET_CANVAS, (472, 480))
    fishing_default = normalized_sprite(front, PET_CANVAS, (462, 480))
    portrait = normalized_sprite(head, PET_CANVAS, (470, 470), 18)
    fishing_failure = normalized_sprite(failure, PET_CANVAS, (462, 480))

    save_image(idle, PET_ROOT / "home" / "golden_munchkin_side_sitting.png")
    save_image(fishing_default, PET_ROOT / "fishing" / "default" / "golden_munchkin_fishing_default.png")
    save_image(portrait, PET_ROOT / "store" / "golden_munchkin_store_portrait.png")
    save_image(idle, PET_ROOT / "store" / "golden_munchkin_store_detail.png")
    save_image(
        fishing_failure,
        PET_ROOT / "fishing" / "failure" / "golden_munchkin_fishing_failure.png",
    )


def sheet_subjects(source_path: Path) -> tuple[Image.Image, list[dict]]:
    source = Image.open(source_path).convert("RGB")
    mask = ~flood_background(np.asarray(source))
    components = connected_components(mask, 1000)
    return source, components


def split_large_subject_sheet(
    source_path: Path,
    destination: Path,
    canvas: tuple[int, int],
    minimum_size: int,
    maximum: tuple[int, int],
    remove_floor_shadow: bool = False,
    walk_direction: str | None = None,
) -> list[Image.Image]:
    source, components = sheet_subjects(source_path)
    subjects = [item for item in components if item["size"] >= minimum_size]
    if len(subjects) != 8:
        raise ValueError(f"Expected 8 subjects in {source_path.name}, found {len(subjects)}")
    subjects.sort(
        key=lambda item: (
            0 if item["centroid"][1] < source.height * 0.5 else 1,
            item["centroid"][0],
        )
    )
    cutouts = [component_cutout(source, item) for item in subjects]
    if remove_floor_shadow:
        cutouts = [trim_floor_shadow(cutout) for cutout in cutouts]
    shared_scale = min(
        maximum[0] / max(item.width for item in cutouts),
        maximum[1] / max(item.height for item in cutouts),
    )
    destination.mkdir(parents=True, exist_ok=True)
    frames: list[Image.Image] = []
    for index, cutout in enumerate(cutouts, start=1):
        resized = resize_clean(
            cutout,
            (
                max(1, round(cutout.width * shared_scale)),
                max(1, round(cutout.height * shared_scale)),
            ),
        )
        frame = Image.new("RGBA", canvas, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            ((canvas[0] - resized.width) // 2, canvas[1] - 12 - resized.height),
        )
        if walk_direction is not None:
            frame = remove_walk_leg_gap_artifacts(frame, walk_direction, index)
        save_image(frame, destination / f"frame_{index:02d}.png")
        frames.append(frame)
    return frames


def prepare_walks_and_success() -> None:
    split_large_subject_sheet(
        SOURCE_ROOT / "golden_munchkin_walk_left_sheet.png",
        PET_ROOT / "move_left",
        WALK_CANVAS,
        28000,
        (WALK_CANVAS[0] - 24, WALK_CANVAS[1] - 28),
        True,
        "move_left",
    )
    split_large_subject_sheet(
        SOURCE_ROOT / "golden_munchkin_walk_right_sheet.png",
        PET_ROOT / "move_right",
        WALK_CANVAS,
        28000,
        (WALK_CANVAS[0] - 24, WALK_CANVAS[1] - 28),
        True,
        "move_right",
    )
    split_large_subject_sheet(
        SOURCE_ROOT / "golden_munchkin_fishing_success_sheet.png",
        PET_ROOT / "fishing" / "success",
        PET_CANVAS,
        70000,
        (PET_CANVAS[0] - 24, PET_CANVAS[1] - 28),
        True,
    )


def smooth_step(value: float) -> float:
    clamped = max(0.0, min(1.0, value))
    return clamped * clamped * (3.0 - 2.0 * clamped)


def warp_sleep_tail(base: Image.Image, amplitude: float) -> Image.Image:
    """Bend only the selected pose's lower-left tail while its body stays fixed."""
    if abs(amplitude) < 0.001:
        return base.copy()

    tail_pivot_x = 152.0
    tail_start_y = 350.0
    mesh_step = 16

    def source_point(x: int, y: int) -> tuple[float, float]:
        horizontal_falloff = smooth_step((tail_pivot_x - x) / 24.0)
        vertical_falloff = smooth_step((y - tail_start_y) / 60.0)
        return (
            float(x) - amplitude * horizontal_falloff * vertical_falloff,
            float(y),
        )

    mesh = []
    for top in range(0, base.height, mesh_step):
        bottom = min(base.height, top + mesh_step)
        for left in range(0, base.width, mesh_step):
            right = min(base.width, left + mesh_step)
            mesh.append(
                (
                    (left, top, right, bottom),
                    (
                        *source_point(left, top),
                        *source_point(left, bottom),
                        *source_point(right, bottom),
                        *source_point(right, top),
                    ),
                )
            )

    warped = base.transform(
        base.size,
        Image.Transform.MESH,
        mesh,
        Image.Resampling.BICUBIC,
    )
    warped_pixels = np.asarray(warped, dtype=np.uint8).copy()
    base_pixels = np.asarray(base, dtype=np.uint8)
    y_indices, x_indices = np.indices((base.height, base.width))
    tail_motion_region = (x_indices < round(tail_pivot_x)) & (y_indices > round(tail_start_y))
    warped_pixels[~tail_motion_region] = base_pixels[~tail_motion_region]
    warped_pixels[warped_pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(warped_pixels, "RGBA")


def prepare_sleep() -> None:
    selected_pose = trim_floor_shadow(
        main_cutout(Image.open(SOURCE_ROOT / "golden_munchkin_sleep_selected.png"))
    )
    base = normalized_sprite(
        selected_pose,
        WIDE_CANVAS,
        (WIDE_CANVAS[0] - 20, WIDE_CANVAS[1] - 28),
    )
    destination = PET_ROOT / "sleep" / "tail_sweep"
    destination.mkdir(parents=True, exist_ok=True)
    for index, amplitude in enumerate(SLEEP_TAIL_SWEEP_AMPLITUDES, start=1):
        frame = warp_sleep_tail(base, amplitude)
        save_image(frame, destination / f"frame_{index:02d}.png")
    save_image(base, PET_ROOT / "sleep" / "golden_munchkin_sleep.png")


def body_core_centroid(image: Image.Image) -> tuple[float, float]:
    """Return a tail-independent body anchor for fixed-canvas animation frames."""
    eroded_alpha = image.getchannel("A").filter(ImageFilter.MinFilter(31))
    core_components = connected_components(np.asarray(eroded_alpha) > 100, 20)
    if not core_components:
        raise ValueError("Animation frame has no stable body core")
    return max(core_components, key=lambda item: item["size"])["centroid"]


def prepare_failed_roll() -> None:
    """Prepare the approved short-legged failed-roll double-click animation."""
    sheet = Image.open(
        SOURCE_ROOT / "golden_munchkin_failed_roll_sheet.png"
    ).convert("RGB")
    components = connected_components(~flood_background(np.asarray(sheet)), 200)
    if len(components) != 12:
        raise ValueError(
            f"Expected 12 Golden Munchkin failed-roll poses, found {len(components)}"
        )
    cell_height = sheet.height / 3.0
    components.sort(
        key=lambda item: (
            min(2, int(item["centroid"][1] / cell_height)),
            item["centroid"][0],
        )
    )
    cutouts = [trim_floor_shadow(component_cutout(sheet, item)) for item in components]
    # The approved replacement fixes frame seven so the tail sits between the
    # two hind legs. Keep it as a separate source instead of regenerating it.
    cutouts[6] = trim_floor_shadow(
        main_cutout(Image.open(SOURCE_ROOT / "golden_munchkin_failed_roll_frame07.png"))
    )

    shared_scale = min(
        (WIDE_CANVAS[1] - 32) / cutouts[0].height,
        (WIDE_CANVAS[0] - 24) / max(frame.width for frame in cutouts),
    )
    destination = PET_ROOT / "desktop" / "failed_roll"
    destination.mkdir(parents=True, exist_ok=True)
    for index, cutout in enumerate(cutouts, start=1):
        resized = resize_clean(
            cutout,
            (
                max(1, round(cutout.width * shared_scale)),
                max(1, round(cutout.height * shared_scale)),
            ),
        )
        core_x, _core_y = body_core_centroid(resized)
        frame = Image.new("RGBA", WIDE_CANVAS, (0, 0, 0, 0))
        frame.alpha_composite(
            resized,
            (
                round(WIDE_CANVAS[0] * 0.5 - core_x),
                WIDE_CANVAS[1] - 12 - resized.height,
            ),
        )
        save_image(frame, destination / f"frame_{index:02d}.png")


def prepare_station() -> None:
    source = Image.open(SOURCE_ROOT / "golden_munchkin_ivory_blanket_station.png").convert("RGBA")
    alpha = np.asarray(source.getchannel("A")) > 8
    components = connected_components(alpha, 50)
    main = max(components, key=lambda item: item["size"])
    cutout = component_cutout(source, main)
    save_image(cutout, STATION_ROOT / "golden_munchkin_ivory_blanket_station.png")


def main() -> None:
    prepare_static_art()
    prepare_walks_and_success()
    prepare_sleep()
    prepare_failed_roll()
    prepare_station()
    print("Prepared Golden Munchkin assets")


if __name__ == "__main__":
    main()
