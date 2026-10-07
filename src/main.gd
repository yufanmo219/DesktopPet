extends Control

const SAVE_PATH := "user://desktop_pet_save.json"
const LEGACY_SAVE_PATH := "user://pet_memory.json"
const PROGRESS_SAVE_KEY := "progress_stats"
# Keep this key only as a one-way compatibility bridge for existing QA saves.
const LEGACY_PROGRESS_SAVE_KEY := "pinball_stats"
const CURRENT_SAVE_VERSION := 8
const MAX_PETS := 9
const PetAvatarScript = preload("res://src/pet_avatar.gd")
const FishingGameScript = preload("res://src/fishing_game.gd")
const AquariumScreenScript = preload("res://src/aquarium_screen.gd")
const AquariumLoadingScreenScript = preload("res://src/aquarium_loading_screen.gd")
const StoreScreenScript = preload("res://src/store_screen.gd")
const FishBookScreenScript = preload("res://src/fish_book_screen.gd")
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const SaveGameRepositoryScript = preload("res://src/persistence/save_game_repository.gd")
const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")
const HOME_DAY_TEXTURE: Texture2D = preload("res://assets/ui/home/home_day_layout_v3.png")
const HOME_NIGHT_TEXTURE: Texture2D = preload("res://assets/ui/home/home_night_layout_v3.png")

const HOME_WAKE_AREA := Rect2(0.0, 0.0, 700.0, 720.0)
const HOME_POINTER_MOVE_THRESHOLD := 2.0
const HOME_SLEEP_DELAY_SECONDS := 10.0
const HOME_WELCOME_TEXT_COLOR := Color("#fff3cf")
const DESKTOP_WIDGET_SCALE := 0.90
const STATION_LOGICAL_SIZE := Vector2i(360, 166)
const PET_WIDGET_LOGICAL_SIZE := Vector2i(400, 300)
const STATION_SCREEN_MARGIN := Vector2i(24, 48)
const STATION_CONTROLS_Y := 88.0
const STATION_TOP_ART_POSITION := Vector2.ZERO
const STATION_TOP_ART_SIZE := Vector2(360.0, STATION_CONTROLS_Y)
const STATION_ART_VISIBLE_ALPHA_THRESHOLD := 0.03
const STATION_PET_FOOT_Y := 107.0
const STATION_WAKE_SECONDS := 30.0
const PET_RETURN_SECONDS := 15.0
const PET_FOLLOW_RUN_SPEED := 150.0
const PET_FOLLOW_REACTION_MIN := 0.3
const PET_FOLLOW_REACTION_MAX := 0.6
# Logical-pixel radii around the screen-clamped follow target. Keep the larger
# restart radius separate so nearby cursor motion cannot repeatedly wake a cat.
const PET_FOLLOW_ARRIVAL_DISTANCE := 60.0
const PET_FOLLOW_RESUME_DISTANCE := 100.0
var save_data: Dictionary = {
	"version": CURRENT_SAVE_VERSION,
	"pet_pool": [],
	"active_pet_id": "",
	"owned_cat_ids": ["maple"],
	"progress_stats": {
		"experience": 0,
		"hearts": 5,
		"next_heart_restore_unix": 0,
		"fishing_level": 1,
		"unlocked_fish_ids": [],
		"aquarium_fish_ids": []
	},
	"last_updated_unix": 0
}
var preview_session := false
var content: Control
var avatar: PetAvatar
var current_screen := ""
var autosave_elapsed := 0.0

var home_xp_label: Label
var home_pet_interaction_surface: Control
var home_entry_pointer_position := Vector2.ZERO
var home_pointer_has_moved := false
var home_pointer_outside_elapsed := 0.0
var fishing_game
var aquarium_screen
var cached_aquarium_screen
var aquarium_loading_screen
var store_screen
var fish_book_screen
var fetch_ball: Button
var fetch_counter_label: Label
var fetch_status_label: Label
var fetch_count := 0

var desktop_mode := false
var desktop_station: Panel
var station_top_art: Control
var station_window: Window
var station_drag_handle: Control
var follow_button: Button
var pet_window: Window
var pet_drag_surface: Control
var pet_station_top_art: Control
var pet_window_raise_pending := false
var widget_following := false
var widget_station_dragging := false
var widget_pet_dragging := false
var widget_pet_at_station := true
var widget_returning_to_station := false
var widget_seconds_outside_station := 0.0
var widget_seconds_since_pet_drag := 0.0
var widget_screen_scale := DESKTOP_WIDGET_SCALE
var widget_station_position := Vector2.ZERO
var widget_pet_position := Vector2.ZERO
var widget_station_drag_start_mouse := Vector2.ZERO
var widget_station_drag_start_position := Vector2.ZERO
var widget_pet_drag_start_mouse := Vector2.ZERO
var widget_pet_drag_start_position := Vector2.ZERO
var widget_follow_last_pointer := Vector2.ZERO
var widget_follow_target := Vector2.ZERO
var widget_follow_reaction_remaining := 0.0
var widget_follow_has_target := false
var widget_follow_chasing := false
var normal_window_size := Vector2i(1152, 648)
var normal_window_position := Vector2i.ZERO
var normal_window_min_size := Vector2i(960, 540)
var normal_content_scale_size := Vector2i(1280, 720)
var normal_window_unresizable := false
var save_enabled := true
var save_read_only := false
var save_repository
var launch_directly_to_widget := false

var palette := {
	"ink": Color("#513c4d"),
	"muted": Color("#796a75"),
	"paper": Color("#fff9ee"),
	"cream": Color("#f7e8cf"),
	"peach": Color("#f5b97b"),
	"orange": Color("#e87942"),
	"orange_dark": Color("#bd553f"),
	"sage": Color("#7f9d8b"),
	"sky": Color("#88bfc5"),
	"night": Color("#283047")
}


func _ready() -> void:
	theme = GameFontStylesScript.make_game_theme()
	get_window().min_size = Vector2i(960, 540)
	normal_window_size = get_window().size
	normal_window_position = get_window().position
	normal_window_min_size = get_window().min_size
	normal_content_scale_size = get_window().content_scale_size
	normal_window_unresizable = get_window().unresizable

	var preview_screen := ""
	var preview_pet_id := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--screen="):
			preview_screen = argument.trim_prefix("--screen=")
		elif argument.begins_with("--pet="):
			preview_pet_id = argument.trim_prefix("--pet=").to_lower()
		elif argument == "--test-mode":
			save_enabled = false
		elif argument == "--desktop-widget":
			launch_directly_to_widget = true
	preview_session = preview_screen != ""
	if preview_session:
		# Screen previews use deliberately simplified pets and progression. They
		# must never be allowed to overwrite the player's real save when a preview
		# button (such as Carry Cat) happens to call save_game().
		save_enabled = false
	if save_enabled:
		load_save()
	ensure_default_pet()
	if launch_directly_to_widget:
		_apply_desktop_launch_pet_override(preview_pet_id)
	if launch_directly_to_widget and not get_pet_pool().is_empty():
		call_deferred("enter_desktop_mode")
	elif preview_session:
		_seed_preview_pets(preview_pet_id)
		match preview_screen:
			"creator", "login": show_home()
			"pool": show_pet_pool()
			"home": show_home()
			"fishing": show_fishing()
			"aquarium": show_aquarium()
			"store": show_store()
			"fish_book": show_fish_book()
			"fetch": show_reverse_fetch()
			"widget": enter_desktop_mode()
			_: show_home()
	else:
		show_home()


func _process(delta: float) -> void:
	if get_active_pet_index() >= 0:
		autosave_elapsed += delta
		if autosave_elapsed >= 30.0:
			autosave_elapsed = 0.0
			save_game()

	if current_screen == "home" and is_instance_valid(avatar):
		var pointer_position := get_local_mouse_position()
		if not home_pointer_has_moved:
			home_pointer_has_moved = (
				pointer_position.distance_to(home_entry_pointer_position)
				>= HOME_POINTER_MOVE_THRESHOLD
			)
		update_home_pointer_state(pointer_position, home_pointer_has_moved, delta)

	if desktop_mode:
		update_desktop_companion(delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
		get_tree().quit()


func _exit_tree() -> void:
	if (
		is_instance_valid(cached_aquarium_screen)
		and cached_aquarium_screen.get_parent() == null
	):
		cached_aquarium_screen.free()
	cached_aquarium_screen = null


func clear_screen() -> void:
	if current_screen in ["home", "fishing", "aquarium", "aquarium_loading", "store", "fish_book"]:
		var music_manager := get_node_or_null("/root/MusicManager")
		if music_manager != null:
			if current_screen == "aquarium" or current_screen == "aquarium_loading":
				music_manager.stop_aquarium_music()
			else:
				music_manager.stop_music()
	if (
		current_screen == "aquarium"
		and
		is_instance_valid(aquarium_screen)
		and aquarium_screen.get_parent() == content
	):
		content.remove_child(aquarium_screen)
		cached_aquarium_screen = aquarium_screen
	if is_instance_valid(content):
		remove_child(content)
		content.queue_free()
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)
	home_xp_label = null
	home_pet_interaction_surface = null
	home_pointer_has_moved = false
	home_pointer_outside_elapsed = 0.0
	avatar = null
	fishing_game = null
	aquarium_screen = null
	aquarium_loading_screen = null
	store_screen = null
	fish_book_screen = null


