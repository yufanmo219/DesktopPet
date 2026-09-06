extends SceneTree

const FishingGameScript = preload("res://src/fishing_game.gd")

var failures: Array[String] = []
var home_requests := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _new_game(stats: Dictionary = {}) -> FishingGame:
	var game := FishingGameScript.new()
	game.configure({}, stats)
	game.back_requested.connect(func(): home_requests += 1)
	root.add_child(game)
	return game


func _press(game: FishingGame, button_name: String) -> void:
	var button: Button = game.find_child(button_name, true, false)
	_check(button != null, "Missing button: %s" % button_name)
	if button != null:
		button.pressed.emit()


func _run_tests() -> void:
	root.size = Vector2i(1280, 720)
	var before_start := _new_game()
	await process_frame
	_press(before_start, "FishingHomeButton")
	_check(
		home_requests == 1 and before_start.hearts == 5
		and before_start.home_return_overlay == null,
		"Leaving before the level starts should be free and should not show a warning"
	)
	before_start.queue_free()
	await process_frame

	home_requests = 0
	var game := _new_game({
		"fishing_level": 1, "fishing_retry_level": 1, "fishing_retry_count": 2
	})
	await process_frame
	game._start_round_from_goal_popup()
	_press(game, "FishingHomeButton")
	var waiting_time := game.round_time_remaining
	game._process(2.0)
	_check(
		game.state == game.GameState.PAUSED and game.spawn_timer.paused
		and is_equal_approx(game.round_time_remaining, waiting_time),
		"The confirmation should freeze the countdown and pending fish-spawn timer"
	)
	_press(game, "FishingHomeReturnCancelButton")
	_check(
		game.state == game.GameState.WAITING_FOR_FISH and not game.spawn_timer.paused
		and not game.spawn_timer.is_stopped() and game.hearts == 5
		and game.current_level_retry_count == 2 and home_requests == 0,
		"Cancel should resume the pending spawn without charging a heart or changing retry assistance"
	)

	game._pause_game()
	_press(game, "FishingHomeButton")
	game._resume_from_pause()
	_check(game.state == game.GameState.PAUSED, "The confirmation must block other resume requests")
	_press(game, "FishingHomeReturnCancelButton")
	_check(
		game.state == game.GameState.PAUSED and game.pause_overlay != null
		and game.spawn_timer.paused,
		"Cancelling from an already paused round should preserve the existing pause"
	)
	game._resume_from_pause()
	game._spawn_fish()
	game.spawn_timer.stop()
	await process_frame
	var fish_view: TextureRect = game.active_fish[0].view
	_press(game, "FishingHomeButton")
	var first_overlay := game.home_return_overlay
	var warning: Label = first_overlay.find_child("FishingHomeReturnWarning", true, false)
	_check(
		warning != null and warning.text.contains("1 HEART")
		and not first_overlay is Button and first_overlay.mouse_filter == Control.MOUSE_FILTER_STOP,
		"The modal should clearly warn of one lost heart and block click-through"
	)
	_press(game, "FishingHomeButton")
	_check(
		game.home_return_overlay == first_overlay and game.hearts == 5,
		"Repeated Home clicks should not stack confirmations or deduct hearts"
	)
	var fish_position := fish_view.position
	var countdown := game.round_time_remaining
	await create_timer(0.15).timeout
	game.request_catch()
	_check(
		fish_view.position.is_equal_approx(fish_position)
		and is_equal_approx(game.round_time_remaining, countdown)
		and game.state == game.GameState.PAUSED,
		"Fish movement and Catch must remain frozen while the player decides"
	)
	_press(game, "FishingHomeReturnCancelButton")
	_check(
		game.home_return_overlay == null and game.state == game.GameState.READY_TO_CATCH
		and game.hearts == 5 and game.round_started,
		"Keep Playing should return to the same active round without losing a heart"
	)
	await create_timer(0.05).timeout
	_check(not fish_view.position.is_equal_approx(fish_position), "Cancelled confirmation should resume swimming")

	# Exercise the asynchronous net animation as well as ordinary swimming.
	fish_view.position = game.NET_CATCH_ZONE.get_center() - fish_view.size * 0.5
	game.request_catch()
	_press(game, "FishingHomeButton")
	var lift_frame := game.animation_frame_index
	await create_timer(0.18).timeout
	_check(
		game.animation_frame_index == lift_frame and game.state == game.GameState.PAUSED,
		"Opening the warning mid-lift should freeze the net animation"
	)
	_press(game, "FishingHomeReturnCancelButton")
	_check(game.state == game.GameState.LIFTING_NET, "Cancelling mid-lift should restore the lift state")
	await create_timer(0.16).timeout
	_check(game.animation_frame_index > lift_frame, "Cancelling mid-lift should resume its animation")
	_press(game, "FishingHomeButton")
	_press(game, "FishingHomeReturnConfirmButton")
	_check(
		game.hearts == 4 and int(game.shared_stats.hearts) == 4
		and game.next_heart_restore_unix > 0 and home_requests == 1
		and not game.round_started and game.state == game.GameState.ROUND_ENDED
		and game.active_fish.is_empty() and game.spawn_timer.is_stopped()
		and game.current_level_retry_count == 2,
		"Confirmed exit should deduct and publish exactly one heart, stop the round, and preserve retry assistance"
	)
	game._confirm_return_home()
	game._request_return_home()
	await create_timer(1.1).timeout
	_check(
		game.hearts == 4 and home_requests == 1 and game.result_overlay == null,
		"Duplicate confirmation and the abandoned lift must not charge again or open a result popup"
	)
	game.queue_free()
	await process_frame

	for succeeded in [false, true]:
		home_requests = 0
		var ended := _new_game()
		await process_frame
		ended._start_round_from_goal_popup()
		if succeeded:
			for goal in ended.round_goals:
				ended.round_goal_counts[str(goal.fish_id)] = int(goal.count)
		ended._end_round()
		var hearts_after_result := ended.hearts
		_press(ended, "FishingLevelCompleteHomeButton" if succeeded else "FishingRoundFailureHomeButton")
		_check(
			home_requests == 1 and ended.hearts == hearts_after_result
			and ended.home_return_overlay == null,
			"Leaving a settled success/failure result should never deduct another heart"
		)
		ended.queue_free()
		await process_frame

	var last_heart := _new_game({"hearts": 1})
	await process_frame
	last_heart._start_round_from_goal_popup()
	_press(last_heart, "FishingHomeButton")
	_press(last_heart, "FishingHomeReturnConfirmButton")
	var exhausted_stats := last_heart.shared_stats.duplicate(true)
	_check(last_heart.hearts == 0, "Returning home with one heart should consume that last heart")
	last_heart.queue_free()
	await process_frame
	var exhausted := _new_game(exhausted_stats)
	await process_frame
	_check(
		exhausted.hearts == 0 and exhausted.no_hearts_popup_pending,
		"Re-entering after spending the last heart should show the heart-restoration screen"
	)
	exhausted.queue_free()
	await process_frame

	# Check the real Home signal wiring and progress propagation without touching
	# the player's save file.
	var main = load("res://main.tscn").instantiate()
	main.save_enabled = false
	root.add_child(main)
	await process_frame
	main.show_fishing()
	await process_frame
	main.fishing_game._start_round_from_goal_popup()
	_press(main.fishing_game, "FishingHomeButton")
	_press(main.fishing_game, "FishingHomeReturnConfirmButton")
	_check(
		main.current_screen == "home" and int(main.get_progress_stats().hearts) == 4,
		"Confirming Home in the real game should return home with the one-heart cost applied"
	)
	main.show_fishing()
	await process_frame
	_check(main.fishing_game.hearts == 4, "Re-entering fishing should retain the deducted heart")
	main.queue_free()
	await process_frame

	if failures.is_empty():
		print("FISHING HOME RETURN TEST PASS")
		quit(0)
	else:
		print("FISHING HOME RETURN TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
