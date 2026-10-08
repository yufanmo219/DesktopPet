extends SceneTree

class FollowHarness:
	extends "res://src/main.gd"
	var test_pointer := Vector2.ZERO
	var test_screens: Array[Rect2] = [Rect2(-4000, -2200, 10000, 5000)]

	func get_desktop_pointer_position() -> Vector2:
		return test_pointer

	func get_desktop_screen_rects() -> Array[Rect2]:
		return test_screens


var failures: Array[String] = []
var game: FollowHarness
var companion: DesktopCompanionController


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _pointer_for_target(target: Vector2) -> Vector2:
	return target + companion.get_pet_widget_pixel_size() * 0.5 - Vector2(28, 28) * companion.widget_screen_scale


func _reset(scale_value := 1.0, pet_id := "maple") -> void:
	companion.set_widget_following(false)
	companion.widget_screen_scale = scale_value
	companion.widget_pet_at_station = false
	companion.widget_pet_dragging = false
	companion.widget_returning_to_station = false
	companion.widget_seconds_since_pet_drag = 0.0
	companion.widget_seconds_outside_station = 0.0
	companion.widget_station_position = Vector2(800, 800) * scale_value
	companion.set_widget_pet_position(Vector2(300, 200) * scale_value, false)
	game.avatar.set_pet({"id": pet_id, "name": pet_id.capitalize()})
	game.avatar.set_process(false)
	game.test_pointer = _pointer_for_target(Vector2(900, 200) * scale_value)


