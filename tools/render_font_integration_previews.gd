extends SceneTree

const OUTPUT_DIR := "res://dev_only/outputs/previews/font_integration"


func _initialize() -> void:
	call_deferred("_render_previews")


func _render_previews() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
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
			"experience": 2400,
			"hearts": 5,
			"next_heart_restore_unix": 0
		}
	}

	game.show_home()
	await _save_after_frames("home.png")
	game.show_store()
	await _save_after_frames("store.png")
	game.show_fishing()
	await _save_after_frames("fishing.png")
	game.fishing_game.catch_hotspot.disabled = true
	await _save_after_frames("fishing_disabled.png")
	game.clear_screen()
	var station_background := ColorRect.new()
	station_background.color = Color("#393432")
	station_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.content.add_child(station_background)
	game._build_desktop_station(game.get_active_pet())
	game.desktop_station.position = Vector2(460, 270)
	await _save_after_frames("desktop_station.png")
	print("FONT INTEGRATION PREVIEWS: %s" % OUTPUT_DIR)
	quit(0)


func _save_after_frames(file_name: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, file_name]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save font integration preview: %s" % error_string(error))
		quit(1)
