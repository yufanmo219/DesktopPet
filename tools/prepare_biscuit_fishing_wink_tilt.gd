extends SceneTree

## Extract the complete imagegen-drawn wink/tilt poses. Only keying, a shared
## uniform scale and foot registration are applied; the head motion is drawn
## in the generated frames, not an eye patch or a runtime sprite rotation.
const BASE_PATH := "res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png"
const SOURCE_PATH := "res://dev_only/unused_assets/assets/pets/biscuit/source/biscuit_fishing_wink_tilt_chroma_v3.png"
const OUTPUT_DIRECTORY := "res://assets/pets/biscuit/fishing/success_wink_v3"
const PREVIEW_DIRECTORY := "res://dev_only/artifacts/biscuit_wink_tilt_v3"


func _initialize() -> void:
	var base := Image.load_from_file(ProjectSettings.globalize_path(BASE_PATH))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	assert(base != null and sheet != null, "Missing Biscuit source art")
	base.convert(Image.FORMAT_RGBA8)
	_key_green_background(sheet)
	var cells: Array[Image] = []
	for index in range(8):
		var column := index % 4
		var row := index / 4
		var left := roundi(float(column) * sheet.get_width() / 4.0)
		var right := roundi(float(column + 1) * sheet.get_width() / 4.0)
		var top := roundi(float(row) * sheet.get_height() / 2.0)
		var bottom := roundi(float(row + 1) * sheet.get_height() / 2.0)
		var cell := sheet.get_region(Rect2i(left, top, right - left, bottom - top))
		assert(Rect2i(5, 5, cell.get_width() - 10, cell.get_height() - 10).encloses(cell.get_used_rect()), "Generated ears/tail must not touch a cell edge")
		cells.append(cell)
	var shared_scale := float(base.get_used_rect().size.y) / cells[0].get_used_rect().size.y
	var target_anchor := _foot_anchor(base)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIRECTORY))
	var gallery := Image.create(1024, 512, false, Image.FORMAT_RGBA8)
	gallery.fill(Color("#f5e6ca"))
	for index in range(cells.size()):
		var cell := cells[index]
		var source_anchor := _foot_anchor(cell)
		var frame := Image.create(512, 512, false, Image.FORMAT_RGBA8)
		frame.fill(Color.TRANSPARENT)
		for y in range(512):
			for x in range(512):
				var source_point := source_anchor + (Vector2(x, y) - target_anchor) / shared_scale
				frame.set_pixel(x, y, _sample_premultiplied(cell, source_point))
		# The bookends remain the approved neutral pose for a clean transition
		# between the new animated reaction and the rest of the fishing game.
		if index == 0 or index == 7:
			frame = base.duplicate() as Image
		var output_path := "%s/frame_%02d.png" % [OUTPUT_DIRECTORY, index + 1]
		assert(frame.save_png(ProjectSettings.globalize_path(output_path)) == OK)
		print("frame %02d: scale=%.6f source feet=%s target feet=%s bounds=%s" % [index + 1, shared_scale, source_anchor, _foot_anchor(frame), frame.get_used_rect()])
		var preview := Image.create(512, 512, false, Image.FORMAT_RGBA8)
		preview.fill(Color("#f5e6ca"))
		preview.blend_rect(frame, Rect2i(0, 0, 512, 512), Vector2i.ZERO)
		preview.save_png(ProjectSettings.globalize_path("%s/frame_%02d.png" % [PREVIEW_DIRECTORY, index + 1]))
		preview.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		gallery.blit_rect(preview, Rect2i(0, 0, 256, 256), Vector2i(index % 4, index / 4) * 256)
	gallery.save_png(ProjectSettings.globalize_path("%s/contact_sheet.png" % PREVIEW_DIRECTORY))
	quit(0)


func _foot_anchor(image: Image) -> Vector2:
	var bounds := image.get_used_rect()
	var sum_x := 0.0
	var sum_weight := 0.0
	for y in range(bounds.end.y - 4, bounds.end.y):
		for x in range(bounds.position.x + roundi(bounds.size.x * 0.35), bounds.end.x):
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.15:
				sum_x += x * alpha
				sum_weight += alpha
	return Vector2(sum_x / maxf(sum_weight, 0.001), bounds.end.y - 1)


func _key_green_background(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var dominance := color.g - maxf(color.r, color.b)
			if dominance > 7.0 / 255.0:
				if color.g > 80.0 / 255.0:
					color.a *= clampf((52.0 / 255.0 - dominance) / (45.0 / 255.0), 0.0, 1.0)
				# Dark outline antialiasing can also contain green spill, even
				# below the bright-matte threshold. Neutralize its color only.
				color.g = minf(color.g, maxf(color.r, color.b) + 8.0 / 255.0)
			if color.a <= 8.0 / 255.0:
				color = Color.TRANSPARENT
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