func add_background(color: Color, with_texture := true) -> void:
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(background)
	if with_texture:
		var glow_one := ColorRect.new()
		glow_one.color = Color(1.0, 0.88, 0.68, 0.18)
		glow_one.position = Vector2(-90, -80)
		glow_one.size = Vector2(470, 260)
		glow_one.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(glow_one)
		var glow_two := ColorRect.new()
		glow_two.color = Color(0.55, 0.75, 0.73, 0.14)
		glow_two.position = Vector2(990, 490)
		glow_two.size = Vector2(380, 280)
		glow_two.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(glow_two)


func make_label(text: String, font_size := 20, color := Color("#513c4d")) -> Label:
	var label := Label.new()
	label.text = GameFontStylesScript.display_text(text)
	GameFontStylesScript.apply_regular(label)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func make_button(text: String, action: Callable, accent := false, compact := false) -> Button:
	var button := Button.new()
	button.text = GameFontStylesScript.display_text(text)
	if accent:
		GameFontStylesScript.apply_button(button)
	else:
		GameFontStylesScript.apply_regular(button)
	button.custom_minimum_size = Vector2(146 if compact else 205, 44 if compact else 54)
	button.add_theme_font_size_override("font_size", 28 if compact else 32)
	button.add_theme_color_override("font_color", Color.WHITE if accent else palette.ink)
	button.add_theme_color_override("font_hover_color", Color.WHITE if accent else palette.ink)
	var normal := StyleBoxFlat.new()
	normal.bg_color = palette.orange if accent else Color("#fff7e9")
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(2)
	normal.border_color = palette.orange_dark if accent else Color("#ddc7b2")
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = palette.orange_dark if accent else Color("#ffffff")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(action)
	return button


func make_home_slot_button(text: String, action: Callable, accent := false) -> Button:
	var button := Button.new()
	button.text = GameFontStylesScript.display_text(text)
	if accent:
		GameFontStylesScript.apply_button(button)
	else:
		GameFontStylesScript.apply_regular(button)
	button.add_theme_font_size_override("font_size", 36)
	var text_color: Color = Color.WHITE if accent else palette.ink
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	var normal := StyleBoxFlat.new()
	normal.bg_color = palette.orange if accent else Color(1.0, 0.975, 0.92, 0.96)
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(2)
	normal.border_color = palette.orange_dark if accent else Color("#ddc7b2")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = palette.orange_dark if accent else Color.WHITE
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color("#a84b3a") if accent else Color("#f1dfc9")
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(action)
	return button


func make_panel(color := Color("#fff9ee"), radius := 24, margin := 24) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	style.shadow_color = Color(0.22, 0.12, 0.18, 0.12)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel


func add_page_title(title_text: String, subtitle_text: String = "") -> void:
	var title := make_label(title_text, 36)
	GameFontStylesScript.apply_accent(title)
	title.position = Vector2(56, 28)
	title.size = Vector2(850, 48)
	content.add_child(title)
	if subtitle_text != "":
		var subtitle := make_label(subtitle_text, 17, palette.muted)
		subtitle.position = Vector2(58, 77)
		subtitle.size = Vector2(1050, 30)
		content.add_child(subtitle)


func show_pet_pool() -> void:
	leave_desktop_mode()
	clear_screen()
	current_screen = "pool"
	add_background(Color("#e7d8c8"))
	add_page_title("Your pet pool", "Choose one companion to carry with you. You can keep up to five pets.")

	var grid := GridContainer.new()
	grid.columns = 3
	grid.position = Vector2(56, 118)
	grid.size = Vector2(1168, 475)
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	content.add_child(grid)
	for pet_value in get_pet_pool():
		var pet: Dictionary = pet_value
		var card := make_panel(Color(1.0, 0.98, 0.94, 0.97), 20, 16)
		card.custom_minimum_size = Vector2(378, 220)
		grid.add_child(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var mini_avatar: PetAvatar = PetAvatarScript.new()
		mini_avatar.custom_minimum_size = Vector2(145, 180)
		mini_avatar.set_pet(pet)
		row.add_child(mini_avatar)
		var details := VBoxContainer.new()
		details.custom_minimum_size.x = 180
		details.add_theme_constant_override("separation", 7)
		row.add_child(details)
		var active_mark := "  • with you" if pet.get("id", "") == save_data.get("active_pet_id", "") else ""
		details.add_child(make_label("%s%s" % [pet.get("name", "Companion"), active_mark], 21))
		details.add_child(make_label(str(pet.get("type", "Cat")), 14, palette.muted))
		var selected_id := str(pet.get("id", ""))
		details.add_child(make_button("Take with me", func():
			select_pet(selected_id)
			show_home()
		, pet.get("id", "") != save_data.get("active_pet_id", ""), true))

	var actions := HBoxContainer.new()
	actions.position = Vector2(56, 628)
	actions.add_theme_constant_override("separation", 14)
	content.add_child(actions)
	if get_active_pet_index() >= 0:
		actions.add_child(make_button("Back home", show_home))


func show_home() -> void:
	leave_desktop_mode()
	ensure_default_pet()
	var pet := get_active_pet()
	clear_screen()
	current_screen = "home"
	var music_manager := get_node_or_null("/root/MusicManager")
	if music_manager != null:
		music_manager.play_home_music()
	var background := TextureRect.new()
	background.texture = get_home_background_texture()
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(background)

	var welcome := make_label("Welcome Home!!", 48, HOME_WELCOME_TEXT_COLOR)
	GameFontStylesScript.apply_accent(welcome)
	# apply_accent supplies the font, outline, and shadow, but its shared coral
	# fill color must not override Home's warm cream welcome sign.
	welcome.add_theme_color_override("font_color", HOME_WELCOME_TEXT_COLOR)
	welcome.position = Vector2(213, 80)
	welcome.size = Vector2(390, 92)
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(welcome)

	avatar = PetAvatarScript.new()
	avatar.position = Vector2(170, 205)
	avatar.size = Vector2(460, 390)
	avatar.set_pet(pet)
	avatar.set_home_idle_enabled(true)
	avatar.set_mood("idle")
	content.add_child(avatar)
	home_entry_pointer_position = get_local_mouse_position()
	home_pointer_has_moved = false
	home_pointer_outside_elapsed = 0.0

	var xp_row := HBoxContainer.new()
	xp_row.name = "HomeXPRow"
	xp_row.position = Vector2(776, 58)
	xp_row.size = Vector2(390, 70)
	xp_row.add_theme_constant_override("separation", 18)
	content.add_child(xp_row)
	var xp_title := make_label("CURRENT XP", 30, Color("#795446"))
	xp_title.custom_minimum_size = Vector2(250, 70)
	xp_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_row.add_child(xp_title)
	home_xp_label = make_label("%d" % int(get_progress_stats().experience), 40, Color("#bd553f"))
	GameFontStylesScript.apply_accent(home_xp_label)
	home_xp_label.name = "HomeXPValueLabel"
	home_xp_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	home_xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	xp_row.add_child(home_xp_label)

	var heading := make_label("%s is here!" % pet.get("name", "Companion"), 45, Color("#603d3b"))
	GameFontStylesScript.apply_accent(heading)
	heading.position = Vector2(756, 200)
	heading.size = Vector2(428, 40)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content.add_child(heading)

	var home_actions := [
		["Keep as desktop companion", enter_desktop_mode, true],
		["Go fishing", show_fishing, false],
		["My aquarium", show_aquarium, false],
		["Adopt another cat", show_store, false]
	]
	var actions_layer := Control.new()
	actions_layer.name = "HomeActionsLayer"
	actions_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(actions_layer)
	var button_y_positions := [265.0, 350.0, 435.0, 520.0]
	for index in range(home_actions.size()):
		var action_data: Array = home_actions[index]
		var button := make_home_slot_button(str(action_data[0]), action_data[1], bool(action_data[2]))
		button.position = Vector2(756, button_y_positions[index])
		button.size = Vector2(428, 70)
		actions_layer.add_child(button)

	home_pet_interaction_surface = Control.new()
	home_pet_interaction_surface.name = "HomePetInteractionSurface"
	home_pet_interaction_surface.position = avatar.position
	home_pet_interaction_surface.size = avatar.size
	home_pet_interaction_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	home_pet_interaction_surface.gui_input.connect(_on_home_pet_input)
	content.add_child(home_pet_interaction_surface)


func update_home_pointer_state(
	pointer_position: Vector2,
	pointer_has_moved := true,
	delta := 0.0
) -> void:
	if current_screen != "home" or not is_instance_valid(avatar):
		return
	var pointer_is_in_wake_area := pointer_has_moved and HOME_WAKE_AREA.has_point(pointer_position)
	if pointer_is_in_wake_area:
		home_pointer_outside_elapsed = 0.0
		if avatar.mood != "idle":
			avatar.set_mood("idle")
		return
	if avatar.mood == "sleep":
		home_pointer_outside_elapsed = 0.0
		return
	home_pointer_outside_elapsed = minf(
		HOME_SLEEP_DELAY_SECONDS,
		home_pointer_outside_elapsed + maxf(0.0, delta)
	)
	if home_pointer_outside_elapsed >= HOME_SLEEP_DELAY_SECONDS:
		avatar.set_mood("sleep")
		home_pointer_outside_elapsed = 0.0


func _on_home_pet_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and event.double_click
	):
		avatar.play_belly_roll()
		home_pet_interaction_surface.accept_event()


