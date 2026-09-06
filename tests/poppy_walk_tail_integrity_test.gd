extends SceneTree

const CHECKS := [
	{
		"path": "res://assets/pets/blue_british/walk_left/frame_02.png",
		"region": Rect2i(0, 110, 50, 65)
	},
	{
		"path": "res://assets/pets/blue_british/walk_left/frame_10.png",
		"region": Rect2i(0, 105, 60, 70)
	},
	{
		"path": "res://assets/pets/blue_british/walk_right/frame_02.png",
		"region": Rect2i(654, 110, 50, 65)
	},
	{
		"path": "res://assets/pets/blue_british/walk_right/frame_10.png",
		"region": Rect2i(644, 105, 60, 70)
	}
]


func _initialize() -> void:
	for check in CHECKS:
		var path := str(check.path)
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image.is_empty():
			push_error("Could not load Poppy walk frame: %s" % path)
			quit(1)
			return
		var region: Rect2i = check.region
		for y in range(region.position.y, region.end.y):
			for x in range(region.position.x, region.end.x):
				if image.get_pixel(x, y).a > 0.03:
					push_error("Poppy tail fragment remains ahead of her head in %s" % path)
					quit(1)
					return
	print("POPPY WALK TAIL TEST PASS: complete tails and clear head-leading regions")
	quit(0)
