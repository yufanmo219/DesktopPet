extends SceneTree

## Use imagegen's corrected moving-arm layer, with the original far front paw
## copied once at its original canvas coordinates and composited behind every
## moving pose. The fixed paw is never redrawn, scaled or translated.
const BASE_PATH := "res://assets/pets/russian_blue/sleep/luna_sleep_v2.png"
const SOURCE_PATH := "res://dev_only/unused_assets/assets/pets/russian_blue/concepts/luna_sleep_face_wash_layer_sheet_v3.png"
const JOIN_PATH := "res://dev_only/unused_assets/assets/pets/russian_blue/concepts/luna_sleep_stationary_foreleg_join_v3.png"
const OUTPUT_DIRECTORY := "res://dev_only/outputs/prepared_assets/pets/russian_blue/sleep/face_wash_v3"
const PREVIEW_DIRECTORY := "res://dev_only/artifacts/luna_sleep_face_wash_v3"
# Imagegen's cats extend slightly beyond the mathematical quarter boundaries.
# Split in the actual empty gutters so no ear/tail pixels are clipped.
const COLUMN_EDGES := [0, 427, 827, 1222, 1618]
const ROW_EDGES := [0, 324, 648, 972]
# The generated sheet repeats neutral poses at each row's beginning. Arrange
# only the accepted bent-arm poses into one lift/wipe/lower, with no upright paw.
const FRAME_ORDER := [-1, -1, 2, 3, 5, 6, 5, 7, 10, 2, -1, -1]


func _initialize() -> void:
	var base := Image.load_from_file(ProjectSettings.globalize_path(BASE_PATH))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	assert(base != null and sheet != null)
	base.convert(Image.FORMAT_RGBA8)
	_key_green_background(sheet)
	var cells: Array[Image] = []
	for index in range(12):
		var column := index % 4
		var row := index / 4
		var cell := sheet.get_region(Rect2i(COLUMN_EDGES[column], ROW_EDGES[row], COLUMN_EDGES[column + 1] - COLUMN_EDGES[column], ROW_EDGES[row + 1] - ROW_EDGES[row]))
		assert(Rect2i(4, 4, cell.get_width() - 8, cell.get_height() - 8).encloses(cell.get_used_rect()), "Ears and tails must retain full padding")
		cells.append(cell)
	# Calibrate the sheet once to the approved static silhouette, including its
	# original low, wide aspect ratio. Reuse exactly this transform for all poses.
	var stationary_paw := _original_stationary_paw(base)
	var base_bounds := base.get_used_rect()
	var shared_scale := Vector2(base_bounds.size) / Vector2(cells[1].get_used_rect().size)
	var target_anchor := Vector2(base_bounds.end - Vector2i.ONE)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIRECTORY))
	stationary_paw.save_png(ProjectSettings.globalize_path("%s/stationary_paw.png" % OUTPUT_DIRECTORY))
	var gallery := Image.create(1280, 768, false, Image.FORMAT_RGBA8)
	gallery.fill(Color("#cbb296"))
	for index in range(FRAME_ORDER.size()):
		var source_index: int = FRAME_ORDER[index]
		var frame := base.duplicate() as Image
		if source_index >= 0:
			var cell := cells[source_index]
			# Register from the unmoving tail/right-body silhouette, not the face
			# or raised forepaw. All frames keep a fixed rear edge and ground line.
			var source_anchor := Vector2(cell.get_used_rect().end - Vector2i.ONE)
			frame.fill(Color.TRANSPARENT)
			for y in range(frame.get_height()):
				for x in range(frame.get_width()):
					var source_point := source_anchor + (Vector2(x, y) - target_anchor) / shared_scale
					frame.set_pixel(x, y, _sample_premultiplied(cell, source_point))
			var combined := stationary_paw.duplicate() as Image
			combined.blend_rect(frame, Rect2i(0, 0, 640, 512), Vector2i.ZERO)
			frame = combined
		var output_path := "%s/frame_%02d.png" % [OUTPUT_DIRECTORY, index + 1]
		assert(frame.save_png(ProjectSettings.globalize_path(output_path)) == OK)
		print("frame %02d: source=%d shared scale=%s bounds=%s" % [index + 1, source_index + 1, shared_scale, frame.get_used_rect()])
		var preview := Image.create(640, 512, false, Image.FORMAT_RGBA8)
		preview.fill(Color("#cbb296"))
		preview.blend_rect(frame, Rect2i(0, 0, 640, 512), Vector2i.ZERO)
		preview.save_png(ProjectSettings.globalize_path("%s/frame_%02d.png" % [PREVIEW_DIRECTORY, index + 1]))
		preview.resize(320, 256, Image.INTERPOLATE_LANCZOS)
		gallery.blit_rect(preview, Rect2i(0, 0, 320, 256), Vector2i(index % 4, index / 4) * Vector2i(320, 256))
	gallery.save_png(ProjectSettings.globalize_path("%s/contact_sheet.png" % PREVIEW_DIRECTORY))
	quit(0)


