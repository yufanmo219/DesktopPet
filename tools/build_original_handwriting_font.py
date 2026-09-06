from pathlib import Path
from collections import deque

from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
BLANK_TEMPLATE = ROOT / "dev_only/unused_assets/assets/font_sheets/original_handwriting_template.png"
FILLED_TEMPLATE = ROOT / "dev_only/unused_assets/assets/font_source/original_handwriting_filled.png"
OUT = ROOT / "dev_only/outputs/fonts/original_handwriting"

GRID_X = 120
GRID_Y = 220
CELL_SIZE = 300
BASELINE_Y = 235
GLYPH_SCALE = 0.85
LINE_HEIGHT = round(CELL_SIZE * GLYPH_SCALE)
FONT_BASE = round(BASELINE_Y * GLYPH_SCALE)
FONT_SIZE = 256
ATLAS_SIZE = 2048
ATLAS_GAP = 4

PAD_LEFT = 16
PAD_TOP = 16
PAD_RIGHT = 28
PAD_BOTTOM = 32

CHARACTER_ROWS = [
    list("ABCDEFG"),
    list("HIJKLMN"),
    list("OPQRSTU"),
    list("VWXYZ01"),
    list("2345678"),
    ["9", "!", "?", ".", ",", ":", "'"],
    ["+", "-", "/", "%", "←", "(", ")"],
]

STYLES = [
    {
        "slug": "white_no_shadow",
        "fill": "#FFFFFF",
        "outline": "#684230",
        "outline_size": 4,
        "shadow": None,
    },
    {
        "slug": "coral_shadow",
        "fill": "#E98555",
        "outline": "#684230",
        "outline_size": 3,
        "shadow": {"color": "#3D271F", "offset": (4, 6), "blur": 1.5, "opacity": 0.55},
    },
    {
        "slug": "white_shadow",
        "fill": "#FFFFFF",
        "outline": "#684230",
        "outline_size": 3,
        "shadow": {"color": "#3D271F", "offset": (4, 6), "blur": 1.5, "opacity": 0.55},
    },
]


def _difference_mask(blank: Image.Image, filled: Image.Image) -> Image.Image:
    difference = ImageChops.difference(blank.convert("RGB"), filled.convert("RGB")).convert("L")
    return difference.point(lambda value: 0 if value <= 8 else min(255, (value - 8) * 2))


def _keep_largest_component(mask: Image.Image) -> Image.Image:
    width, height = mask.size
    pixels = mask.load()
    visited = bytearray(width * height)
    largest: list[int] = []
    neighbors = [
        (-1, -1), (0, -1), (1, -1),
        (-1, 0),           (1, 0),
        (-1, 1),  (0, 1),  (1, 1),
    ]
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if visited[index] or pixels[x, y] == 0:
                continue
            visited[index] = 1
            queue = deque([(x, y)])
            component: list[int] = []
            while queue:
                current_x, current_y = queue.popleft()
                component.append(current_y * width + current_x)
                for offset_x, offset_y in neighbors:
                    next_x = current_x + offset_x
                    next_y = current_y + offset_y
                    if next_x < 0 or next_y < 0 or next_x >= width or next_y >= height:
                        continue
                    next_index = next_y * width + next_x
                    if visited[next_index] or pixels[next_x, next_y] == 0:
                        continue
                    visited[next_index] = 1
                    queue.append((next_x, next_y))
            if len(component) > len(largest):
                largest = component

    cleaned = Image.new("L", mask.size, 0)
    cleaned_pixels = cleaned.load()
    for index in largest:
        x = index % width
        y = index // width
        cleaned_pixels[x, y] = pixels[x, y]
    return cleaned


