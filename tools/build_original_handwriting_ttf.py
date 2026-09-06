"""Vectorize the filled handwriting sheet into a real TrueType font."""

from __future__ import annotations

from collections import deque
from pathlib import Path
import math

import numpy as np
from PIL import Image, ImageChops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen


ROOT = Path(__file__).resolve().parents[1]
BLANK_TEMPLATE = ROOT / "dev_only/unused_assets/assets/font_sheets/original_handwriting_template.png"
FILLED_TEMPLATE = ROOT / "dev_only/unused_assets/assets/font_source/original_handwriting_filled.png"
OUTPUT = ROOT / "assets/fonts/original_handwriting/yufan_original_handwriting.ttf"

GRID_X = 120
GRID_Y = 220
CELL_SIZE = 300
SOURCE_BASELINE_Y = 235
UNITS_PER_EM = 1000
PIXEL_TO_UNITS = 3.45
LEFT_BEARING = 52
RIGHT_BEARING = 58
ASCENT = 820
DESCENT = -220
SIMPLIFY_TOLERANCE = 1.15

CHARACTER_ROWS = [
    list("ABCDEFG"),
    list("HIJKLMN"),
    list("OPQRSTU"),
    list("VWXYZ01"),
    list("2345678"),
    ["9", "!", "?", ".", ",", ":", "'"],
    ["+", "-", "/", "%", "←", "(", ")"],
]


Point = tuple[int, int]


def _difference_mask(blank: Image.Image, filled: Image.Image) -> np.ndarray:
    difference = ImageChops.difference(blank.convert("RGB"), filled.convert("RGB")).convert("L")
    values = np.asarray(difference, dtype=np.uint8)
    return values > 12


def _components(binary: np.ndarray) -> list[list[Point]]:
    height, width = binary.shape
    visited = np.zeros_like(binary, dtype=bool)
    result: list[list[Point]] = []
    for y in range(height):
        for x in range(width):
            if not binary[y, x] or visited[y, x]:
                continue
            visited[y, x] = True
            queue: deque[Point] = deque([(x, y)])
            component: list[Point] = []
            while queue:
                current_x, current_y = queue.popleft()
                component.append((current_x, current_y))
                for offset_x, offset_y in (
                    (-1, -1), (0, -1), (1, -1),
                    (-1, 0),            (1, 0),
                    (-1, 1),  (0, 1),   (1, 1),
                ):
                    next_x = current_x + offset_x
                    next_y = current_y + offset_y
                    if next_x < 0 or next_y < 0 or next_x >= width or next_y >= height:
                        continue
                    if binary[next_y, next_x] and not visited[next_y, next_x]:
                        visited[next_y, next_x] = True
                        queue.append((next_x, next_y))
            result.append(component)
    return result


def _clean_cell(cell: np.ndarray, character: str) -> np.ndarray:
    components = _components(cell)
    if not components:
        raise RuntimeError(f"No handwriting found for {character!r}")
    components.sort(key=len, reverse=True)
    if character.isalnum():
        components = components[:1]
    else:
        minimum_area = max(5, round(len(components[0]) * 0.012))
        components = [component for component in components if len(component) >= minimum_area]
    cleaned = np.zeros_like(cell, dtype=bool)
    for component in components:
        for x, y in component:
            cleaned[y, x] = True
    return cleaned


def _direction(start: Point, end: Point) -> int:
    delta = (end[0] - start[0], end[1] - start[1])
    return {(1, 0): 0, (0, 1): 1, (-1, 0): 2, (0, -1): 3}[delta]


def _choose_next(previous: Point, current: Point, candidates: set[Point]) -> Point:
    previous_direction = _direction(previous, current)
    priority = {1: 0, 0: 1, 3: 2, 2: 3}
    return min(
        candidates,
        key=lambda candidate: priority[(_direction(current, candidate) - previous_direction) % 4],
    )


def _trace_contours(binary: np.ndarray) -> list[list[Point]]:
    height, width = binary.shape
    edges: set[tuple[Point, Point]] = set()
    for y in range(height):
        for x in range(width):
            if not binary[y, x]:
                continue
            if y == 0 or not binary[y - 1, x]:
                edges.add(((x, y), (x + 1, y)))
            if x == width - 1 or not binary[y, x + 1]:
                edges.add(((x + 1, y), (x + 1, y + 1)))
            if y == height - 1 or not binary[y + 1, x]:
                edges.add(((x + 1, y + 1), (x, y + 1)))
            if x == 0 or not binary[y, x - 1]:
                edges.add(((x, y + 1), (x, y)))

    outgoing: dict[Point, set[Point]] = {}
    for start, end in edges:
        outgoing.setdefault(start, set()).add(end)

    contours: list[list[Point]] = []
    while edges:
        start, first_end = min(edges)
        contour = [start]
        previous = start
        current = first_end
        while True:
            edge = (previous, current)
            edges.remove(edge)
            outgoing[previous].remove(current)
            contour.append(current)
            if current == start:
                break
            candidates = outgoing.get(current, set())
            if not candidates:
                raise RuntimeError("Open contour found while vectorizing handwriting")
            next_point = _choose_next(previous, current, candidates)
            previous, current = current, next_point
        if len(contour) >= 5:
            contours.append(contour[:-1])
    return contours


