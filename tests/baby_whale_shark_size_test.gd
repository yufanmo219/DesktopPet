extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")


func _init() -> void:
	var baby_whale_shark: Dictionary = FishCatalogScript.definition("baby_whale_shark")
	assert(
		baby_whale_shark.get("swim_size") == Vector2(177, 99),
		"Baby Whale Shark should render at 1.5 times its former gameplay size"
	)
	print("BABY WHALE SHARK SIZE TEST PASS: swim_size=Vector2(177, 99)")
	quit()
