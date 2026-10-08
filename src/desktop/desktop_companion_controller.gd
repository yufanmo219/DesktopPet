class_name DesktopCompanionController
extends Node

signal home_requested
signal quit_requested

const PetAvatarScript = preload("res://src/pet_avatar.gd")
const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const DesktopWindowHostScript = preload("res://src/desktop/desktop_window_host.gd")

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
const PET_FOLLOW_ARRIVAL_DISTANCE := 60.0
const PET_FOLLOW_RESUME_DISTANCE := 100.0

var active := false
var desktop_station: Panel
var station_top_art: Control
var station_drag_handle: Control
var follow_button: Button
var pet_drag_surface: Control
var pet_station_top_art: Control
var avatar: PetAvatar

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

var window_host: DesktopWindowHost
var fallback_parent: Control
var pointer_position_provider: Callable
var screen_rects_provider: Callable
var _pet_root: Control

var station_window: Window:
	get:
		return window_host.station_window if is_instance_valid(window_host) else null

var pet_window: Window:
	get:
		return window_host.pet_window if is_instance_valid(window_host) else null

var pet_window_raise_pending: bool:
	get:
		return (
			window_host.pet_window_raise_pending
			if is_instance_valid(window_host)
			else false
		)

var normal_window_unresizable: bool:
	get:
		return (
			window_host.normal_window_unresizable
			if is_instance_valid(window_host)
			else false
		)


func configure(
	fallback: Control,
	pointer_provider: Callable,
	screens_provider: Callable
) -> void:
	fallback_parent = fallback
	pointer_position_provider = pointer_provider
	screen_rects_provider = screens_provider
	_ensure_window_host()


func set_fallback_parent(value: Control) -> void:
	fallback_parent = value


func start(pet: Dictionary) -> void:
	if active:
		stop()
	_ensure_window_host()
	active = true
	_reset_behavior()
	window_host.capture_main_window()
	if DisplayServer.get_name() != "headless":
		var screen_index := DisplayServer.window_get_current_screen()
		widget_screen_scale = (
			maxf(1.0, DisplayServer.screen_get_scale(screen_index))
			* DESKTOP_WIDGET_SCALE
		)
		get_viewport().gui_embed_subwindows = false
	else:
		widget_screen_scale = DESKTOP_WIDGET_SCALE
	_initialize_desktop_geometry()
	window_host.create_station_window(
		get_station_pixel_size(),
		STATION_LOGICAL_SIZE,
		widget_station_position
	)
	_build_desktop_station(pet)
	window_host.create_pet_window(
		get_pet_widget_pixel_size(),
		PET_WIDGET_LOGICAL_SIZE,
		widget_pet_position
	)
	_build_pet_content(pet)
	set_widget_pet_position(get_station_pet_anchor())
	window_host.show_windows(widget_station_position, widget_pet_position)
	if DisplayServer.get_name() != "headless":
		window_host.park_main_window(get_desktop_screen_rect())
	widget_pet_at_station = true
	widget_returning_to_station = false
	widget_seconds_outside_station = 0.0
	widget_seconds_since_pet_drag = 0.0
	if is_instance_valid(avatar):
		avatar.stop_move()
		avatar.set_mood("idle")
	_sync_desktop_idle_animation_state()


func stop() -> void:
	if not active and not is_instance_valid(desktop_station):
		return
	active = false
	if is_instance_valid(avatar):
		avatar.set_desktop_idle_enabled(false)
	widget_following = false
	_destroy_visuals()
	if is_instance_valid(window_host):
		window_host.shutdown()


func _ensure_window_host() -> void:
	if is_instance_valid(window_host):
		return
	window_host = DesktopWindowHostScript.new()
	window_host.name = "DesktopWindowHost"
	add_child(window_host)


func _reset_behavior() -> void:
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


