extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")


func _init() -> void:
	var giant_arapaima: Dictionary = FishCatalogScript.definition("giant_arapaima")
	var ancient_sturgeon: Dictionary = FishCatalogScript.definition("ancient_sturgeon")
	assert(
		giant_arapaima.get("swim_size") == Vector2(270, 130),
		"Giant Arapaima should render at twice its former gameplay size"
	)
	assert(
		ancient_sturgeon.get("swim_size") == Vector2(264, 116),
		"Ancient Sturgeon should render at twice its former gameplay size"
	)
	print(
		"GIANT FISH SIZE TEST PASS: Giant Arapaima=Vector2(270, 130), "
		+ "Ancient Sturgeon=Vector2(264, 116)"
	)
	quit()