func show_store() -> void:
	leave_desktop_mode()
	ensure_default_pet()
	clear_screen()
	current_screen = "store"
	var music_manager := get_node_or_null("/root/MusicManager")
	if music_manager != null:
		music_manager.play_shop_music()
	store_screen = StoreScreenScript.new()
	store_screen.configure(get_progress_stats(), get_owned_cat_ids(), "cats")
	store_screen.back_requested.connect(show_home)
	store_screen.cat_purchased.connect(_on_store_cat_purchased)
	store_screen.cat_selected.connect(_on_store_cat_selected)
	store_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(store_screen)


func show_fish_book() -> void:
	leave_desktop_mode()
	ensure_default_pet()
	clear_screen()
	current_screen = "fish_book"
	var music_manager := get_node_or_null("/root/MusicManager")
	if music_manager != null:
		music_manager.play_shop_music()
	fish_book_screen = FishBookScreenScript.new()
	fish_book_screen.configure_book(get_progress_stats())
	fish_book_screen.back_requested.connect(show_aquarium)
	fish_book_screen.aquarium_fish_ids_changed.connect(_on_aquarium_fish_ids_changed)
	fish_book_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(fish_book_screen)


func get_home_background_texture(hour_override := -1) -> Texture2D:
	var hour := int(hour_override)
	if hour < 0:
		hour = int(Time.get_datetime_dict_from_system().get("hour", 12))
	return HOME_NIGHT_TEXTURE if hour < 7 or hour >= 19 else HOME_DAY_TEXTURE


func show_fishing() -> void:
	leave_desktop_mode()
	ensure_default_pet()
	var pet := get_active_pet()
	clear_screen()
	current_screen = "fishing"
	var music_manager := get_node_or_null("/root/MusicManager")
	if music_manager != null:
		music_manager.play_fishing_music()
	fishing_game = FishingGameScript.new()
	fishing_game.configure(pet, get_progress_stats())
	fishing_game.catch_completed.connect(_on_fishing_catch_completed)
	fishing_game.shared_stats_changed.connect(_on_progress_stats_changed)
	fishing_game.back_requested.connect(_on_fishing_back_requested)
	fishing_game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(fishing_game)


func _on_fishing_catch_completed(succeeded: bool, _caught: int, _xp_earned: int) -> void:
	if succeeded:
		save_game()


func _on_fishing_back_requested() -> void:
	# Save the confirmed mid-round heart cost before destroying the game view.
	save_game()
	show_home()


func show_aquarium() -> void:
	leave_desktop_mode()
	ensure_default_pet()
	clear_screen()
	var music_manager := get_node_or_null("/root/MusicManager")
	if music_manager != null:
		music_manager.play_aquarium_music()
	if is_instance_valid(cached_aquarium_screen):
		current_screen = "aquarium"
		aquarium_screen = cached_aquarium_screen
		aquarium_screen.configure(get_progress_stats())
		aquarium_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.add_child(aquarium_screen)
		return

	current_screen = "aquarium_loading"
	aquarium_loading_screen = AquariumLoadingScreenScript.new()
	aquarium_loading_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(aquarium_loading_screen)
	await get_tree().process_frame

	aquarium_screen = AquariumScreenScript.new()
	aquarium_screen.configure(get_progress_stats())
	aquarium_screen.back_requested.connect(show_home)
	aquarium_screen.fish_book_requested.connect(show_fish_book)
	aquarium_screen.visible = false
	aquarium_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(aquarium_screen)
	content.move_child(aquarium_loading_screen, content.get_child_count() - 1)
	await aquarium_screen.prepare_animations_async()

	if (
		current_screen != "aquarium_loading"
		or not is_instance_valid(aquarium_screen)
		or aquarium_screen.get_parent() != content
	):
		return
	cached_aquarium_screen = aquarium_screen
	aquarium_screen.visible = true
	if is_instance_valid(aquarium_loading_screen):
		aquarium_loading_screen.queue_free()
	aquarium_loading_screen = null
	current_screen = "aquarium"


func get_progress_stats() -> Dictionary:
	var raw_stats: Variant = save_data.get(
		PROGRESS_SAVE_KEY,
		save_data.get(LEGACY_PROGRESS_SAVE_KEY, {})
	)
	return _normalize_progress_stats(raw_stats)


func _normalize_progress_stats(value: Variant) -> Dictionary:
	var stats: Dictionary = value if value is Dictionary else {}
	# Keep fields added by current or future minigames. Normalization should fill
	# and sanitize shared fields, not silently erase unrelated progression.
	var normalized_stats := stats.duplicate(true)
	# These counters belonged exclusively to the removed relay minigame.
	normalized_stats.erase("successful_returns")
	normalized_stats.erase("best_combo")
	var unlocked_fish_ids: Array[String] = []
	for starter_fish_id in FishingGameScript.STARTER_FISH_IDS:
		unlocked_fish_ids.append(starter_fish_id)
	var raw_unlocked_fish_ids: Variant = stats.get("unlocked_fish_ids", [])
	if raw_unlocked_fish_ids is Array:
		for fish_id_value in raw_unlocked_fish_ids:
			var fish_id := str(fish_id_value)
			if fish_id != "" and not unlocked_fish_ids.has(fish_id):
				unlocked_fish_ids.append(fish_id)
	var aquarium_fish_ids := FishCatalogScript.normalize_aquarium_fish_ids(
		stats.get(
			"aquarium_fish_ids",
			FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS
		),
		unlocked_fish_ids
	)
	normalized_stats["experience"] = maxi(0, int(stats.get("experience", 0)))
	normalized_stats["hearts"] = clampi(int(stats.get("hearts", 5)), 0, 5)
	normalized_stats["next_heart_restore_unix"] = maxi(
		0,
		int(stats.get("next_heart_restore_unix", 0))
	)
	normalized_stats["fishing_level"] = maxi(1, int(stats.get("fishing_level", 1)))
	normalized_stats["fishing_retry_level"] = maxi(
		0,
		int(stats.get("fishing_retry_level", 0))
	)
	normalized_stats["fishing_retry_count"] = maxi(
		0,
		int(stats.get("fishing_retry_count", 0))
	)
	normalized_stats["unlocked_fish_ids"] = unlocked_fish_ids
	normalized_stats["aquarium_fish_ids"] = aquarium_fish_ids
	return normalized_stats


func _on_progress_stats_changed(stats: Dictionary) -> void:
	var merged_stats := get_progress_stats()
	for key in stats:
		merged_stats[key] = stats[key]
	save_data[PROGRESS_SAVE_KEY] = _normalize_progress_stats(merged_stats)


func _on_store_cat_purchased(cat_id: String, remaining_experience: int) -> void:
	var stats := get_progress_stats()
	stats["experience"] = maxi(0, remaining_experience)
	save_data[PROGRESS_SAVE_KEY] = _normalize_progress_stats(stats)
	var owned_cat_ids := get_owned_cat_ids()
	if not owned_cat_ids.has(cat_id):
		owned_cat_ids.append(cat_id)
	save_data["owned_cat_ids"] = owned_cat_ids
	var pet_id := _ensure_online_cat_in_pet_pool(cat_id)
	if pet_id != "":
		save_data["active_pet_id"] = pet_id
	save_game()


func _on_store_cat_selected(cat_id: String) -> void:
	var raw_progress: Variant = save_data.get(PROGRESS_SAVE_KEY, {})
	var progress_snapshot: Dictionary = (
		raw_progress.duplicate(true) if raw_progress is Dictionary else {}
	)
	var pet_id := _ensure_online_cat_in_pet_pool(cat_id)
	if pet_id == "" or get_pet_index(pet_id) < 0:
		return
	# Carrying another cat changes identity only. Shared XP, fishing levels,
	# discovered fish, aquarium contents, hearts, and any future progress fields
	# are restored byte-for-byte before the single save.
	save_data["active_pet_id"] = pet_id
	save_data[PROGRESS_SAVE_KEY] = progress_snapshot
	save_game()
	show_home()


func _ensure_online_cat_in_pet_pool(cat_id: String) -> String:
	var normalized_cat_id := cat_id.to_lower()
	var definition = PetCatalogScript.definition_by_catalog_id(normalized_cat_id)
	if definition == null:
		return ""
	var pet_id := str(definition.pet_id)
	if get_pet_index(pet_id) >= 0:
		return pet_id
	var pet_pool := get_pet_pool()
	var new_pet: Dictionary = definition.save_profile()
	new_pet["created_at"] = Time.get_datetime_string_from_system()
	pet_pool.append(new_pet)
	save_data["pet_pool"] = pet_pool
	return pet_id


func _on_aquarium_fish_ids_changed(fish_ids: Array[String]) -> void:
	var stats := get_progress_stats()
	stats["aquarium_fish_ids"] = FishCatalogScript.normalize_aquarium_fish_ids(
		fish_ids,
		stats.unlocked_fish_ids
	)
	save_data[PROGRESS_SAVE_KEY] = _normalize_progress_stats(stats)
	_discard_cached_aquarium()
	save_game()


func _discard_cached_aquarium() -> void:
	if is_instance_valid(cached_aquarium_screen):
		if cached_aquarium_screen.get_parent() != null:
			cached_aquarium_screen.get_parent().remove_child(cached_aquarium_screen)
		cached_aquarium_screen.free()
	cached_aquarium_screen = null


