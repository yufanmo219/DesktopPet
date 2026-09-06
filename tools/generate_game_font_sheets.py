from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path("/Users/yufanmo/Documents/Steam游戏")
OUT = ROOT / "dev_only" / "outputs" / "font_sheets"
FONT_PATH = Path("/System/Library/Fonts/Supplemental/ChalkboardSE.ttc")
FONT_INDEX = 2  # Chalkboard SE Bold: casual, readable handwritten uppercase.

W, H = 1800, 700
SCALE = 2
FONT_SIZE = 126 * SCALE
ROWS = ("ABCDEFGHIJKLM", "NOPQRSTUVWXYZ", "0123456789")
ROW_Y = (86, 274, 476)

INK_DARK = "#684230"
INK_DEEP = "#3D271F"
WHITE_TOP = "#FFFFFF"
WHITE_BOTTOM = "#FFFFFF"
ACCENT_CORAL = "#E98555"


def linear_gradient(size, top, bottom):
    width, height = size
    top_rgb = Image.new("RGB", (1, 1), top).getpixel((0, 0))
    bottom_rgb = Image.new("RGB", (1, 1), bottom).getpixel((0, 0))
    gradient = Image.new("RGBA", size)
    pixels = gradient.load()
    for y in range(height):
        t = y / max(1, height - 1)
        color = tuple(round(a * (1 - t) + b * t) for a, b in zip(top_rgb, bottom_rgb)) + (255,)
        for x in range(width):
            pixels[x, y] = color
    return gradient


def centered_x(draw, text, font, stroke_width=0):
    box = draw.textbbox((0, 0), text, font=font, stroke_width=stroke_width)
    return (W * SCALE - (box[2] - box[0])) // 2


def draw_row(base, text, y, font, style):
    canvas_size = (W * SCALE, H * SCALE)
    x = centered_x(ImageDraw.Draw(base), text, font, stroke_width=style["stroke"])
    y *= SCALE

    if style["shadow"]:
        shadow = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sx, sy = style["shadow_offset"]
        sd.text(
            (x + sx * SCALE, y + sy * SCALE),
            text,
            font=font,
            fill=INK_DARK,
            stroke_width=style["shadow_stroke"] * SCALE,
            stroke_fill=INK_DEEP,
        )
        shadow = shadow.filter(ImageFilter.GaussianBlur(radius=0.45 * SCALE))
        base.alpha_composite(shadow)

    outline = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    od = ImageDraw.Draw(outline)
    od.text(
        (x, y),
        text,
        font=font,
        fill=INK_DARK,
        stroke_width=style["stroke"] * SCALE,
        stroke_fill=INK_DARK,
    )
    base.alpha_composite(outline)

    mask = Image.new("L", canvas_size, 0)
    md = ImageDraw.Draw(mask)
    md.text((x, y), text, font=font, fill=255)
    fill = linear_gradient(canvas_size, style["top"], style["bottom"])
    fill.putalpha(mask)
    base.alpha_composite(fill)

    if style["highlight"]:
        highlight = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
        hd = ImageDraw.Draw(highlight)
        hd.text(
            (x, y - 1 * SCALE),
            text,
            font=font,
            fill=(255, 255, 255, 42),
            stroke_width=1 * SCALE,
            stroke_fill=(255, 255, 255, 24),
        )
        highlight.putalpha(Image.composite(highlight.getchannel("A"), Image.new("L", canvas_size, 0), mask))
        base.alpha_composite(highlight)


def make_sheet(filename, style):
    font = ImageFont.truetype(str(FONT_PATH), FONT_SIZE, index=FONT_INDEX)
    sheet = Image.new("RGBA", (W * SCALE, H * SCALE), (0, 0, 0, 0))
    for text, y in zip(ROWS, ROW_Y):
        draw_row(sheet, text, y, font, style)
    sheet = sheet.resize((W, H), Image.Resampling.LANCZOS)
    sheet.save(OUT / filename)
    return sheet


def make_preview(filename, title, sheet):
    preview = Image.new("RGBA", (W, H + 140), "#352A25")
    draw = ImageDraw.Draw(preview)

    # Subtle diagonal game-UI pattern.
    for x in range(-H, W, 110):
        draw.polygon(
            [(x, 0), (x + 54, 0), (x + H + 54, H + 140), (x + H, H + 140)],
            fill="#3C302A",
        )
    draw.rounded_rectangle((18, 18, W - 18, H + 122), radius=38, outline="#99694D", width=4)

    title_font = ImageFont.truetype(str(FONT_PATH), 42, index=FONT_INDEX)
    draw.text((64, 48), title, font=title_font, fill="#F6E5CF")
    draw.text((W - 270, 54), "A–Z  0–9", font=title_font, fill="#C59B79")
    # Paste with the sheet's alpha mask so transparent areas never replace the card.
    preview.paste(sheet, (0, 118), sheet)
    preview.save(OUT / filename)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    styles = [
        (
            "handwritten-group-1-white-no-shadow.png",
            "handwritten-group-1-preview.png",
            "GROUP 1 / WHITE / NO SHADOW",
            {
                "top": WHITE_TOP,
                "bottom": WHITE_BOTTOM,
                "stroke": 2,
                "shadow": False,
                "shadow_offset": (0, 0),
                "shadow_stroke": 0,
                "highlight": False,
            },
        ),
        (
            "handwritten-group-2-coral-shadow.png",
            "handwritten-group-2-preview.png",
            "GROUP 2 / WARM CORAL / SHADOW",
            {
                "top": ACCENT_CORAL,
                "bottom": ACCENT_CORAL,
                "stroke": 4,
                "shadow": True,
                "shadow_offset": (5, 9),
                "shadow_stroke": 5,
                "highlight": True,
            },
        ),
        (
            "handwritten-group-3-white-shadow.png",
            "handwritten-group-3-preview.png",
            "GROUP 3 / WHITE / SHADOW",
            {
                "top": WHITE_TOP,
                "bottom": WHITE_BOTTOM,
                "stroke": 4,
                "shadow": True,
                "shadow_offset": (5, 9),
                "shadow_stroke": 5,
                "highlight": True,
            },
        ),
    ]

    for sheet_name, preview_name, title, style in styles:
        sheet = make_sheet(sheet_name, style)
        make_preview(preview_name, title, sheet)


if __name__ == "__main__":
    main()