def _point_line_distance(point: Point, start: Point, end: Point) -> float:
    if start == end:
        return math.dist(point, start)
    delta_x = end[0] - start[0]
    delta_y = end[1] - start[1]
    numerator = abs(delta_y * point[0] - delta_x * point[1] + end[0] * start[1] - end[1] * start[0])
    return numerator / math.hypot(delta_x, delta_y)


def _rdp(points: list[Point], tolerance: float) -> list[Point]:
    if len(points) <= 2:
        return points
    farthest_index = 0
    farthest_distance = 0.0
    for index in range(1, len(points) - 1):
        distance = _point_line_distance(points[index], points[0], points[-1])
        if distance > farthest_distance:
            farthest_distance = distance
            farthest_index = index
    if farthest_distance <= tolerance:
        return [points[0], points[-1]]
    left = _rdp(points[: farthest_index + 1], tolerance)
    right = _rdp(points[farthest_index:], tolerance)
    return left[:-1] + right


def _simplify_closed(contour: list[Point]) -> list[Point]:
    if len(contour) < 8:
        return contour
    first = contour[0]
    opposite_index = max(range(1, len(contour)), key=lambda index: math.dist(first, contour[index]))
    first_half = _rdp(contour[: opposite_index + 1], SIMPLIFY_TOLERANCE)
    second_half = _rdp(contour[opposite_index:] + [contour[0]], SIMPLIFY_TOLERANCE)
    simplified = first_half[:-1] + second_half[:-1]
    return simplified if len(simplified) >= 3 else contour


def _glyph_name(character: str) -> str:
    if character == " ":
        return "space"
    return f"uni{ord(character):04X}"


def _make_glyph(cell: np.ndarray, cell_left: int) -> tuple[object, tuple[int, int]]:
    ys, xs = np.nonzero(cell)
    left = int(xs.min())
    right = int(xs.max()) + 1
    contours = _trace_contours(cell)
    pen = TTGlyphPen(None)
    for contour in contours:
        points = _simplify_closed(contour)
        font_points = [
            (
                round((x - left) * PIXEL_TO_UNITS + LEFT_BEARING),
                round((SOURCE_BASELINE_Y - y) * PIXEL_TO_UNITS),
            )
            for x, y in points
        ]
        pen.moveTo(font_points[0])
        for point in font_points[1:]:
            pen.lineTo(point)
        pen.closePath()
    advance = round((right - left) * PIXEL_TO_UNITS + LEFT_BEARING + RIGHT_BEARING)
    return pen.glyph(), (advance, LEFT_BEARING)


def main() -> None:
    blank = Image.open(BLANK_TEMPLATE)
    filled = Image.open(FILLED_TEMPLATE)
    if blank.size != filled.size:
        raise RuntimeError("The blank and filled handwriting templates must have the same dimensions")
    difference = _difference_mask(blank, filled)

    glyph_order = [".notdef", "space"]
    glyphs: dict[str, object] = {}
    metrics: dict[str, tuple[int, int]] = {}
    character_map: dict[int, str] = {32: "space"}

    empty_pen = TTGlyphPen(None)
    glyphs[".notdef"] = empty_pen.glyph()
    metrics[".notdef"] = (600, 0)
    glyphs["space"] = TTGlyphPen(None).glyph()
    metrics["space"] = (310, 0)

    for row_index, row in enumerate(CHARACTER_ROWS):
        for column_index, character in enumerate(row):
            cell_x = GRID_X + column_index * CELL_SIZE
            cell_y = GRID_Y + row_index * CELL_SIZE
            cell = difference[cell_y : cell_y + CELL_SIZE, cell_x : cell_x + CELL_SIZE]
            cell = _clean_cell(cell, character)
            name = _glyph_name(character)
            glyph, metric = _make_glyph(cell, cell_x)
            glyph_order.append(name)
            glyphs[name] = glyph
            metrics[name] = metric
            character_map[ord(character)] = name

    builder = FontBuilder(UNITS_PER_EM, isTTF=True)
    builder.setupGlyphOrder(glyph_order)
    builder.setupCharacterMap(character_map)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(metrics)
    builder.setupHorizontalHeader(ascent=ASCENT, descent=DESCENT, lineGap=80)
    builder.setupNameTable(
        {
            "familyName": "Yufan Original Handwriting",
            "styleName": "Regular",
            "uniqueFontIdentifier": "YufanOriginalHandwriting-Regular-2026",
            "fullName": "Yufan Original Handwriting Regular",
            "psName": "YufanOriginalHandwriting-Regular",
            "version": "Version 1.000",
        }
    )
    builder.setupOS2(
        sTypoAscender=ASCENT,
        sTypoDescender=DESCENT,
        sTypoLineGap=80,
        usWinAscent=850,
        usWinDescent=250,
        sxHeight=520,
        sCapHeight=700,
    )
    builder.setupPost()
    builder.setupMaxp()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    builder.save(OUTPUT)
    print(OUTPUT)


if __name__ == "__main__":
    main()
