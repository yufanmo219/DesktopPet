extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")


func _init() -> void:
	var red_arowana: Dictionary = FishCatalogScript.definition("red_arowana")
	assert(
		red_arowana.get("swim_size") == Vector2(292.5, 126),
		"Red Arowana should render at 75% of its previous gameplay size"
	)
	print("RED AROWANA SIZE TEST PASS: swim_size=Vector2(292.5, 126)")
	quit()
