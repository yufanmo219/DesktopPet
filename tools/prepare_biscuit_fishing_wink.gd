extends SceneTree

## Assemble the generated eyelid keyframes on the unchanged approved sprite.
## Never use the generated body/background: only a feathered interior eye patch
## is sampled, preserving the other eye, coat, silhouette and alpha byte-for-byte.
const BASE_PATH := "res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png"
const SOURCE_PATH := "res://dev_only/unused_assets/assets/pets/biscuit/source/biscuit_fishing_single_wink_keyframes_v2.png"
const OUTPUT_DIRECTORY := "res://dev_only/outputs/prepared_assets/pets/biscuit/fishing/success_wink_v2"
const EYE_REGION := Rect2i(203, 156, 65, 66)
const TARGET_EYE_CENTER := Vector2(235.5, 190.0)
const SOURCE_EYE_CENTERS := [Vector2(391.0, 296.0), Vector2(1201.5, 296.0)]
const SOURCE_SCALE := 0.60
const FEATHER_PIXELS := 7.0
const POSE_SEQUENCE := [0, 1, 1, 2, 2, 1, 1, 0]


func _initialize() -> void:
	var base := Image.load_from_file(ProjectSettings.globalize_path(BASE_PATH))
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_PATH))
	if base == null or sheet == null:
		push_error("Missing Biscuit approved sprite or generated wink keyframes")
		quit(1)
		return
	assert(base.get_size() == Vector2i(512, 512))
	assert(sheet.get_size() == Vector2i(1774, 887))
	base.convert(Image.FORMAT_RGBA8)
	sheet.convert(Image.FORMAT_RGBA8)
	var poses: Array[Image] = [base]
	for source_center in SOURCE_EYE_CENTERS:
		var pose := base.duplicate() as Image
		for y in range(EYE_REGION.position.y, EYE_REGION.end.y):
			for x in range(EYE_REGION.position.x, EYE_REGION.end.x):
				var point := Vector2(x, y)
				var sample_position: Vector2 = source_center + (point - TARGET_EYE_CENTER) / SOURCE_SCALE
				var generated := _sample_bilinear(sheet, sample_position)
				var original := base.get_pixel(x, y)
				var edge_distance := minf(
					minf(x - EYE_REGION.position.x, EYE_REGION.end.x - 1 - x),
					minf(y - EYE_REGION.position.y, EYE_REGION.end.y - 1 - y)
				)
				var weight := smoothstep(0.0, FEATHER_PIXELS, edge_distance)
				var color := original.lerp(generated, weight)
				color.a = original.a
				pose.set_pixel(x, y, color)
		poses.append(pose)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	var gallery := Image.create(1024, 512, false, Image.FORMAT_RGBA8)
	gallery.fill(Color("#f5e6ca"))
	for index in range(POSE_SEQUENCE.size()):
		var frame := poses[POSE_SEQUENCE[index]]
		var output_path := "%s/frame_%02d.png" % [OUTPUT_DIRECTORY, index + 1]
		var error := frame.save_png(ProjectSettings.globalize_path(output_path))
		if error != OK:
			push_error("Cannot save Biscuit single-eye wink frame")
			quit(1)
			return
		var thumbnail := frame.duplicate() as Image
		thumbnail.resize(256, 256, Image.INTERPOLATE_LANCZOS)
		gallery.blend_rect(thumbnail, Rect2i(0, 0, 256, 256), Vector2i(index % 4, index / 4) * 256)
		print("Saved ", output_path, " (pose ", POSE_SEQUENCE[index], ")")
	gallery.save_png("/private/tmp/biscuit-single-wink-contact-sheet.png")
	var face_gallery := Image.create(720, 330, false, Image.FORMAT_RGBA8)
	face_gallery.fill(Color("#f5e6ca"))
	for index in range(poses.size()):
		var face := poses[index].get_region(Rect2i(195, 145, 80, 110))
		face.resize(240, 330, Image.INTERPOLATE_NEAREST)
		face_gallery.blit_rect(face, Rect2i(0, 0, 240, 330), Vector2i(index * 240, 0))
	face_gallery.save_png("/private/tmp/biscuit-single-wink-eye-poses.png")
	quit(0)


func _sample_bilinear(image: Image, point: Vector2) -> Color:
	var top_left := Vector2i(floori(point.x), floori(point.y))
	var fraction := point - Vector2(top_left)
	var top := image.get_pixelv(top_left).lerp(image.get_pixelv(top_left + Vector2i.RIGHT), fraction.x)
	var bottom := image.get_pixelv(top_left + Vector2i.DOWN).lerp(image.get_pixelv(top_left + Vector2i.ONE), fraction.x)
	return top.lerp(bottom, fraction.y)
