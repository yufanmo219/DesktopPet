extends SceneTree

## Imagegen-authored gait based only on Sable's approved seated identity art.
## No prior walking sprite is loaded, sampled, traced or transformed here.
const SOURCE_PATH := "res://dev_only/unused_assets/assets/pets/black_cat/concepts/sable_walk_redraw_sheet_v3.png"
const LEFT_DIRECTORY := "res://assets/pets/black_cat/walk_left_v3"
const RIGHT_DIRECTORY := "res://assets/pets/black_cat/walk_right_v3"
const PREVIEW_DIRECTORY := "res://dev_only/artifacts/sable_walk_v3"
const CANVAS := Vector2i(704, 512)
const GROUND_Y := 498.0
const TARGET_CENTER_X := 352.0


func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	assert(sheet != null)
	_key_green(sheet)
	var cells: Array[Image] = []
	var anchors: Array[Vector2] = []
	var maximum_left := 0.0
	var maximum_right := 0.0
	var maximum_height := 0.0
	for index in range(12):
		var column := index % 4
		var row := index / 4
		var left := roundi(float(column) * sheet.get_width() / 4.0)
		var right := roundi(float(column + 1) * sheet.get_width() / 4.0)
		var top := roundi(float(row) * sheet.get_height() / 3.0)
		var bottom := roundi(float(row + 1) * sheet.get_height() / 3.0)
		var cell := sheet.get_region(Rect2i(left, top, right - left, bottom - top))
		_retain_connected_cat(cell)
		var bounds := cell.get_used_rect()
		print("source frame %02d cell=%s bounds=%s" % [index + 1, cell.get_size(), bounds])
		# The last pose has one fine whisker touching the cell's left edge; ears,
		# paws, body and tail all retain vertical padding and complete silhouettes.
		assert(bounds.position.y > 0 and bounds.end.y < cell.get_height(), "Every new Sable ear, paw and tail must be complete")
		var anchor := Vector2(_torso_center_x(cell), bounds.end.y - 1)
		maximum_left = maxf(maximum_left, anchor.x - bounds.position.x)
		maximum_right = maxf(maximum_right, bounds.end.x - anchor.x)
		maximum_height = maxf(maximum_height, bounds.size.y)
		cells.append(cell)
		anchors.append(anchor)
	var shared_scale := minf(
		minf(330.0 / maximum_left, 330.0 / maximum_right),
		470.0 / maximum_height
	)
	for directory in [LEFT_DIRECTORY, RIGHT_DIRECTORY, PREVIEW_DIRECTORY]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))

	var contact_sheet := Image.create(1408, 768, false, Image.FORMAT_RGBA8)
	contact_sheet.fill(Color("#e6d7c1"))
	for index in range(cells.size()):
		# Lanczos-resize the keyed source cell as a whole. This preserves the
		# generator's smooth curves much better than enlarging every output pixel
		# with a four-sample bilinear lookup.
		var scaled_cell := cells[index].duplicate() as Image
		scaled_cell.resize(
			roundi(scaled_cell.get_width() * shared_scale),
			roundi(scaled_cell.get_height() * shared_scale),
			Image.INTERPOLATE_LANCZOS
		)
		_clean_resampled_edge(scaled_cell)
		var scaled_bounds := scaled_cell.get_used_rect()
		var scaled_torso_center_x := _torso_center_x(scaled_cell)
		var destination := Vector2i(
			roundi(TARGET_CENTER_X - scaled_torso_center_x),
			roundi(GROUND_Y + 2.0 - scaled_bounds.end.y)
		)
		var left_frame := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
		left_frame.fill(Color.TRANSPARENT)
		var destination_rect := Rect2i(destination, scaled_cell.get_size()).intersection(
			Rect2i(Vector2i.ZERO, CANVAS)
		)
		var source_rect := Rect2i(destination_rect.position - destination, destination_rect.size)
		left_frame.blend_rect(scaled_cell, source_rect, destination_rect.position)

		# The body/gait is mirrored exactly. Sable is heterochromatic: her
		# left-facing near eye is amber; on the opposite side the visible near
		# eye is blue, so recolor only that tiny iris after mirroring.
		var right_frame := left_frame.duplicate() as Image
		right_frame.flip_x()
		_recolor_right_near_eye_blue(right_frame)
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
		var thumbnail := left_frame.duplicate() as Image
		thumbnail.resize(352, 256, Image.INTERPOLATE_LANCZOS)
		contact_sheet.blend_rect(
			thumbnail,
			Rect2i(0, 0, 352, 256),
			Vector2i(index % 4, index / 4) * Vector2i(352, 256)
		)
		print("frame %02d: scale=%.6f torso anchor=%s bounds=%s" % [
			index + 1, shared_scale, anchors[index], left_frame.get_used_rect()
		])
	contact_sheet.save_png(ProjectSettings.globalize_path("%s/contact_sheet.png" % PREVIEW_DIRECTORY))
	quit(0)


