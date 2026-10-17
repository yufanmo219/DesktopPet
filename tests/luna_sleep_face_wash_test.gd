extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
const FRAME_DIRECTORY := "res://assets/pets/russian_blue/sleep/face_wash_v2"
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
	var frames := luna_assets.animation_frames("sleep_effect")
	var sleep_clip := luna_assets.animation_clip("sleep_effect")
	var base := Image.load_from_file(ProjectSettings.globalize_path(luna_assets.sleep_texture.resource_path))
	var bounds := base.get_used_rect()
	_check(frames.size() == 12 and durations.size() == frames.size(), "The face wash must have twelve timed poses")
	_check(frames[0] == luna_assets.sleep_texture and frames[-1] == luna_assets.sleep_texture, "Bookends must reuse the repaired original resting texture")
	for index in range(frames.size()):
		var frame: Image = frames[index].get_image()
		_check(frame.get_size() == base.get_size(), "Frame %d must keep the 640x512 canvas" % (index + 1))
		var current_bounds := frame.get_used_rect()
		_check(Rect2i(8, 8, 624, 497).encloses(current_bounds), "No tail, paw or ear may touch the canvas edge")
		_check(absi(current_bounds.size.x - bounds.size.x) <= 8 and absi(current_bounds.size.y - bounds.size.y) <= 4, "Frames must preserve Luna's overall visual size")
		_check(absi(current_bounds.end.x - bounds.end.x) <= 1 and absi(current_bounds.end.y - bounds.end.y) <= 1, "The rear tail edge and ground line must remain fixed")
		_check(durations[index] > 0.0, "Every pose must have a positive duration")
		if index > 0 and index < frames.size() - 1:
			_check(frames[index].resource_path == "%s/frame_%02d.png" % [FRAME_DIRECTORY, index + 1], "Every animated pose must use the user-selected v2 sequence, not the later fixed-paw revision")
			var green_count := 0
			var gap_transparent_count := 0
			var gap_yellow_spill_count := 0
			for y in range(frame.get_height()):
				for x in range(frame.get_width()):
					var color := frame.get_pixel(x, y)
					if color.a > 0.0 and color.g > maxf(color.r, color.b) + 8.0 / 255.0:
						green_count += 1
					if Rect2i(547, 406, 36, 36).has_point(Vector2i(x, y)):
						if color.a == 0.0:
							gap_transparent_count += 1
						elif color.a > 0.05 and color.g > 0.35 and color.b < color.g * 0.75 and color.r < color.g * 1.35:
							gap_yellow_spill_count += 1
			_check(green_count == 0, "Frame %d must contain no green background islands or green outline spill" % (index + 1))
			_check(gap_transparent_count > 25, "The enclosed tail/body gap must be genuinely transparent, not painted grey")
			_check(gap_yellow_spill_count == 0, "The tail gap must not retain yellow/green matte edge pixels after keying")
			print("frame %02d: green=%d transparent tail-gap pixels=%d" % [index + 1, green_count, gap_transparent_count])
	_check(frames[2].get_image().get_data() != frames[5].get_image().get_data(), "Lifting and wiping must use different drawn bent-arm poses")

	for display_size in [Vector2(460, 390), Vector2(400, 300), Vector2(800, 600)]:
		var avatar := AvatarScript.new()
		avatar.size = display_size
		avatar.set_pet({"id": "luna", "name": "Luna"})
		root.add_child(avatar)
		avatar.set_process(false)
		avatar.set_mood("sleep")
		var initial_position := avatar.cat_sprite.position
		var initial_scale := avatar.cat_sprite.scale
		avatar.sleep_effect_wait_remaining = 0.0
		avatar._process(0.001)
		for index in range(frames.size()):
			_check(avatar.sleep_effect_playing and avatar.sleep_effect_frame == index and avatar.cat_sprite.texture == frames[index], "Sleep must play every new frame in order")
			_check(avatar.cat_sprite.position.is_equal_approx(initial_position) and avatar.cat_sprite.scale.is_equal_approx(initial_scale), "Paw motion must never recenter or resize the runtime cat")
			avatar._process(sleep_clip.frame_duration(index) + 0.00001)
		_check(not avatar.sleep_effect_playing and avatar.cat_sprite.texture == avatar.sleep_texture, "The wash must settle back onto the repaired resting pose")
		_check(avatar.sleep_effect_wait_remaining >= sleep_clip.wait_min and avatar.sleep_effect_wait_remaining <= sleep_clip.wait_max, "The original random sleep interval must remain intact")
		avatar.sleep_effect_wait_remaining = 0.0
		avatar._process(0.001)
		avatar._process(0.8)
		avatar.set_mood("idle")
		_check(not avatar.sleep_effect_playing and avatar.cat_sprite.texture == avatar.idle_texture, "Waking mid-wipe must stop the sleep animation")
		avatar.play_move(Vector2.LEFT)
		_check(avatar.cat_sprite.texture in avatar.animation_frames("move_left"), "Walking must work normally after waking")
		avatar.stop_move()
		avatar.set_mood("sleep")
		avatar.sleep_effect_wait_remaining = 0.0
		avatar._process(0.001)
		avatar.set_pet({"id": "biscuit", "name": "Biscuit"})
		_check(not avatar.sleep_effect_playing and avatar.cat_sprite.texture == avatar.sleep_texture, "Switching cats mid-wipe must clear Luna's animation")
		avatar.queue_free()
		await process_frame

	luna_assets.free()
	if OS.get_cmdline_user_args().has("--capture-face-wash"):
		await _capture_runtime_frames()
	if failures.is_empty():
		print("LUNA FACE WASH TEST PASS: selected v2 frames restored, clean tail-gap alpha, stable layout and sleep/wake/move/cat-switch playback")
		quit(0)
	else:
		print("LUNA FACE WASH TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _capture_runtime_frames() -> void:
	root.size = Vector2i(640, 512)
	RenderingServer.set_default_clear_color(Color("#cbb296"))
	var avatar := AvatarScript.new()
	avatar.size = Vector2(640, 512)
	avatar.set_pet({"id": "luna", "name": "Luna"})
	root.add_child(avatar)
	avatar.set_process(false)
	avatar.set_mood("sleep")
	avatar.mood_badge.hide()
	avatar.sleep_effect_wait_remaining = 0.0
	avatar._process(0.001)
	var preview_frames := avatar.animation_frames("sleep_effect")
	var preview_clip := avatar.animation_clip("sleep_effect")
	for index in range(preview_frames.size()):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/luna-face-wash-runtime-%02d.png" % (index + 1))
		await create_timer(preview_clip.frame_duration(index)).timeout
		avatar._process(preview_clip.frame_duration(index) + 0.00001)
	avatar.queue_free()
	await process_frame
