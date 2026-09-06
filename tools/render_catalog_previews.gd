extends SceneTree

const FISH_BOOK_OUTPUT_PATH := "res://dev_only/outputs/previews/catalog/fish_book_runtime_preview.png"
const FISH_BOOK_LOCKED_OUTPUT_PATH := "res://dev_only/outputs/previews/catalog/fish_book_locked_runtime_preview.png"
const CAT_STORE_OUTPUT_PATH := "res://dev_only/outputs/previews/catalog/adopt_cat_runtime_preview.png"


func _initialize() -> void:
	call_deferred("_render_previews")


func _render_previews() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FISH_BOOK_OUTPUT_PATH.get_base_dir()))
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
	game.show_fish_book()
	await process_frame
	await process_frame
	if root.get_texture().get_image().save_png(FISH_BOOK_OUTPUT_PATH) != OK:
		push_error("Could not save Fish Book preview")
		quit(1)
		return
	game.fish_book_screen.select_fish("coral")
	await process_frame
	if root.get_texture().get_image().save_png(FISH_BOOK_LOCKED_OUTPUT_PATH) != OK:
		push_error("Could not save locked Fish Book preview")
		quit(1)
		return
	game.show_store()
	await process_frame
	await process_frame
	if root.get_texture().get_image().save_png(CAT_STORE_OUTPUT_PATH) != OK:
		push_error("Could not save cat store preview")
		quit(1)
		return
	print("CATALOG PREVIEWS: %s %s %s" % [
		FISH_BOOK_OUTPUT_PATH,
		FISH_BOOK_LOCKED_OUTPUT_PATH,
		CAT_STORE_OUTPUT_PATH
	])
	quit(0)