func _run() -> void:
	game = FollowHarness.new()
	companion = game.desktop_controller
	game.save_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.enter_desktop_mode()
	game.avatar.set_process(false)
	await process_frame
	_check(companion.PET_FOLLOW_RUN_SPEED == 150.0, "The approved following speed must not change")
	for scale_value in [0.9, 1.0, 1.8]:
		_test_current_pointer_start(scale_value)
		_test_continuous_pointer(scale_value)
		_test_stop_and_restart(scale_value)
		_test_return_speed(scale_value)
	_test_delta_independence()
	_test_return_delta_independence()
	_test_long_return_stays_awake()
	_test_screen_boundaries()
	_test_interactions_and_drag()
	_test_unfollow()
	game.queue_free()
	await process_frame
	var music = root.get_node_or_null("MusicManager")
	if music != null:
		music.stop_music(0.0)
	if failures.is_empty():
		print("DESKTOP FOLLOW TEST PASS: immediate targeting, one-time short reaction, continuous retargeting, 60/100 hysteresis, matching follow/return speeds, awake long returns, display scaling/seams, double-click, drag, and Unfollow")
		quit(0)
	else:
		print("DESKTOP FOLLOW TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _test_current_pointer_start(scale_value: float) -> void:
	_reset(scale_value)
	var initial := companion.widget_pet_position
	companion.set_widget_following(true)
	_check(companion.widget_follow_has_target and companion.widget_follow_chasing, "Follow Me must target a distant stationary pointer immediately")
	_check(companion.widget_follow_target.is_equal_approx(Vector2(900, 200) * scale_value), "Activation must use the actual current pointer")
	_check(companion.widget_follow_reaction_remaining >= 0.3 and companion.widget_follow_reaction_remaining <= 0.6, "Starting from rest should wait only 0.3–0.6 seconds")
	_check(companion.follow_button.text == "UNFOLLOW" and game.avatar.mood == "follow" and not game.avatar.mood_badge.visible, "Follow UI and hidden mood badge must remain correct")
	var reaction := companion.widget_follow_reaction_remaining
	companion.update(reaction * 0.5)
	_check(companion.widget_pet_position == initial, "The initial reaction must not move or teleport the cat")
	companion.update(companion.widget_follow_reaction_remaining + 0.1)
	_check(is_equal_approx(companion.widget_pet_position.distance_to(initial), 15.0 * scale_value), "Without another mouse movement, the cat must start at the unchanged speed")


func _test_continuous_pointer(scale_value: float) -> void:
	_reset(scale_value)
	companion.set_widget_following(true)
	var initial := companion.widget_pet_position
	for step in range(180):
		# Exceeds the old movement threshold on EVERY frame, including startup.
		var target := Vector2(900 + step * 6.0, 200) * scale_value
		game.test_pointer = _pointer_for_target(target)
		var remaining_before := companion.widget_follow_reaction_remaining
		var position_before := companion.widget_pet_position
		companion.update(1.0 / 60.0)
		_check(companion.widget_follow_target.is_equal_approx(target), "Every moving-pointer update must refresh the target")
		_check(companion.widget_follow_reaction_remaining <= remaining_before + 0.00001, "Moving the pointer must never reset the reaction countdown")
		var moved := companion.widget_pet_position.distance_to(position_before)
		_check(moved <= 2.5 * scale_value + 0.001, "Retargeting must preserve the fixed speed")
		if step >= 37:
			_check(moved > 0.0 and game.avatar.move_time_remaining > 0.0, "A continuously moving far-away pointer must never freeze a chasing cat")
	_check(companion.widget_pet_position.distance_to(initial) > 350.0 * scale_value, "Three seconds of continuous cursor motion must produce sustained following")
	game.test_pointer = _pointer_for_target(companion.widget_pet_position + Vector2(-400, 0) * scale_value)
	var before_turn := companion.widget_pet_position
	companion.update(0.1)
	_check(companion.widget_pet_position.x < before_turn.x and game.avatar.move_direction == "left" and companion.widget_follow_reaction_remaining == 0.0, "A running cat must turn toward a new target without another reaction delay")


func _test_stop_and_restart(scale_value: float) -> void:
	_reset(scale_value)
	companion.set_widget_following(true)
	companion.update(10.0)
	var resting := companion.widget_pet_position
	_check(is_equal_approx(resting.distance_to(companion.widget_follow_target), 60.0 * scale_value), "A large delta must stop at the 60-pixel radius, not snap onto the cursor")
	_check(not companion.widget_follow_chasing and game.avatar.move_time_remaining == 0.0, "Reaching the near radius must stop walking")
	for distance in [60.0, 65.0, 80.0, 99.0, 100.0, 75.0, 55.0, 90.0]:
		game.test_pointer = _pointer_for_target(resting + Vector2(distance, 0) * scale_value)
		companion.update(0.1)
		_check(companion.widget_pet_position.is_equal_approx(resting) and not companion.widget_follow_chasing and companion.widget_follow_reaction_remaining == 0.0, "Small pointer movements inside 100 pixels must not restart a resting cat")
	game.test_pointer = _pointer_for_target(resting + Vector2(110, 0) * scale_value)
	companion.update(0.0)
	_check(companion.widget_follow_chasing and companion.widget_follow_reaction_remaining >= 0.3 and companion.widget_follow_reaction_remaining <= 0.6, "Leaving the 100-pixel radius must start one fresh short reaction")
	companion.widget_follow_reaction_remaining = 0.0
	companion.update(0.1)
	_check(companion.widget_follow_chasing and is_equal_approx(companion.widget_pet_position.distance_to(companion.widget_follow_target), 95.0 * scale_value), "An active chase must continue through the 60–100 band")
	companion.update(1.0)
	_check(not companion.widget_follow_chasing and is_equal_approx(companion.widget_pet_position.distance_to(companion.widget_follow_target), 60.0 * scale_value), "An active chase should stop only at the near radius")
	game.test_pointer = _pointer_for_target(companion.widget_pet_position + Vector2(120, 0) * scale_value)
	companion.update(0.0)
	game.test_pointer = _pointer_for_target(companion.widget_pet_position + Vector2(40, 0) * scale_value)
	companion.update(0.1)
	_check(not companion.widget_follow_chasing and companion.widget_follow_reaction_remaining == 0.0, "A pointer that returns nearby during the reaction should cancel the chase")


func _test_delta_independence() -> void:
	for step_size in [0.01, 0.05, 0.2]:
		_reset()
		companion.set_widget_following(true)
		companion.widget_follow_reaction_remaining = 0.4
		var initial := companion.widget_pet_position
		for step in range(roundi(1.0 / step_size)):
			companion.update(step_size)
		_check(absf(companion.widget_pet_position.distance_to(initial) - 90.0) < 0.01, "Reaction expiry must use the remaining delta so speed does not depend on frame rate")


func _test_return_speed(scale_value: float) -> void:
	_reset(scale_value)
	var follow_start := companion.widget_pet_position
	companion.set_widget_following(true)
	companion.widget_follow_reaction_remaining = 0.0
	companion.update(0.1)
	var follow_step := companion.widget_pet_position.distance_to(follow_start)
	for distance in [4.0, 300.0, 2600.0]:
		_reset(scale_value)
		var station_target := companion.get_station_pet_anchor()
		companion.set_widget_pet_position(station_target + Vector2(0.6, -0.8) * distance * scale_value, false)
		companion.set_widget_following(true)
		companion.set_widget_following(false)
		game.test_pointer = Vector2(-3000, -2000)
		_check(companion.widget_returning_to_station, "Unfollow must start returning from both nearby and distant positions")
		var step_count := ceili(distance * scale_value / follow_step) + 2
		for step in range(step_count):
			var before := companion.widget_pet_position
			var remaining := before.distance_to(station_target)
			companion.update(0.1)
			var expected_step := minf(follow_step, remaining)
			_check(absf(companion.widget_pet_position.distance_to(before) - expected_step) < 0.001, "Every return step must match the follow speed, regardless of distance or display scale, without a final snap")
			if not companion.widget_pet_at_station:
				_check(game.avatar.move_time_remaining > 0.0, "Returning cats must retain their normal walking animation")
		_check(companion.widget_pet_at_station and not companion.widget_returning_to_station and companion.widget_pet_position == station_target, "A constant-speed return must finish exactly at the Station without overshooting")
		_check(game.avatar.move_time_remaining == 0.0 and game.avatar.mood == "idle", "Arrival must stop walking and restore the resting pose")


func _test_return_delta_independence() -> void:
	for step_size in [0.01, 0.05, 0.2, 1.0]:
		_reset()
		var station_target := companion.get_station_pet_anchor()
		var initial := station_target + Vector2(1000, 0)
		companion.set_widget_pet_position(initial, false)
		companion.set_widget_following(false)
		for step in range(roundi(1.0 / step_size)):
			companion.update(step_size)
		_check(absf(companion.widget_pet_position.distance_to(initial) - 150.0) < 0.01, "Returning must move 150 logical pixels per second at every frame rate")
		companion.update(20.0)
		_check(companion.widget_pet_at_station and companion.widget_pet_position == station_target, "A large return delta must stop exactly at the Station")


func _test_long_return_stays_awake() -> void:
	_reset()
	var station_target := companion.get_station_pet_anchor()
	companion.set_widget_pet_position(station_target + Vector2(2600, 0), false)
	game.test_pointer = Vector2(-3000, -2000)
	# Model a manual drag whose return starts after 15 seconds. Without resetting
	# the independent 30-second sleep timer, this distance sleeps for its final
	# 2.3 seconds while the pet window keeps moving.
	companion.widget_seconds_since_pet_drag = companion.PET_RETURN_SECONDS - 0.1
	companion.widget_seconds_outside_station = companion.PET_RETURN_SECONDS - 0.1
	companion.update(0.2)
	_check(companion.widget_returning_to_station, "A distant pet must begin its automatic return after fifteen seconds")
	var stayed_awake := game.avatar.mood == "idle"
	var sleep_timer_stayed_reset := companion.widget_seconds_outside_station == 0.0
	for step in range(200):
		if companion.widget_pet_at_station:
			break
		companion.update(0.1)
		if companion.widget_returning_to_station:
			stayed_awake = stayed_awake and game.avatar.mood == "idle"
			sleep_timer_stayed_reset = (
				sleep_timer_stayed_reset
				and companion.widget_seconds_outside_station == 0.0
			)
	_check(companion.widget_pet_at_station, "The long automatic return must still reach the Station")
	_check(stayed_awake, "A pet must never enter its sleep pose while returning to the Station")
	_check(sleep_timer_stayed_reset, "Returning must keep the sleep countdown reset")
	companion.update(companion.STATION_WAKE_SECONDS - 0.1)
	_check(game.avatar.mood == "idle", "The sleep countdown must restart only after the pet reaches the Station")
	companion.update(0.2)
	_check(game.avatar.mood == "sleep", "An idle pet may still sleep thirty seconds after returning")


func _test_screen_boundaries() -> void:
	_reset()
	game.test_screens = [Rect2(-1280, 0, 1280, 720), Rect2(0, 0, 1280, 720)]
	companion.set_widget_pet_position(Vector2(-50, 120), false)
	game.test_pointer = _pointer_for_target(Vector2(400, 120))
	companion.set_widget_following(true)
	companion.widget_follow_reaction_remaining = 0.0
	for step in range(8):
		companion.update(0.1)
	_check(companion.widget_pet_position.x > 0.0, "Continuous following must cross a display seam without clamping intermediate steps")
	game.test_pointer = Vector2(5000, 5000)
	companion.update(20.0)
	var edge_rest := companion.widget_pet_position
	for step in range(10):
		companion.update(0.1)
	_check(companion.widget_pet_position.is_equal_approx(edge_rest) and not companion.widget_follow_chasing, "An unreachable off-screen pointer must settle at the clamped target, not restart forever")
	game.test_screens = [Rect2(-4000, -2200, 10000, 5000)]


func _test_interactions_and_drag() -> void:
	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.pressed = true
	double_click.double_click = true
	for pet_id in ["maple", "mochi", "biscuit"]:
		_reset(1.0, pet_id)
		companion.set_widget_following(true)
		companion.widget_follow_reaction_remaining = 0.0
		companion.update(0.1)
		companion._on_pet_drag_input(double_click)
		var paused := companion.widget_pet_position
		game.test_pointer = _pointer_for_target(Vector2(1300, 400))
		companion.update(0.5)
		_check(game.avatar.is_playing_interaction() and companion.widget_pet_position == paused and not companion.widget_pet_dragging, "Double-click must pause following without becoming a drag")
		_check(companion.widget_follow_target.is_equal_approx(Vector2(1300, 400)), "The target should still track the cursor during an interaction")
		game.avatar._process(20.0)
		companion.update(0.1)
		_check(companion.widget_following and companion.widget_pet_position.distance_to(paused) > 0.0 and companion.widget_follow_reaction_remaining == 0.0, "Following should resume toward the latest target after the interaction")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	_check(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "The simulated drag must hold the actual input button state")
	companion._on_pet_drag_input(press)
	var drag_start := companion.widget_pet_position
	game.test_pointer += Vector2(100, 30)
	companion.update(0.5)
	_check(companion.widget_pet_dragging and companion.widget_pet_position == drag_start, "Follow Me must never fight an active manual drag")
	companion._on_pet_drag_input(InputEventMouseMotion.new())
	_check(companion.widget_pet_position.is_equal_approx(drag_start + Vector2(100, 30)), "Manual dragging must still control the cat position")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	companion._on_pet_drag_input(release)
	game.test_pointer = _pointer_for_target(companion.widget_pet_position + Vector2(600, 0))
	var released := companion.widget_pet_position
	companion.update(0.1)
	_check(not companion.widget_pet_dragging and companion.widget_following and companion.widget_pet_position.distance_to(released) > 0.0, "Releasing a drag must allow continuous following again")


func _test_unfollow() -> void:
	companion.set_widget_following(false)
	_check(not companion.widget_follow_has_target and not companion.widget_follow_chasing and companion.widget_follow_reaction_remaining == 0.0 and companion.follow_button.text == "FOLLOW ME", "Unfollow must clear all chase state and reset its button")
	_check(companion.widget_returning_to_station or companion.widget_pet_at_station, "Unfollow must keep the existing return-to-station behavior")
	game.test_pointer = Vector2(-3000, -2000)
	for step in range(60):
		companion.update(0.1)
	_check(companion.widget_pet_at_station and companion.widget_pet_position.distance_to(companion.get_station_pet_anchor()) < 2.0, "The unfollowed cat must arrive home normally")
	game.test_pointer = _pointer_for_target(companion.widget_pet_position + Vector2(500, 0))
	companion.set_widget_following(true)
	_check(companion.widget_follow_chasing and companion.widget_follow_reaction_remaining >= 0.3 and companion.widget_follow_reaction_remaining <= 0.6, "Re-enabling Follow Me must start a fresh chase without stale state")
