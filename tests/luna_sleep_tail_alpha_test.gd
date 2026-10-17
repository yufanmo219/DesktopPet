extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
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
	var repaired := Image.load_from_file(ProjectSettings.globalize_path(REPAIRED_PATH))
	_check(repaired != null and not repaired.is_empty(), "Luna's repaired sleep image must exist in the runtime asset set")
	if repaired == null or repaired.is_empty():
		luna_assets.free()
		quit(1)
		return
	var repaired_bounds := repaired.get_used_rect()
	_check(repaired.get_size() == Vector2i(640, 512), "Luna's sleeping pose must retain its fixed runtime canvas")
	_check(repaired_bounds.has_area(), "Luna's repaired sleeping pose must contain visible pixels")
	_check(Rect2i(Vector2i.ZERO, repaired.get_size()).encloses(repaired_bounds), "Luna's visible sleeping pose must stay inside its canvas")
	var remaining_green := 0
	for y in range(TAIL_GAP_REGION.position.y, TAIL_GAP_REGION.end.y):
		for x in range(TAIL_GAP_REGION.position.x, TAIL_GAP_REGION.end.x):
			var after := repaired.get_pixel(x, y)
			if after.a > 0.0 and after.g > maxf(after.r, after.b) + 2.0 / 255.0:
				remaining_green += 1
	_check(remaining_green == 0, "No visible green may remain in the tail gap")
	_check(luna_assets.sleep_texture.resource_path == REPAIRED_PATH, "Luna's static sleeping pose must use the repaired local asset")
	for display_size in [Vector2(460, 390), Vector2(400, 300), Vector2(800, 600)]:
		var avatar := AvatarScript.new()
		avatar.size = display_size
		avatar.set_pet({"id": "luna", "name": "Luna"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar.set_mood("sleep")
		avatar._update_layout()
		_check(avatar.cat_sprite.texture == avatar.sleep_texture, "Home/Desktop sleep must display the fixed static sprite")
		var texture_size := Vector2(repaired.get_size())
		var expected_scale := minf(display_size.x / texture_size.x, display_size.y / texture_size.y) * 0.95
		var bounds := Rect2(repaired_bounds)
		var expected_position := Vector2(
			display_size.x * 0.5 - (bounds.get_center().x - texture_size.x * 0.5) * expected_scale,
			display_size.y * avatar.SHADOW_CENTER_Y_RATIO - (bounds.end.y - texture_size.y * 0.5) * expected_scale
		)
		_check(avatar.cat_sprite.scale.is_equal_approx(Vector2.ONE * expected_scale) and avatar.cat_sprite.position.is_equal_approx(expected_position), "Transparency-only repair must not shift or resize Luna")
		avatar.sleep_effect_wait_remaining = 0.0
		avatar._process(0.01)
		_check(avatar.cat_sprite.texture == avatar.animation_frames("sleep_effect")[0] and avatar.animation_frames("sleep_effect").size() == 12, "The twelve-frame sleep animation must still start from the repaired static pose")
		avatar.queue_free()
		await process_frame
	luna_assets.free()
	if failures.is_empty():
		print("LUNA SLEEP TAIL TEST PASS: runtime asset is valid, tail gap is clean, layout is stable, and sleep animation starts correctly")
		quit(0)
	else:
		print("LUNA SLEEP TAIL TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
