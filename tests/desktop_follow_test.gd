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


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _pointer_for_target(target: Vector2) -> Vector2:
	return target + game.get_pet_widget_pixel_size() * 0.5 - Vector2(28, 28) * game.widget_screen_scale


func _reset(scale_value := 1.0, pet_id := "maple") -> void:
	game.set_widget_following(false)
	game.widget_screen_scale = scale_value
	game.widget_pet_at_station = false
	game.widget_pet_dragging = false
	game.widget_returning_to_station = false
	game.widget_seconds_since_pet_drag = 0.0
	game.widget_seconds_outside_station = 0.0
	game.widget_station_position = Vector2(800, 800) * scale_value
	game.set_widget_pet_position(Vector2(300, 200) * scale_value, false)
	game.avatar.set_pet({"id": pet_id, "name": pet_id.capitalize()})
	game.avatar.set_process(false)
	game.test_pointer = _pointer_for_target(Vector2(900, 200) * scale_value)


func _run() -> void:
	game = FollowHarness.new()
	game.save_enabled = false
	root.add_child(game)
	game.set_process(false)
	game.enter_desktop_mode()
	game.avatar.set_process(false)
	await process_frame
	_check(game.PET_FOLLOW_RUN_SPEED == 150.0, "The approved following speed must not change")
	for scale_value in [0.9, 1.0, 1.8]:
		_test_current_pointer_start(scale_value)
		_test_continuous_pointer(scale_value)
		_test_stop_and_restart(scale_value)
		_test_return_speed(scale_value)
	_test_delta_independence()
	_test_return_delta_independence()
	_test_screen_boundaries()
	_test_interactions_and_drag()
	_test_unfollow()
	game.queue_free()
	await process_frame
	var music = root.get_node_or_null("MusicManager")
	if music != null:
		music.stop_music(0.0)
	if failures.is_empty():
		print("DESKTOP FOLLOW TEST PASS: immediate targeting, one-time short reaction, continuous retargeting, 60/100 hysteresis, matching follow/return speeds, display scaling/seams, double-click, drag, and Unfollow")
		quit(0)
	else:
		print("DESKTOP FOLLOW TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _test_current_pointer_start(scale_value: float) -> void:
	_reset(scale_value)
	var initial := game.widget_pet_position
	game.set_widget_following(true)
	_check(game.widget_follow_has_target and game.widget_follow_chasing, "Follow Me must target a distant stationary pointer immediately")
	_check(game.widget_follow_target.is_equal_approx(Vector2(900, 200) * scale_value), "Activation must use the actual current pointer")
	_check(game.widget_follow_reaction_remaining >= 0.3 and game.widget_follow_reaction_remaining <= 0.6, "Starting from rest should wait only 0.3–0.6 seconds")
	_check(game.follow_button.text == "UNFOLLOW" and game.avatar.mood == "follow" and not game.avatar.mood_badge.visible, "Follow UI and hidden mood badge must remain correct")
	var reaction := game.widget_follow_reaction_remaining
	game.update_desktop_companion(reaction * 0.5)
	_check(game.widget_pet_position == initial, "The initial reaction must not move or teleport the cat")
	game.update_desktop_companion(game.widget_follow_reaction_remaining + 0.1)
	_check(is_equal_approx(game.widget_pet_position.distance_to(initial), 15.0 * scale_value), "Without another mouse movement, the cat must start at the unchanged speed")


func _test_continuous_pointer(scale_value: float) -> void:
	_reset(scale_value)
	game.set_widget_following(true)
	var initial := game.widget_pet_position
	for step in range(180):
		# Exceeds the old movement threshold on EVERY frame, including startup.
		var target := Vector2(900 + step * 6.0, 200) * scale_value
		game.test_pointer = _pointer_for_target(target)
		var remaining_before := game.widget_follow_reaction_remaining
		var position_before := game.widget_pet_position
		game.update_desktop_companion(1.0 / 60.0)
		_check(game.widget_follow_target.is_equal_approx(target), "Every moving-pointer update must refresh the target")
		_check(game.widget_follow_reaction_remaining <= remaining_before + 0.00001, "Moving the pointer must never reset the reaction countdown")
		var moved := game.widget_pet_position.distance_to(position_before)
		_check(moved <= 2.5 * scale_value + 0.001, "Retargeting must preserve the fixed speed")
		if step >= 37:
			_check(moved > 0.0 and game.avatar.move_time_remaining > 0.0, "A continuously moving far-away pointer must never freeze a chasing cat")
	_check(game.widget_pet_position.distance_to(initial) > 350.0 * scale_value, "Three seconds of continuous cursor motion must produce sustained following")
	game.test_pointer = _pointer_for_target(game.widget_pet_position + Vector2(-400, 0) * scale_value)
	var before_turn := game.widget_pet_position
	game.update_desktop_companion(0.1)
	_check(game.widget_pet_position.x < before_turn.x and game.avatar.move_direction == "left" and game.widget_follow_reaction_remaining == 0.0, "A running cat must turn toward a new target without another reaction delay")


func _test_stop_and_restart(scale_value: float) -> void:
	_reset(scale_value)
	game.set_widget_following(true)
	game.update_desktop_companion(10.0)
	var resting := game.widget_pet_position
	_check(is_equal_approx(resting.distance_to(game.widget_follow_target), 60.0 * scale_value), "A large delta must stop at the 60-pixel radius, not snap onto the cursor")
	_check(not game.widget_follow_chasing and game.avatar.move_time_remaining == 0.0, "Reaching the near radius must stop walking")
	for distance in [60.0, 65.0, 80.0, 99.0, 100.0, 75.0, 55.0, 90.0]:
		game.test_pointer = _pointer_for_target(resting + Vector2(distance, 0) * scale_value)
		game.update_desktop_companion(0.1)
		_check(game.widget_pet_position.is_equal_approx(resting) and not game.widget_follow_chasing and game.widget_follow_reaction_remaining == 0.0, "Small pointer movements inside 100 pixels must not restart a resting cat")
	game.test_pointer = _pointer_for_target(resting + Vector2(110, 0) * scale_value)
	game.update_desktop_companion(0.0)
	_check(game.widget_follow_chasing and game.widget_follow_reaction_remaining >= 0.3 and game.widget_follow_reaction_remaining <= 0.6, "Leaving the 100-pixel radius must start one fresh short reaction")
	game.widget_follow_reaction_remaining = 0.0
	game.update_desktop_companion(0.1)
	_check(game.widget_follow_chasing and is_equal_approx(game.widget_pet_position.distance_to(game.widget_follow_target), 95.0 * scale_value), "An active chase must continue through the 60–100 band")
	game.update_desktop_companion(1.0)
	_check(not game.widget_follow_chasing and is_equal_approx(game.widget_pet_position.distance_to(game.widget_follow_target), 60.0 * scale_value), "An active chase should stop only at the near radius")
	game.test_pointer = _pointer_for_target(game.widget_pet_position + Vector2(120, 0) * scale_value)
	game.update_desktop_companion(0.0)
	game.test_pointer = _pointer_for_target(game.widget_pet_position + Vector2(40, 0) * scale_value)
	game.update_desktop_companion(0.1)
	_check(not game.widget_follow_chasing and game.widget_follow_reaction_remaining == 0.0, "A pointer that returns nearby during the reaction should cancel the chase")


func _test_delta_independence() -> void:
	for step_size in [0.01, 0.05, 0.2]:
		_reset()
		game.set_widget_following(true)
		game.widget_follow_reaction_remaining = 0.4
		var initial := game.widget_pet_position
		for step in range(roundi(1.0 / step_size)):
			game.update_desktop_companion(step_size)
		_check(absf(game.widget_pet_position.distance_to(initial) - 90.0) < 0.01, "Reaction expiry must use the remaining delta so speed does not depend on frame rate")


func _test_return_speed(scale_value: float) -> void:
	_reset(scale_value)
	var follow_start := game.widget_pet_position
	game.set_widget_following(true)
	game.widget_follow_reaction_remaining = 0.0
	game.update_desktop_companion(0.1)
	var follow_step := game.widget_pet_position.distance_to(follow_start)
	for distance in [4.0, 300.0, 2600.0]:
		_reset(scale_value)
		var station_target := game.get_station_pet_anchor()
		game.set_widget_pet_position(station_target + Vector2(0.6, -0.8) * distance * scale_value, false)
		game.set_widget_following(true)
		game.set_widget_following(false)
		game.test_pointer = Vector2(-3000, -2000)
		_check(game.widget_returning_to_station, "Unfollow must start returning from both nearby and distant positions")
		var step_count := ceili(distance * scale_value / follow_step) + 2
		for step in range(step_count):
			var before := game.widget_pet_position
			var remaining := before.distance_to(station_target)
			game.update_desktop_companion(0.1)
			var expected_step := minf(follow_step, remaining)
			_check(absf(game.widget_pet_position.distance_to(before) - expected_step) < 0.001, "Every return step must match the follow speed, regardless of distance or display scale, without a final snap")
			if not game.widget_pet_at_station:
				_check(game.avatar.move_time_remaining > 0.0, "Returning cats must retain their normal walking animation")
		_check(game.widget_pet_at_station and not game.widget_returning_to_station and game.widget_pet_position == station_target, "A constant-speed return must finish exactly at the Station without overshooting")
		_check(game.avatar.move_time_remaining == 0.0 and game.avatar.mood == "idle", "Arrival must stop walking and restore the resting pose")


func _test_return_delta_independence() -> void:
	for step_size in [0.01, 0.05, 0.2, 1.0]:
		_reset()
		var station_target := game.get_station_pet_anchor()
		var initial := station_target + Vector2(1000, 0)
		game.set_widget_pet_position(initial, false)
		game.set_widget_following(false)
		for step in range(roundi(1.0 / step_size)):
			game.update_desktop_companion(step_size)
		_check(absf(game.widget_pet_position.distance_to(initial) - 150.0) < 0.01, "Returning must move 150 logical pixels per second at every frame rate")
		game.update_desktop_companion(20.0)
		_check(game.widget_pet_at_station and game.widget_pet_position == station_target, "A large return delta must stop exactly at the Station")


func _test_screen_boundaries() -> void:
	_reset()
	game.test_screens = [Rect2(-1280, 0, 1280, 720), Rect2(0, 0, 1280, 720)]
	game.set_widget_pet_position(Vector2(-50, 120), false)
	game.test_pointer = _pointer_for_target(Vector2(400, 120))
	game.set_widget_following(true)
	game.widget_follow_reaction_remaining = 0.0
	for step in range(8):
		game.update_desktop_companion(0.1)
	_check(game.widget_pet_position.x > 0.0, "Continuous following must cross a display seam without clamping intermediate steps")
	game.test_pointer = Vector2(5000, 5000)
	game.update_desktop_companion(20.0)
	var edge_rest := game.widget_pet_position
	for step in range(10):
		game.update_desktop_companion(0.1)
	_check(game.widget_pet_position.is_equal_approx(edge_rest) and not game.widget_follow_chasing, "An unreachable off-screen pointer must settle at the clamped target, not restart forever")
	game.test_screens = [Rect2(-4000, -2200, 10000, 5000)]


func _test_interactions_and_drag() -> void:
	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.pressed = true
	double_click.double_click = true
	for pet_id in ["maple", "mochi", "biscuit"]:
		_reset(1.0, pet_id)
		game.set_widget_following(true)
		game.widget_follow_reaction_remaining = 0.0
		game.update_desktop_companion(0.1)
		game._on_pet_drag_input(double_click)
		var paused := game.widget_pet_position
		game.test_pointer = _pointer_for_target(Vector2(1300, 400))
		game.update_desktop_companion(0.5)
		_check(game.avatar.is_playing_interaction() and game.widget_pet_position == paused and not game.widget_pet_dragging, "Double-click must pause following without becoming a drag")
		_check(game.widget_follow_target.is_equal_approx(Vector2(1300, 400)), "The target should still track the cursor during an interaction")
		game.avatar._process(20.0)
		game.update_desktop_companion(0.1)
		_check(game.widget_following and game.widget_pet_position.distance_to(paused) > 0.0 and game.widget_follow_reaction_remaining == 0.0, "Following should resume toward the latest target after the interaction")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	_check(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT), "The simulated drag must hold the actual input button state")
	game._on_pet_drag_input(press)
	var drag_start := game.widget_pet_position
	game.test_pointer += Vector2(100, 30)
	game.update_desktop_companion(0.5)
	_check(game.widget_pet_dragging and game.widget_pet_position == drag_start, "Follow Me must never fight an active manual drag")
	game._on_pet_drag_input(InputEventMouseMotion.new())
	_check(game.widget_pet_position.is_equal_approx(drag_start + Vector2(100, 30)), "Manual dragging must still control the cat position")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	game._on_pet_drag_input(release)
	game.test_pointer = _pointer_for_target(game.widget_pet_position + Vector2(600, 0))
	var released := game.widget_pet_position
	game.update_desktop_companion(0.1)
	_check(not game.widget_pet_dragging and game.widget_following and game.widget_pet_position.distance_to(released) > 0.0, "Releasing a drag must allow continuous following again")


func _test_unfollow() -> void:
	game.set_widget_following(false)
	_check(not game.widget_follow_has_target and not game.widget_follow_chasing and game.widget_follow_reaction_remaining == 0.0 and game.follow_button.text == "FOLLOW ME", "Unfollow must clear all chase state and reset its button")
	_check(game.widget_returning_to_station or game.widget_pet_at_station, "Unfollow must keep the existing return-to-station behavior")
	game.test_pointer = Vector2(-3000, -2000)
	for step in range(60):
		game.update_desktop_companion(0.1)
	_check(game.widget_pet_at_station and game.widget_pet_position.distance_to(game.get_station_pet_anchor()) < 2.0, "The unfollowed cat must arrive home normally")
	game.test_pointer = _pointer_for_target(game.widget_pet_position + Vector2(500, 0))
	game.set_widget_following(true)
	_check(game.widget_follow_chasing and game.widget_follow_reaction_remaining >= 0.3 and game.widget_follow_reaction_remaining <= 0.6, "Re-enabling Follow Me must start a fresh chase without stale state")
