extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")


func _visible_component_count(image: Image) -> int:
	var width := image.get_width()
	var height := image.get_height()
	var visible := PackedByteArray()
	visible.resize(width * height)
	var first_visible := -1
	var total_visible := 0
	for y in range(height):
		for x in range(width):
			var index := y * width + x
			if image.get_pixel(x, y).a > 9.0 / 255.0:
				visible[index] = 1
				total_visible += 1
				if first_visible < 0:
					first_visible = index
	if first_visible < 0:
		return 0

	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue := PackedInt32Array([first_visible])
	visited[first_visible] = 1
	var queue_index := 0
	var connected_visible := 0
	while queue_index < queue.size():
		var index := queue[queue_index]
		queue_index += 1
		connected_visible += 1
		var x := index % width
		var y := floori(float(index) / float(width))
		var neighbors := PackedInt32Array()
		if x > 0:
			neighbors.append(index - 1)
		if x + 1 < width:
			neighbors.append(index + 1)
		if y > 0:
			neighbors.append(index - width)
		if y + 1 < height:
			neighbors.append(index + width)
		for neighbor in neighbors:
			if visible[neighbor] == 1 and visited[neighbor] == 0:
				visited[neighbor] = 1
				queue.append(neighbor)
	if connected_visible != total_visible:
		print("visible connectivity mismatch: connected=%d total=%d" % [connected_visible, total_visible])
		return 2
	return 1


func _initialize() -> void:
	var avatar := AvatarScript.new()
	avatar.set_pet({"id": "maine_coon", "name": "Cedar"})
	var directions := {
		"left": avatar.animation_frames("move_left"),
		"right": avatar.animation_frames("move_right"),
	}
	for direction in directions:
		var frames: Array = directions[direction]
		if frames.size() != 12:
			push_error("Maine Coon %s walk must retain all twelve frames" % direction)
			quit(1)
			return
		for index in range(frames.size()):
			var image := Image.load_from_file(
				ProjectSettings.globalize_path(frames[index].resource_path)
			)
			if image.get_size() != Vector2i(704, 512):
				push_error("Maine Coon %s frame %02d must retain its 704x512 canvas" % [direction, index + 1])
				quit(1)
				return
			if _visible_component_count(image) != 1:
				push_error("Maine Coon %s frame %02d contains detached backdrop pixels" % [direction, index + 1])
				quit(1)
				return
	avatar.free()
	print("MAINE COON WALK CLEANUP TEST PASS: all 24 frames have clean leg gaps and one intact subject")
	quit(0)
