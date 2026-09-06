extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")

const CLEAN_LEG_GAP_POINTS := {
	"res://assets/pets/golden_munchkin/move_left/frame_01.png": [Vector2i(370, 430)],
	"res://assets/pets/golden_munchkin/move_left/frame_04.png": [Vector2i(365, 430)],
	"res://assets/pets/golden_munchkin/move_left/frame_05.png": [Vector2i(370, 430)],
	"res://assets/pets/golden_munchkin/move_left/frame_06.png": [Vector2i(312, 430), Vector2i(370, 430)],
	"res://assets/pets/golden_munchkin/move_left/frame_07.png": [Vector2i(365, 430)],
	"res://assets/pets/golden_munchkin/move_left/frame_08.png": [Vector2i(370, 430)],
	"res://assets/pets/golden_munchkin/move_right/frame_01.png": [Vector2i(333, 430), Vector2i(410, 440)],
	"res://assets/pets/golden_munchkin/move_right/frame_02.png": [Vector2i(350, 430)],
	"res://assets/pets/golden_munchkin/move_right/frame_03.png": [Vector2i(335, 430), Vector2i(385, 430)],
	"res://assets/pets/golden_munchkin/move_right/frame_04.png": [Vector2i(280, 430), Vector2i(370, 430)],
	"res://assets/pets/golden_munchkin/move_right/frame_05.png": [Vector2i(360, 430), Vector2i(410, 430)],
	"res://assets/pets/golden_munchkin/move_right/frame_06.png": [Vector2i(290, 430), Vector2i(350, 430)],
	"res://assets/pets/golden_munchkin/move_right/frame_07.png": [Vector2i(325, 430), Vector2i(378, 430)],
	"res://assets/pets/golden_munchkin/move_right/frame_08.png": [Vector2i(320, 430), Vector2i(367, 430)],
}


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _initialize() -> void:
	var directions := {
		"left": AvatarScript.GOLDEN_MUNCHKIN_MOVE_LEFT_FRAMES,
		"right": AvatarScript.GOLDEN_MUNCHKIN_MOVE_RIGHT_FRAMES,
	}
	for direction: String in directions:
		var frames: Array = directions[direction]
		if frames.size() != 8:
			_fail("Honey's %s walk must retain all eight frames" % direction)
			return
		for index in range(frames.size()):
			var image := Image.load_from_file(
				ProjectSettings.globalize_path(frames[index].resource_path)
			)
			if image.is_empty():
				_fail("Could not load Honey %s frame %02d" % [direction, index + 1])
				return
			if image.get_size() != Vector2i(704, 512):
				_fail("Honey %s frame %02d must retain its 704x512 canvas" % [direction, index + 1])
				return

	for path: String in CLEAN_LEG_GAP_POINTS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		for point: Vector2i in CLEAN_LEG_GAP_POINTS[path]:
			if image.get_pixelv(point).a > 0.02:
				_fail("Honey still has a backdrop pixel at %s in %s" % [point, path])
				return

	print("GOLDEN MUNCHKIN WALK CLEANUP TEST PASS: all sixteen frames keep their fixed canvas and every known leg-gap remnant is transparent")
	quit(0)
