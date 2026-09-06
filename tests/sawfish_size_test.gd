extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")


func _init() -> void:
	var sawfish: Dictionary = FishCatalogScript.definition("sawfish")
	assert(
		sawfish.get("swim_size") == Vector2(290, 104),
		"Sawfish should render at twice its former gameplay size"
	)
	print("SAWFISH SIZE TEST PASS: swim_size=Vector2(290, 104)")
	quit()
