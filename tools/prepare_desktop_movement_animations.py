#!/usr/bin/env python3
"""Prepare fixed-canvas, same-scale Desktop Companion movement frames."""

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

from prepare_desktop_idle_animations import _connected_components


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SPRITES_ROOT = PROJECT_ROOT / "assets" / "pets" / "current" / "sprites"
SOURCE_SPRITES_ROOT = (
    PROJECT_ROOT / "dev_only" / "unused_assets" / "assets" / "pets" / "current" / "sprites"
)
PREVIEW_ROOT = PROJECT_ROOT / "dev_only" / "outputs" / "previews" / "desktop_movement"
FRAME_SIZE = (704, 512)
FRAME_PADDING_X = 12
FRAME_PADDING_Y = 16
TARGET_SEATED_HEIGHT = 400
OVERFLOW_MARGIN = 112
FRAME_COUNT = 12

ANIMATIONS = {
    "move_right": {
        "sheet": SOURCE_SPRITES_ROOT / "processed" / "desktop_run_right_transparent.png",
        "grid": (3, 4),
    },
}


def _cell_edges(length: int, divisions: int) -> list[int]:
    return [round(index * length / divisions) for index in range(divisions + 1)]


def _extract_subject(
    sheet: Image.Image,
    column: int,
    row: int,
    columns: int,
    rows: int,
) -> Image.Image:
    x_edges = _cell_edges(sheet.width, columns)
    y_edges = _cell_edges(sheet.height, rows)
    cell_left, cell_right = x_edges[column], x_edges[column + 1]
    cell_top, cell_bottom = y_edges[row], y_edges[row + 1]
    expanded_left = max(0, cell_left - OVERFLOW_MARGIN)
    expanded_top = max(0, cell_top - OVERFLOW_MARGIN)
    expanded_right = min(sheet.width, cell_right + OVERFLOW_MARGIN)
    expanded_bottom = min(sheet.height, cell_bottom + OVERFLOW_MARGIN)
    expanded = sheet.crop((expanded_left, expanded_top, expanded_right, expanded_bottom))
    components = _connected_components(expanded.getchannel("A"))
    if not components:
        raise ValueError(f"No subject found in cell ({column}, {row})")

    target_x = (cell_left + cell_right) * 0.5 - expanded_left
    target_y = (cell_top + cell_bottom) * 0.5 - expanded_top
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


def _build_fixed_frames(sheet_path: Path, columns: int, rows: int) -> tuple[list[Image.Image], float]:
    sheet = Image.open(sheet_path).convert("RGBA")
    cutouts = [
        _extract_subject(sheet, index % columns, index // columns, columns, rows)
        for index in range(columns * rows)
    ]
    if len(cutouts) != FRAME_COUNT:
        raise ValueError(f"{sheet_path} must contain {FRAME_COUNT} frames")

    available_width = FRAME_SIZE[0] - FRAME_PADDING_X * 2
    available_height = FRAME_SIZE[1] - FRAME_PADDING_Y * 2
    scale = min(
        TARGET_SEATED_HEIGHT / cutouts[0].height,
        available_width / max(cutout.width for cutout in cutouts),
        available_height / max(cutout.height for cutout in cutouts),
    )
    frames: list[Image.Image] = []
    for cutout in cutouts:
        cutout = cutout.resize(
            (max(1, round(cutout.width * scale)), max(1, round(cutout.height * scale))),
            Image.Resampling.LANCZOS,
        )
        frame = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
        destination_x = (FRAME_SIZE[0] - cutout.width) // 2
        destination_y = FRAME_SIZE[1] - FRAME_PADDING_Y - cutout.height
        frame.alpha_composite(cutout, (destination_x, destination_y))
        frames.append(frame)
    return frames, scale


def _save_frames(animation_name: str, frames: list[Image.Image]) -> None:
    output_dir = SPRITES_ROOT / animation_name
    output_dir.mkdir(parents=True, exist_ok=True)
    for index, frame in enumerate(frames, start=1):
        if frame.getbbox() is None:
            raise ValueError(f"Frame {index} in {animation_name} is empty")
        frame.save(output_dir / f"frame_{index:02d}.png", optimize=True)


def _render_preview(animation_name: str, frames: list[Image.Image]) -> None:
    PREVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    preview_frames: list[Image.Image] = []
    for index, frame in enumerate(frames, start=1):
        preview = Image.new("RGBA", FRAME_SIZE, "#fff4dc")
        draw = ImageDraw.Draw(preview)
        draw.ellipse((82, 458, 622, 490), fill=(83, 55, 47, 28))
        preview.alpha_composite(frame)
        draw.text((18, 16), f"{animation_name.upper()}  {index:02d}/{FRAME_COUNT}", fill="#6b4437")
        preview_frames.append(preview.convert("P", palette=Image.Palette.ADAPTIVE))
    durations = [650, 150, 150] + [110] * (FRAME_COUNT - 3)
    preview_frames[0].save(
        PREVIEW_ROOT / f"desktop_{animation_name}_preview.gif",
        save_all=True,
        append_images=preview_frames[1:],
        duration=durations,
        loop=0,
        disposal=2,
        optimize=False,
    )


def main() -> None:
    prepared: dict[str, list[Image.Image]] = {}
    for animation_name, config in ANIMATIONS.items():
        frames, scale = _build_fixed_frames(config["sheet"], *config["grid"])
        prepared[animation_name] = frames
        _save_frames(animation_name, frames)
        _render_preview(animation_name, frames)
        print(f"Prepared {FRAME_COUNT} {animation_name} frames at scale {scale:.3f}")

    left_frames = [frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT) for frame in prepared["move_right"]]
    _save_frames("move_left", left_frames)
    _render_preview("move_left", left_frames)
    print(f"Prepared {FRAME_COUNT} move_left frames from the right-facing sequence")


if __name__ == "__main__":
    main()
