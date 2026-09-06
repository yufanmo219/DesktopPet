extends SceneTree

## Apply the requested tiny transparency repair to the original sprite.
## The imagegen result is retained as an edit reference, not substituted for
## the original artwork because it changed the fur texture and canvas.
const ORIGINAL_PATH := "res://dev_only/unused_assets/assets/pets/russian_blue/sleep/luna_sleep.png"
const OUTPUT_PATH := "res://assets/pets/russian_blue/sleep/luna_sleep_v2.png"
const TAIL_GAP_REGION := Rect2i(542, 398, 40, 44)
const MIN_GREEN_DOMINANCE := 2.0 / 255.0


func _initialize() -> void:
	var original := Image.load_from_file(ProjectSettings.globalize_path(ORIGINAL_PATH))
	assert(original != null and original.get_size() == Vector2i(640, 512))
	original.convert(Image.FORMAT_RGBA8)
	var repaired := original.duplicate() as Image
	var cleared := 0
	for y in range(TAIL_GAP_REGION.position.y, TAIL_GAP_REGION.end.y):
		for x in range(TAIL_GAP_REGION.position.x, TAIL_GAP_REGION.end.x):
			var pixel := original.get_pixel(x, y)
			if pixel.a > 0.0 and pixel.g > maxf(pixel.r, pixel.b) + MIN_GREEN_DOMINANCE:
				# Clear hidden green RGB as well as alpha, so image previews and
				# texture filtering cannot reveal the erased matte color again.
				repaired.set_pixel(x, y, Color.TRANSPARENT)
				cleared += 1
	assert(cleared > 0 and cleared < 200, "Repair must remain limited to the small tail crescent")
	assert(repaired.get_used_rect() == original.get_used_rect(), "Transparency repair must not change the silhouette's bounds")
	assert(repaired.save_png(ProjectSettings.globalize_path(OUTPUT_PATH)) == OK)
	var preview := Image.create(512, 256, false, Image.FORMAT_RGBA8)
	preview.fill(Color("#bd9b83"))
	for index in range(2):
		var source: Image = original if index == 0 else repaired
		var crop := source.get_region(Rect2i(532, 390, 64, 64))
		crop.resize(256, 256, Image.INTERPOLATE_NEAREST)
		preview.blend_rect(crop, Rect2i(0, 0, 256, 256), Vector2i(index * 256, 0))
	preview.save_png("/private/tmp/luna-sleep-tail-alpha-check.png")
	print("LUNA TAIL ALPHA REPAIR: ", cleared, " green pixels cleared to transparent; all other pixels, canvas and silhouette bounds unchanged")
	quit(0)
