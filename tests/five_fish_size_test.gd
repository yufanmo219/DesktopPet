extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")

const EXPECTED_SIZES := {
	"blue_small": Vector2(188, 122),
	"neon_tetra": Vector2(200, 110),
	"zebra_danio": Vector2(208, 108),
	"silver_flyingfish": Vector2(175, 85.4),
	"spotted_gar": Vector2(528, 208),
}


func _init() -> void:
	for fish_id: String in EXPECTED_SIZES:
		var definition: Dictionary = FishCatalogScript.definition(fish_id)
		assert(
			definition.get("swim_size") == EXPECTED_SIZES[fish_id],
			"%s should render at the requested doubled gameplay size" % fish_id
		)
	print("FIVE FISH SIZE TEST PASS")
	quit()
