extends SceneTree

const FRAME_PATHS := [
	"res://assets/pets/siamese/walk_left/frame_01.png",
	"res://assets/pets/siamese/walk_left/frame_02.png",
	"res://assets/pets/siamese/walk_left/frame_03.png",
	"res://assets/pets/siamese/walk_left/frame_04.png",
	"res://assets/pets/siamese/walk_right/frame_01.png",
	"res://assets/pets/siamese/walk_right/frame_02.png",
	"res://assets/pets/siamese/walk_right/frame_03.png",
	"res://assets/pets/siamese/walk_right/frame_04.png",
]

const REPAIRED_SEAMS := {
	"res://assets/pets/siamese/walk_left/frame_01.png": [Vector2i(206, 220), Vector2i(206, 300)],
	"res://assets/pets/siamese/walk_left/frame_03.png": [Vector2i(110, 410)],
	"res://assets/pets/siamese/walk_left/frame_04.png": [Vector2i(250, 300)],
	"res://assets/pets/siamese/walk_right/frame_01.png": [Vector2i(188, 300), Vector2i(223, 300), Vector2i(510, 300)],
	"res://assets/pets/siamese/walk_right/frame_02.png": [Vector2i(430, 300)],
	"res://assets/pets/siamese/walk_right/frame_03.png": [Vector2i(221, 300), Vector2i(433, 290)],
	"res://assets/pets/siamese/walk_right/frame_04.png": [Vector2i(292, 300), Vector2i(435, 290), Vector2i(560, 280)],
}


func _initialize() -> void:
	for path in FRAME_PATHS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image.is_empty():
			push_error("Could not load Pearl walk frame: %s" % path)
			quit(1)
			return
		if image.get_size() != Vector2i(704, 512):
			push_error("Pearl walk frame must retain its fixed 704x512 canvas: %s" % path)
			quit(1)
			return

	for path in REPAIRED_SEAMS:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		for point: Vector2i in REPAIRED_SEAMS[path]:
			var pixel := image.get_pixelv(point)
			if pixel.a < 0.95:
				push_error("Pearl has a transparent seam at %s in %s" % [point, path])
				quit(1)
				return
			if pixel.get_luminance() < 0.35:
				push_error("Pearl has a dark divider at %s in %s" % [point, path])
				quit(1)
				return

	var left_frame_two := Image.load_from_file(
		ProjectSettings.globalize_path("res://assets/pets/siamese/walk_left/frame_02.png")
	)
	for y in range(340, 500):
		for x in range(120, 240):
			var pixel := left_frame_two.get_pixel(x, y)
			if pixel.a > 0.15 and pixel.r - pixel.g > 0.30:
				push_error("Pearl's left frame 02 still contains the orange paw smear")
				quit(1)
				return

	print("PEARL WALK INTEGRITY TEST PASS: all eight frames have intact fur colors and repaired seams")
	quit(0)
