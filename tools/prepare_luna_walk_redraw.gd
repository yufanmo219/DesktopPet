extends SceneTree

## Newly imagegen-authored gait, using only Luna's static identity reference.
## No pixels or motion from the previous walking animations are consumed.
const SOURCE_PATH := "res://dev_only/unused_assets/assets/pets/russian_blue/concepts/luna_walk_redraw_sheet_v3.png"
const LEFT_DIRECTORY := "res://assets/pets/russian_blue/walk_left_v3"
const RIGHT_DIRECTORY := "res://assets/pets/russian_blue/walk_right_v3"
const PREVIEW_DIRECTORY := "res://dev_only/artifacts/luna_walk_v3"
const CANVAS := Vector2i(704, 512)
const GROUND_Y := 498.0


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	assert(sheet != null)
	_key_cyan(sheet)
	var cells: Array[Image] = []
	var anchors: Array[Vector2] = []
	var maximum_left := 0.0
	var maximum_right := 0.0
	var maximum_height := 0.0
	for index in range(12):
		var col := index % 4
		var row := index / 4
		var left := roundi(float(col) * sheet.get_width() / 4.0)
		var right := roundi(float(col + 1) * sheet.get_width() / 4.0)
		var top := roundi(float(row) * sheet.get_height() / 3.0)
		var bottom := roundi(float(row + 1) * sheet.get_height() / 3.0)
		var cell := sheet.get_region(Rect2i(left, top, right - left, bottom - top))
		var bounds := cell.get_used_rect()
		assert(Rect2i(6, 6, cell.get_width() - 12, cell.get_height() - 12).encloses(bounds), "Every newly drawn ear, paw and tail must be complete")
		var anchor := Vector2(_torso_center_x(cell), bounds.end.y - 1)
		maximum_left = maxf(maximum_left, anchor.x - bounds.position.x)
		maximum_right = maxf(maximum_right, bounds.end.x - anchor.x)
		maximum_height = maxf(maximum_height, bounds.size.y)
		cells.append(cell)
		anchors.append(anchor)
	var shared_scale := minf(minf(330.0 / maximum_left, 330.0 / maximum_right), 470.0 / maximum_height)
	for directory in [LEFT_DIRECTORY, RIGHT_DIRECTORY, PREVIEW_DIRECTORY]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var gallery := Image.create(1408, 768, false, Image.FORMAT_RGBA8)
	gallery.fill(Color("#e6d7c1"))
	for index in range(cells.size()):
		var left_frame := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
		left_frame.fill(Color.TRANSPARENT)
		for y in range(CANVAS.y):
			for x in range(CANVAS.x):
				var point := anchors[index] + (Vector2(x, y) - Vector2(352.0, GROUND_Y)) / shared_scale
				var color := _sample_premultiplied(cells[index], point)
				# Resampling can mix a protected green iris with adjacent colors.
				# Keep the eyes intact; neutralize any residual cyan elsewhere.
				if not Rect2i(34, 156, 132, 65).has_point(Vector2i(x, y)) and minf(color.g, color.b) > color.r + 7.0 / 255.0:
					color.g = minf(color.g, color.r)
					color.b = minf(color.b, color.r + 12.0 / 255.0)
				left_frame.set_pixel(x, y, color)
		# Luna has no asymmetric coat markings. Mirror the NEW complete cycle
		# so direction changes preserve identical anatomy, gait and visual size.
		var right_frame := left_frame.duplicate() as Image
		right_frame.flip_x()
		for direction in ["left", "right"]:
			var frame := left_frame if direction == "left" else right_frame
			var directory := LEFT_DIRECTORY if direction == "left" else RIGHT_DIRECTORY
			assert(frame.save_png(ProjectSettings.globalize_path("%s/frame_%02d.png" % [directory, index + 1])) == OK)
		var preview := Image.create(1088, 412, false, Image.FORMAT_RGBA8)
		preview.fill(Color("#e6d7c1"))
		for direction_index in range(2):
			var small := (left_frame if direction_index == 0 else right_frame).duplicate() as Image
			small.resize(528, 384, Image.INTERPOLATE_LANCZOS)
			preview.blend_rect(small, Rect2i(0, 0, 528, 384), Vector2i(8 + direction_index * 544, 14))
		preview.save_png(ProjectSettings.globalize_path("%s/frame_%02d.png" % [PREVIEW_DIRECTORY, index + 1]))
		var thumb := left_frame.duplicate() as Image
		thumb.resize(352, 256, Image.INTERPOLATE_LANCZOS)
		gallery.blend_rect(thumb, Rect2i(0, 0, 352, 256), Vector2i(index % 4, index / 4) * Vector2i(352, 256))
		print("frame %02d: scale=%.6f body anchor=%s bounds=%s" % [index + 1, shared_scale, anchors[index], left_frame.get_used_rect()])
	gallery.save_png(ProjectSettings.globalize_path("%s/contact_sheet.png" % PREVIEW_DIRECTORY))
	quit(0)


func _torso_center_x(image: Image) -> float:
	var bounds := image.get_used_rect()
	var total := 0.0
	var weight := 0.0
	for y in range(bounds.position.y + roundi(bounds.size.y * 0.43), bounds.position.y + roundi(bounds.size.y * 0.64)):
		for x in range(bounds.position.x + roundi(bounds.size.x * 0.30), bounds.position.x + roundi(bounds.size.x * 0.71)):
			var alpha := image.get_pixel(x, y).a
			total += x * alpha
			weight += alpha
	return total / maxf(weight, 0.001)


func _key_cyan(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var dominance := minf(color.g, color.b) - color.r
			var column := mini(3, floori(float(x) * 4.0 / image.get_width()))
			var row := mini(2, floori(float(y) * 3.0 / image.get_height()))
			var cell_point := Vector2i(x - roundi(float(column) * image.get_width() / 4.0), y - roundi(float(row) * image.get_height() / 3.0))
			var is_green_iris := Rect2i(35, 95, 95, 52).has_point(cell_point) and color.g > color.r + 0.04 and color.g > color.b + 0.04
			if dominance > 7.0 / 255.0 and not is_green_iris:
				if minf(color.g, color.b) > 80.0 / 255.0:
					color.a *= clampf((52.0 / 255.0 - dominance) / (45.0 / 255.0), 0.0, 1.0)
				color.g = minf(color.g, color.r)
				color.b = minf(color.b, color.r + 12.0 / 255.0)
			if color.a <= 8.0 / 255.0:
				color = Color.TRANSPARENT
			# Cyan, rather than green, lets us key every enclosed leg/tail gap
			# without masking or damaging Luna's green eyes or pink inner ears.
			image.set_pixel(x, y, color)


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
