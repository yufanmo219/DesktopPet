#!/usr/bin/env python3
"""Normalize the thirty candidate fish icons and render review sheets."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "assets/ui/fishing/fish/candidates_30/processed"
OUTPUT_DIR = ROOT / "dev_only/outputs/previews/candidate_fish_icons"
FONT_PATH = ROOT / "assets/fonts/original_handwriting/yufan_original_handwriting.ttf"

CANVAS_SIZE = 1024
SUBJECT_MAX_SIZE = 820
ALPHA_THRESHOLD = 8

FISH: list[tuple[str, str]] = [
    ("ruby_betta", "RUBY BETTA"),
    ("neon_tetra", "NEON TETRA"),
    ("sapphire_discus", "SAPPHIRE DISCUS"),
    ("sunset_swordtail", "SUNSET SWORDTAIL"),
    ("black_molly", "BLACK MOLLY"),
    ("zebra_danio", "ZEBRA DANIO"),
    ("mandarin_dragonet", "MANDARIN DRAGONET"),
    ("fire_dartfish", "FIRE DARTFISH"),
    ("royal_gramma", "ROYAL GRAMMA"),
    ("rainbow_parrotfish", "RAINBOW PARROTFISH"),
    ("picasso_triggerfish", "PICASSO TRIGGERFISH"),
    ("moorish_idol", "MOORISH IDOL"),
    ("spotted_frogfish", "SPOTTED FROGFISH"),
    ("silver_flyingfish", "SILVER FLYINGFISH"),
    ("glass_knifefish", "GLASS KNIFEFISH"),
    ("electric_eel", "ELECTRIC EEL"),
    ("emerald_seahorse", "EMERALD SEAHORSE"),
    ("leafy_seadragon", "LEAFY SEADRAGON"),
    ("blue_spotted_stingray", "BLUE-SPOTTED STINGRAY"),
    ("golden_manta_ray", "GOLDEN MANTA RAY"),
    ("baby_whale_shark", "BABY WHALE SHARK"),
    ("hammerhead_shark", "HAMMERHEAD SHARK"),
    ("sawfish", "SAWFISH"),
    ("moray_eel", "MORAY EEL"),
    ("red_arowana", "RED AROWANA"),
    ("giant_arapaima", "GIANT ARAPAIMA"),
    ("spotted_gar", "SPOTTED GAR"),
    ("ancient_sturgeon", "ANCIENT STURGEON"),
    ("ocean_sunfish", "OCEAN SUNFISH"),
    ("coelacanth", "COELACANTH"),
]


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    mask = alpha.point(lambda value: 255 if value >= ALPHA_THRESHOLD else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("Image contains no visible subject")
    return bbox


def normalize_icon(path: Path) -> dict[str, object]:
    source = Image.open(path).convert("RGBA")
    cropped = source.crop(alpha_bbox(source))
    scale = min(SUBJECT_MAX_SIZE / cropped.width, SUBJECT_MAX_SIZE / cropped.height)
    size = (
        max(1, round(cropped.width * scale)),
        max(1, round(cropped.height * scale)),
    )
    subject = cropped.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    position = ((CANVAS_SIZE - size[0]) // 2, (CANVAS_SIZE - size[1]) // 2)
    canvas.alpha_composite(subject, position)
    canvas.save(path)

    bbox = alpha_bbox(canvas)
    gutters = {
        "left": bbox[0],
        "top": bbox[1],
        "right": CANVAS_SIZE - bbox[2],
        "bottom": CANVAS_SIZE - bbox[3],
    }
    if min(gutters.values()) < 95:
        raise ValueError(f"Unsafe icon gutter for {path.name}: {gutters}")
    return {
        "file": path.name,
        "canvas": [CANVAS_SIZE, CANVAS_SIZE],
        "subject_bbox": list(bbox),
        "gutters": gutters,
        "transparent_corners": all(
            canvas.getpixel(point)[3] == 0
            for point in ((0, 0), (CANVAS_SIZE - 1, 0), (0, CANVAS_SIZE - 1), (CANVAS_SIZE - 1, CANVAS_SIZE - 1))
        ),
    }


def fitting_font(text: str, maximum_width: int) -> ImageFont.FreeTypeFont:
    for size in range(24, 13, -1):
        font = ImageFont.truetype(FONT_PATH, size)
        if font.getlength(text) <= maximum_width:
            return font
    return ImageFont.truetype(FONT_PATH, 13)


def render_sheet(entries: list[tuple[str, str]], page_number: int) -> Path:
    columns = 5
    rows = 3
    cell_width = 326
    cell_height = 322
    header_height = 80
    canvas = Image.new(
        "RGBA",
        (columns * cell_width + 40, rows * cell_height + header_height + 30),
        "#d9f4f8",
    )
    draw = ImageDraw.Draw(canvas)
    title_font = ImageFont.truetype(FONT_PATH, 34)
    title = f"NEW FISH ICONS {page_number} / 2"
    title_box = draw.textbbox((0, 0), title, font=title_font)
    draw.text(
        ((canvas.width - (title_box[2] - title_box[0])) / 2, 22),
        title,
        font=title_font,
        fill="#654034",
    )

    for index, (slug, display_name) in enumerate(entries):
        column = index % columns
        row = index // columns
        left = 20 + column * cell_width
        top = header_height + row * cell_height
        card = (left + 8, top + 8, left + cell_width - 8, top + cell_height - 8)
        draw.rounded_rectangle(card, radius=24, fill="#fff3d3", outline="#b9794e", width=4)

        icon = Image.open(ICON_DIR / f"{slug}.png").convert("RGBA")
        icon.thumbnail((250, 230), Image.Resampling.LANCZOS)
        icon_position = (
            left + (cell_width - icon.width) // 2,
            top + 25 + (225 - icon.height) // 2,
        )
        canvas.alpha_composite(icon, icon_position)

        name_font = fitting_font(display_name, cell_width - 42)
        name_box = draw.textbbox((0, 0), display_name, font=name_font)
        draw.text(
            (left + (cell_width - (name_box[2] - name_box[0])) / 2, top + 264),
            display_name,
            font=name_font,
            fill="#654034",
        )

    output = OUTPUT_DIR / f"candidate_fish_icons_page_{page_number}_v1.png"
    canvas.convert("RGB").save(output, quality=95)
    return output


def main() -> None:
    reports: list[dict[str, object]] = []
    for slug, _display_name in FISH:
        reports.append(normalize_icon(ICON_DIR / f"{slug}.png"))

    report_path = OUTPUT_DIR / "candidate_fish_icons_validation_v1.json"
    report_path.write_text(json.dumps(reports, indent=2), encoding="utf-8")
    pages = [render_sheet(FISH[:15], 1), render_sheet(FISH[15:], 2)]
    print(f"Normalized {len(FISH)} icons")
    print(f"Validation: {report_path}")
    for page in pages:
        print(f"Preview: {page}")


if __name__ == "__main__":
    main()
