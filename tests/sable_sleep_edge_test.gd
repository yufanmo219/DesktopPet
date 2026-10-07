extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _warm_lower_edge_pixels(image: Image) -> int:
	var warm_edge_pixels := 0
	for y in range(roundi(image.get_height() * 0.63) + 1, image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if (
				pixel.a <= 0.0
				or not (
					pixel.get_luminance() > 80.0 / 255.0
					or (
						pixel.r >= pixel.b - 1.0 / 255.0
						and pixel.get_luminance() > 55.0 / 255.0
					)
				)
			):
				continue
			var touches_transparency := false
			for neighbor_y in range(maxi(0, y - 2), mini(image.get_height(), y + 3)):
				for neighbor_x in range(maxi(0, x - 2), mini(image.get_width(), x + 3)):
					if image.get_pixel(neighbor_x, neighbor_y).a <= 0.0:
						touches_transparency = true
						break
				if touches_transparency:
					break
			if touches_transparency:
				warm_edge_pixels += 1
	return warm_edge_pixels


func _run() -> void:
	var sable_assets := AvatarScript.new()
	sable_assets.set_pet({"id": "black_cat", "name": "Sable"})
	var frames := sable_assets.BLACK_CAT_FALL_ASLEEP_FRAMES
	_check(frames.size() == 8, "Sable's complete fall-asleep sequence must keep all eight frames")
	var final_image_data: PackedByteArray
	for index in range(frames.size()):
		var image := Image.load_from_file(ProjectSettings.globalize_path(frames[index].resource_path))
		_check(image.get_size() == Vector2i(640, 512), "Every Sable sleep frame must retain its fixed 640x512 canvas")
		var warm_lower_edge_pixels := _warm_lower_edge_pixels(image)
		print("sleep frame %02d: warm lower-edge pixels=%d" % [index + 1, warm_lower_edge_pixels])
		_check(warm_lower_edge_pixels == 0, "Sable sleep frame %02d must not contain a warm ochre halo along its lower transparent edge" % (index + 1))
		var soft_edge_pixels := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var alpha := image.get_pixel(x, y).a
				if alpha > 0.05 and alpha < 0.95:
					soft_edge_pixels += 1
		_check(soft_edge_pixels > 250, "Sable sleep frame %02d must retain a soft antialiased silhouette" % (index + 1))
		if index == frames.size() - 1:
			final_image_data = image.get_data()
	var static_image := Image.load_from_file(ProjectSettings.globalize_path(sable_assets.BLACK_CAT_SLEEP_TEXTURE.resource_path))
	_check(static_image.get_data() == final_image_data, "Sable's final sleeping pose must exactly match the last cleaned transition frame")

	var avatar := AvatarScript.new()
	avatar.size = Vector2(460, 390)
	root.add_child(avatar)
	avatar.set_process(false)
	avatar.set_pet({"id": "black_cat", "name": "Sable"})
	avatar.set_mood("sleep")
	for index in range(frames.size()):
		_check(avatar.cat_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Home and Desktop must linearly filter every Sable sleep frame")
		avatar._process(float(AvatarScript.BLACK_CAT_FALL_ASLEEP_FRAME_DURATIONS[index]) + 0.01)
	_check(avatar.cat_sprite.texture == avatar.BLACK_CAT_SLEEP_TEXTURE, "Sable must settle on the cleaned final sleeping pose")
	_check(avatar.cat_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Sable's final sleeping pose must remain linearly filtered")
	avatar.queue_free()
	sable_assets.free()
	await process_frame

	if failures.is_empty():
		print("SABLE SLEEP EDGE TEST PASS: all warm ground-shadow pixels removed and the lower silhouette remains smooth")
		quit(0)
	else:
		print("SABLE SLEEP EDGE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
