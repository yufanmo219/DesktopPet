extends SceneTree

## Offline asset packaging. Never use a generated whole-cat frame: its coat can
## drift. Retain every original pixel and use imagegen only BELOW the cut tail.
const PATCH_PATH := "res://dev_only/unused_assets/assets/pets/mochi/source/mochi_tail_bottom_patch_chroma_v3.png"
const ORIGINAL_DIRECTORY := "res://dev_only/unused_assets/assets/pets/mochi/side_lick_paw"
const IDLE_PATH := "res://assets/pets/mochi/home_tail_blink/frame_01.png"
const OUTPUT_DIRECTORY := "res://assets/pets/mochi/side_lick_paw_v3"
const SOURCE_OFFSET := Vector2i(-49, 19)
const ORIGINAL_CUTOFF_Y := 1115
# Only this shallow lower edge of the generated crop is permitted in the game.
const PATCH_REGION := Rect2i(232, 700, 971, 80)


func _initialize() -> void:
	var patch_source := Image.load_from_file(ProjectSettings.globalize_path(PATCH_PATH))
	var idle := Image.load_from_file(ProjectSettings.globalize_path(IDLE_PATH))
	if patch_source == null or idle == null:
		push_error("Missing Mochi tail patch or idle artwork")
		quit(1)
		return
	_key_green_background(patch_source)
	var patch := patch_source.get_region(PATCH_REGION)
	var extension_height := idle.get_used_rect().end.y - ORIGINAL_CUTOFF_Y - SOURCE_OFFSET.y
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	for index in range(1, 13):
		var output := idle.duplicate() as Image
		if index > 1 and index < 12:
			var source := Image.load_from_file(ProjectSettings.globalize_path("%s/frame_%02d.png" % [ORIGINAL_DIRECTORY, index]))
			if source == null or source.get_used_rect().end.y != ORIGINAL_CUTOFF_Y:
				push_error("Mochi's original frame %d no longer matches the authored cutoff" % index)
				quit(1)
				return
			output = Image.create(idle.get_width(), idle.get_height(), false, Image.FORMAT_RGBA8)
			output.fill(Color.TRANSPARENT)
			# Integer translation only: do not resize, recolor, key, or redraw source.
			output.blit_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), SOURCE_OFFSET)
			_append_tail_bottom(output, source, patch, extension_height)
		var output_path := "%s/frame_%02d.png" % [OUTPUT_DIRECTORY, index]
		var error := output.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			push_error("Could not save %s: %s" % [output_path, error_string(error)])
			quit(1)
			return
		print(output_path, " ", output.get_used_rect())
	quit(0)


func _append_tail_bottom(output: Image, source: Image, patch: Image, height: int) -> void:
	var left := source.get_width()
	var right := -1
	for x in range(source.get_width()):
		if source.get_pixel(x, ORIGINAL_CUTOFF_Y - 1).a > 0.01:
			left = mini(left, x)
			right = maxi(right, x)
	assert(right >= left and height > 0, "Mochi's cut tail edge must exist")
	var edge := patch.duplicate() as Image
	edge.resize(right - left + 1, height, Image.INTERPOLATE_LANCZOS)
	for x in range(edge.get_width()):
		var seam := source.get_pixel(left + x, ORIGINAL_CUTOFF_Y - 1)
		var donor_seam := edge.get_pixel(x, 0)
		for y in range(edge.get_height()):
			var color := edge.get_pixel(x, y)
			# Match the join to the existing fur, fading the correction into the
			# generated lower outline. None of this touches an original pixel.
			if seam.a > 0.95 and donor_seam.a > 0.95 and color.a > 0.95:
				var weight := pow(1.0 - float(y) / maxf(height - 1, 1), 2.0)
				color.r = clampf(color.r + (seam.r - donor_seam.r) * weight, 0.0, 1.0)
				color.g = clampf(color.g + (seam.g - donor_seam.g) * weight, 0.0, 1.0)
				color.b = clampf(color.b + (seam.b - donor_seam.b) * weight, 0.0, 1.0)
			if y == 0:
				color = seam
			edge.set_pixel(x, y, color)
	output.blit_rect(edge, Rect2i(Vector2i.ZERO, edge.get_size()), Vector2i(left, ORIGINAL_CUTOFF_Y) + SOURCE_OFFSET)


func _key_green_background(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			var other := maxf(color.r, color.b)
			var green_excess := color.g - other
			if color.g > 0.30 and green_excess > 0.025:
				color.a *= clampf((0.20 - green_excess) / 0.175, 0.0, 1.0)
				color.g = minf(color.g, other + 0.025)
				if color.a < 0.02:
					color = Color.TRANSPARENT
				image.set_pixel(x, y, color)
