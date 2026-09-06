extends SceneTree

const OUTPUT_PATH := "res://dev_only/outputs/previews/aquarium/aquarium_runtime_preview.png"
const IDLE_OUTPUT_PATH := "res://dev_only/outputs/previews/aquarium/aquarium_runtime_idle_preview.png"


func _initialize() -> void:
	call_deferred("_render_preview")


func _render_preview() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var packed: PackedScene = load("res://main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	game.save_data = {
		"version": 7,
		"pet_pool": [{"id": "default_orange_cat", "name": "Maple", "type": "Cat"}],
		"active_pet_id": "default_orange_cat",
		"owned_cat_ids": ["maple"],
		"progress_stats": {
			"experience": 0,
			"unlocked_fish_ids": ["green"]
		}
	}
	game.show_aquarium()
	for frame_index in range(600):
		if game.current_screen == "aquarium":
			break
		await process_frame
	if game.current_screen != "aquarium":
		push_error("Aquarium did not finish loading before preview timeout")
		quit(1)
		return
	var image := root.get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Could not save Aquarium preview: %s" % error_string(error))
		quit(1)
		return
	for fish_actor in game.aquarium_screen.extra_fish_actors:
		fish_actor._start_resting(5.0)
	await create_timer(1.0 / game.aquarium_screen.extra_fish_actors[0].IDLE_ANIMATION_FPS * 2.0).timeout
	await process_frame
	var idle_image := root.get_texture().get_image()
	var idle_error := idle_image.save_png(IDLE_OUTPUT_PATH)
	if idle_error != OK:
		push_error("Could not save Aquarium idle preview: %s" % error_string(idle_error))
		quit(1)
		return
	print("AQUARIUM PREVIEWS: %s %s" % [OUTPUT_PATH, IDLE_OUTPUT_PATH])
	quit(0)
