extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
const ORIGINAL_PATH := "res://dev_only/unused_assets/assets/pets/russian_blue/sleep/luna_sleep.png"
const REPAIRED_PATH := "res://assets/pets/russian_blue/sleep/luna_sleep_v2.png"
const TAIL_GAP_REGION := Rect2i(542, 398, 40, 44)
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var luna_assets := AvatarScript.new()
	luna_assets.set_pet({"id": "luna", "name": "Luna"})
	# Compare the actual PNG bytes decoded as pixels, before Godot's optional
	# transparent-border RGB preprocessing. Only erased green pixels may change.
	var original := Image.load_from_file(ProjectSettings.globalize_path(ORIGINAL_PATH))
	var repaired := Image.load_from_file(ProjectSettings.globalize_path(REPAIRED_PATH))
	_check(original.get_size() == repaired.get_size() and original.get_used_rect() == repaired.get_used_rect(), "The original canvas and visible bounds must remain identical")
	var original_bytes := original.get_data()
	var repaired_bytes := repaired.get_data()
	var changed_alpha := 0
	var changed_rgb := 0
	var unexpected_changes := 0
	var remaining_green := 0
	for y in range(original.get_height()):
		for x in range(original.get_width()):
			var before := original.get_pixel(x, y)
			var after := repaired.get_pixel(x, y)
			var is_green := before.g > maxf(before.r, before.b) + 2.0 / 255.0
			var in_gap := TAIL_GAP_REGION.has_point(Vector2i(x, y))
			var offset := (y * original.get_width() + x) * 4
			for channel in range(3):
				if original_bytes[offset + channel] != repaired_bytes[offset + channel] and not (in_gap and is_green and before.a > 0.0 and after == Color.TRANSPARENT):
					changed_rgb += 1
			if before.a != after.a:
				changed_alpha += 1
				if not in_gap or not is_green or after.a != 0.0:
					unexpected_changes += 1
			if in_gap and is_green and after.a > 0.0:
				remaining_green += 1
	_check(changed_rgb == 0, "All RGB outside the erased green pixels must remain unchanged, including fur, outlines and tail")
	_check(changed_alpha > 0 and changed_alpha < 200 and unexpected_changes == 0, "Only the small green tail crescent may become transparent")
	_check(remaining_green == 0, "No visible green may remain in the tail gap")
	_check(luna_assets.LUNA_SLEEP_TEXTURE.resource_path == REPAIRED_PATH, "Luna's static sleeping pose must use the repaired local asset")
	for display_size in [Vector2(460, 390), Vector2(400, 300), Vector2(800, 600)]:
		var avatar := AvatarScript.new()
		avatar.size = display_size
		avatar.set_pet({"id": "luna", "name": "Luna"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar.set_mood("sleep")
		avatar._update_layout()
		_check(avatar.cat_sprite.texture == avatar.LUNA_SLEEP_TEXTURE, "Home/Desktop sleep must display the fixed static sprite")
		var texture_size := Vector2(original.get_size())
		var expected_scale := minf(display_size.x / texture_size.x, display_size.y / texture_size.y) * 0.95
		var bounds := Rect2(original.get_used_rect())
		var expected_position := Vector2(
			display_size.x * 0.5 - (bounds.get_center().x - texture_size.x * 0.5) * expected_scale,
			display_size.y * avatar.SHADOW_CENTER_Y_RATIO - (bounds.end.y - texture_size.y * 0.5) * expected_scale
		)
		_check(avatar.cat_sprite.scale.is_equal_approx(Vector2.ONE * expected_scale) and avatar.cat_sprite.position.is_equal_approx(expected_position), "Transparency-only repair must not shift or resize Luna")
		avatar.luna_sleep_idle_wait_remaining = 0.0
		avatar._process(0.01)
		_check(avatar.cat_sprite.texture == avatar.LUNA_SLEEP_IDLE_FRAMES[0] and avatar.LUNA_SLEEP_IDLE_FRAMES.size() == 12, "The twelve-frame sleep animation must still start from the repaired static pose")
		avatar.queue_free()
		await process_frame
	luna_assets.free()
	print("Luna tail repair pixel audit: erased green pixels=", changed_alpha, ", protected RGB changes=", changed_rgb, ", unrelated alpha changes=", unexpected_changes)
	if failures.is_empty():
		print("LUNA SLEEP TAIL TEST PASS: only the green crescent is transparent, static pixels/size/position preserved, sleep animation starts correctly")
		quit(0)
	else:
		print("LUNA SLEEP TAIL TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
