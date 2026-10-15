class_name HomeScreen
extends Control

signal desktop_requested
signal fishing_requested
signal aquarium_requested
signal store_requested

const GameFontStylesScript = preload("res://src/game_font_styles.gd")

const WAKE_AREA := Rect2(0.0, 0.0, 700.0, 720.0)
const POINTER_MOVE_THRESHOLD := 2.0
const SLEEP_DELAY_SECONDS := 10.0
const WELCOME_TEXT_COLOR := Color("#fff3cf")
const TEXT_COLOR := Color("#513c4d")
const ORANGE := Color("#e87942")
const ORANGE_DARK := Color("#bd553f")

@onready var background: TextureRect = $HomeBackground
@onready var welcome_label: Label = $WelcomeLabel
@onready var avatar: PetAvatar = $PetAvatar
@onready var xp_title_label: Label = $HomeXPRow/HomeXPTitleLabel
@onready var xp_value_label: Label = $HomeXPRow/HomeXPValueLabel
@onready var pet_heading_label: Label = $PetHeadingLabel
@onready var desktop_button: Button = $HomeActionsLayer/DesktopButton
@onready var fishing_button: Button = $HomeActionsLayer/FishingButton
@onready var aquarium_button: Button = $HomeActionsLayer/AquariumButton
@onready var store_button: Button = $HomeActionsLayer/StoreButton
@onready var pet_interaction_surface: Control = $HomePetInteractionSurface

var home_entry_pointer_position := Vector2.ZERO
var pointer_has_moved := false
var pointer_outside_elapsed := 0.0

var _pet: Dictionary = {}
var _experience := 0
var _background_texture: Texture2D


func configure(pet: Dictionary, experience: int, background_texture: Texture2D) -> void:
	_pet = pet.duplicate(true)
	_experience = maxi(0, experience)
	_background_texture = background_texture
	if is_node_ready():
		_refresh_content()


func set_experience(experience: int) -> void:
	_experience = maxi(0, experience)
	if is_node_ready():
		xp_value_label.text = GameFontStylesScript.display_text(_experience)


func _ready() -> void:
	_apply_styles()
	_refresh_content()
	desktop_button.pressed.connect(func(): desktop_requested.emit())
	fishing_button.pressed.connect(func(): fishing_requested.emit())
	aquarium_button.pressed.connect(func(): aquarium_requested.emit())
	store_button.pressed.connect(func(): store_requested.emit())
	pet_interaction_surface.gui_input.connect(handle_pet_input)
	home_entry_pointer_position = get_local_mouse_position()


func _process(delta: float) -> void:
	var pointer_position := get_local_mouse_position()
	if not pointer_has_moved:
		pointer_has_moved = (
			pointer_position.distance_to(home_entry_pointer_position)
			>= POINTER_MOVE_THRESHOLD
		)
	update_pointer_state(pointer_position, pointer_has_moved, delta)


func update_pointer_state(
	pointer_position: Vector2,
	has_pointer_moved := true,
	delta := 0.0
) -> void:
	if not is_instance_valid(avatar):
		return
	var pointer_is_in_wake_area := has_pointer_moved and WAKE_AREA.has_point(pointer_position)
	if pointer_is_in_wake_area:
		pointer_outside_elapsed = 0.0
		if avatar.mood != "idle":
			avatar.set_mood("idle")
		return
	if avatar.mood == "sleep":
		pointer_outside_elapsed = 0.0
		return
	pointer_outside_elapsed = minf(
		SLEEP_DELAY_SECONDS,
		pointer_outside_elapsed + maxf(0.0, delta)
	)
	if pointer_outside_elapsed >= SLEEP_DELAY_SECONDS:
		avatar.set_mood("sleep")
		pointer_outside_elapsed = 0.0


func handle_pet_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
		and event.double_click
	):
		avatar.play_belly_roll()
		pet_interaction_surface.accept_event()


func _refresh_content() -> void:
	background.texture = _background_texture
	avatar.set_pet(_pet)
	avatar.set_home_idle_enabled(true)
	avatar.set_mood("idle")
	xp_value_label.text = GameFontStylesScript.display_text(_experience)
	pet_heading_label.text = GameFontStylesScript.display_text(
		"%s is here!" % _pet.get("name", "Companion")
	)


func _apply_styles() -> void:
	welcome_label.text = GameFontStylesScript.display_text(welcome_label.text)
	GameFontStylesScript.apply_accent(welcome_label)
	welcome_label.add_theme_color_override("font_color", WELCOME_TEXT_COLOR)

	xp_title_label.text = GameFontStylesScript.display_text(xp_title_label.text)
	GameFontStylesScript.apply_regular(xp_title_label)
	GameFontStylesScript.apply_accent(xp_value_label)
	GameFontStylesScript.apply_accent(pet_heading_label)

	_style_action_button(desktop_button, true)
	_style_action_button(fishing_button, false)
	_style_action_button(aquarium_button, false)
	_style_action_button(store_button, false)


func _style_action_button(button: Button, accent: bool) -> void:
	button.text = GameFontStylesScript.display_text(button.text)
	if accent:
		GameFontStylesScript.apply_button(button)
	else:
		GameFontStylesScript.apply_regular(button)
	button.add_theme_font_size_override("font_size", 36)
	var text_color: Color = Color.WHITE if accent else TEXT_COLOR
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	var normal := StyleBoxFlat.new()
	normal.bg_color = ORANGE if accent else Color(1.0, 0.975, 0.92, 0.96)
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(2)
	normal.border_color = ORANGE_DARK if accent else Color("#ddc7b2")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = ORANGE_DARK if accent else Color.WHITE
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color("#a84b3a") if accent else Color("#f1dfc9")
	button.add_theme_stylebox_override("pressed", pressed)
