extends SceneTree

const SOURCE_DIR := "res://dev_only/unused_assets/assets/pets/cat/walk/source"
const OUTPUT_DIR := "res://dev_only/outputs/prepared_assets/pets/cat/walk/frames"
const FRAME_COUNT := 12
const LARGE_COMPONENT := 6000

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for index in range(FRAME_COUNT):
		var source := "%s/cat_walk_512x512_frame%03d.png" % [SOURCE_DIR, index + 1]
		var frame := Image.load_from_file(source)
		if frame == null or frame.is_empty():
			push_error("Could not load %s" % source)
			quit(1)
			return
		remove_large_neutral_components(frame)
		var output := "%s/cat_walk_frame_%02d.png" % [OUTPUT_DIR, index + 1]
		var error := frame.save_png(output)
		if error != OK:
			push_error("Could not save %s" % output)
			quit(1)
			return
	print("Prepared %d transparent cat walk frames" % FRAME_COUNT)
	quit(0)

func remove_large_neutral_components(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	for y in range(height):
		for x in range(width):
			var packed := y * width + x
			if visited[packed] == 1 or not is_background(image.get_pixel(x, y)):
				continue
			var component := collect_component(image, x, y, width, visited)
			if component.size() >= LARGE_COMPONENT:
				for component_pixel in component:
					var component_x := component_pixel % width
					var component_y: int = component_pixel / width
					var color := image.get_pixel(component_x, component_y)
					color.a = 0.0
					image.set_pixel(component_x, component_y, color)

func collect_component(image: Image, start_x: int, start_y: int, width: int, visited: PackedByteArray) -> PackedInt32Array:
	var component := PackedInt32Array()
	var queue := PackedInt32Array([start_y * width + start_x])
	visited[start_y * width + start_x] = 1
	var cursor := 0
	while cursor < queue.size():
		var packed := queue[cursor]
		cursor += 1
		component.append(packed)
		var x := packed % width
		var y: int = packed / width
		try_enqueue(image, x - 1, y, width, visited, queue)
		try_enqueue(image, x + 1, y, width, visited, queue)
		try_enqueue(image, x, y - 1, width, visited, queue)
		try_enqueue(image, x, y + 1, width, visited, queue)
	return component

func try_enqueue(image: Image, x: int, y: int, width: int, visited: PackedByteArray, queue: PackedInt32Array) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var packed := y * width + x
	if visited[packed] == 1:
		return
	visited[packed] = 1
	var color := image.get_pixel(x, y)
	if not is_background(color):
		return
	queue.append(packed)

func is_background(color: Color) -> bool:
	if color.a <= 0.02:
		return false
	var maximum: float = maxf(color.r, maxf(color.g, color.b))
	var minimum: float = minf(color.r, minf(color.g, color.b))
	var chroma: float = maximum - minimum
	return chroma < 0.14 and maximum > 0.38 and maximum < 0.93
