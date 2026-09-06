extends SceneTree

const OUTPUT_PATH := "res://dev_only/outputs/previews/pets/sleep_bubble_home_preview.png"


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
		"pet_pool": [],
		"active_pet_id": "",
		"owned_cat_ids": ["maple"],
		"progress_stats": {"experience": 0}
	}
	game.show_home()
	await process_frame
	game.avatar.set_process(false)
	game.avatar.sleep_bubble_active = true
	game.avatar.sleep_bubble_frame = game.avatar.SLEEP_BUBBLE_FRAMES.size() - 1
	game.avatar._update_sleep_bubble()
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Could not save sleeping-bubble preview: %s" % error_string(error))
		quit(1)
		return
	print("SLEEP BUBBLE HOME PREVIEW: %s" % OUTPUT_PATH)
	quit(0)
