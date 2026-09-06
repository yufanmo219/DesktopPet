extends SceneTree

## Recover original tail pixels that crossed the old 4x2 sheet's cell borders.
## No generated or redrawn artwork: existing runtime pixels stay untouched.
const SHEET_PATH := "res://dev_only/unused_assets/assets/pets/mochi/fishing/source/mochi_fishing_cry_spritesheet_chroma.png"
const ORIGINAL_DIRECTORY := "res://dev_only/unused_assets/assets/pets/mochi/fishing/cry"
const OUTPUT_DIRECTORY := "res://assets/pets/mochi/fishing/cry_v2"
const COLUMN_EDGES := [0, 314, 627, 940, 1254]
const ROW_HEIGHT := 627
const DISPLAY_HEIGHT := 520
const DISPLAY_TOP := 70


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET_PATH))
	if sheet == null:
		push_error("Missing original Mochi fishing cry sheet")
		quit(1)
		return
	_key_green_background(sheet)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	for index in range(8):
		var source := Image.load_from_file(ProjectSettings.globalize_path("%s/frame_%02d.png" % [ORIGINAL_DIRECTORY, index + 1]))
		var output := source.duplicate() as Image
		var column := index % 4
		var row := floori(float(index) / 4)
		var added_pixels := 0
		if column != 0:
			# Follow the connected silhouette from its own torso. Unlike a grid
			# crop, this includes its tail but never a neighboring cat's fragment.
			var seed := Vector2i((COLUMN_EDGES[column] + COLUMN_EDGES[column + 1]) / 2, row * ROW_HEIGHT + 350)
			var subject := _isolate_subject(sheet, seed)
			var full_bounds := subject.get_used_rect()
			assert(full_bounds.position.x < COLUMN_EDGES[column], "Expected a tail extending beyond the old crop")
			var visible := source.get_used_rect()
			var crop_bounds := full_bounds.intersection(Rect2i(COLUMN_EDGES[column], row * ROW_HEIGHT, COLUMN_EDGES[column + 1] - COLUMN_EDGES[column], ROW_HEIGHT))
			var scale_x := float(visible.size.x) / crop_bounds.size.x
			var scale_y := float(DISPLAY_HEIGHT) / crop_bounds.size.y
			for y in range(DISPLAY_TOP, DISPLAY_TOP + DISPLAY_HEIGHT):
				for x in range(visible.position.x):
					var sample_point := Vector2(
						crop_bounds.position.x + (x - visible.position.x + 0.5) / scale_x - 0.5,
						crop_bounds.position.y + (y - DISPLAY_TOP + 0.5) / scale_y - 0.5
					)
					var color := _sample_premultiplied(subject, sample_point)
					if color.a > 0.01:
						output.set_pixel(x, y, color)
						added_pixels += 1
			print("frame %02d: source=%s, old crop=%s, restored=%d pixels" % [index + 1, full_bounds, crop_bounds, added_pixels])
		var error := output.save_png(ProjectSettings.globalize_path("%s/frame_%02d.png" % [OUTPUT_DIRECTORY, index + 1]))
		if error != OK:
			push_error("Cannot save repaired Mochi crying frame")
			quit(1)
			return
	quit(0)


func _key_green_background(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var dominance := color.g - maxf(color.r, color.b)
			if color.g > 80.0 / 255.0 and dominance > 7.0 / 255.0:
				color.a *= clampf((52.0 / 255.0 - dominance) / (45.0 / 255.0), 0.0, 1.0)
				color.g = minf(color.g, maxf(color.r, color.b) + 8.0 / 255.0)
			if color.a <= 8.0 / 255.0:
				color = Color.TRANSPARENT
			image.set_pixel(x, y, color)


func _isolate_subject(sheet: Image, seed: Vector2i) -> Image:
	var subject := Image.create(sheet.get_width(), sheet.get_height(), false, Image.FORMAT_RGBA8)
	subject.fill(Color.TRANSPARENT)
	var visited := PackedByteArray()
	visited.resize(sheet.get_width() * sheet.get_height())
	var queue := PackedVector2Array([Vector2(seed)])
	var next := 0
	while next < queue.size():
		var point := Vector2i(queue[next])
		next += 1
		if point.x < 0 or point.y < 0 or point.x >= sheet.get_width() or point.y >= sheet.get_height():
			continue
		var key := point.y * sheet.get_width() + point.x
		if visited[key]:
			continue
		visited[key] = 1
		var color := sheet.get_pixelv(point)
		if color.a == 0.0:
			continue
		subject.set_pixelv(point, color)
		for delta in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			queue.append(Vector2(point + delta))
	return subject


func _sample_premultiplied(image: Image, point: Vector2) -> Color:
	var base := Vector2i(floori(point.x), floori(point.y))
	var fraction := point - Vector2(base)
	var result := Color(0, 0, 0, 0)
	for dy in range(2):
		for dx in range(2):
			var position := base + Vector2i(dx, dy)
			if position.x < 0 or position.y < 0 or position.x >= image.get_width() or position.y >= image.get_height():
				continue
			var weight := (fraction.x if dx else 1.0 - fraction.x) * (fraction.y if dy else 1.0 - fraction.y)
			var color := image.get_pixelv(position)
			result += Color(color.r * color.a, color.g * color.a, color.b * color.a, color.a) * weight
	if result.a > 0.0:
		result.r /= result.a
		result.g /= result.a
		result.b /= result.a
	return result