def _extract_glyphs(mask: Image.Image) -> list[dict]:
    glyphs: list[dict] = []
    for row_index, row in enumerate(CHARACTER_ROWS):
        for column_index, character in enumerate(row):
            cell_x = GRID_X + column_index * CELL_SIZE
            cell_y = GRID_Y + row_index * CELL_SIZE
            cell = mask.crop((cell_x + 8, cell_y + 8, cell_x + CELL_SIZE - 8, cell_y + CELL_SIZE - 8))
            if character.isalnum():
                cell = _keep_largest_component(cell)
            bbox = cell.getbbox()
            if bbox is None:
                raise RuntimeError(f"No handwriting found for {character!r}")

            cropped = cell.crop(bbox)
            scaled_size = (
                max(1, round(cropped.width * GLYPH_SCALE)),
                max(1, round(cropped.height * GLYPH_SCALE)),
            )
            scaled = cropped.resize(scaled_size, Image.Resampling.LANCZOS)
            source_y = 8 + bbox[1]
            patch_size = (
                scaled.width + PAD_LEFT + PAD_RIGHT,
                scaled.height + PAD_TOP + PAD_BOTTOM,
            )
            glyphs.append(
                {
                    "character": character,
                    "mask": scaled,
                    "patch_size": patch_size,
                    "xoffset": -PAD_LEFT,
                    "yoffset": round(source_y * GLYPH_SCALE) - PAD_TOP,
                    "xadvance": scaled.width + 24,
                }
            )
    return glyphs


def _pack_glyphs(glyphs: list[dict]) -> None:
    x = ATLAS_GAP
    y = ATLAS_GAP
    shelf_height = 0
    for glyph in glyphs:
        width, height = glyph["patch_size"]
        if x + width + ATLAS_GAP > ATLAS_SIZE:
            x = ATLAS_GAP
            y += shelf_height + ATLAS_GAP
            shelf_height = 0
        if y + height + ATLAS_GAP > ATLAS_SIZE:
            raise RuntimeError("The handwriting atlas no longer fits inside 2048×2048")
        glyph["atlas_x"] = x
        glyph["atlas_y"] = y
        x += width + ATLAS_GAP
        shelf_height = max(shelf_height, height)


def _color_layer(color: str, alpha: Image.Image, opacity: float = 1.0) -> Image.Image:
    layer = Image.new("RGBA", alpha.size, color)
    if opacity < 1.0:
        alpha = alpha.point(lambda value: round(value * opacity))
    layer.putalpha(alpha)
    return layer


def _render_patch(glyph: dict, style: dict) -> Image.Image:
    width, height = glyph["patch_size"]
    patch = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    glyph_mask: Image.Image = glyph["mask"]
    mask_origin = (PAD_LEFT, PAD_TOP)

    shadow = style["shadow"]
    if shadow is not None:
        shadow_mask = glyph_mask.filter(ImageFilter.MaxFilter(style["outline_size"] * 2 + 1))
        shadow_canvas = Image.new("L", patch.size, 0)
        shadow_canvas.paste(
            shadow_mask,
            (PAD_LEFT + shadow["offset"][0], PAD_TOP + shadow["offset"][1]),
        )
        shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(shadow["blur"]))
        patch.alpha_composite(_color_layer(shadow["color"], shadow_canvas, shadow["opacity"]))

    outline_mask = glyph_mask.filter(ImageFilter.MaxFilter(style["outline_size"] * 2 + 1))
    outline_canvas = Image.new("L", patch.size, 0)
    outline_canvas.paste(outline_mask, mask_origin)
    patch.alpha_composite(_color_layer(style["outline"], outline_canvas))

    fill_canvas = Image.new("L", patch.size, 0)
    fill_canvas.paste(glyph_mask, mask_origin)
    patch.alpha_composite(_color_layer(style["fill"], fill_canvas))
    return patch


