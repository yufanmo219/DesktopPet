extends SceneTree

const MainScene = preload("res://main.tscn")

var failures: Array[String] = []
var music_manager


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _check_silent(context: String) -> void:
	_check(
		not music_manager.music_player.playing
		and music_manager.current_track_key == &""
		and music_manager.fade_tween == null,
		context + ": Desktop Companion must stop background playback and cancel its fade"
	)


func _press_text(parent: Node, text: String) -> void:
	var buttons := parent.find_children("*", "Button", true, false)
	for button in buttons:
		if button.text == text:
			button.pressed.emit()
			return
	_check(false, "Missing button: " + text)


func _run_tests() -> void:
	music_manager = root.get_node_or_null("MusicManager")
	if music_manager == null:
		var music_scene: PackedScene = load("res://src/music_manager.tscn")
		music_manager = music_scene.instantiate()
		root.add_child(music_manager)
	music_manager.stop_music(0.0)
	var game = MainScene.instantiate()
	game.save_enabled = false
	root.add_child(game)
	await process_frame
	_check(music_manager.is_home_music_active(), "Normal HOME startup should still play music")

	# The real button used to overwrite current_screen before clear_screen could
	# recognize HOME and stop its music. Test both the click and the later fade.
	_press_text(game.content, "KEEP AS DESKTOP COMPANION")
	_check(game.desktop_mode and game.current_screen == "widget", "Keep as Desktop Companion should enter widget mode")
	_check_silent("HOME button entry")
	await create_timer(1.6).timeout
	_check_silent("After HOME's old fade-in would have completed")
	_press_text(game.desktop_station, "GO HOME")
	_check(music_manager.is_home_music_active(), "GO HOME should resume HOME music")

	# Every track and both active fades must be stopped, not just HOME's track.
	for screen in ["home", "fishing", "store", "fish_book", "aquarium"]:
		await game.call("show_" + screen)
		_check(music_manager.music_player.playing, screen + " should start its normal background track")
		game.enter_desktop_mode()
		_check_silent(screen + " entry during fade-in")
		game.enter_desktop_mode()
		await process_frame
		_check_silent(screen + " repeated entry")
		game.restore_from_widget()
		_check(music_manager.is_home_music_active(), screen + " return should restore HOME music")

	game.show_pet_pool()
	_check(
		music_manager.current_track_key == &"" and music_manager.music_player.playing,
		"Leaving HOME for the pet pool should exercise an in-progress music fade-out"
	)
	game.enter_desktop_mode()
	_check_silent("Entry during a previous screen's fade-out")
	game.restore_from_widget()
	await create_timer(1.0).timeout
	_check(music_manager.is_home_music_active(), "An old fade-out must not stop music after returning HOME")
	game.enter_desktop_mode()
	_check_silent("Repeated HOME-to-desktop cycle")
	game.queue_free()
	await process_frame
	music_manager.stop_music(0.0)

	# Simulate the fresh desktop-only process without loading or writing a save.
	var direct_game = MainScene.instantiate()
	direct_game.save_enabled = false
	direct_game.launch_directly_to_widget = true
	root.add_child(direct_game)
	_check_silent("Direct desktop startup before deferred entry")
	await process_frame
	await process_frame
	_check(direct_game.desktop_mode and direct_game.current_screen == "widget", "Direct startup should enter Desktop Companion")
	_check_silent("Direct desktop startup")
	direct_game.restore_from_widget()
	_check(music_manager.is_home_music_active(), "Desktop-only launch should allow music after GO HOME")
	direct_game.enter_desktop_mode()
	_check_silent("Desktop-only launch after a round trip through HOME")
	direct_game.queue_free()
	await process_frame
	music_manager.stop_music(0.0)

	if failures.is_empty():
		print("DESKTOP MUSIC TEST PASS: HOME button, all background tracks, fade cancellation, direct launch, and GO HOME")
		quit(0)
	else:
		print("DESKTOP MUSIC TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
