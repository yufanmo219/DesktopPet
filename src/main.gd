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
const SaveGameRepositoryScript = preload("res://src/persistence/save_game_repository.gd")
const PlayerProgressScript = preload("res://src/progression/player_progress.gd")
const GameStateStoreScript = preload("res://src/progression/game_state_store.gd")
const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")
const DesktopCompanionControllerScript = preload(
	"res://src/desktop/desktop_companion_controller.gd"
)
const HOME_DAY_TEXTURE: Texture2D = preload("res://assets/ui/home/home_day_layout_v3.png")
const HOME_NIGHT_TEXTURE: Texture2D = preload("res://assets/ui/home/home_night_layout_v3.png")

const HOME_WAKE_AREA := Rect2(0.0, 0.0, 700.0, 720.0)
const HOME_POINTER_MOVE_THRESHOLD := 2.0
const HOME_SLEEP_DELAY_SECONDS := 10.0
const HOME_WELCOME_TEXT_COLOR := Color("#fff3cf")
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
var desktop_controller: DesktopCompanionController = DesktopCompanionControllerScript.new()
var save_enabled := true
var save_read_only := false
var save_repository
var game_state_store = GameStateStoreScript.new()
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
	game_state_store.progress_changed.connect(_on_game_state_progress_changed)
	get_window().min_size = Vector2i(960, 540)
	desktop_controller.name = "DesktopCompanionController"
	add_child(desktop_controller)
	desktop_controller.configure(
		null,
		Callable(self, "get_desktop_pointer_position"),
		Callable(self, "get_desktop_screen_rects")
	)
	desktop_controller.home_requested.connect(restore_from_widget)
	desktop_controller.quit_requested.connect(quit_from_widget)

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
		desktop_controller.update(delta)


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
	fishing_game.configure(pet, get_progress_stats(), game_state_store)
	fishing_game.catch_completed.connect(_on_fishing_catch_completed)
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
	var normalized := _normalize_progress_stats(raw_stats)
	# Keep the compatibility save Dictionary and the runtime model synchronized.
	# Production code mutates the store; this silent refresh also protects debug
	# tools and older tests that still replace save_data directly.
	game_state_store.replace(normalized, false)
	return game_state_store.snapshot()


func _normalize_progress_stats(value: Variant) -> Dictionary:
	var progress = PlayerProgressScript.new()
	progress.load_dictionary(value)
	return progress.to_dictionary()


func _on_game_state_progress_changed(snapshot: Dictionary) -> void:
	save_data[PROGRESS_SAVE_KEY] = snapshot.duplicate(true)


func _on_progress_stats_changed(stats: Dictionary) -> void:
	get_progress_stats()
	game_state_store.merge(stats)


func _on_store_cat_purchased(cat_id: String, remaining_experience: int) -> void:
	get_progress_stats()
	game_state_store.set_experience(remaining_experience)
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
	get_progress_stats()
	game_state_store.replace_aquarium_fish_ids(fish_ids)
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
	desktop_controller.set_fallback_parent(content)
	desktop_controller.start(pet)
	avatar = desktop_controller.avatar


func get_desktop_screen_rects() -> Array[Rect2]:
	var screen_rects: Array[Rect2] = []
	if DisplayServer.get_name() == "headless":
		screen_rects.append(Rect2(0.0, 0.0, 1280.0, 720.0))
		return screen_rects
	for screen_index in range(DisplayServer.get_screen_count()):
		screen_rects.append(Rect2(DisplayServer.screen_get_usable_rect(screen_index)))
	return screen_rects


func get_desktop_pointer_position() -> Vector2:
	if DisplayServer.get_name() == "headless":
		return (
			desktop_controller.widget_pet_position
			+ desktop_controller.get_pet_widget_pixel_size() * 0.5
		)
	return Vector2(DisplayServer.mouse_get_position())


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
	desktop_controller.stop()
	avatar = null


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