func _destroy_visuals() -> void:
	if DisplayServer.get_name() == "headless":
		if is_instance_valid(_pet_root):
			_pet_root.queue_free()
		if is_instance_valid(desktop_station):
			desktop_station.queue_free()
	desktop_station = null
	station_top_art = null
	station_drag_handle = null
	follow_button = null
	pet_drag_surface = null
	pet_station_top_art = null
	avatar = null
	_pet_root = null


func _build_desktop_station(pet: Dictionary) -> void:
	var station_id := get_pet_station_id(pet)
	var theme := get_desktop_station_theme(station_id)
	desktop_station = Panel.new()
	desktop_station.name = "DesktopStation"
	desktop_station.position = Vector2.ZERO
	desktop_station.size = Vector2(STATION_LOGICAL_SIZE)
	desktop_station.set_meta("station_id", station_id)
	desktop_station.set_meta("top_kind", str(theme.motif))
	desktop_station.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	desktop_station.mouse_filter = Control.MOUSE_FILTER_STOP
	desktop_station.mouse_default_cursor_shape = Control.CURSOR_MOVE
	desktop_station.gui_input.connect(_on_station_drag_input)
	if is_instance_valid(station_window):
		station_window.add_child(desktop_station)
	elif is_instance_valid(fallback_parent):
		fallback_parent.add_child(desktop_station)
	station_drag_handle = desktop_station

	station_top_art = _make_station_top_art(station_id, theme)
	desktop_station.add_child(station_top_art)

	var controls_panel := Panel.new()
	controls_panel.name = "StationControlsPanel"
	controls_panel.position = Vector2(0, STATION_CONTROLS_Y)
	controls_panel.size = Vector2(
		STATION_LOGICAL_SIZE.x,
		STATION_LOGICAL_SIZE.y - STATION_CONTROLS_Y
	)
	controls_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	controls_panel.add_theme_stylebox_override("panel", _station_controls_style())
	desktop_station.add_child(controls_panel)

	var go_home_button := _make_station_button("Go Home", _request_home)
	go_home_button.name = "GoHomeButton"
	go_home_button.position = Vector2(12, 13)
	go_home_button.size = Vector2(104, 50)
	controls_panel.add_child(go_home_button)
	follow_button = _make_station_button("Follow Me", toggle_widget_follow, true)
	follow_button.name = "FollowButton"
	follow_button.position = Vector2(128, 13)
	follow_button.size = Vector2(104, 50)
	controls_panel.add_child(follow_button)
	var quit_button := _make_station_button("Quit", _request_quit)
	quit_button.name = "QuitButton"
	quit_button.position = Vector2(244, 13)
	quit_button.size = Vector2(104, 50)
	controls_panel.add_child(quit_button)


func _request_home() -> void:
	home_requested.emit()


func _request_quit() -> void:
	quit_requested.emit()


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


func _make_station_button(
	text: String,
	action: Callable,
	accent := false
) -> Button:
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


func _build_pet_content(pet: Dictionary) -> void:
	_pet_root = Control.new()
	_pet_root.name = "DesktopPetRoot"
	_pet_root.size = Vector2(PET_WIDGET_LOGICAL_SIZE)
	if is_instance_valid(pet_window):
		pet_window.add_child(_pet_root)
	elif is_instance_valid(fallback_parent):
		_pet_root.visible = false
		fallback_parent.add_child(_pet_root)
	if is_instance_valid(station_top_art):
		pet_station_top_art = station_top_art.duplicate()
		pet_station_top_art.name = "PetStationTopArt"
		pet_station_top_art.position += Vector2(
			(PET_WIDGET_LOGICAL_SIZE.x - STATION_LOGICAL_SIZE.x) * 0.5,
			PET_WIDGET_LOGICAL_SIZE.y - STATION_PET_FOOT_Y
		)
		pet_station_top_art.visible = false
		_pet_root.add_child(pet_station_top_art)
	avatar = PetAvatarScript.new()
	avatar.position = Vector2.ZERO
	avatar.size = Vector2(PET_WIDGET_LOGICAL_SIZE)
	avatar.set_pet(pet)
	_pet_root.add_child(avatar)
	pet_drag_surface = Control.new()
	pet_drag_surface.name = "PetDragSurface"
	pet_drag_surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pet_drag_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	pet_drag_surface.mouse_default_cursor_shape = Control.CURSOR_DRAG
	pet_drag_surface.gui_input.connect(_on_pet_drag_input)
	_pet_root.add_child(pet_drag_surface)


