extends SceneTree

const CONFIRMATION_OUTPUT := "res://dev_only/outputs/previews/store/store_purchase_confirmation_preview.png"
const CONGRATULATIONS_OUTPUT := "res://dev_only/outputs/previews/store/store_purchase_congratulations_preview.png"
const UNLOCK_BUTTON_OUTPUT := "res://dev_only/outputs/previews/store/store_unlock_button_preview.png"


func _initialize() -> void:
	call_deferred("_render_popups")


func _render_popups() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CONFIRMATION_OUTPUT.get_base_dir()))
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
			"experience": 2400,
			"hearts": 5,
			"next_heart_restore_unix": 0
		}
	}
	game.show_store()
	await process_frame
	var store = game.store_screen
	store.select_cat("mochi")
	await process_frame
	if not _save_viewport(UNLOCK_BUTTON_OUTPUT):
		quit(1)
		return
	store.detail_unlock_button.emit_signal("pressed")
	await process_frame
	await process_frame
	if not _save_viewport(CONFIRMATION_OUTPUT):
		quit(1)
		return
	store.purchase_yes_button.emit_signal("pressed")
	await process_frame
	await process_frame
	if not _save_viewport(CONGRATULATIONS_OUTPUT):
		quit(1)
		return
	print("STORE UI PREVIEWS: %s %s %s" % [UNLOCK_BUTTON_OUTPUT, CONFIRMATION_OUTPUT, CONGRATULATIONS_OUTPUT])
	quit(0)


func _save_viewport(path: String) -> bool:
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save Store popup preview: %s" % error_string(error))
		return false
	return true
