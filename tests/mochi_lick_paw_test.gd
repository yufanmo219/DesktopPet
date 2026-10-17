extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run_tests() -> void:
	var mochi_assets := AvatarScript.new()
	mochi_assets.set_pet({"id": "mochi", "name": "Mochi"})
	var idle := mochi_assets.animation_frames("home_idle")[0].get_image()
	var idle_bounds := idle.get_used_rect()
	var frames := mochi_assets.animation_frames("interaction")
	var interaction_clip := mochi_assets.animation_clip("interaction")
	_check(frames.size() == 12, "Mochi should retain her twelve-frame paw-licking sequence")
	_check(frames[0].get_image().get_data() == idle.get_data(), "The first interaction frame must exactly match the approved idle artwork")
	_check(frames[-1].get_image().get_data() == idle.get_data(), "The last interaction frame must return to the exact idle artwork")
	for index in range(frames.size()):
		var image := frames[index].get_image()
		var bounds := image.get_used_rect()
		_check(image.get_size() == idle.get_size(), "Every frame must share the idle canvas")
		_check(bounds.position.y == idle_bounds.position.y and bounds.end.y == idle_bounds.end.y, "Every frame should preserve Mochi's displayed height and ground line")
		_check(Rect2i(16, 16, image.get_width() - 32, image.get_height() - 32).encloses(bounds), "Full ears and tail must have transparent canvas padding")
		_check(image.get_pixel(0, 0).a == 0.0, "The chroma backdrop must not remain visible")
		_check(_bottom_edge_run(image, bounds) < bounds.size.x * 0.35, "Frame %d must have a rounded tail edge, not a long horizontal cutoff" % (index + 1))

	for display_size in [Vector2(460, 390), Vector2(400, 300), Vector2(800, 600)]:
		var avatar := AvatarScript.new()
		avatar.size = display_size
		avatar.set_pet({"id": "mochi", "name": "Mochi"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar._update_layout()
		var idle_position := avatar.cat_sprite.position
		var idle_scale := avatar.cat_sprite.scale
		avatar.play_belly_roll()
		for index in range(frames.size()):
			_check(avatar.interaction_frame == index, "Mochi's interaction should retain its original timing and frame order")
			_check(avatar.cat_sprite.position.is_equal_approx(idle_position), "Mochi must not sink or recenter during the interaction")
			_check(avatar.cat_sprite.scale.is_equal_approx(idle_scale), "Mochi must not shrink during the interaction")
			var bounds := Rect2(avatar.cat_sprite.texture.get_image().get_used_rect())
			var visible_rect := Rect2(
				avatar.cat_sprite.position + (bounds.position - avatar.cat_sprite.texture.get_size() * 0.5) * idle_scale,
				bounds.size * idle_scale
			)
			_check(Rect2(Vector2.ZERO, display_size).encloses(visible_rect), "The complete animated tail must fit inside the Home/desktop viewport")
			avatar._process(interaction_clip.frame_duration(index) + 0.00001)
		_check(not avatar.is_playing_interaction(), "Mochi's interaction should finish once")
		_check(avatar.cat_sprite.position.is_equal_approx(idle_position) and avatar.cat_sprite.scale.is_equal_approx(idle_scale), "Returning to idle must not shift Mochi")
		avatar.queue_free()
		await process_frame

	mochi_assets.free()
	# Verify the actual double-click routes, not just a direct animation call.
	var main = load("res://main.tscn").instantiate()
	main.save_enabled = false
	root.add_child(main)
	main.set_process(false)
	main._seed_preview_pets("mochi")
	main.show_home()
	main.avatar.set_process(false)
	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.pressed = true
	double_click.double_click = true
	main.home_screen.handle_pet_input(double_click)
	_check(main.avatar.is_playing_interaction(), "Home double-click should start the repaired Mochi animation")
	main.enter_desktop_mode()
	main.avatar.set_process(false)
	var position_before: Vector2 = main.desktop_controller.widget_pet_position
	main.desktop_controller._on_pet_drag_input(double_click)
	_check(main.avatar.is_playing_interaction() and not main.desktop_controller.widget_pet_dragging, "Desktop double-click should animate Mochi without dragging")
	main.desktop_controller.update(0.1, Vector2(-100000.0, -100000.0))
	_check(main.desktop_controller.widget_pet_position.is_equal_approx(position_before), "Double-clicking must not move Mochi's native window")
	main.queue_free()
	await process_frame
	var music = root.get_node_or_null("MusicManager")
	if music != null:
		music.stop_music(0.0)
	if failures.is_empty():
		print("MOCHI LICK PAW TEST PASS: original coat pixels preserved, complete tails, stable scale/anchor, twelve frames, Home and desktop double-click")
		quit(0)
	else:
		print("MOCHI LICK PAW TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _bottom_edge_run(image: Image, bounds: Rect2i) -> int:
	var longest := 0
	var run := 0
	for x in range(bounds.position.x, bounds.end.x):
		if image.get_pixel(x, bounds.end.y - 2).a > 0.5:
			run += 1
			longest = maxi(longest, run)
		else:
			run = 0
	return longest
