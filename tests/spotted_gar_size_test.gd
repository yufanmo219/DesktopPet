extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")


func _init() -> void:
	var spotted_gar: Dictionary = FishCatalogScript.definition("spotted_gar")
	assert(
		spotted_gar.get("swim_size") == Vector2(528, 208),
		"Spotted Gar should include both requested two-times size increases"
	)
	print("SPOTTED GAR SIZE TEST PASS: swim_size=Vector2(528, 208)")
	quit()
