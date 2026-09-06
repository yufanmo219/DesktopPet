extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")


func _init() -> void:
	var hammerhead_shark: Dictionary = FishCatalogScript.definition("hammerhead_shark")
	assert(
		hammerhead_shark.get("swim_size") == Vector2(240, 136),
		"Hammerhead Shark should render at twice its former gameplay size"
	)
	print("HAMMERHEAD SHARK SIZE TEST PASS: swim_size=Vector2(240, 136)")
	quit()