func show_reverse_fetch() -> void:
	leave_desktop_mode()
	ensure_default_pet()
	var pet := get_active_pet()
	clear_screen()
	current_screen = "fetch"
	add_background(Color("#d7d9ad"))
	add_page_title("Reverse fetch", "%s throws the ball. Your job is to retrieve it!" % pet.get("name", "Your pet"))
	fetch_count = 0

	var field := ColorRect.new()
	field.color = Color("#91af83")
	field.position = Vector2(55, 135)
	field.size = Vector2(820, 485)
	content.add_child(field)
	avatar = PetAvatarScript.new()
	avatar.position = Vector2(80, 145)
	avatar.size = Vector2(370, 390)
	avatar.set_pet(pet)
	content.add_child(avatar)
	fetch_ball = Button.new()
	fetch_ball.text = "BALL"
	GameFontStylesScript.apply_button(fetch_ball)
	fetch_ball.position = Vector2(650, 470)
	fetch_ball.size = Vector2(92, 92)
	fetch_ball.add_theme_font_size_override("font_size", 22)
	var ball_style := StyleBoxFlat.new()
	ball_style.bg_color = Color("#e9674d")
	ball_style.set_corner_radius_all(46)
	ball_style.set_border_width_all(5)
	ball_style.border_color = Color("#fff1c8")
	fetch_ball.add_theme_stylebox_override("normal", ball_style)
	fetch_ball.pressed.connect(retrieve_ball)
	content.add_child(fetch_ball)

	var info_panel := make_panel(Color(1.0, 0.98, 0.94, 0.97), 24, 26)
	info_panel.position = Vector2(910, 135)
	info_panel.size = Vector2(315, 485)
	content.add_child(info_panel)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 15)
	info_panel.add_child(info)
	var info_title := make_label("Your turn!", 27)
	GameFontStylesScript.apply_accent(info_title)
	info.add_child(info_title)
	fetch_status_label = make_label("Click the ball and bring it back.", 17, palette.muted)
	fetch_status_label.custom_minimum_size.y = 70
	info.add_child(fetch_status_label)
	fetch_counter_label = make_label("Retrieved: 0", 19)
	info.add_child(fetch_counter_label)
	info.add_child(make_label("The pet is the thrower in this game — a tiny role reversal.", 15, palette.muted))
	var back := make_button("Back home", show_home)
	back.position = Vector2(55, 640)
	content.add_child(back)


func retrieve_ball() -> void:
	fetch_count += 1
	var positions := [
		Vector2(650, 470), Vector2(520, 195), Vector2(740, 275),
		Vector2(475, 465), Vector2(685, 165)
	]
	if is_instance_valid(fetch_ball):
		fetch_ball.position = positions[fetch_count % positions.size()]
	if is_instance_valid(fetch_counter_label):
		fetch_counter_label.text = GameFontStylesScript.display_text("Retrieved: %d" % fetch_count)
	if is_instance_valid(fetch_status_label):
		fetch_status_label.text = GameFontStylesScript.display_text(
			"%s throws it again. Go get it!" % get_active_pet().get("name", "Your pet")
		)
	if is_instance_valid(avatar):
		avatar.set_mood("happy")


func enter_desktop_mode() -> void:
	if desktop_mode or get_active_pet().is_empty():
		return
	if Engine.is_embedded_in_editor():
		launch_external_desktop_companion()
		return
	desktop_mode = true
	# Keep the outgoing screen until show_widget_preview() has cleaned it up.
	widget_following = false
	widget_station_dragging = false
	widget_pet_dragging = false
	widget_pet_at_station = true
	widget_returning_to_station = false
	widget_seconds_outside_station = 0.0
	widget_seconds_since_pet_drag = 0.0
	widget_follow_reaction_remaining = 0.0
	widget_follow_has_target = false
	widget_follow_chasing = false
	if DisplayServer.get_name() != "headless":
		normal_window_size = get_window().size
		normal_window_position = get_window().position
		normal_window_min_size = get_window().min_size
		normal_content_scale_size = get_window().content_scale_size
		normal_window_unresizable = get_window().unresizable
		var screen_index := DisplayServer.window_get_current_screen()
		widget_screen_scale = maxf(1.0, DisplayServer.screen_get_scale(screen_index)) * DESKTOP_WIDGET_SCALE
		var screen_rect := Rect2(DisplayServer.screen_get_usable_rect(screen_index))
		get_viewport().gui_embed_subwindows = false
		widget_station_position = get_initial_station_position(screen_rect)
	else:
		widget_screen_scale = DESKTOP_WIDGET_SCALE
		_initialize_desktop_geometry()
	show_widget_preview()


func launch_external_desktop_companion() -> void:
	# Embedded game windows cannot change window flags or detach at runtime.
	# On macOS, Launch Services creates a clean process that does not inherit the
	# editor's embedding connection. Starting the executable directly would keep
	# that connection and create a windowless process.
	save_game()
	var executable_path := OS.get_executable_path()
	var project_path := ProjectSettings.globalize_path("res://")
	var active_pet_id := str(get_active_pet().get("id", ""))
	var process_id := -1
	if OS.get_name() == "macOS":
		var app_bundle_path := executable_path.get_base_dir().get_base_dir().get_base_dir()
		var launch_arguments := [
			"-na",
			app_bundle_path,
			"--args",
			"--path",
			project_path,
			"--",
			"--desktop-widget"
		]
		if active_pet_id != "":
			launch_arguments.append("--pet=%s" % active_pet_id)
		process_id = OS.create_process(
			"/usr/bin/open",
			launch_arguments
		)
	if process_id > 0:
		get_tree().quit()
	else:
		show_desktop_launch_error()


func _apply_desktop_launch_pet_override(pet_id: String) -> bool:
	# The Desktop companion runs in a fresh process on macOS. Passing the chosen
	# pet explicitly prevents that process from falling back to a stale saved cat.
	if pet_id == "" or get_pet_index(pet_id) < 0:
		return false
	save_data["active_pet_id"] = pet_id
	return true


func show_desktop_launch_error() -> void:
	var message := make_panel(Color(1.0, 0.96, 0.90, 0.98), 18, 18)
	message.position = Vector2(370, 250)
	message.size = Vector2(540, 190)
	content.add_child(message)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	message.add_child(box)
	box.add_child(make_label("Godot blocked the desktop window", 23))
	box.add_child(make_label("Stop the game, open the Game menu in Godot, turn off “Embed Game on Next Play”, then run it again.", 16, palette.muted))
	box.add_child(make_button("Close", func(): message.queue_free(), true, true))


func show_widget_preview() -> void:
	clear_screen()
	current_screen = "widget"
	# Desktop Companion is always music-free, including during pending fades.
	var music_manager := get_node_or_null("/root/MusicManager")
	if music_manager != null:
		music_manager.stop_music(0.0)
	var pet := get_active_pet()
	if pet.is_empty():
		return
	if widget_station_position == Vector2.ZERO:
		_initialize_desktop_geometry()
	_build_station_window()
	_build_desktop_station(pet)
	_build_pet_window(pet)
	if is_instance_valid(station_window):
		_apply_station_window_transparency()
		station_window.show()
		call_deferred("_settle_initial_station_window_order")
		call_deferred("_apply_station_window_transparency")
	set_widget_pet_position(get_station_pet_anchor())
	if is_instance_valid(pet_window):
		_apply_pet_window_transparency()
		pet_window.show()
		call_deferred("_apply_pet_window_transparency")
		_schedule_pet_window_raise()
	if is_instance_valid(station_window):
		_park_main_window_for_desktop()
		station_window.grab_focus()
		call_deferred("_schedule_pet_window_raise")
	widget_pet_at_station = true
	widget_returning_to_station = false
	widget_seconds_outside_station = 0.0
	widget_seconds_since_pet_drag = 0.0
	if is_instance_valid(avatar):
		avatar.stop_move()
		avatar.set_mood("idle")
	_sync_desktop_idle_animation_state()


func _build_station_window() -> void:
	_destroy_station_window()
	if DisplayServer.get_name() == "headless":
		return
	station_window = Window.new()
	station_window.name = "DesktopStationWindow"
	station_window.visible = false
	station_window.size = Vector2i(get_station_pixel_size())
	station_window.content_scale_size = STATION_LOGICAL_SIZE
	station_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	# The 90% desktop scale produces fractional physical heights on Retina
	# displays. Filling the rounded window avoids one-pixel letterbox bars at the
	# left and right edges.
	station_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	# Configure every native flag before adding the window. In particular, this
	# lets macOS create a genuinely borderless transparent NSWindow with no frame.
	station_window.force_native = true
	station_window.transparent_bg = true
	station_window.borderless = true
	station_window.transparent = true
	station_window.transient = false
	station_window.transient_to_focused = false
	station_window.always_on_top = true
	station_window.unresizable = true
	station_window.position = Vector2i(widget_station_position)
	station_window.focus_entered.connect(_schedule_pet_window_raise)
	add_child(station_window)
	_apply_station_window_transparency()


func _apply_station_window_transparency() -> void:
	if not is_instance_valid(station_window):
		return
	station_window.transparent_bg = true
	station_window.borderless = true
	station_window.transparent = true
	station_window.always_on_top = true
	station_window.unresizable = true


func _settle_initial_station_window_order() -> void:
	if not is_instance_valid(station_window):
		return
	station_window.position = Vector2i(widget_station_position) + Vector2i.RIGHT
	if is_instance_valid(pet_window):
		pet_window.position = Vector2i(widget_pet_position) + Vector2i.RIGHT
	call_deferred("_finish_initial_station_window_order")


