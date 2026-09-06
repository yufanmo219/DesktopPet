extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _unshifted_position(avatar: Control) -> Vector2:
	var bounds := Rect2(avatar.cat_sprite.texture.get_image().get_used_rect())
	var center: Vector2 = avatar.cat_sprite.texture.get_size() * 0.5
	var scale_value: float = avatar.cat_sprite.scale.x
	return Vector2(
		avatar.size.x * 0.5 - (bounds.get_center().x - center.x) * scale_value,
		avatar.size.y * avatar.SHADOW_CENTER_Y_RATIO - (bounds.end.y - center.y) * scale_value
	)


func _run() -> void:
	for display_size in [Vector2(460, 390), Vector2(400, 300), Vector2(800, 600)]:
		var avatar := AvatarScript.new()
		avatar.size = display_size
		avatar.set_pet({"id": "biscuit", "name": "Biscuit"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar._update_layout()
		var idle_position: Vector2 = avatar.cat_sprite.position
		var original_scale: Vector2 = avatar.cat_sprite.scale
		avatar.play_belly_roll()
		for index in range(16):
			_check(avatar.interaction_frame == index, "Biscuit must retain all sixteen frames and their timing")
			_check(avatar.cat_sprite.texture == AvatarScript.BISCUIT_BUTTERFLY_FRAMES[index], "Biscuit must use her unchanged original butterfly textures")
			_check(avatar.cat_sprite.scale.is_equal_approx(original_scale), "Biscuit must not change size")
			_check(avatar.cat_sprite.position.is_equal_approx(_unshifted_position(avatar) + Vector2(0, -8)), "Every double-click frame must move exactly eight pixels up, never horizontally")
			_check(avatar.cat_sprite.modulate == Color.WHITE and avatar.cat_sprite.self_modulate == Color.WHITE, "No tint may change Biscuit's coat")
			var position_before: Vector2 = avatar.cat_sprite.position
			avatar._update_layout()
			_check(avatar.cat_sprite.position.is_equal_approx(position_before), "Repeated layout must not accumulate the offset")
			avatar._process(float(AvatarScript.BISCUIT_BUTTERFLY_FRAME_DURATIONS[index]) + 0.00001)
		_check(not avatar.is_playing_interaction() and avatar.cat_sprite.position.is_equal_approx(idle_position), "The offset must clear when returning to idle")
		avatar._start_desktop_idle_animation("biscuit_butterfly")
		avatar._update_layout()
		_check(avatar.cat_sprite.position.is_equal_approx(_unshifted_position(avatar)), "The automatic butterfly animation must remain at its previous position")
		avatar.queue_free()
		await process_frame
	if failures.is_empty():
		print("BISCUIT DOUBLE CLICK OFFSET TEST PASS: all sixteen original frames shift up eight pixels; size, color, timing and non-interaction positions unchanged")
		quit(0)
	else:
		print("BISCUIT DOUBLE CLICK OFFSET TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