func _key_green_background(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var dominance := color.g - maxf(color.r, color.b)
			# Remove even the faint mixed-matte pixels in the enclosed tail gap.
			# Merely desaturating their green could leave a yellow/brown crescent.
			var yellow_green_spill := color.g > 0.35 and color.b < color.g * 0.75 and color.r < color.g * 1.35
			if (dominance > 2.0 / 255.0 or yellow_green_spill) and _inside_tail_gap(Vector2i(x, y)):
				image.set_pixel(x, y, Color.TRANSPARENT)
				continue
			if dominance > 7.0 / 255.0:
				if color.g > 80.0 / 255.0:
					color.a *= clampf((52.0 / 255.0 - dominance) / (45.0 / 255.0), 0.0, 1.0)
				color.g = minf(color.g, maxf(color.r, color.b))
			if color.a <= 8.0 / 255.0:
				color = Color.TRANSPARENT
			# Whole-image keying is intentional: sleeping eyes are closed, and
			# enclosed green islands between the tail and body must ALSO clear.
			image.set_pixel(x, y, color)


func _inside_tail_gap(point: Vector2i) -> bool:
	for gap_x in [346, 752, 1144, 1540]:
		for gap_y in [196, 496, 797]:
			if Rect2i(gap_x, gap_y, 55, 60).has_point(point):
				return true
	return false


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


func _original_stationary_paw(base: Image) -> Image:
	# The small far paw beside the left cheek, not the long near foreleg under
	# the chin. This mask selects original pixels; it does not draw new artwork.
	var outline := PackedVector2Array([
		Vector2(36, 426), Vector2(65, 419), Vector2(80, 435),
		Vector2(110, 454), Vector2(110, 474), Vector2(36, 484)
	])
	var layer := Image.create(640, 512, false, Image.FORMAT_RGBA8)
	layer.fill(Color.TRANSPARENT)
	for y in range(419, 484):
		for x in range(36, 111):
			if Geometry2D.is_point_in_polygon(Vector2(x, y), outline):
				layer.set_pixel(x, y, base.get_pixel(x, y))
	# Raising the head/near arm reveals a short section of the far foreleg that
	# was occluded in the original pose. Imagegen drew that connection; retain
	# only this small supporting layer, never its redrawn cat/head/body.
	var joint := Image.load_from_file(ProjectSettings.globalize_path(JOIN_PATH))
	joint.convert(Image.FORMAT_RGBA8)
	for y in range(joint.get_height()):
		for x in range(joint.get_width()):
			var color := joint.get_pixel(x, y)
			if minf(color.r, minf(color.g, color.b)) > 0.86 and maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) < 0.05:
				joint.set_pixel(x, y, Color.TRANSPARENT)
	var source_bounds := joint.get_used_rect()
	var target_bounds := Rect2i(23, 210, 599, 291)
	var joint_scale := Vector2(target_bounds.size) / Vector2(source_bounds.size)
	for y in range(415, 478):
		for x in range(84, 340):
			var source_point := Vector2(source_bounds.position) + (Vector2(x, y) - Vector2(target_bounds.position)) / joint_scale
			var drawn_connection := _sample_premultiplied(joint, source_point)
			var original := layer.get_pixel(x, y)
			var weight := smoothstep(84.0, 108.0, float(x))
			var premultiplied := Color(original.r * original.a, original.g * original.a, original.b * original.a, original.a).lerp(Color(drawn_connection.r * drawn_connection.a, drawn_connection.g * drawn_connection.a, drawn_connection.b * drawn_connection.a, drawn_connection.a), weight)
			if premultiplied.a > 0.0:
				premultiplied.r /= premultiplied.a
				premultiplied.g /= premultiplied.a
				premultiplied.b /= premultiplied.a
			layer.set_pixel(x, y, premultiplied)
	# The original PNG has a few mixed green-matte pixels on this paw's outer
	# antialiased rim. Clear only that spill; the visible paw core stays exact.
	for y in range(419, 484):
		for x in range(36, 340):
			var color := layer.get_pixel(x, y)
			if color.a > 0.0 and color.g > maxf(color.r, color.b) + 8.0 / 255.0:
				layer.set_pixel(x, y, Color.TRANSPARENT)
	return layer