func _finish_initial_station_window_order() -> void:
	if not is_instance_valid(station_window):
		return
	station_window.position = Vector2i(widget_station_position)
	if is_instance_valid(pet_window):
		pet_window.position = Vector2i(widget_pet_position)
	_schedule_pet_window_raise()


func _park_main_window_for_desktop() -> void:
	# Godot does not allow its main Window to be hidden. Keep it as a fully
	# transparent one-pixel process host far outside the desktop instead; only the
	# purpose-built Station and pet windows remain visible to the user.
	var host_window := get_window()
	host_window.unresizable = true
	host_window.borderless = true
	host_window.always_on_top = false
	get_viewport().transparent_bg = true
	host_window.transparent = true
	host_window.min_size = Vector2i.ONE
	host_window.content_scale_size = Vector2i.ONE
	host_window.size = Vector2i.ONE
	var desktop_rect := get_desktop_screen_rect()
	host_window.position = Vector2i(desktop_rect.position) - Vector2i(4096, 4096)


func _destroy_station_window() -> void:
	if is_instance_valid(station_window):
		station_window.hide()
		station_window.queue_free()
	station_window = null
	desktop_station = null
	station_top_art = null
	station_drag_handle = null
	follow_button = null


func _build_desktop_station(pet: Dictionary) -> void:
	var station_id := get_pet_station_id(pet)
	var theme := get_desktop_station_theme(station_id)
	desktop_station = Panel.new()
	desktop_station.name = "DesktopStation"
	desktop_station.position = Vector2.ZERO
	desktop_station.size = Vector2(STATION_LOGICAL_SIZE)
	desktop_station.set_meta("station_id", station_id)
	desktop_station.set_meta("top_kind", str(theme.motif))
	var transparent_style := StyleBoxEmpty.new()
	desktop_station.add_theme_stylebox_override("panel", transparent_style)
	desktop_station.mouse_filter = Control.MOUSE_FILTER_STOP
	desktop_station.mouse_default_cursor_shape = Control.CURSOR_MOVE
	desktop_station.gui_input.connect(_on_station_drag_input)
	if is_instance_valid(station_window):
		station_window.add_child(desktop_station)
	else:
		content.add_child(desktop_station)
	station_drag_handle = desktop_station

	station_top_art = _make_station_top_art(station_id, theme)
	desktop_station.add_child(station_top_art)

	var controls_panel := Panel.new()
	controls_panel.name = "StationControlsPanel"
	controls_panel.position = Vector2(0, STATION_CONTROLS_Y)
	controls_panel.size = Vector2(STATION_LOGICAL_SIZE.x, STATION_LOGICAL_SIZE.y - STATION_CONTROLS_Y)
	controls_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	controls_panel.add_theme_stylebox_override("panel", _station_controls_style())
	desktop_station.add_child(controls_panel)

	var go_home_button := _make_station_button("Go Home", restore_from_widget)
	go_home_button.name = "GoHomeButton"
	go_home_button.position = Vector2(12, 13)
	go_home_button.size = Vector2(104, 50)
	controls_panel.add_child(go_home_button)
	follow_button = _make_station_button("Follow Me", toggle_widget_follow, true)
	follow_button.name = "FollowButton"
	follow_button.position = Vector2(128, 13)
	follow_button.size = Vector2(104, 50)
	controls_panel.add_child(follow_button)
	var quit_button := _make_station_button("Quit", quit_from_widget)
	quit_button.position = Vector2(244, 13)
	quit_button.size = Vector2(104, 50)
	controls_panel.add_child(quit_button)

func _make_station_top_art(station_id: String, theme: Dictionary) -> Control:
	var definition = PetCatalogScript.definition_by_catalog_id(station_id)
	if definition != null:
		var art := Control.new()
		art.name = "StationTopArt"
		art.position = STATION_TOP_ART_POSITION
		art.size = STATION_TOP_ART_SIZE
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var source_texture: Texture2D = definition.load_texture("station")
		var source_image := source_texture.get_image()
		var visible_region := _station_art_visible_region(source_image)
		if visible_region.size == Vector2i.ZERO:
			visible_region = Rect2i(Vector2i.ZERO, source_image.get_size())
		var cropped_texture := AtlasTexture.new()
		cropped_texture.atlas = source_texture
		cropped_texture.region = Rect2(visible_region)
		var visible_size := Vector2(visible_region.size)
		var fit_scale := minf(
			STATION_TOP_ART_SIZE.x / visible_size.x,
			STATION_TOP_ART_SIZE.y / visible_size.y
		)
		var rendered_size := visible_size * fit_scale
		var artwork := TextureRect.new()
		artwork.name = "Artwork"
		artwork.texture = cropped_texture
		artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		artwork.stretch_mode = TextureRect.STRETCH_SCALE
		artwork.position = Vector2(
			(STATION_TOP_ART_SIZE.x - rendered_size.x) * 0.5,
			STATION_TOP_ART_SIZE.y - rendered_size.y
		)
		artwork.size = rendered_size
		artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(artwork)
		return art
	var placeholder := Panel.new()
	placeholder.name = "StationTopArt"
	placeholder.position = STATION_TOP_ART_POSITION
	placeholder.size = STATION_TOP_ART_SIZE
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var placeholder_style := StyleBoxFlat.new()
	placeholder_style.bg_color = Color(str(theme.primary))
	placeholder_style.set_corner_radius_all(25)
	placeholder.add_theme_stylebox_override("panel", placeholder_style)
	return placeholder


func _station_art_visible_region(source_image: Image) -> Rect2i:
	# Generated station art can retain almost-transparent background pixels.
	# Ignoring that invisible residue keeps the visible cushion/grass flush with
	# the shared controls panel instead of leaving a noticeable gap above it.
	var image_size := source_image.get_size()
	var min_x := image_size.x
	var min_y := image_size.y
	var max_x := -1
	var max_y := -1
	for y in range(image_size.y):
		for x in range(image_size.x):
			if source_image.get_pixel(x, y).a < STATION_ART_VISIBLE_ALPHA_THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _station_controls_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f6dfb3")
	style.border_color = Color("#a96b45")
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0.18, 0.09, 0.05, 0.22)
	style.shadow_size = 7
	return style


