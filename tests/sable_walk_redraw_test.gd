extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
const LEFT_DIRECTORY := "res://assets/pets/black_cat/walk_left_v3"
const RIGHT_DIRECTORY := "res://assets/pets/black_cat/walk_right_v3"
const LEFT_EYE_REGION := Rect2i(48, 100, 125, 92)
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var left_frames := AvatarScript.BLACK_CAT_MOVE_LEFT_FRAMES
	var right_frames := AvatarScript.BLACK_CAT_MOVE_RIGHT_FRAMES
	_check(left_frames.size() == 12 and right_frames.size() == 12, "Both new Sable directions must have twelve frames")
	_check(AvatarScript.BLACK_CAT_MOVE_FPS == 10.0 and AvatarScript.MOVE_FPS == 7.0 and AvatarScript.LUNA_MOVE_FPS == 12.0, "Only Sable may gain the new ten-FPS cadence")
	var leg_silhouettes: Dictionary = {}
	var minimum_height := 512
	var maximum_height := 0
	for index in range(12):
		_check(
			left_frames[index].resource_path == "%s/frame_%02d.png" % [LEFT_DIRECTORY, index + 1]
			and right_frames[index].resource_path == "%s/frame_%02d.png" % [RIGHT_DIRECTORY, index + 1],
			"Runtime must use only the new side-profile walk, never the discarded old frames"
		)
		var left := Image.load_from_file(ProjectSettings.globalize_path(left_frames[index].resource_path))
		var right := Image.load_from_file(ProjectSettings.globalize_path(right_frames[index].resource_path))
		_check(left.get_size() == Vector2i(704, 512) and right.get_size() == left.get_size(), "Walking canvases must remain 704x512")
		var right_facing := right.duplicate() as Image
		right.flip_x()
		var bounds := left.get_used_rect()
		_check(Rect2i(32, 20, 656, 484).encloses(bounds), "Every ear, paw and the complete elegant tail must retain canvas padding")
		_check(bounds.end.y == 500, "All planted paws must share one ground line")
		minimum_height = mini(minimum_height, bounds.size.y)
		maximum_height = maxi(maximum_height, bounds.size.y)
		var green_spill := 0
		var amber_eye_pixels := 0
		var blue_eye_pixels := 0
		var right_blue_eye_pixels := 0
		var non_eye_mirror_differences := 0
		var torso_opaque_pixels := 0
		var torso_neutral_pixels := 0
		var torso_too_bright_pixels := 0
		var ground_contacts := 0
		var soft_edge_pixels := 0
		var right_nose_pixels := 0
		for y in range(left.get_height()):
			for x in range(left.get_width()):
				var color := left.get_pixel(x, y)
				var mirrored_color := right.get_pixel(x, y)
				var right_facing_color := right_facing.get_pixel(x, y)
				if color.a > 0.08 and color.a < 0.92:
					soft_edge_pixels += 1
				if (
					Rect2i(540, 125, 145, 95).has_point(Vector2i(x, y))
					and right_facing_color.a > 0.55
					and right_facing_color.r > right_facing_color.g * 1.18
					and right_facing_color.b > right_facing_color.g * 1.12
				):
					right_nose_pixels += 1
				if not is_equal_approx(color.a, mirrored_color.a):
					non_eye_mirror_differences += 1
				elif not LEFT_EYE_REGION.has_point(Vector2i(x, y)) and color != mirrored_color:
					non_eye_mirror_differences += 1
				if color.a > 0.05 and color.g > maxf(color.r, color.b) + 0.05:
					green_spill += 1
				if LEFT_EYE_REGION.has_point(Vector2i(x, y)) and color.a > 0.45:
					if color.r > 0.46 and color.r > color.g * 1.10 and color.g > color.b * 1.18:
						amber_eye_pixels += 1
					if color.g > 0.35 and color.b > 0.45 and color.b > color.r * 1.30 and color.g > color.r * 1.15:
						blue_eye_pixels += 1
					if mirrored_color.g > 0.35 and mirrored_color.b > 0.45 and mirrored_color.b > mirrored_color.r * 1.30 and mirrored_color.g > mirrored_color.r * 1.15:
						right_blue_eye_pixels += 1
				if Rect2i(175, 180, 350, 150).has_point(Vector2i(x, y)) and color.a > 0.9:
					torso_opaque_pixels += 1
					if maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) < 0.15:
						torso_neutral_pixels += 1
					if color.get_luminance() > 0.36:
						torso_too_bright_pixels += 1
				if y >= 493 and color.a > 0.8:
					ground_contacts += 1
		_check(green_spill == 0, "No green matte may remain on Sable or inside leg/tail gaps")
		_check(non_eye_mirror_differences == 0, "Directions must share identical new anatomy and alpha; only the visible eye color may change")
		_check(amber_eye_pixels > 25 and blue_eye_pixels == 0, "Left-facing Sable must show only the amber near-side profile eye")
		_check(right_blue_eye_pixels > 25, "Right-facing Sable must show her blue near-side profile eye")
		_check(torso_opaque_pixels > 9000 and float(torso_neutral_pixels) / torso_opaque_pixels > 0.97, "Sable's coat must stay solid charcoal-black without brown or tabby color patches")
		_check(torso_too_bright_pixels < 40, "Sable's torso must not acquire pale tabby stripes or spots")
		_check(ground_contacts > 55, "Every pose must keep a natural support paw on the ground")
		_check(soft_edge_pixels > 500, "The repaired short-hair silhouette must retain a soft antialiased coverage edge")
		_check(right_nose_pixels > 6, "Every right-facing frame must retain a complete muted-plum nose tip")
		var silhouette := PackedByteArray()
		for y in range(330, 501, 2):
			for x in range(70, 630, 2):
				silhouette.append(1 if left.get_pixel(x, y).a > 0.5 else 0)
		leg_silhouettes[silhouette.hex_encode()] = true
		print("frame %02d: bounds=%s green=%d amber=%d blue-right=%d contacts=%d torso-bright=%d" % [
			index + 1, bounds, green_spill, amber_eye_pixels, right_blue_eye_pixels,
			ground_contacts, torso_too_bright_pixels
		])
	_check(leg_silhouettes.size() >= 10, "The new walk must contain genuinely different leg poses")
	_check(maximum_height - minimum_height <= 12, "An elegant walk should use only subtle head and shoulder bob")

	for display_size in [Vector2(460, 390), Vector2(400, 300), Vector2(800, 600)]:
		var avatar := AvatarScript.new()
		avatar.size = display_size
		avatar.set_pet({"id": "black_cat", "name": "Sable"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar.set_mood("follow")
		var duration := 1.0 / AvatarScript.BLACK_CAT_MOVE_FPS
		for direction in [Vector2.LEFT, Vector2.RIGHT]:
			avatar.stop_move()
			avatar.play_move(direction)
			avatar._update_layout()
			_check(avatar.cat_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Sable's repaired walk must use linear filtering so the short-hair outline stays smooth")
			var fixed_position := avatar.cat_sprite.position
			var fixed_scale := avatar.cat_sprite.scale
			var expected_frames := left_frames if direction == Vector2.LEFT else right_frames
			for frame_index in range(24):
				_check(avatar.move_frame == frame_index % 12 and avatar.cat_sprite.texture == expected_frames[frame_index % 12], "Sable's new side-profile gait must loop continuously")
				_check(avatar.cat_sprite.position.is_equal_approx(fixed_position) and avatar.cat_sprite.scale.is_equal_approx(fixed_scale), "Moving paws and tail must not make Sable jump or resize")
				avatar.play_move(direction)
				avatar._process(duration + 0.000001)
			avatar.play_move(-direction)
			avatar._update_layout()
			_check(avatar.move_frame == 0, "Changing direction must begin the opposite side-profile cycle cleanly")
			_check(avatar.cat_sprite.position.is_equal_approx(fixed_position) and avatar.cat_sprite.scale.is_equal_approx(fixed_scale), "Turning must preserve Sable's exact body anchor")
			avatar.stop_move()
			_check(avatar.cat_sprite.texture == AvatarScript.BLACK_CAT_IDLE_TEXTURE, "Stopping must restore Sable's unchanged seated art")
			_check(avatar.cat_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "Sable's side-sitting art must use linear filtering so the paw and tail undersides stay smooth")
		avatar.play_belly_roll()
		_check(avatar.cat_sprite.texture == AvatarScript.BLACK_CAT_LICK_PAW_FRAMES[0], "The redraw must not change Sable's double-click animation")
		avatar._process(10.0)
		avatar.set_mood("sleep")
		_check(avatar.cat_sprite.texture in AvatarScript.BLACK_CAT_FALL_ASLEEP_FRAMES, "The redraw must not change Sable's sleep animation")
		avatar.set_pet({"id": "mochi", "name": "Mochi"})
		avatar.set_mood("idle")
		avatar.play_move(Vector2.LEFT)
		avatar._process(0.10)
		_check(avatar.move_frame == 0, "Other cats must keep their existing seven-FPS cadence")
		avatar._process(0.05)
		_check(avatar.move_frame == 1, "Other cats must still advance at seven FPS")
		avatar.queue_free()
		await process_frame

	if OS.get_cmdline_user_args().has("--capture-walk"):
		await _capture_walk()
	if failures.is_empty():
		print("SABLE WALK REDRAW TEST PASS: side gaze, solid coat, directional eyes, grounded gait, fixed layout, smooth loops and unchanged other animations")
		quit(0)
	else:
		print("SABLE WALK REDRAW TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _capture_walk() -> void:
	root.size = Vector2i(1088, 520)
	RenderingServer.set_default_clear_color(Color("#e6d7c1"))
	var avatars: Array[Control] = []
	for index in range(2):
		var avatar := AvatarScript.new()
		avatar.size = Vector2(500, 390)
		avatar.position = Vector2(22 + index * 544, 50)
		avatar.set_pet({"id": "black_cat", "name": "Sable"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar.set_mood("follow")
		avatar.play_move(Vector2.LEFT if index == 0 else Vector2.RIGHT)
		avatar.mood_badge.hide()
		avatars.append(avatar)
	for frame_index in range(24):
		await RenderingServer.frame_post_draw
		if frame_index < 12:
			root.get_texture().get_image().save_png("/private/tmp/sable-walk-v3-runtime-%02d.png" % (frame_index + 1))
		await create_timer(1.0 / AvatarScript.BLACK_CAT_MOVE_FPS).timeout
		for avatar_index in range(2):
			avatars[avatar_index].play_move(Vector2.LEFT if avatar_index == 0 else Vector2.RIGHT)
			avatars[avatar_index]._process(1.0 / AvatarScript.BLACK_CAT_MOVE_FPS + 0.000001)
	for avatar in avatars:
		avatar.queue_free()
	await process_frame
