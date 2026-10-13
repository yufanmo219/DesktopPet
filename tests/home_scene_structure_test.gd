extends SceneTree

const HomeScreenScene = preload("res://src/home/home_screen.tscn")
const HomeDayTexture: Texture2D = preload(
	"res://assets/ui/home/home_day_layout_v3.png"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func run_tests() -> void:
	var home: HomeScreen = HomeScreenScene.instantiate()
	home.configure(
		{"id": "default_orange_cat", "name": "Maple", "type": "Cat"},
		137,
		HomeDayTexture
	)
	root.add_child(home)
	await process_frame
	home.set_process(false)

	_check(home.background.texture == HomeDayTexture, "Home scene should bind its configured background")
	_check(home.avatar.pet_id == "default_orange_cat", "Home scene should configure its PetAvatar")
	_check(home.xp_value_label.text == "137", "Home scene should render current XP")
	_check(home.pet_heading_label.text == "MAPLE IS HERE!", "Home scene should render the pet name")
	_check(
		home.get_node_or_null("HomeXPRow") != null
		and home.get_node_or_null("HomeActionsLayer") != null
		and home.get_node_or_null("HomePetInteractionSurface") != null,
		"Home layout should be declared by stable scene nodes"
	)
	_check(
		home.find_children("*", "Button", true, false).size() == 4,
		"Home scene should own exactly four navigation actions"
	)

	var navigation_event := {"aquarium_requested": false}
	home.aquarium_requested.connect(
		func(): navigation_event.aquarium_requested = true
	)
	home.aquarium_button.pressed.emit()
	_check(
		bool(navigation_event.aquarium_requested),
		"Home navigation should leave through typed signals"
	)

	home.avatar.set_mood("idle")
	home.update_pointer_state(Vector2(900, 360), true, 10.1)
	_check(home.avatar.mood == "sleep", "Home scene should own its sleep policy")
	home.update_pointer_state(Vector2(320, 360), true)
	_check(home.avatar.mood == "idle", "Home scene should wake the pet in its wake area")

	home.queue_free()
	await process_frame
	if failures.is_empty():
		print("HOME SCENE STRUCTURE TEST PASS: composition, data binding, signals, and sleep policy")
		quit(0)
	else:
		print("HOME SCENE STRUCTURE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
