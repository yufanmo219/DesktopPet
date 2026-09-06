extends SceneTree

const FishingGameScript = preload("res://src/fishing_game.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _caught_fishes(species_count: int, increasing_counts := true) -> Array[Dictionary]:
	var fishes: Array[Dictionary] = []
	for index in range(species_count):
		for copy_index in range(index + 1 if increasing_counts else 1):
			fishes.append(FishCatalogScript.FISH_TYPES[index].duplicate(true))
	return fishes


func _new_game() -> FishingGame:
	var unlocked_ids: Array[String] = []
	for fish in FishCatalogScript.FISH_TYPES:
		unlocked_ids.append(str(fish.id))
	var game := FishingGameScript.new()
	game.configure({}, {"unlocked_fish_ids": unlocked_ids})
	root.add_child(game)
	game.set_process(false)
	game._start_round_from_goal_popup()
	game.spawn_timer.stop()
	return game


func _check_page_layout(game: FishingGame, species_count: int) -> void:
	var use_two_columns := species_count > 3
	var occupied_rects: Array[Rect2] = []
	for index in range(species_count):
		var view := game.catch_popup_fish_views[index]
		var label := game.catch_popup_count_labels[index]
		var row_index := floori(float(index) / 2.0) if use_two_columns else index
		var slot_origin := game.CATCH_POPUP_FISH_POSITIONS[row_index]
		var slot_size := game.CATCH_POPUP_FISH_SIZE
		var count_position := game.CATCH_POPUP_COUNT_POSITIONS[row_index]
		if use_two_columns:
			var offset := Vector2(index % 2, row_index) * game.CATCH_POPUP_TWO_COLUMN_STEP
			slot_origin = game.CATCH_POPUP_TWO_COLUMN_FISH_ORIGIN + offset
			slot_size = game.CATCH_POPUP_TWO_COLUMN_FISH_SIZE
			count_position = game.CATCH_POPUP_TWO_COLUMN_COUNT_ORIGIN + offset
		_check(
			view.position.is_equal_approx(slot_origin + (slot_size - view.size) * 0.5)
			and label.position == count_position,
			"Catch entries should use the correct single-column or two-column cell positions"
		)
		for rect in [view.get_rect(), label.get_rect()]:
			_check(
				rect.position.x >= 20 and rect.end.x <= game.CATCH_POPUP_PANEL_SIZE.x - 20
				and rect.position.y >= 110 and rect.end.y < game.CATCH_POPUP_FOOTER_POSITION.y,
				"Catch art and counts must remain inside the content area"
			)
			if use_two_columns:
				for previous in occupied_rects:
					_check(not rect.intersects(previous), "Two-column catch art and count boxes must not overlap")
			occupied_rects.append(rect)


func _run_tests() -> void:
	root.size = Vector2i(1280, 720)
	var game := _new_game()
	await process_frame
	game.round_goals = [{"fish_id": "green", "count": 999}]
	var every_species := _caught_fishes(FishCatalogScript.FISH_TYPES.size(), false)
	_check(
		game._aggregate_caught_fishes(every_species).size() == FishCatalogScript.FISH_TYPES.size(),
		"Aggregating catches must retain every species, not truncate at three or six"
	)
	for species_count in [1, 2, 3, 4, 5, 6, 7, 9, 10, 12, 13]:
		game._reset_round_goal_progress()
		game.fish_caught = 0
		var catches := _caught_fishes(species_count)
		game._finish_attempt(catches)
		var shown_ids: Array[String] = []
		var shown_total := 0
		var page_index := 0
		while game.result_overlay != null:
			await process_frame
			var visible_count := mini(6, species_count - page_index * 6)
			_check(
				game.catch_popup_fish_views.size() == visible_count
				and game.catch_popup_count_labels.size() == visible_count,
				"Every page should show up to six complete fish/count pairs"
			)
			_check_page_layout(game, visible_count)
			for index in range(visible_count):
				var global_index := page_index * 6 + index
				var fish_id := str(game.catch_popup_fish_views[index].get_meta("fish_id"))
				shown_ids.append(fish_id)
				_check(
					fish_id == str(FishCatalogScript.FISH_TYPES[global_index].id)
					and game.catch_popup_count_labels[index].text == "X %d" % (global_index + 1),
					"Every species should retain its correct aggregated count and first-catch order"
				)
				shown_total += global_index + 1
			var footer: Label = game.result_overlay.find_child("FishingCatchPopupFooter", true, false)
			var has_more: bool = shown_ids.size() < species_count
			_check(
				footer.text == ("CLICK ANYWHERE TO SEE MORE" if has_more else "CLICK ANYWHERE TO CONTINUE"),
				"The footer should distinguish another results page from returning to the game"
			)
			var time_before := game.round_time_remaining
			game._process(5.0)
			_check(is_equal_approx(game.round_time_remaining, time_before), "All results pages should pause the countdown")
			game.result_overlay.emit_signal("pressed")
			if has_more:
				_check(game.state == game.GameState.SHOWING_RESULT, "Turning a results page must not resume gameplay")
			page_index += 1
		game.spawn_timer.stop()
		_check(
			shown_ids.size() == species_count and shown_total == catches.size()
			and game.fish_caught == catches.size() and game.hearts == 5,
			"Paging should display every caught fish without recounting catches or charging hearts"
		)
	game.queue_free()
	await process_frame

	# Newly discovered fish still show their unlock popups first, and finishing
	# the level waits until the player has seen all catch-summary pages.
	var completing := _new_game()
	await process_frame
	completing.round_goals = [{"fish_id": "green", "count": 1}]
	completing._reset_round_goal_progress()
	completing.unlocked_fish_ids = ["green"]
	completing._finish_attempt(_caught_fishes(7, false))
	var unlock_pages := 0
	while completing.result_overlay.name == "FishingNewFishPopupOverlay":
		unlock_pages += 1
		completing.result_overlay.emit_signal("pressed")
	_check(unlock_pages == 6, "New fish unlock popups should still appear before the multi-page summary")
	_check(completing.round_completion_pending, "The final goal should remain pending throughout the summary")
	completing.result_overlay.emit_signal("pressed")
	_check(
		completing.result_overlay.name == "FishingCatchPopupOverlay"
		and completing.catch_popup_fish_views.size() == 1
		and not completing.round_completion_xp_awarded,
		"The seventh species must be shown before awarding completion XP"
	)
	completing.result_overlay.emit_signal("pressed")
	_check(
		completing.result_overlay.name == "FishingLevelCompletePopupOverlay"
		and completing.round_completion_xp_awarded
		and int(completing.shared_stats.experience) == completing.round_xp_reward,
		"The final results page should lead into the normal one-time completion reward"
	)
	completing.queue_free()
	await process_frame
	if failures.is_empty():
		print("FISHING CATCH POPUP TEST PASS")
		quit(0)
	else:
		print("FISHING CATCH POPUP TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
