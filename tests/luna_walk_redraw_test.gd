extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
const LEFT_DIRECTORY := "res://assets/pets/russian_blue/walk_left_v3"
const RIGHT_DIRECTORY := "res://assets/pets/russian_blue/walk_right_v3"
const LEFT_EYES_REGION := Rect2i(34, 156, 132, 65)
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
	var left_frames := luna_assets.LUNA_MOVE_LEFT_FRAMES
	var right_frames := luna_assets.LUNA_MOVE_RIGHT_FRAMES
	_check(left_frames.size() == 12 and right_frames.size() == 12, "Both new walking directions must have twelve frames")
	_check(AvatarScript.LUNA_MOVE_FPS == 12.0 and AvatarScript.MOVE_FPS == 7.0, "Only Luna's new walk cadence may change")
	var leg_silhouettes: Dictionary = {}
	var minimum_height := 512
	var maximum_height := 0
	for index in range(12):
		_check(left_frames[index].resource_path == "%s/frame_%02d.png" % [LEFT_DIRECTORY, index + 1] and right_frames[index].resource_path == "%s/frame_%02d.png" % [RIGHT_DIRECTORY, index + 1], "Runtime must use only the new walking sprites, never the discarded old cycles")
		var left := Image.load_from_file(ProjectSettings.globalize_path(left_frames[index].resource_path))
		var right := Image.load_from_file(ProjectSettings.globalize_path(right_frames[index].resource_path))
		_check(left.get_size() == Vector2i(704, 512) and right.get_size() == left.get_size(), "Walking canvases must remain 704x512")
		right.flip_x()
		_check(left.get_data() == right.get_data(), "Right walking must be an exact mirror of the NEW left gait with identical anatomy and size")
		var bounds := left.get_used_rect()
		_check(Rect2i(16, 20, 672, 484).encloses(bounds), "Every ear, paw and the entire tail must retain transparent canvas padding")
		_check(bounds.end.y == 500, "All planted feet must share the same ground line")
		minimum_height = mini(minimum_height, bounds.size.y)
		maximum_height = maxi(maximum_height, bounds.size.y)
		var cyan_count := 0
		var green_eyes := 0
		var contacts := 0
		for y in range(left.get_height()):
			for x in range(left.get_width()):
				var color := left.get_pixel(x, y)
				var green_iris := color.g > color.r + 0.04 and color.g > color.b + 0.04
				# Luna's green irises legitimately include mint/teal antialiasing;
				# inspect matte spill outside the small, fully opaque eye area.
				if color.a > 0.05 and minf(color.g, color.b) > color.r + 0.05 and not LEFT_EYES_REGION.has_point(Vector2i(x, y)):
					cyan_count += 1
				if x < 245 and y < 250 and color.a > 0.9 and green_iris:
					green_eyes += 1
				if y >= 493 and color.a > 0.8:
					contacts += 1
		_check(cyan_count == 0, "No cyan matte may remain on outlines or inside leg/tail gaps")
		_check(green_eyes > 60, "Both directions must preserve Luna's opaque green eyes")
		_check(contacts > 45, "Every walking frame must have grounded support paws, not a floating jump")
		var silhouette := PackedByteArray()
		for y in range(338, 501, 2):
			for x in range(70, 580, 2):
				silhouette.append(1 if left.get_pixel(x, y).a > 0.5 else 0)
		leg_silhouettes[silhouette.hex_encode()] = true
		print("frame %02d: bounds=%s cyan=%d green-eye pixels=%d ground contacts=%d" % [index + 1, bounds, cyan_count, green_eyes, contacts])
	_check(leg_silhouettes.size() >= 10, "The new sequence must animate the legs, not just move a static cat or tail")
	_check(maximum_height - minimum_height <= 18, "Head/shoulder bob must be subtle without frame-by-frame resizing")

	for display_size in [Vector2(460, 390), Vector2(400, 300), Vector2(800, 600)]:
		var avatar := AvatarScript.new()
		avatar.size = display_size
		avatar.set_pet({"id": "luna", "name": "Luna"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar.set_mood("follow")
		var duration := 1.0 / AvatarScript.LUNA_MOVE_FPS
		for direction in [Vector2.LEFT, Vector2.RIGHT]:
			avatar.stop_move()
			avatar.play_move(direction)
			avatar._update_layout()
			var position := avatar.cat_sprite.position
			var scale_value := avatar.cat_sprite.scale
			var frames := left_frames if direction == Vector2.LEFT else right_frames
			for index in range(24):
				_check(avatar.move_frame == index % 12 and avatar.cat_sprite.texture == frames[index % 12], "The new walk must loop continuously in the selected direction")
				_check(avatar.cat_sprite.position.is_equal_approx(position) and avatar.cat_sprite.scale.is_equal_approx(scale_value), "Moving legs/tail must not recenter or resize the cat")
				avatar.play_move(direction)
				_check(avatar.move_frame == index % 12, "Repeated follow updates must not reset the walk cycle")
				avatar._process(duration + 0.000001)
			avatar._process(duration * 2.1)
			avatar.play_move(-direction)
			avatar._update_layout()
			_check(avatar.move_frame == 0 and avatar.move_frame_elapsed == 0.0, "A real direction change should start the opposite cycle cleanly")
			_check(avatar.cat_sprite.position.is_equal_approx(position) and avatar.cat_sprite.scale.is_equal_approx(scale_value), "Turning around must preserve the exact canvas anchor and scale")
			avatar.stop_move()
			_check(avatar.cat_sprite.texture == avatar.LUNA_IDLE_TEXTURE, "Stopping must restore the unchanged seated Luna")
		avatar.set_mood("sleep")
		avatar.play_move(Vector2.LEFT)
		_check(avatar.cat_sprite.texture == avatar.LUNA_SLEEP_TEXTURE and avatar.move_time_remaining == 0.0, "Sleeping must block walking")
		_check(avatar.LUNA_SLEEP_IDLE_FRAMES[2].resource_path.contains("face_wash_v2/"), "The user's selected sleeping animation must remain untouched")
		avatar.set_mood("idle")
		avatar.play_move(Vector2.LEFT)
		avatar._process(1.16)
		_check(avatar.cat_sprite.texture == avatar.LUNA_IDLE_TEXTURE, "The normal movement timeout must still return to idle")
		avatar.set_pet({"id": "mochi", "name": "Mochi"})
		avatar.play_move(Vector2.LEFT)
		avatar._process(0.10)
		_check(avatar.move_frame == 0, "Other cats must retain their existing seven-FPS walking cadence")
		avatar._process(0.05)
		_check(avatar.move_frame == 1, "Other cats' walking should still advance at the original cadence")
		avatar.queue_free()
		await process_frame

	luna_assets.free()
	if OS.get_cmdline_user_args().has("--capture-walk"):
		await _capture_walk()
	if failures.is_empty():
		print("LUNA WALK REDRAW TEST PASS: new mirrored gait, green eyes, clean alpha, grounded paws, fixed layout, continuous loops, turning/stopping and unchanged sleep/other-cat timing")
		quit(0)
	else:
		print("LUNA WALK REDRAW TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _capture_walk() -> void:
	root.size = Vector2i(1088, 520)
	RenderingServer.set_default_clear_color(Color("#e6d7c1"))
	var avatars: Array[Control] = []
	for index in range(2):
		var avatar := AvatarScript.new()
		avatar.size = Vector2(500, 390)
		avatar.position = Vector2(22 + index * 544, 50)
		avatar.set_pet({"id": "luna", "name": "Luna"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar.set_mood("follow")
		avatar.play_move(Vector2.LEFT if index == 0 else Vector2.RIGHT)
		avatar.mood_badge.hide()
		avatars.append(avatar)
	for index in range(24):
		await RenderingServer.frame_post_draw
		if index < 12:
			root.get_texture().get_image().save_png("/private/tmp/luna-walk-v3-runtime-%02d.png" % (index + 1))
		await create_timer(1.0 / AvatarScript.LUNA_MOVE_FPS).timeout
		for avatar_index in range(2):
			avatars[avatar_index].play_move(Vector2.LEFT if avatar_index == 0 else Vector2.RIGHT)
			avatars[avatar_index]._process(1.0 / AvatarScript.LUNA_MOVE_FPS + 0.000001)
	for avatar in avatars:
		avatar.queue_free()
	await process_frame