func get_pet_station_id(pet: Dictionary) -> String:
	var pet_id := str(pet.get("id", "")).to_lower()
	var definition = PetCatalogScript.definition_by_pet_id(pet_id)
	if definition != null:
		return definition.catalog_id
	var name_id := str(pet.get("name", "maple")).to_lower()
	return name_id if PetCatalogScript.definition_by_catalog_id(name_id) != null else "maple"


func get_desktop_station_theme(station_id: String) -> Dictionary:
	var definition = PetCatalogScript.definition_by_catalog_id(station_id.to_lower())
	if definition == null:
		definition = PetCatalogScript.default_definition()
	var theme: Dictionary = definition.station_theme.duplicate(true)
	theme["id"] = definition.catalog_id
	return theme


func _initialize_desktop_geometry() -> void:
	widget_station_position = get_initial_station_position(
		get_current_desktop_screen_rect()
	)
	widget_pet_position = get_station_pet_anchor()


func get_initial_station_position(screen_rect: Rect2) -> Vector2:
	var station_size := get_station_pixel_size()
	var pet_size := get_pet_widget_pixel_size()
	var scaled_margin := Vector2(STATION_SCREEN_MARGIN) * widget_screen_scale
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
	widget_station_position = clamp_desktop_item_position(
		value,
		get_station_pixel_size()
	)
	window_host.set_station_position(widget_station_position)
	if widget_pet_at_station and not widget_pet_dragging and not widget_following:
		set_widget_pet_position(get_station_pet_anchor())
		if is_instance_valid(avatar):
			avatar.stop_move()
	window_host.schedule_pet_window_raise()


func set_widget_pet_position(value: Vector2, clamp_to_screen := true) -> void:
	widget_pet_position = (
		clamp_desktop_item_position(value, get_pet_widget_pixel_size())
		if clamp_to_screen
		else value
	)
	window_host.set_pet_position(widget_pet_position)


func clamp_desktop_item_position(value: Vector2, item_size: Vector2) -> Vector2:
	return clamp_desktop_item_position_to_screens(
		value,
		item_size,
		get_desktop_screen_rects()
	)


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
			break
		var closest_point := Vector2(
			clampf(item_center.x, screen_rect.position.x, screen_rect.end.x),
			clampf(item_center.y, screen_rect.position.y, screen_rect.end.y)
		)
		var distance_squared := item_center.distance_squared_to(closest_point)
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			target_screen = screen_rect
	return Vector2(
		clampf(
			value.x,
			target_screen.position.x,
			target_screen.end.x - item_size.x
		),
		clampf(
			value.y,
			target_screen.position.y,
			target_screen.end.y - item_size.y
		)
	)


func get_desktop_screen_rects() -> Array[Rect2]:
	if pointer_position_provider.is_valid() and screen_rects_provider.is_valid():
		var provided: Variant = screen_rects_provider.call()
		if provided is Array:
			var result: Array[Rect2] = []
			for rect in provided:
				if rect is Rect2:
					result.append(rect)
			if not result.is_empty():
				return result
	if DisplayServer.get_name() == "headless":
		return [Rect2(0.0, 0.0, 1280.0, 720.0)]
	var screen_rects: Array[Rect2] = []
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
	return Rect2(
		DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	)


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
	if pointer_position_provider.is_valid():
		return Vector2(pointer_position_provider.call())
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
		_update_widget_follow_target(widget_follow_last_pointer)
		if (
			widget_follow_target.distance_to(widget_pet_position)
			> PET_FOLLOW_RESUME_DISTANCE * widget_screen_scale
		):
			_start_widget_follow_chase()
	else:
		widget_pet_at_station = (
			widget_pet_position.distance_to(get_station_pet_anchor()) < 3.0
		)
		widget_returning_to_station = not widget_pet_at_station
	_sync_desktop_idle_animation_state()


