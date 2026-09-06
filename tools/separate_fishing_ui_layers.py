#!/usr/bin/env python3
"""Extract the baked Fishing UI frames into transparent movable textures."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


PROJECT_ROOT = Path(__file__).resolve().parents[1]
FISHING_ROOT = PROJECT_ROOT / "assets" / "ui" / "fishing"
SOURCE_PATH = FISHING_ROOT / "concepts" / "fishing_main_background_layout_v3.png"
CLEAN_BACKGROUND_PATH = FISHING_ROOT / "concepts" / "fishing_environment_background.png"
OUTPUT_ROOT = FISHING_ROOT / "panels" / "processed"
PREVIEW_PATH = PROJECT_ROOT / "dev_only" / "outputs" / "previews" / "fishing_separated_layers_preview.png"

PADDING = 12
SHADOW_OFFSET_Y = 7
SHADOW_BLUR = 6
SHADOW_COLOR = (67, 35, 24, 90)

# Bounds isolate the painted outer frame itself, excluding the old shadow and
# surrounding landscape. Coordinates are in the original 1671 x 941 artwork.
PANELS = {
    # The Stats frame has broad painted outer corners. A tighter mask prevents
    # small pieces of the original sky/grass background from surviving at the
    # upper-right and lower-right edges of the extracted transparent texture.
    "stats_panel_frame": {"bbox": (95, 98, 460, 252), "radius": 32},
    "heart_panel_frame": {"bbox": (1184, 102, 1570, 194), "radius": 22},
    "fish_types_panel_frame": {
        "bbox": (1177, 214, 1580, 562),
        "radius": 22,
        "divider_centers": (121, 195, 268),
    },
}


def _rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    scale = 4
    high_size = (size[0] * scale, size[1] * scale)
    high_mask = Image.new("L", high_size, 0)
    draw = ImageDraw.Draw(high_mask)
    draw.rounded_rectangle(
        (0, 0, high_size[0] - 1, high_size[1] - 1),
        radius=radius * scale,
        fill=255,
    )
    return high_mask.resize(size, Image.Resampling.LANCZOS)


def _extract_panel(source: Image.Image, bbox: tuple[int, int, int, int], radius: int) -> Image.Image:
    art = source.crop(bbox).convert("RGBA")
    art.putalpha(_rounded_mask(art.size, radius))
    canvas = Image.new(
        "RGBA",
        (art.width + PADDING * 2, art.height + PADDING * 2),
        (0, 0, 0, 0),
    )
    shadow_mask = Image.new("L", canvas.size, 0)
    shadow_mask.paste(art.getchannel("A"), (PADDING, PADDING + SHADOW_OFFSET_Y))
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))
    shadow = Image.new("RGBA", canvas.size, SHADOW_COLOR)
    shadow.putalpha(shadow_mask.point(lambda value: round(value * SHADOW_COLOR[3] / 255)))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(art, (PADDING, PADDING))
    return canvas


def _remove_horizontal_dividers(panel: Image.Image, centers: tuple[int, ...]) -> None:
    """Replace dotted divider bands with interpolated paper texture."""
    pixels = panel.load()
    for center_y in centers:
        upper_y = center_y - 7
        lower_y = center_y + 7
        for y in range(center_y - 3, center_y + 4):
            blend = (y - (center_y - 3)) / 6.0
            for x in range(38, panel.width - 38):
                upper = pixels[x, upper_y]
                lower = pixels[x, lower_y]
                pixels[x, y] = tuple(
                    round(upper[channel] * (1.0 - blend) + lower[channel] * blend)
                    for channel in range(4)
                )


def _remove_stats_upper_right_bleed(panel: Image.Image) -> None:
    """Clear the small patch of old blue-gray sky left outside the frame."""
    pixels = panel.load()
    for y in range(min(46, panel.height)):
        for x in range(338, panel.width):
            red, green, blue, alpha = pixels[x, y]
            is_old_sky = (
                alpha > 20
                and red < 215
                and green > 145
                and blue > 125
                and abs(green - blue) < 55
            )
            if is_old_sky:
                pixels[x, y] = (red, green, blue, 0)


def main() -> None:
    clean_background = Image.open(CLEAN_BACKGROUND_PATH).convert("RGBA")
    expected_canvas_size = (1671, 941)
    if clean_background.size != expected_canvas_size:
        raise ValueError("The clean background must preserve the original Fishing canvas size")

    source = Image.open(SOURCE_PATH).convert("RGB") if SOURCE_PATH.exists() else None
    if source is not None and source.size != expected_canvas_size:
        raise ValueError("The baked Fishing source must preserve the original canvas size")

    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    PREVIEW_PATH.parent.mkdir(parents=True, exist_ok=True)
    preview = clean_background.copy()
    for name, config in PANELS.items():
        output_path = OUTPUT_ROOT / f"{name}.png"
        if source is not None:
            panel = _extract_panel(source, config["bbox"], config["radius"])
        elif output_path.exists():
            panel = Image.open(output_path).convert("RGBA")
        else:
            raise FileNotFoundError(f"Missing extracted panel: {output_path}")
        if name == "stats_panel_frame":
            _remove_stats_upper_right_bleed(panel)
        if source is not None and "divider_centers" in config:
            _remove_horizontal_dividers(panel, config["divider_centers"])
        panel.save(output_path, optimize=True)
        left, top, _, _ = config["bbox"]
        preview.alpha_composite(panel, (left - PADDING, top - PADDING))
        print(f"Saved {name}: {panel.size}")

    preview.save(PREVIEW_PATH, optimize=True)
    print(f"Saved separated-layer preview: {PREVIEW_PATH}")


if __name__ == "__main__":
    main()