func _make_station_button(text: String, action: Callable, accent := false) -> Button:
	var button := Button.new()
	button.text = GameFontStylesScript.display_text(text)
	GameFontStylesScript.apply_regular(button)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#654033"))
	button.add_theme_color_override("font_hover_color", Color("#4f342c"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#dcebb2") if accent else Color("#fff6df")
	normal.border_color = Color("#789453") if accent else Color("#bd835b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(25)
	normal.shadow_color = Color(0.18, 0.09, 0.05, 0.16)
	normal.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#ebf6c9") if accent else Color("#fffdf4")
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("#c6da91") if accent else Color("#f1d6ae")
	pressed.shadow_size = 1
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(action)
	return button


func _build_pet_window(pet: Dictionary) -> void:
	_destroy_pet_window()
	var pet_root := Control.new()
	pet_root.name = "DesktopPetRoot"
	pet_root.size = Vector2(PET_WIDGET_LOGICAL_SIZE)
	if DisplayServer.get_name() == "headless":
		pet_root.visible = false
		content.add_child(pet_root)
	else:
		pet_window = Window.new()
		pet_window.name = "DesktopPetWindow"
		pet_window.visible = false
		pet_window.size = Vector2i(get_pet_widget_pixel_size())
		pet_window.content_scale_size = PET_WIDGET_LOGICAL_SIZE
		pet_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		pet_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
		# A separate native window lets the cat move independently from its station.
		# Transparent BG must be enabled before the native transparent flag is applied;
		# otherwise macOS clears transparent pixels to black.
		pet_window.force_native = true
		pet_window.transparent_bg = true
		pet_window.borderless = true
		pet_window.transparent = true
		# Keep the cat in an independent top-level native window. macOS can place a
		# transparent transient child behind its parent after the parent is moved or
		# focused, which made the cat slip behind the Station. Re-raising this
		# independent window keeps the cat in front without stealing button focus.
		pet_window.transient = false
		pet_window.transient_to_focused = false
		pet_window.always_on_top = true
		pet_window.unresizable = true
		add_child(pet_window)
		_apply_pet_window_transparency()
		pet_window.add_child(pet_root)
	# When the cat is seated, draw a copy of the Station art inside the cat's
	# native window. This gives the mat and cat one deterministic canvas z-order;
	# macOS otherwise freely reorders their two transparent top-level windows.
	if is_instance_valid(station_top_art):
		pet_station_top_art = station_top_art.duplicate()
		pet_station_top_art.name = "PetStationTopArt"
		pet_station_top_art.position += Vector2(
			(PET_WIDGET_LOGICAL_SIZE.x - STATION_LOGICAL_SIZE.x) * 0.5,
			PET_WIDGET_LOGICAL_SIZE.y - STATION_PET_FOOT_Y
		)
		pet_station_top_art.visible = false
		pet_root.add_child(pet_station_top_art)
	avatar = PetAvatarScript.new()
	avatar.position = Vector2.ZERO
	avatar.size = Vector2(PET_WIDGET_LOGICAL_SIZE)
	avatar.set_pet(pet)
	pet_root.add_child(avatar)
	pet_drag_surface = Control.new()
	pet_drag_surface.name = "PetDragSurface"
	pet_drag_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pet_drag_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	pet_drag_surface.mouse_default_cursor_shape = Control.CURSOR_DRAG
	pet_drag_surface.gui_input.connect(_on_pet_drag_input)
	pet_root.add_child(pet_drag_surface)


func _apply_pet_window_transparency() -> void:
	if not is_instance_valid(pet_window):
		return
	pet_window.transparent_bg = true
	pet_window.borderless = true
	pet_window.transparent = true
	pet_window.always_on_top = true


func _schedule_pet_window_raise() -> void:
	if pet_window_raise_pending or not is_instance_valid(pet_window):
		return
	pet_window_raise_pending = true
	# Native macOS ordering settles one frame after a transparent window moves or
	# receives focus. Apply the cat order on the following frame.
	call_deferred("_defer_pet_window_raise_once")


func _defer_pet_window_raise_once() -> void:
	call_deferred("_raise_pet_window_above_station")


func _raise_pet_window_above_station() -> void:
	pet_window_raise_pending = false
	if not is_instance_valid(pet_window) or not pet_window.visible:
		return
	# Native top-level windows do not share the Control-node z-order. Re-apply the
	# Station first and the cat second so the mat stays underneath the cat even
	# after the Station receives focus or either window moves between displays.
	if is_instance_valid(station_window) and station_window.visible:
		station_window.always_on_top = false
		station_window.always_on_top = true
	pet_window.always_on_top = false
	pet_window.always_on_top = true


func _destroy_pet_window() -> void:
	if is_instance_valid(pet_window):
		pet_window.hide()
		pet_window.queue_free()
	pet_window = null
	pet_drag_surface = null
	pet_station_top_art = null
	pet_window_raise_pending = false


func get_pet_station_id(pet: Dictionary) -> String:
	var pet_id := str(pet.get("id", "")).to_lower()
	var definition = PetCatalogScript.definition_by_pet_id(pet_id)
	if definition != null:
		return definition.catalog_id
	var name_id := str(pet.get("name", "maple")).to_lower()
	return name_id if PetCatalogScript.definition_by_catalog_id(name_id) != null else "maple"


func get_desktop_station_theme(station_id: String) -> Dictionary:
	var normalized_id := station_id.to_lower()
	var definition = PetCatalogScript.definition_by_catalog_id(normalized_id)
	if definition == null:
		definition = PetCatalogScript.default_definition()
	var theme: Dictionary = definition.station_theme.duplicate(true)
	theme["id"] = definition.catalog_id
	return theme


func _initialize_desktop_geometry() -> void:
	var screen_rect := get_current_desktop_screen_rect()
	widget_station_position = get_initial_station_position(screen_rect)
	widget_pet_position = get_station_pet_anchor()


func get_initial_station_position(screen_rect: Rect2) -> Vector2:
	var station_size := get_station_pixel_size()
	var pet_size := get_pet_widget_pixel_size()
	var scaled_margin := Vector2(STATION_SCREEN_MARGIN) * widget_screen_scale
	# The movement window is wider than the Station so stretched running poses keep
	# the same visual scale. Leave enough room to keep that transparent window
	# centered over the grass without extending beyond the edge of the display.
	var pet_side_overhang := maxf(0.0, (pet_size.x - station_size.x) * 0.5)
	var right_clearance := maxf(scaled_margin.x, pet_side_overhang)
	return Vector2(
		screen_rect.end.x - station_size.x - right_clearance,
		screen_rect.end.y - station_size.y - scaled_margin.y
	)


func get_station_pixel_size() -> Vector2:
	var scaled_size := Vector2(STATION_LOGICAL_SIZE) * widget_screen_scale
	return Vector2(roundf(scaled_size.x), roundf(scaled_size.y))


func get_pet_widget_pixel_size() -> Vector2:
	var scaled_size := Vector2(PET_WIDGET_LOGICAL_SIZE) * widget_screen_scale
	return Vector2(roundf(scaled_size.x), roundf(scaled_size.y))


func get_station_pet_anchor() -> Vector2:
	var station_size := get_station_pixel_size()
	var pet_size := get_pet_widget_pixel_size()
	return widget_station_position + Vector2(
		(station_size.x - pet_size.x) * 0.5,
		-pet_size.y + STATION_PET_FOOT_Y * widget_screen_scale
	)


func get_station_wake_rect() -> Rect2:
	var station_size := get_station_pixel_size()
	return Rect2(
		widget_station_position + Vector2(0.0, -station_size.x),
		Vector2(station_size.x, station_size.x)
	)


func get_pet_screen_rect() -> Rect2:
	return Rect2(widget_pet_position, get_pet_widget_pixel_size())


func set_widget_station_position(value: Vector2) -> void:
	widget_station_position = clamp_desktop_item_position(value, get_station_pixel_size())
	if is_instance_valid(station_window):
		station_window.position = Vector2i(widget_station_position)
	if widget_pet_at_station and not widget_pet_dragging and not widget_following:
		set_widget_pet_position(get_station_pet_anchor())
		if is_instance_valid(avatar):
			avatar.stop_move()
	_schedule_pet_window_raise()


func set_widget_pet_position(value: Vector2, clamp_to_screen := true) -> void:
	# Slow Follow Me movement must be allowed to cross the seam between displays.
	# Its final target is already clamped to a real screen; clamping every small
	# intermediate step would pin the window to the edge of its current display.
	widget_pet_position = (
		clamp_desktop_item_position(value, get_pet_widget_pixel_size())
		if clamp_to_screen
		else value
	)
	if is_instance_valid(pet_window):
		pet_window.position = Vector2i(widget_pet_position)
	_schedule_pet_window_raise()


func clamp_desktop_item_position(value: Vector2, item_size: Vector2) -> Vector2:
	return clamp_desktop_item_position_to_screens(value, item_size, get_desktop_screen_rects())


func clamp_desktop_item_position_to_screens(
	value: Vector2,
	item_size: Vector2,
	screen_rects: Array[Rect2]
) -> Vector2:
	if screen_rects.is_empty():
		return value
	var item_center := value + item_size * 0.5
	var target_screen := screen_rects[0]
	var closest_distance_squared := INF
	for screen_rect in screen_rects:
		if screen_rect.has_point(item_center):
			target_screen = screen_rect
			closest_distance_squared = 0.0
			break
		var closest_point := Vector2(
			clampf(item_center.x, screen_rect.position.x, screen_rect.end.x),
			clampf(item_center.y, screen_rect.position.y, screen_rect.end.y)
		)
		var distance_squared := item_center.distance_squared_to(closest_point)
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			target_screen = screen_rect
	var screen_origin := target_screen.position
	var screen_size := target_screen.size
	return Vector2(
		clampf(value.x, screen_origin.x, screen_origin.x + maxf(0.0, screen_size.x - item_size.x)),
		clampf(value.y, screen_origin.y, screen_origin.y + maxf(0.0, screen_size.y - item_size.y))
	)


func get_desktop_screen_rects() -> Array[Rect2]:
	var screen_rects: Array[Rect2] = []
	if DisplayServer.get_name() == "headless":
		screen_rects.append(Rect2(0.0, 0.0, 1280.0, 720.0))
		return screen_rects
	for screen_index in range(DisplayServer.get_screen_count()):
		screen_rects.append(Rect2(DisplayServer.screen_get_usable_rect(screen_index)))
	return screen_rects


func get_desktop_screen_rect() -> Rect2:
	var screen_rects := get_desktop_screen_rects()
	if screen_rects.is_empty():
		return Rect2()
	var desktop_rect := screen_rects[0]
	for screen_index in range(1, screen_rects.size()):
		desktop_rect = desktop_rect.merge(screen_rects[screen_index])
	return desktop_rect


func get_current_desktop_screen_rect() -> Rect2:
	if DisplayServer.get_name() == "headless":
		return get_desktop_screen_rects()[0]
	return Rect2(DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()))


func _on_station_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		widget_station_dragging = event.pressed
		if event.pressed:
			widget_station_drag_start_mouse = get_desktop_pointer_position()
			widget_station_drag_start_position = widget_station_position
		station_drag_handle.accept_event()
	elif event is InputEventMouseMotion and widget_station_dragging:
		set_widget_station_position(
			widget_station_drag_start_position
			+ get_desktop_pointer_position()
			- widget_station_drag_start_mouse
		)
		station_drag_handle.accept_event()


func _on_pet_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.double_click:
			widget_pet_dragging = false
			avatar.play_belly_roll()
			pet_drag_surface.accept_event()
			return
		widget_pet_dragging = event.pressed
		if event.pressed:
			widget_pet_drag_start_mouse = get_desktop_pointer_position()
			widget_pet_drag_start_position = widget_pet_position
			widget_pet_at_station = false
			widget_returning_to_station = false
			widget_seconds_since_pet_drag = 0.0
			if is_instance_valid(avatar):
				avatar.set_mood("idle")
			_sync_desktop_station_art_layer()
		pet_drag_surface.accept_event()
	elif event is InputEventMouseMotion and widget_pet_dragging:
		var next_position := (
			widget_pet_drag_start_position
			+ get_desktop_pointer_position()
			- widget_pet_drag_start_mouse
		)
		if is_instance_valid(avatar):
			avatar.play_move(next_position - widget_pet_position)
		set_widget_pet_position(next_position)
		widget_seconds_since_pet_drag = 0.0
		pet_drag_surface.accept_event()


func get_desktop_pointer_position() -> Vector2:
	if DisplayServer.get_name() == "headless":
		return widget_pet_position + get_pet_widget_pixel_size() * 0.5
	return Vector2(DisplayServer.mouse_get_position())


func toggle_widget_follow() -> void:
	set_widget_following(not widget_following)


func set_widget_following(enabled: bool) -> void:
	widget_following = enabled
	widget_returning_to_station = false
	widget_seconds_since_pet_drag = 0.0
	widget_follow_reaction_remaining = 0.0
	widget_follow_has_target = false
	widget_follow_chasing = false
	widget_follow_target = widget_pet_position
	widget_follow_last_pointer = get_desktop_pointer_position()
	if is_instance_valid(follow_button):
		follow_button.text = "UNFOLLOW" if enabled else "FOLLOW ME"
	if is_instance_valid(avatar):
		avatar.stop_move()
		avatar.set_mood("follow" if enabled else "idle")
	if enabled:
		# The current pointer is already a target; no extra mouse movement is
		# required after clicking Follow Me.
		_update_widget_follow_target(widget_follow_last_pointer)
		if widget_follow_target.distance_to(widget_pet_position) > PET_FOLLOW_RESUME_DISTANCE * widget_screen_scale:
			_start_widget_follow_chase()
	else:
		widget_pet_at_station = widget_pet_position.distance_to(get_station_pet_anchor()) < 3.0
		widget_returning_to_station = not widget_pet_at_station
	_sync_desktop_idle_animation_state()


func _update_widget_follow_target(pointer_position: Vector2) -> void:
	widget_follow_last_pointer = pointer_position
	widget_follow_target = (
		pointer_position
		- get_pet_widget_pixel_size() * 0.5
		+ Vector2(28.0, 28.0) * widget_screen_scale
	)
	widget_follow_target = clamp_desktop_item_position(widget_follow_target, get_pet_widget_pixel_size())
	widget_follow_has_target = true


func _start_widget_follow_chase() -> void:
	# Only an idle-to-chasing transition gets a reaction delay. Retargeting a
	# moving pointer must never restart the timer or stop an already moving cat.
	widget_follow_chasing = true
	widget_follow_reaction_remaining = randf_range(PET_FOLLOW_REACTION_MIN, PET_FOLLOW_REACTION_MAX)
	if is_instance_valid(avatar):
		avatar.stop_move()


func _stop_widget_follow_chase() -> void:
	widget_follow_chasing = false
	widget_follow_reaction_remaining = 0.0
	if is_instance_valid(avatar):
		avatar.stop_move()


func _sync_desktop_station_art_layer() -> void:
	# At Home the visible mat lives in the same native window as the cat and is
	# inserted before the avatar, so it cannot cover the cat. Once the cat leaves,
	# restore the original Station-window art so the empty bed stays behind.
	var use_pet_window_art := widget_pet_at_station
	if is_instance_valid(station_top_art):
		station_top_art.visible = not use_pet_window_art
	if is_instance_valid(pet_station_top_art):
		pet_station_top_art.visible = use_pet_window_art


func _sync_desktop_idle_animation_state() -> void:
	_sync_desktop_station_art_layer()
	if not is_instance_valid(avatar):
		return
	avatar.set_desktop_idle_enabled(
		desktop_mode
		and widget_pet_at_station
		and not widget_pet_dragging
		and not widget_following
		and not widget_returning_to_station
		and avatar.mood == "idle"
	)


func update_desktop_companion(delta: float, pointer_override := Vector2(-1000000.0, -1000000.0)) -> void:
	if not is_instance_valid(avatar):
		return
	if widget_station_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		widget_station_dragging = false
	if widget_pet_dragging and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		widget_pet_dragging = false
		widget_seconds_since_pet_drag = 0.0
	_sync_desktop_idle_animation_state()
	var pointer_position := pointer_override
	if pointer_position.x <= -999999.0:
		pointer_position = get_desktop_pointer_position()

	var pointer_in_station_space := get_station_wake_rect().has_point(pointer_position)
	var pointer_on_pet := get_pet_screen_rect().has_point(pointer_position)
	if (
		pointer_in_station_space
		or pointer_on_pet
		or widget_following
		or widget_pet_dragging
		or widget_returning_to_station
	):
		widget_seconds_outside_station = 0.0
	else:
		widget_seconds_outside_station += delta

	if widget_following and not widget_pet_dragging:
		avatar.set_mood("follow")
		_update_widget_follow_target(pointer_position)
		if avatar.is_playing_interaction():
			_sync_desktop_idle_animation_state()
			return
		var follow_displacement := widget_follow_target - widget_pet_position
		var arrival_distance := PET_FOLLOW_ARRIVAL_DISTANCE * widget_screen_scale
		var resume_distance := PET_FOLLOW_RESUME_DISTANCE * widget_screen_scale
		# Use different stop/restart radii so small cursor movements near a
		# settled cat do not make it repeatedly change between idle and walking.
		if follow_displacement.length() <= arrival_distance:
			_stop_widget_follow_chase()
			_sync_desktop_idle_animation_state()
			return
		if not widget_follow_chasing:
			if follow_displacement.length() <= resume_distance:
				avatar.stop_move()
				_sync_desktop_idle_animation_state()
				return
			_start_widget_follow_chase()
		var movement_delta := maxf(0.0, delta)
		if widget_follow_reaction_remaining > 0.0:
			var reaction_delta := minf(movement_delta, widget_follow_reaction_remaining)
			widget_follow_reaction_remaining -= reaction_delta
			movement_delta -= reaction_delta
		if movement_delta > 0.0:
			# Keep the approved speed and stop at the near radius without snapping
			# onto the cursor, even when one update has a large delta.
			var follow_distance := minf(
				PET_FOLLOW_RUN_SPEED * widget_screen_scale * movement_delta,
				follow_displacement.length() - arrival_distance
			)
			var next_follow_position := widget_pet_position.move_toward(widget_follow_target, follow_distance)
			avatar.play_move(next_follow_position - widget_pet_position)
			set_widget_pet_position(next_follow_position, false)
			widget_pet_at_station = false
			if widget_pet_position.distance_to(widget_follow_target) <= arrival_distance + 0.001:
				_stop_widget_follow_chase()
		_sync_desktop_idle_animation_state()
		return

	if pointer_on_pet:
		if avatar.mood == "sleep":
			avatar.set_mood("idle")
	elif widget_seconds_outside_station >= STATION_WAKE_SECONDS and not widget_pet_dragging:
		avatar.set_mood("sleep")

	if avatar.is_playing_interaction():
		_sync_desktop_idle_animation_state()
		return

	if not widget_pet_at_station and not widget_pet_dragging:
		widget_seconds_since_pet_drag += delta
		if widget_seconds_since_pet_drag >= PET_RETURN_SECONDS:
			widget_returning_to_station = true
	if widget_returning_to_station and not widget_pet_dragging:
		# Returning is active movement, so it must keep the cat awake and restart
		# the sleep countdown only after the cat has reached the Station.
		widget_seconds_outside_station = 0.0
		var station_target := get_station_pet_anchor()
		# Use the same fixed walking speed as Follow Me. Interpolating a fraction
		# of the remaining distance made distant cats rush back to the Station.
		var return_distance := PET_FOLLOW_RUN_SPEED * widget_screen_scale * maxf(0.0, delta)
		var next_return_position := widget_pet_position.move_toward(station_target, return_distance)
		avatar.set_mood("idle")
		avatar.play_move(next_return_position - widget_pet_position)
		# Just like Follow Me, the return path must be allowed to pass through a
		# display seam. Clamping every intermediate point can pin the native pet
		# window to the edge of the display it is leaving.
		set_widget_pet_position(next_return_position, false)
		if widget_pet_position == station_target:
			set_widget_pet_position(station_target)
			widget_pet_at_station = true
			widget_returning_to_station = false
			widget_seconds_since_pet_drag = 0.0
			avatar.stop_move()
			avatar.set_mood("idle")
			_schedule_pet_window_raise()
	_sync_desktop_idle_animation_state()


func restore_from_widget() -> void:
	leave_desktop_mode()
	show_home()
	if DisplayServer.get_name() != "headless":
		call_deferred("_focus_main_window_after_desktop")


func _focus_main_window_after_desktop() -> void:
	if desktop_mode or DisplayServer.get_name() == "headless":
		return
	get_window().show()
	get_window().grab_focus()


func leave_desktop_mode() -> void:
	if not desktop_mode:
		return
	desktop_mode = false
	if is_instance_valid(avatar):
		avatar.set_desktop_idle_enabled(false)
	set_widget_following(false)
	_destroy_pet_window()
	_destroy_station_window()
	if DisplayServer.get_name() != "headless":
		get_window().show()
		get_window().transparent = false
		get_viewport().transparent_bg = false
		get_viewport().gui_embed_subwindows = true
		get_window().borderless = false
		get_window().always_on_top = false
		get_window().unresizable = normal_window_unresizable
		get_window().min_size = normal_window_min_size
		get_window().content_scale_size = normal_content_scale_size
		get_window().size = normal_window_size
		get_window().position = normal_window_position


func quit_from_widget() -> void:
	save_game()
	get_tree().quit()


func ensure_default_pet() -> void:
	var pool := get_pet_pool()
	var changed := false
	if pool.is_empty():
		var default_pet: Dictionary = PetCatalogScript.default_definition().save_profile()
		default_pet["created_at"] = Time.get_datetime_string_from_system()
		pool = [default_pet]
		save_data["pet_pool"] = pool
		save_data["active_pet_id"] = default_pet.id
		changed = true
	elif get_active_pet_index() < 0:
		save_data["active_pet_id"] = str(pool[0].get("id", "default_orange_cat"))
		changed = true
	var owned_cat_ids := get_owned_cat_ids()
	for cat_id in PetCatalogScript.catalog_ids():
		if not owned_cat_ids.has(cat_id):
			continue
		var definition = PetCatalogScript.definition_by_catalog_id(cat_id)
		if get_pet_index(str(definition.pet_id)) < 0:
			_ensure_online_cat_in_pet_pool(cat_id)
			changed = true
	if not save_data.has("owned_cat_ids") or save_data.get("owned_cat_ids") != owned_cat_ids:
		save_data["owned_cat_ids"] = owned_cat_ids
		changed = true
	if changed:
		save_game()


func select_pet(pet_id: String) -> bool:
	if get_pet_index(pet_id) < 0:
		return false
	save_data["active_pet_id"] = pet_id
	save_game()
	return true


func get_pet_pool() -> Array:
	var pool = save_data.get("pet_pool", [])
	return pool if pool is Array else []


func get_owned_cat_ids() -> Array:
	var raw_ids = save_data.get("owned_cat_ids", ["maple"])
	var normalized: Array[String] = []
	if raw_ids is Array:
		for raw_id in raw_ids:
			var cat_id := str(raw_id)
			if cat_id != "" and not normalized.has(cat_id):
				normalized.append(cat_id)
	if not normalized.has("maple"):
		normalized.push_front("maple")
	return normalized


func get_pet_index(pet_id: String) -> int:
	var pool := get_pet_pool()
	for index in range(pool.size()):
		if str(pool[index].get("id", "")) == pet_id:
			return index
	return -1


func get_active_pet_index() -> int:
	return get_pet_index(str(save_data.get("active_pet_id", "")))


func get_active_pet() -> Dictionary:
	var index := get_active_pet_index()
	if index < 0:
		return {}
	return get_pet_pool()[index]


func save_game() -> void:
	if not _can_write_save():
		return
	save_data["version"] = CURRENT_SAVE_VERSION
	save_data["last_updated_unix"] = int(Time.get_unix_time_from_system())
	var repository = _get_save_repository()
	var save_error: Error = repository.save(save_data)
	if save_error != OK:
		push_error("Could not save Desktop Pet progress: %s" % repository.last_error_message)


func _can_write_save() -> bool:
	return save_enabled and not preview_session and not save_read_only


func _get_save_repository():
	if save_repository == null:
		save_repository = SaveGameRepositoryScript.new(SAVE_PATH)
	return save_repository


func load_save() -> void:
	var repository = _get_save_repository()
	var load_result = repository.load(CURRENT_SAVE_VERSION)
	if load_result.status == SaveGameRepositoryScript.LoadStatus.FUTURE_VERSION:
		save_read_only = true
		push_warning(load_result.message)
		if load_result.data.has("pet_pool"):
			var future_version := int(load_result.data.get("version", CURRENT_SAVE_VERSION + 1))
			save_data = load_result.data
			normalize_save_data()
			# normalize_save_data() targets this executable's schema. Preserve the
			# original version in memory so no caller mistakes this for writable data.
			save_data["version"] = future_version
		return
	if load_result.status in [
		SaveGameRepositoryScript.LoadStatus.LOADED,
		SaveGameRepositoryScript.LoadStatus.RECOVERED_BACKUP
	] and load_result.data.has("pet_pool"):
		var loaded_version := int(load_result.data.get("version", 0))
		var uses_legacy_progress_key: bool = bool(
			load_result.data.has(LEGACY_PROGRESS_SAVE_KEY)
		)
		save_data = load_result.data
		normalize_save_data()
		if load_result.status == SaveGameRepositoryScript.LoadStatus.RECOVERED_BACKUP:
			push_warning(load_result.message)
		if loaded_version < CURRENT_SAVE_VERSION or uses_legacy_progress_key:
			save_game()
		return
	if load_result.status == SaveGameRepositoryScript.LoadStatus.INVALID:
		push_warning("Desktop Pet could not read the player save. %s" % load_result.message)
	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		migrate_legacy_save()


func normalize_save_data() -> void:
	var saved_version := int(save_data.get("version", 0))
	var raw_owned_cat_ids: Variant = save_data.get("owned_cat_ids", [])
	var relock_development_catalog := saved_version < CURRENT_SAVE_VERSION and raw_owned_cat_ids is Array
	if relock_development_catalog:
		for cat_id in PetCatalogScript.catalog_ids():
			if not raw_owned_cat_ids.has(cat_id):
				relock_development_catalog = false
				break
	if relock_development_catalog:
		# Version 7 temporarily granted every finished cat for QA. Remove that
		# grant once, while preserving XP, fishing, aquarium, and non-cat pets.
		save_data["owned_cat_ids"] = ["maple"]
		save_data["active_pet_id"] = "default_orange_cat"

	var saved_active_pet_id := str(save_data.get("active_pet_id", ""))
	var normalized_candidates: Array = []
	var seen_pet_ids: Array[String] = []
	var raw_pool = save_data.get("pet_pool", [])
	if raw_pool is Array:
		for item in raw_pool:
			if item is Dictionary:
				var pet: Dictionary = item.duplicate(true)
				if (
					relock_development_catalog
					and str(pet.get("type", "Cat")) == "Cat"
					and str(pet.get("id", "")) != "default_orange_cat"
				):
					continue
				if str(pet.get("id", "")) == "":
					pet["id"] = "%d_%d" % [
						int(Time.get_unix_time_from_system() * 1000.0),
						normalized_candidates.size()
					]
				var pet_id := str(pet.get("id", ""))
				if seen_pet_ids.has(pet_id):
					continue
				pet["name"] = str(pet.get("name", "Mochi"))
				var definition = PetCatalogScript.definition_by_pet_id(pet_id)
				if definition != null:
					pet["name"] = definition.display_name
				pet["type"] = str(pet.get("type", "Cat"))
				pet.erase("personality")
				pet.erase("energy")
				normalized_candidates.append(pet)
				seen_pet_ids.append(pet_id)

	var normalized: Array = normalized_candidates.slice(
		0,
		mini(MAX_PETS, normalized_candidates.size())
	)
	if saved_active_pet_id != "":
		var active_candidate: Dictionary = {}
		for candidate_value in normalized_candidates:
			var candidate: Dictionary = candidate_value
			if str(candidate.get("id", "")) == saved_active_pet_id:
				active_candidate = candidate
				break
		if not active_candidate.is_empty():
			var active_is_retained := normalized.any(func(candidate):
				return str(candidate.get("id", "")) == saved_active_pet_id
			)
			if not active_is_retained:
				if normalized.size() >= MAX_PETS:
					normalized[MAX_PETS - 1] = active_candidate
				else:
					normalized.append(active_candidate)
	save_data["pet_pool"] = normalized
	save_data["owned_cat_ids"] = get_owned_cat_ids()
	if get_active_pet_index() < 0 and not normalized.is_empty():
		save_data["active_pet_id"] = normalized[0].id
	var raw_progress: Variant = save_data.get(
		PROGRESS_SAVE_KEY,
		save_data.get(LEGACY_PROGRESS_SAVE_KEY, {})
	)
	save_data[PROGRESS_SAVE_KEY] = _normalize_progress_stats(raw_progress)
	save_data.erase(LEGACY_PROGRESS_SAVE_KEY)
	save_data["version"] = CURRENT_SAVE_VERSION


func migrate_legacy_save() -> void:
	var file := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var legacy = JSON.parse_string(file.get_as_text())
	if not legacy is Dictionary or str(legacy.get("name", "")).strip_edges() == "":
		return
	var legacy_type := "Dog" if str(legacy.get("species", "")) in ["狗", "Dog"] else "Cat"
	var pet_id := "legacy_%d" % int(Time.get_unix_time_from_system() * 1000.0)
	save_data["pet_pool"] = [{
		"id": pet_id,
		"name": str(legacy.get("name", "Mochi")),
		"type": legacy_type,
		"created_at": Time.get_datetime_string_from_system()
	}]
	save_data["active_pet_id"] = pet_id
	save_game()


func _seed_preview_pets(preview_pet_id := "") -> void:
	var active_preview_id := preview_pet_id if preview_pet_id != "" else "demo_1"
	var preview_definition = PetCatalogScript.definition_by_pet_id(active_preview_id)
	var active_preview_name: String = (
		preview_definition.display_name if preview_definition != null else "Maple"
	)
	var preview_owned_cat_ids: Array[String] = ["maple"]
	if preview_definition != null and preview_definition.catalog_id != "maple":
		preview_owned_cat_ids.append(preview_definition.catalog_id)
	save_data = {
		"version": CURRENT_SAVE_VERSION,
		"pet_pool": [
			{"id": active_preview_id, "name": active_preview_name, "type": "Cat"},
			{"id": "demo_2", "name": "Peanut", "type": "Bird"},
			{"id": "demo_3", "name": "Nori", "type": "Little Monster"}
		],
		"active_pet_id": active_preview_id,
		"owned_cat_ids": preview_owned_cat_ids,
		"progress_stats": {
			"experience": 0,
			"hearts": 5,
			"next_heart_restore_unix": 0,
			"fishing_level": 1,
			"unlocked_fish_ids": [],
			"aquarium_fish_ids": []
		},
		"last_updated_unix": int(Time.get_unix_time_from_system())
	}