func _update_widget_follow_target(pointer_position: Vector2) -> void:
	widget_follow_last_pointer = pointer_position
	widget_follow_target = (
		pointer_position
		- get_pet_widget_pixel_size() * 0.5
		+ Vector2(28.0, 28.0) * widget_screen_scale
	)
	widget_follow_target = clamp_desktop_item_position(
		widget_follow_target,
		get_pet_widget_pixel_size()
	)
	widget_follow_has_target = true


func _start_widget_follow_chase() -> void:
	widget_follow_chasing = true
	widget_follow_reaction_remaining = randf_range(
		PET_FOLLOW_REACTION_MIN,
		PET_FOLLOW_REACTION_MAX
	)
	if is_instance_valid(avatar):
		avatar.stop_move()


func _stop_widget_follow_chase() -> void:
	widget_follow_chasing = false
	widget_follow_reaction_remaining = 0.0
	if is_instance_valid(avatar):
		avatar.stop_move()


func _sync_desktop_station_art_layer() -> void:
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
		active
		and widget_pet_at_station
		and not widget_pet_dragging
		and not widget_following
		and not widget_returning_to_station
		and avatar.mood == "idle"
	)


func update(
	delta: float,
	pointer_override := Vector2(-1000000.0, -1000000.0)
) -> void:
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
			var reaction_delta := minf(
				movement_delta,
				widget_follow_reaction_remaining
			)
			widget_follow_reaction_remaining -= reaction_delta
			movement_delta -= reaction_delta
		if movement_delta > 0.0:
			var follow_distance := minf(
				PET_FOLLOW_RUN_SPEED * widget_screen_scale * movement_delta,
				follow_displacement.length() - arrival_distance
			)
			var next_follow_position := widget_pet_position.move_toward(
				widget_follow_target,
				follow_distance
			)
			avatar.play_move(next_follow_position - widget_pet_position)
			set_widget_pet_position(next_follow_position, false)
			widget_pet_at_station = false
			if (
				widget_pet_position.distance_to(widget_follow_target)
				<= arrival_distance + 0.001
			):
				_stop_widget_follow_chase()
		_sync_desktop_idle_animation_state()
		return

	if pointer_on_pet:
		if avatar.mood == "sleep":
			avatar.set_mood("idle")
	elif (
		widget_seconds_outside_station >= STATION_WAKE_SECONDS
		and not widget_pet_dragging
	):
		avatar.set_mood("sleep")

	if avatar.is_playing_interaction():
		_sync_desktop_idle_animation_state()
		return

	if not widget_pet_at_station and not widget_pet_dragging:
		widget_seconds_since_pet_drag += delta
		if widget_seconds_since_pet_drag >= PET_RETURN_SECONDS:
			widget_returning_to_station = true
	if widget_returning_to_station and not widget_pet_dragging:
		widget_seconds_outside_station = 0.0
		var station_target := get_station_pet_anchor()
		var return_distance := (
			PET_FOLLOW_RUN_SPEED
			* widget_screen_scale
			* maxf(0.0, delta)
		)
		var next_return_position := widget_pet_position.move_toward(
			station_target,
			return_distance
		)
		avatar.set_mood("idle")
		avatar.play_move(next_return_position - widget_pet_position)
		set_widget_pet_position(next_return_position, false)
		if widget_pet_position == station_target:
			set_widget_pet_position(station_target)
			widget_pet_at_station = true
			widget_returning_to_station = false
			widget_seconds_since_pet_drag = 0.0
			avatar.stop_move()
			avatar.set_mood("idle")
			window_host.schedule_pet_window_raise()
	_sync_desktop_idle_animation_state()