def _write_bmfont(path: Path, atlas_name: str, glyphs: list[dict]) -> None:
    lines = [
        f'info face="Yufan Original Handwriting" size={FONT_SIZE} bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=0,0 outline=0',
        f"common lineHeight={LINE_HEIGHT} base={FONT_BASE} scaleW={ATLAS_SIZE} scaleH={ATLAS_SIZE} pages=1 packed=0 alphaChnl=0 redChnl=0 greenChnl=0 blueChnl=0",
        f'page id=0 file="{atlas_name}"',
        f"chars count={len(glyphs) + 1}",
        f"char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=70 page=0 chnl=15",
    ]
    for glyph in glyphs:
        lines.append(
            "char id={id} x={x} y={y} width={width} height={height} "
            "xoffset={xoffset} yoffset={yoffset} xadvance={xadvance} page=0 chnl=15".format(
                id=ord(glyph["character"]),
                x=glyph["atlas_x"],
                y=glyph["atlas_y"],
                width=glyph["patch_size"][0],
                height=glyph["patch_size"][1],
                xoffset=glyph["xoffset"],
                yoffset=glyph["yoffset"],
                xadvance=glyph["xadvance"],
            )
        )
    lines.append("kernings count=0")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def _render_sample(atlas: Image.Image, glyphs: list[dict], text: str) -> Image.Image:
    metrics = {glyph["character"]: glyph for glyph in glyphs}
    width = 40
    for character in text:
        width += 70 if character == " " else metrics[character]["xadvance"]
    image = Image.new("RGBA", (width + 40, LINE_HEIGHT + 80), (0, 0, 0, 0))
    cursor_x = 30
    for character in text:
        if character == " ":
            cursor_x += 70
            continue
        glyph = metrics[character]
        source_box = (
            glyph["atlas_x"],
            glyph["atlas_y"],
            glyph["atlas_x"] + glyph["patch_size"][0],
            glyph["atlas_y"] + glyph["patch_size"][1],
        )
        patch = atlas.crop(source_box)
        image.alpha_composite(
            patch,
            (cursor_x + glyph["xoffset"], 25 + glyph["yoffset"]),
        )
        cursor_x += glyph["xadvance"]
    return image


def _write_preview(path: Path, atlas: Image.Image, glyphs: list[dict]) -> None:
    preview = Image.new("RGBA", (1800, 820), "#352A25")
    draw = ImageDraw.Draw(preview)
    draw.rounded_rectangle((22, 22, 1778, 798), radius=38, outline="#99694D", width=4)
    samples = [
        "WELCOME HOME!!",
        "CURRENT XP: 2,400",
        "UNLOCK WITH 500 XP",
        "GO FISHING / AQUARIUM",
    ]
    y_positions = [70, 250, 430, 610]
    for sample, y in zip(samples, y_positions):
        line = _render_sample(atlas, glyphs, sample)
        max_width = 1540
        max_height = 130
        scale = min(max_width / line.width, max_height / line.height, 1.0)
        if scale < 1.0:
            line = line.resize(
                (round(line.width * scale), round(line.height * scale)),
                Image.Resampling.LANCZOS,
            )
        preview.alpha_composite(line, ((preview.width - line.width) // 2, y))
    preview.save(path)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    blank = Image.open(BLANK_TEMPLATE)
    filled = Image.open(FILLED_TEMPLATE)
    if blank.size != filled.size:
        raise RuntimeError(f"Template size mismatch: blank={blank.size}, filled={filled.size}")

    glyphs = _extract_glyphs(_difference_mask(blank, filled))
    _pack_glyphs(glyphs)

    for style in STYLES:
        atlas_name = f"yufan_hand_{style['slug']}.png"
        font_name = f"yufan_hand_{style['slug']}.fnt"
        preview_name = f"yufan_hand_{style['slug']}_preview.png"
        atlas = Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE), (0, 0, 0, 0))
        for glyph in glyphs:
            atlas.alpha_composite(
                _render_patch(glyph, style),
                (glyph["atlas_x"], glyph["atlas_y"]),
            )
        atlas.save(OUT / atlas_name)
        _write_bmfont(OUT / font_name, atlas_name, glyphs)
        _write_preview(OUT / preview_name, atlas, glyphs)
        print(OUT / font_name)


if __name__ == "__main__":
    main()
