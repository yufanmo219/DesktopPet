extends SceneTree

const OUTPUT_PATH := "res://dev_only/outputs/previews/desktop_station/orange_cat_station_preview.png"
const PET_OUTPUT_PATH := "res://dev_only/outputs/previews/desktop_station/orange_cat_pet_window_preview.png"


func _initialize() -> void:
	call_deferred("_render_preview")


func _render_preview() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_PATH.get_base_dir()))
	var packed: PackedScene = load("res://main.tscn")
	var game = packed.instantiate()
	root.transparent_bg = true
	root.add_child(game)
	await process_frame
	game.save_enabled = false
	game._seed_preview_pets()
	var screen_index := DisplayServer.window_get_current_screen()
	game.widget_screen_scale = maxf(1.0, DisplayServer.screen_get_scale(screen_index)) * game.DESKTOP_WIDGET_SCALE
	root.gui_embed_subwindows = false
	game.widget_station_position = Vector2(896, 518)
	game.show_widget_preview()
	game.set_widget_station_position(game.widget_station_position)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var initial_top_window := _get_top_overlapping_window(game)
	var pet_window_id: int = game.pet_window.get_window_id()
	var station_window_id: int = game.station_window.get_window_id()
	print("WINDOW ORDER INITIAL: top=%d pet=%d station=%d station_pos=%s pet_pos=%s expected_pet_pos=%s transient=%s station_unresizable=%s host_pos=%s host_size=%s" % [initial_top_window, pet_window_id, station_window_id, game.station_window.position, game.pet_window.position, game.widget_pet_position, game.pet_window.transient, game.station_window.unresizable, game.get_window().position, game.get_window().size])
	if initial_top_window != pet_window_id:
		push_error("The cat window is not above the Station at startup")
		quit(1)
		return
	game.set_widget_station_position(game.widget_station_position + Vector2(180, 80))
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var moved_top_window := _get_top_overlapping_window(game)
	print("WINDOW ORDER AFTER MOVE: top=%d pet=%d station=%d" % [moved_top_window, pet_window_id, station_window_id])
	if moved_top_window != pet_window_id:
		push_error("The cat window is not above the Station after moving it")
		quit(1)
		return
	game.station_window.grab_focus()
	game.set_widget_pet_position(game.get_station_pet_anchor())
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var returned_top_window := _get_top_overlapping_window(game)
	print("WINDOW ORDER AFTER PET RETURN: top=%d pet=%d station=%d" % [returned_top_window, pet_window_id, station_window_id])
	if returned_top_window != pet_window_id:
		push_error("The cat window is not above the Station after the pet returns")
		quit(1)
		return
	print("DESKTOP SCREENS: count=%d usable_rects=%s" % [DisplayServer.get_screen_count(), game.get_desktop_screen_rects()])
	var station_top = game.desktop_station.find_child("StationTopArt", true, false)
	print(
		"STATION GEOMETRY: viewport=%s content=%s station=%s top=%s texture=%s" % [
			game.station_window.size,
			game.content.size,
			game.desktop_station.size,
			station_top.size,
			station_top.texture.get_size()
		]
	)
	var image: Image = game.station_window.get_texture().get_image()
	if image.get_size() != game.station_window.size:
		push_error("Station content does not fill its native window and may create black edge bars")
		quit(1)
		return
	_print_vertical_edge_pixels(image)
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Could not save Station preview: %s" % error_string(error))
		quit(1)
		return
	print("STATION PREVIEW: %s" % OUTPUT_PATH)
	if is_instance_valid(game.pet_window):
		var pet_image: Image = game.pet_window.get_texture().get_image()
		var pet_error: Error = pet_image.save_png(PET_OUTPUT_PATH)
		if pet_error != OK:
			push_error("Could not save pet-window preview: %s" % error_string(pet_error))
			quit(1)
			return
		print(
			"PET WINDOW: size=%s logical=%s scale_mode=%s alpha_bounds=%s transient=%s always_on_top=%s transparent=%s transparent_bg=%s corner_alpha=%.3f output=%s" % [
				game.pet_window.size,
				game.pet_window.content_scale_size,
				game.pet_window.content_scale_mode,
				pet_image.get_used_rect(),
				game.pet_window.transient,
				game.pet_window.always_on_top,
				game.pet_window.transparent,
				game.pet_window.transparent_bg,
				pet_image.get_pixel(0, 0).a,
				PET_OUTPUT_PATH
			]
		)
	var capture_rect := Rect2i(
		game.station_window.position - Vector2i(8, 8),
		game.station_window.size + Vector2i(16, 16)
	)
	var composited_image := DisplayServer.screen_get_image_rect(capture_rect)
	if not composited_image.is_empty():
		var composited_path := "/private/tmp/orange_cat_station_composited.png"
		var composited_error := composited_image.save_png(composited_path)
		print("STATION COMPOSITED CAPTURE: rect=%s error=%s output=%s" % [capture_rect, error_string(composited_error), composited_path])
	quit(0)


func _print_vertical_edge_pixels(image: Image) -> void:
	var left_visible := 0
	var right_visible := 0
	var left_dark := 0
	var right_dark := 0
	for y in range(image.get_height()):
		var left := image.get_pixel(0, y)
		var right := image.get_pixel(image.get_width() - 1, y)
		if left.a > 0.01:
			left_visible += 1
			if maxf(left.r, maxf(left.g, left.b)) < 0.12:
				left_dark += 1
		if right.a > 0.01:
			right_visible += 1
			if maxf(right.r, maxf(right.g, right.b)) < 0.12:
				right_dark += 1
	print(
		"STATION EDGE PIXELS: size=%s left_visible=%d left_dark=%d right_visible=%d right_dark=%d" % [
			image.get_size(), left_visible, left_dark, right_visible, right_dark
		]
	)


func _get_top_overlapping_window(game) -> int:
	var station_rect: Rect2 = Rect2(game.widget_station_position, game.get_station_pixel_size())
	var pet_rect: Rect2 = game.get_pet_screen_rect()
	var overlap: Rect2 = station_rect.intersection(pet_rect)
	return DisplayServer.get_window_at_screen_position(Vector2i(overlap.get_center()))
