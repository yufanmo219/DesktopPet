extends SceneTree

const FishingGameScene = preload("res://src/fishing/fishing_game.tscn")

const POPUP_PATHS: Array[String] = [
	"res://src/fishing/ui/popups/goal_popup.tscn",
	"res://src/fishing/ui/popups/catch_popup.tscn",
	"res://src/fishing/ui/popups/home_confirmation_popup.tscn",
	"res://src/fishing/ui/popups/new_fish_popup.tscn",
	"res://src/fishing/ui/popups/level_complete_popup.tscn",
	"res://src/fishing/ui/popups/round_failure_popup.tscn",
	"res://src/fishing/ui/popups/no_hearts_popup.tscn",
	"res://src/fishing/ui/popups/catch_failure_popup.tscn",
	"res://src/fishing/ui/popups/pause_overlay.tscn"
]

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var game = FishingGameScene.instantiate()
	var view := game.get_node_or_null("FishingView")
	var hud := game.get_node_or_null("FishingView/FishingHUD")
	_check(view != null and hud != null, "FishingGame should compose its view and HUD scenes")
	_check(
		game.get_node_or_null("FishingView/FishingSpawnTimer") is Timer
		and hud.get_node_or_null("FishingHomeButton") is Button
		and hud.get_node_or_null("FishingCatchButton") is Button,
		"The scene should own the timer and primary controls before runtime binding"
	)
	game.free()

	for popup_path in POPUP_PATHS:
		var packed_scene = load(popup_path)
		_check(packed_scene is PackedScene, "Popup scene should load: %s" % popup_path)
		if packed_scene is PackedScene:
			var popup = packed_scene.instantiate()
			_check(
				popup is Control and popup.get_child_count() > 0,
				"Popup scene should provide a complete editable node tree: %s" % popup_path
			)
			popup.free()

	if failures.is_empty():
		print("FISHING SCENE STRUCTURE TEST PASS")
		quit(0)
	else:
		print("FISHING SCENE STRUCTURE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
