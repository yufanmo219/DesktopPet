extends SceneTree

const AquariumScene = preload("res://src/aquarium/aquarium_screen.tscn")
const AquariumLoadingScene = preload(
	"res://src/aquarium/aquarium_loading_screen.tscn"
)
const AquariumLoadingScript = preload("res://src/aquarium_loading_screen.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func run_tests() -> void:
	var aquarium: AquariumScreen = AquariumScene.instantiate()
	aquarium.configure({
		"unlocked_fish_ids": [],
		"aquarium_fish_ids": []
	})
	root.add_child(aquarium)
	await process_frame

	_check(
		aquarium.get_node_or_null("AquariumView/AquariumBackground") != null
		and aquarium.fish_layer == aquarium.get_node_or_null("AquariumView/AquariumFishLayer"),
		"Aquarium scene should compose stable background and fish-layer nodes"
	)
	_check(
		aquarium.fish_count_label.text == "FISH CAP 0 / 10"
		and aquarium.home_button.text == "← HOME"
		and aquarium.fish_book_button.text == "FISH BOOK",
		"Aquarium scene should bind its capacity and navigation controls"
	)
	var navigation := {"home": false, "fish_book": false}
	aquarium.back_requested.connect(func(): navigation.home = true)
	aquarium.fish_book_requested.connect(func(): navigation.fish_book = true)
	aquarium.home_button.pressed.emit()
	aquarium.fish_book_button.pressed.emit()
	_check(
		bool(navigation.home) and bool(navigation.fish_book),
		"Aquarium navigation should leave through typed feature signals"
	)

	var loading: AquariumLoadingScreen = AquariumLoadingScene.instantiate()
	root.add_child(loading)
	await process_frame
	var initial_rotation := loading.hourglass.rotation
	loading._process(loading.ROTATION_SECONDS / 4.0)
	_check(
		loading.background.color == loading.BACKGROUND_COLOR
		and loading.hourglass.size == loading.HOURGLASS_SIZE
		and loading.message_label.text == loading.LOADING_MESSAGE,
		"Loading scene should expose the approved static loading view"
	)
	_check(
		not is_equal_approx(loading.hourglass.rotation, initial_rotation),
		"Loading screen should retain its runtime hourglass animation"
	)

	var compatibility_loading: AquariumLoadingScreen = AquariumLoadingScript.new()
	root.add_child(compatibility_loading)
	await process_frame
	_check(
		compatibility_loading.get_node_or_null(
			"AquariumLoadingView/AquariumLoadingMessage"
		) != null,
		"Direct script construction should reuse the production loading view"
	)

	aquarium.queue_free()
	loading.queue_free()
	compatibility_loading.queue_free()
	await process_frame
	if failures.is_empty():
		print("AQUARIUM SCENE STRUCTURE TEST PASS: composed views, signals, and loading animation")
		quit(0)
	else:
		print("AQUARIUM SCENE STRUCTURE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
