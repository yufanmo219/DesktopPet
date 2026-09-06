#!/usr/bin/env python3
"""Render easy-to-review GIFs for the two Desktop Companion idle gestures."""

from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SPRITES_ROOT = PROJECT_ROOT / "assets" / "pets" / "current" / "sprites"
STATION_ART = PROJECT_ROOT / "assets" / "ui" / "desktop_station" / "orange_cat_grass_station_side_v1.png"
OUTPUT_DIR = PROJECT_ROOT / "dev_only" / "outputs" / "previews" / "desktop_idle"
CANVAS_SIZE = (600, 500)
CAT_SCALE = 0.76
GROUND_Y = 405


def render_frame(frame_path: Path, station: Image.Image) -> Image.Image:
    frame = Image.open(frame_path).convert("RGBA")
    resized = frame.resize(
        (round(frame.width * CAT_SCALE), round(frame.height * CAT_SCALE)),
        Image.Resampling.LANCZOS,
    )
    visual_bounds = resized.getbbox()
    if visual_bounds is None:
        raise ValueError(f"Empty animation frame: {frame_path}")
    visual_center_x = (visual_bounds[0] + visual_bounds[2]) // 2
    visual_bottom = visual_bounds[3]

    canvas = Image.new("RGBA", CANVAS_SIZE, "#fff8e8")
    station_x = (CANVAS_SIZE[0] - station.width) // 2
    canvas.alpha_composite(station, (station_x, GROUND_Y - 5))
    cat_x = CANVAS_SIZE[0] // 2 - visual_center_x
    cat_y = GROUND_Y - visual_bottom
    canvas.alpha_composite(resized, (cat_x, cat_y))
    return canvas.convert("RGB")


def animation_paths(name: str, frame_numbers: list[int] | None = None) -> list[Path]:
    all_frame_paths = sorted((SPRITES_ROOT / name).glob("frame_*.png"))
    if len(all_frame_paths) != 9:
        raise ValueError(f"Expected 9 source frames for {name}, got {len(all_frame_paths)}")
    return (
        [all_frame_paths[index - 1] for index in frame_numbers]
        if frame_numbers is not None
        else all_frame_paths
    )


def render_animation(
    name: str,
    frame_duration_ms: int,
    frame_paths: list[Path] | None = None,
) -> None:
    station = Image.open(STATION_ART).convert("RGBA")
    station = station.resize((570, round(station.height * 570 / station.width)), Image.Resampling.LANCZOS)
    if frame_paths is None:
        frame_paths = animation_paths(name)
    frames = [render_frame(frame_path, station) for frame_path in frame_paths]
    durations = [frame_duration_ms] * len(frames)
    durations[0] = 650
    durations[-1] = 850
    output_path = OUTPUT_DIR / f"{name}_preview.gif"
    frames[0].save(
        output_path,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
        optimize=True,
    )
    print(f"Rendered {output_path}")


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    render_animation("desktop_wink", 165)
    belly_sequence = (
        animation_paths("desktop_roll", [1, 2, 3, 4, 5, 6])
        + animation_paths("desktop_biscuit")
        + animation_paths("desktop_roll", [6, 5, 4, 3, 2, 1])
    )
    render_animation("desktop_roll", 220, belly_sequence)


if __name__ == "__main__":
    main()