func _retain_connected_cat(image: Image) -> void:
	# A few generated whisker strokes cross a neighboring grid boundary. Keep
	# only the one connected full-cat silhouette in each cell so no fragment of
	# the next pose can enter a runtime frame.
	var size := image.get_size()
	var center := Vector2(size) * 0.5
	var seed := Vector2i(-1, -1)
	var closest_distance := INF
	for y in range(size.y):
		for x in range(size.x):
			if image.get_pixel(x, y).a <= 0.01:
				continue
			var distance := Vector2(x, y).distance_squared_to(center)
			if distance < closest_distance:
				closest_distance = distance
				seed = Vector2i(x, y)
	assert(seed.x >= 0)
	var connected := PackedByteArray()
	connected.resize(size.x * size.y)
	var queue: Array[Vector2i] = [seed]
	connected[seed.y * size.x + seed.x] = 1
	var cursor := 0
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while cursor < queue.size():
		var point := queue[cursor]
		cursor += 1
		for direction in directions:
			var neighbor: Vector2i = point + direction
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= size.x or neighbor.y >= size.y:
				continue
			var offset: int = neighbor.y * size.x + neighbor.x
			if connected[offset] == 0 and image.get_pixelv(neighbor).a > 0.01:
				connected[offset] = 1
				queue.append(neighbor)
	for y in range(size.y):
		for x in range(size.x):
			if connected[y * size.x + x] == 0:
				image.set_pixel(x, y, Color.TRANSPARENT)


func _torso_center_x(image: Image) -> float:
	var bounds := image.get_used_rect()
	var weighted_x := 0.0
	var total_weight := 0.0
	for y in range(
		bounds.position.y + roundi(bounds.size.y * 0.43),
		bounds.position.y + roundi(bounds.size.y * 0.64)
	):
		for x in range(
			bounds.position.x + roundi(bounds.size.x * 0.30),
			bounds.position.x + roundi(bounds.size.x * 0.71)
		):
			var alpha := image.get_pixel(x, y).a
			weighted_x += x * alpha
			total_weight += alpha
	return weighted_x / maxf(total_weight, 0.001)


func _key_green(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var other_max := maxf(color.r, color.b)
			var green_dominance := color.g - other_max
			if color.g > 64.0 / 255.0 and green_dominance > 5.0 / 255.0:
				# Recover a soft coverage ramp from the chroma matte instead of
				# cutting it at one hard threshold. Dark edge pixels stay dark and
				# partially transparent, producing smooth short-hair contours.
				# This generated matte is a slightly varied vivid green whose empty
				# regions have 0.65+ green dominance. Map that range to transparent,
				# while retaining a broad soft ramp through contaminated edge pixels.
				color.a *= clampf((0.68 - green_dominance) / 0.66, 0.0, 1.0)
				color.g = other_max
			if color.a <= 16.0 / 255.0:
				color = Color.TRANSPARENT
			image.set_pixel(x, y, color)


func _clean_resampled_edge(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.g > maxf(color.r, color.b) + 5.0 / 255.0:
				color.g = maxf(color.r, color.b)
			if color.a <= 6.0 / 255.0:
				color = Color.TRANSPARENT
			image.set_pixel(x, y, color)


func _recolor_right_near_eye_blue(image: Image) -> void:
	# Mirror of the left-facing amber eye. The tight mask protects ears, nose,
	# whiskers and the solid charcoal coat.
	for y in range(108, 178):
		for x in range(560, 642):
			var color := image.get_pixel(x, y)
			if (
				color.a > 0.45
				and color.r > 0.46
				and color.r > color.g * 1.12
				and color.g > color.b * 1.20
			):
				var brightness := maxf(color.r, color.g)
				color.r = brightness * 0.34
				color.g = brightness * 0.76
				color.b = minf(1.0, brightness * 1.08)
				image.set_pixel(x, y, color)


func _sample_premultiplied(image: Image, point: Vector2) -> Color:
	var base := Vector2i(floori(point.x), floori(point.y))
	var fraction := point - Vector2(base)
	var result := Color(0, 0, 0, 0)
	for dy in range(2):
		for dx in range(2):
			var position := base + Vector2i(dx, dy)
			if (
				position.x < 0
				or position.y < 0
				or position.x >= image.get_width()
				or position.y >= image.get_height()
			):
				continue
			var weight := (
				(fraction.x if dx else 1.0 - fraction.x)
				* (fraction.y if dy else 1.0 - fraction.y)
			)
			var color := image.get_pixelv(position)
			result += Color(color.r * color.a, color.g * color.a, color.b * color.a, color.a) * weight
	if result.a > 0.0:
		result.r /= result.a
		result.g /= result.a
		result.b /= result.a
	return result
