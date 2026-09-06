from pathlib import Path

from PIL import Image


ROOT = Path("/Users/yufanmo/Documents/Steam游戏")
HOME = ROOT / "assets" / "ui" / "home"
HOME_SOURCES = ROOT / "dev_only" / "unused_assets" / "assets" / "ui" / "home"
SIZE = (1280, 720)
SEAM_START_X = 676
SEAM_END_X = 690


def composite_right_side(original_path: Path, generated_path: Path, output_path: Path) -> None:
    original = Image.open(original_path).convert("RGB").resize(SIZE, Image.Resampling.LANCZOS)
    generated = Image.open(generated_path).convert("RGB").resize(SIZE, Image.Resampling.LANCZOS)

    mask = Image.new("L", SIZE, 0)
    pixels = mask.load()
    for x in range(SEAM_START_X, SIZE[0]):
        opacity = 255 if x >= SEAM_END_X else round(
            255 * (x - SEAM_START_X) / (SEAM_END_X - SEAM_START_X)
        )
        for y in range(SIZE[1]):
            pixels[x, y] = opacity

    result = Image.composite(generated, original, mask)
    result.save(output_path)


if __name__ == "__main__":
    composite_right_side(
        HOME_SOURCES / "home_day.png",
        HOME_SOURCES / "home_layout_v3_generated_source.png",
        HOME / "home_day_layout_v3.png",
    )
    composite_right_side(
        HOME_SOURCES / "home_night.png",
        HOME_SOURCES / "home_layout_v3_generated_source.png",
        HOME / "home_night_layout_v3.png",
    )
