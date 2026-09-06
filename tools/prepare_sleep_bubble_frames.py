#!/usr/bin/env python3
"""Build five fixed-anchor sleeping-bubble animation frames from the master cutout."""

from pathlib import Path

from PIL import Image


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MASTER_PATH = PROJECT_ROOT / "dev_only/unused_assets/assets/pets/current/sprites/sleep_bubble/sleep_bubble_master.png"
FRAMES_DIR = PROJECT_ROOT / "assets/pets/current/sprites/sleep_bubble/frames"
CANVAS_SIZE = (144, 96)
NOSE_ANCHOR = (10, 70)
MAX_WIDTH = 130
# Keep the approved 0.82 maximum. One occasional cycle breathes outward,
# contracts, then swells once more before the gameplay code hides it.
FRAME_SCALES = (
    0.28,
    0.34,
    0.44,
    0.55,
    0.66,
    0.74,
    0.82,
    0.70,
    0.58,
    0.46,
    0.56,
    0.66,
    0.74,
    0.82,
)


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value >= 2 else 0).getbbox()
    if bbox is None:
        raise RuntimeError(f"No visible pixels found in {MASTER_PATH}")
    return bbox


def left_tip_y(image: Image.Image) -> float:
    alpha = image.getchannel("A")
    visible = alpha.point(lambda value: 255 if value >= 24 else 0)
    bbox = visible.getbbox()
    if bbox is None:
        return image.height * 0.5
    search_width = max(3, round(image.width * 0.018))
    tip_pixels: list[int] = []
    for x in range(bbox[0], min(bbox[0] + search_width, bbox[2])):
        for y in range(bbox[1], bbox[3]):
            if visible.getpixel((x, y)):
                tip_pixels.append(y)
    return sum(tip_pixels) / len(tip_pixels) if tip_pixels else image.height * 0.5


def main() -> None:
    source = Image.open(MASTER_PATH).convert("RGBA")
    cropped = source.crop(alpha_bbox(source))
    master_scale = MAX_WIDTH / cropped.width
    master_size = (
        MAX_WIDTH,
        max(1, round(cropped.height * master_scale)),
    )
    master = cropped.resize(master_size, Image.Resampling.LANCZOS)
    master_tip_y = left_tip_y(master)

    FRAMES_DIR.mkdir(parents=True, exist_ok=True)
    for index, frame_scale in enumerate(FRAME_SCALES, start=1):
        frame_size = (
            max(1, round(master.width * frame_scale)),
            max(1, round(master.height * frame_scale)),
        )
        bubble = master.resize(frame_size, Image.Resampling.LANCZOS)
        frame_tip_y = master_tip_y * frame_scale
        paste_position = (
            NOSE_ANCHOR[0],
            round(NOSE_ANCHOR[1] - frame_tip_y),
        )
        canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
        canvas.alpha_composite(bubble, paste_position)
        output_path = FRAMES_DIR / f"frame_{index:02d}.png"
        canvas.save(output_path, optimize=True)
        print(f"Wrote {output_path.relative_to(PROJECT_ROOT)}")


if __name__ == "__main__":
    main()
