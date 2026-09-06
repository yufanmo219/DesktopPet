extends SceneTree

const FishingScript = preload("res://src/fishing_game.gd")
const RIGHT_EYE_REGION := Rect2i(310, 150, 90, 105)
const LEFT_EYE_REGION := Rect2i(190, 164, 100, 75)

class FishingHarness:
	extends "res://src/fishing_game.gd"
	var observed_frames: Array[Texture2D] = []
	var observed_durations: Array[float] = []
	var observed_positions: Array[Vector2] = []
	var observed_sizes: Array[Vector2] = []
	var capture_frames := false

	func _wait_for_unpaused_gameplay_time(duration: float) -> void:
		observed_frames.append(pet_view.texture)
		observed_durations.append(duration)
		observed_positions.append(pet_view.position)
		observed_sizes.append(pet_view.size)
		if capture_frames:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("/private/tmp/biscuit-fishing-wink-tilt-runtime-%02d.png" % observed_frames.size())
			await super._wait_for_unpaused_gameplay_time(duration)
		else:
			await get_tree().process_frame

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var frames := FishingScript.BISCUIT_FISHING_WINK_FRAMES
	var base := FishingScript.BISCUIT_FISHING_DEFAULT_TEXTURE.get_image()
	base.convert(Image.FORMAT_RGBA8)
	_check(frames.size() == 8, "Biscuit must retain the eight-frame fishing reaction")
	_check(frames[0] == FishingScript.BISCUIT_FISHING_DEFAULT_TEXTURE and frames[-1] == frames[0], "The wink must start and finish on the approved default texture")
	var open_pupil_count := _left_eye_dark_pixels(base)
	var neutral_foot_anchor := _foot_anchor(base)
	for index in range(frames.size()):
		var frame := frames[index].get_image()
		frame.convert(Image.FORMAT_RGBA8)
		var bounds := frame.get_used_rect()
		_check(frame.get_size() == base.get_size(), "Frame %d must preserve the fixed 512px canvas" % (index + 1))
		_check(Rect2i(12, 12, 488, 490).encloses(bounds), "Every head tilt must retain padding around both ears, all paws and the tail")
		_check(absf(bounds.size.y - base.get_used_rect().size.y) <= 8.0, "Head motion must not visibly shrink or enlarge the cat")
		var foot_anchor := _foot_anchor(frame)
		_check(absf(foot_anchor.x - neutral_foot_anchor.x) <= 3.0 and absf(foot_anchor.y - neutral_foot_anchor.y) <= 1.0, "Front paws must remain planted while the head tilts")
		var head_changes := 0
		var green_pixels := 0
		for y in range(base.get_height()):
			for x in range(base.get_width()):
				var original := base.get_pixel(x, y)
				var current := frame.get_pixel(x, y)
				if y < 270 and original != current:
					head_changes += 1
				if current.a > 0.05 and current.g > maxf(current.r, current.b) + 0.08:
					green_pixels += 1
		var right_iris := _right_eye_iris_pixels(frame)
		var left_pupil := _left_eye_dark_pixels(frame)
		print("frame %02d: foot=%s height=%d right iris=%d left pupil/lid=%d head changes=%d" % [index + 1, foot_anchor, bounds.size.y, right_iris, left_pupil, head_changes])
		_check(right_iris > 100, "The grey-side eye must remain visibly open in every frame, including the head tilt")
		if index > 0 and index < frames.size() - 1:
			_check(green_pixels == 0, "New generated poses must have no green matte or outline spill")
			_check(head_changes > 12000, "The new reaction must animate the entire head, not just swap a static eye patch")
		else:
			_check(frame.get_data() == base.get_data(), "Neutral bookends must preserve the existing approved art without modifying its legacy edge pixels")
		if index in [2, 3, 4, 5]:
			_check(left_pupil < open_pupil_count * 0.65, "The yellow-side eye must close during the playful wink")
		else:
			_check(left_pupil > open_pupil_count * 0.65, "The yellow-side eye must start open and reopen before the reaction ends")
	_check(frames[1].get_image().get_data() != frames[6].get_image().get_data(), "Anticipation and settling must use distinct generated head poses")

	var game := FishingHarness.new()
	game.capture_frames = OS.get_cmdline_user_args().has("--capture-wink")
	if game.capture_frames:
		root.size = Vector2i(1280, 720)
	game.configure({"id": "biscuit", "name": "Biscuit"}, {"hearts": 5})
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start_round_from_goal_popup()
	game.spawn_timer.stop()
	game.state = game.GameState.LIFTING_NET
	var initial_position := game.pet_view.position
	var initial_size := game.pet_view.size
	var caught_visual := TextureRect.new()
	caught_visual.position = Vector2(400, 300)
	game.add_child(caught_visual)
	var caught_visuals: Array[TextureRect] = [caught_visual]
	await game._play_lift_animation(caught_visuals, true)
	_check(game.observed_frames == frames, "A successful net lift must play the exact new eight-frame single-eye wink in order")
	var expected_durations: Array[float] = [0.13, 0.12, 0.12, 0.13, 0.18, 0.10, 0.10, 0.10]
	_check(game.observed_durations == expected_durations, "The existing net-lift and reaction timing must remain unchanged")
	_check(game.observed_positions.all(func(value): return value == initial_position) and game.observed_sizes.all(func(value): return value == initial_size), "The actual riverbank cat must not shift or resize during the wink")
	_check(caught_visual.position == Vector2(400, 210), "Caught fish must still rise with the original net motion")
	_check(game.pet_view.texture == FishingScript.BISCUIT_FISHING_DEFAULT_TEXTURE, "The successful reaction must end with both eyes open")
	game.capture_frames = false
	game.observed_frames.clear()
	var empty_catch: Array[TextureRect] = []
	await game._play_lift_animation(empty_catch, false)
	_check(game.observed_frames.size() == 6 and game.observed_frames.all(func(value): return value == FishingScript.BISCUIT_FISHING_DEFAULT_TEXTURE), "An empty net must not trigger the success wink")
	_check(game._failure_cat_texture() == FishingScript.BISCUIT_FISHING_FAILURE_TEXTURE, "Biscuit's failure artwork must remain unchanged")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("BISCUIT FISHING WINK TEST PASS: generated full-head tilt, one-eye wink, planted paws, consistent scale, clean alpha, success-only playback and original net timing")
		quit(0)
	else:
		print("BISCUIT FISHING WINK TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _left_eye_dark_pixels(image: Image) -> int:
	var count := 0
	for y in range(LEFT_EYE_REGION.position.y, LEFT_EYE_REGION.end.y):
		for x in range(LEFT_EYE_REGION.position.x, LEFT_EYE_REGION.end.x):
			var color := image.get_pixel(x, y)
			if color.a > 0.9 and color.r < 0.45 and color.g < 0.22 and color.b < 0.25:
				count += 1
	return count


func _right_eye_iris_pixels(image: Image) -> int:
	var count := 0
	for y in range(RIGHT_EYE_REGION.position.y, RIGHT_EYE_REGION.end.y):
		for x in range(RIGHT_EYE_REGION.position.x, RIGHT_EYE_REGION.end.x):
			var color := image.get_pixel(x, y)
			if color.a > 0.9 and color.r > 0.75 and color.g > 0.42 and color.g < 0.85 and color.b < 0.35:
				count += 1
	return count


func _foot_anchor(image: Image) -> Vector2:
	var bounds := image.get_used_rect()
	var sum_x := 0.0
	var sum_weight := 0.0
	for y in range(bounds.end.y - 4, bounds.end.y):
		for x in range(bounds.position.x + roundi(bounds.size.x * 0.35), bounds.end.x):
			var alpha := image.get_pixel(x, y).a
			if alpha > 0.15:
				sum_x += x * alpha
				sum_weight += alpha
	return Vector2(sum_x / maxf(sum_weight, 0.001), bounds.end.y - 1)
