class_name FishBookScreen
extends Control

signal back_requested
signal aquarium_fish_ids_changed(fish_ids: Array[String])

const BACKGROUND_TEXTURE: Texture2D = preload("res://assets/ui/store/concepts/adopt_cat_store_background_v3.png")
const LOCK_TEXTURE: Texture2D = preload("res://assets/ui/store/overlays/processed/cat_lock_icon_simple_warm.png")
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const BookShellScene = preload("res://src/catalog/book_shell.tscn")

const FISH_CATALOG_TITLE_TEXT := "Fishipedia"
const SLOT_ORIGIN := Vector2(266, 198)
const SLOT_SIZE := Vector2(110, 110)
const SLOT_STEP := Vector2(116.5, 117.0)
const FISH_PAGE_SIZE := 9
const FISH_PAGE_PREVIOUS_POSITION := Vector2(337, 559)
const FISH_PAGE_NEXT_POSITION := Vector2(568, 559)
const FISH_PAGE_BUTTON_SIZE := Vector2(62, 38)
const FISH_PAGE_LABEL_POSITION := Vector2(404, 561)
const FISH_PAGE_LABEL_SIZE := Vector2(160, 36)
const FISH_SLOT_ICON_CENTER := Vector2(55, 55)
const FISH_SLOT_ICON_MAX_SIZE := Vector2(88, 68)
const FISH_DETAIL_ICON_CENTER := Vector2(173.5, 121)
const FISH_DETAIL_ICON_MAX_SIZE := Vector2(245, 128)
const FISH_LOCKED_DETAIL_ICON_CENTER := Vector2(173.5, 142)
const FISH_LOCKED_DETAIL_ICON_MAX_SIZE := Vector2(255, 142)
const FISH_LOCKED_DETAIL_ICON_MODULATE := Color(0.54, 0.51, 0.48, 0.34)
const FISH_LOCKED_DETAIL_VEIL_POSITION := Vector2(9, 58)
const FISH_LOCKED_DETAIL_VEIL_SIZE := Vector2(329, 174)
const FISH_LOCKED_DETAIL_VEIL_COLOR := Color(0.96, 0.91, 0.79, 0.025)
const FISH_LOCKED_DETAIL_LOCK_CENTER := Vector2(173.5, 144)
const FISH_LOCKED_DETAIL_LOCK_MAX_SIZE := Vector2(76, 102)
const FISH_LOCKED_MESSAGE_POSITION := Vector2(22, 274)
const FISH_LOCKED_MESSAGE_SIZE := Vector2(303, 52)
const FISH_LOCKED_MESSAGE_FONT_SIZE := 27
const FISH_LOCKED_MESSAGE_TEXT := "FISH MORE TO UNLOCK"
const FISH_AQUARIUM_CAPACITY_MESSAGE_POSITION := Vector2(22, 181)
const FISH_AQUARIUM_CAPACITY_MESSAGE_SIZE := Vector2(303, 25)
const FISH_AQUARIUM_BUTTON_POSITION := Vector2(30, 207)
const FISH_AQUARIUM_BUTTON_SIZE := Vector2(287, 52)
const FISH_DESCRIPTION_POSITION := Vector2(27, 270)
const FISH_DESCRIPTION_SIZE := Vector2(293, 76)
const FISH_RARITY_POSITION := Vector2(55, 359)
const FISH_RARITY_SIZE := Vector2(237, 36)
const FISH_CAPACITY_MESSAGE_HOLD_SECONDS := 0.65
const FISH_CAPACITY_MESSAGE_FADE_SECONDS := 0.35

var experience := 0
var unlocked_fish_ids: Array[String] = FishCatalogScript.STARTER_FISH_IDS.duplicate()
var selected_fish_id := "green"
var aquarium_fish_ids: Array[String] = FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS.duplicate()
var active_catalog_tab := "fish"
var fish_page_index := 0

# Compatibility sentinels make the feature boundary explicit to callers.
var cat_grid_layer: Control
var cat_detail_panel: Panel
var fish_grid_layer: Control
var fish_slots_layer: Control
var fish_slot_buttons: Array[Button] = []
var fish_slot_views: Array[Sprite2D] = []
var fish_slot_lock_views: Array[Sprite2D] = []
var fish_slot_selection_frames: Array[Panel] = []
var fish_slot_ids: Array[String] = []
var fish_page_label: Label
var fish_previous_button: Button
var fish_next_button: Button
var fish_next_arrow_label: Label
var store_home_button: Button
var store_title_label: Label
var experience_label: Label
var fish_detail_panel: Panel
var fish_detail_view: Sprite2D
var fish_detail_locked_veil: ColorRect
var fish_detail_lock_view: Sprite2D
var fish_detail_locked_message_label: Label
var fish_detail_name_label: Label
var fish_detail_rarity_label: Label
var fish_detail_description_label: Label
var fish_aquarium_button: Button
var fish_aquarium_capacity_label: Label
var fish_aquarium_capacity_tween: Tween

func configure_book(stats: Dictionary) -> void:
	experience = maxi(0, int(stats.get("experience", 0)))
	unlocked_fish_ids = FishCatalogScript.STARTER_FISH_IDS.duplicate()
	var saved_fish_ids: Variant = stats.get("unlocked_fish_ids", [])
	if saved_fish_ids is Array:
		for fish_id_value in saved_fish_ids:
			var fish_id := str(fish_id_value)
			if fish_id != "" and not unlocked_fish_ids.has(fish_id):
				unlocked_fish_ids.append(fish_id)
	aquarium_fish_ids = FishCatalogScript.normalize_aquarium_fish_ids(
		stats.get(
			"aquarium_fish_ids",
			FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS
		),
		unlocked_fish_ids
	)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_ensure_book_shell()
	_bind_book_shell()
	_build_fish_catalog()
	_build_fish_detail_page()
	select_fish("green")
	store_home_button.move_to_front()

func _ensure_book_shell() -> void:
	if get_node_or_null("CatalogBookShell") == null:
		add_child(BookShellScene.instantiate())

func _bind_book_shell() -> void:
	store_title_label = $CatalogBookShell/CatalogTitle
	store_title_label.name = "FishBookCatalogTitle"
	store_title_label.text = GameFontStylesScript.display_text("Fishipedia")
	GameFontStylesScript.apply_accent(store_title_label)

	experience_label = $CatalogBookShell/ExperienceLabel
	experience_label.name = "FishBookExperienceLabel"
	experience_label.text = GameFontStylesScript.display_text(
		"Your XP: %s" % _format_number(experience)
	)
	GameFontStylesScript.apply_accent(experience_label)

	store_home_button = $CatalogBookShell/BackButton
	store_home_button.name = "FishBookAquariumButton"
	_style_text_button(store_home_button, "← Aquarium")
	store_home_button.pressed.connect(func(): back_requested.emit())

func _build_fish_catalog() -> void:
	fish_grid_layer = Control.new()
	fish_grid_layer.name = "FishCatalogGrid"
	fish_grid_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fish_grid_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fish_grid_layer)

	fish_slots_layer = Control.new()
	fish_slots_layer.name = "FishCatalogSlots"
	fish_slots_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fish_slots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_grid_layer.add_child(fish_slots_layer)

	fish_previous_button = _make_text_button("←")
	fish_previous_button.name = "FishCatalogPreviousPage"
	fish_previous_button.position = FISH_PAGE_PREVIOUS_POSITION
	fish_previous_button.size = FISH_PAGE_BUTTON_SIZE
	fish_previous_button.pressed.connect(func(): _change_fish_page(-1))
	fish_grid_layer.add_child(fish_previous_button)

	fish_page_label = _make_label("", 21, Color("#5b382f"))
	fish_page_label.name = "FishCatalogPageLabel"
	fish_page_label.position = FISH_PAGE_LABEL_POSITION
	fish_page_label.size = FISH_PAGE_LABEL_SIZE
	fish_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_grid_layer.add_child(fish_page_label)

	fish_next_button = _make_text_button("")
	fish_next_button.name = "FishCatalogNextPage"
	fish_next_button.position = FISH_PAGE_NEXT_POSITION
	fish_next_button.size = FISH_PAGE_BUTTON_SIZE
	fish_next_button.pressed.connect(func(): _change_fish_page(1))
	fish_grid_layer.add_child(fish_next_button)

	# The handwritten font contains the user's left-arrow glyph. Mirroring that
	# exact glyph keeps the right arrow in the same handwriting instead of
	# falling back to a formal system-font arrow.
	fish_next_arrow_label = _make_label("←", 28, Color("#5b382f"))
	fish_next_arrow_label.name = "FishCatalogNextPageHandwrittenArrow"
	fish_next_arrow_label.position = Vector2.ZERO
	fish_next_arrow_label.size = FISH_PAGE_BUTTON_SIZE
	fish_next_arrow_label.pivot_offset = FISH_PAGE_BUTTON_SIZE * 0.5
	fish_next_arrow_label.scale = Vector2(-1.0, 1.0)
	fish_next_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_next_arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_next_arrow_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_next_button.add_child(fish_next_arrow_label)

	_rebuild_fish_catalog_page()

func _rebuild_fish_catalog_page() -> void:
	for child in fish_slots_layer.get_children():
		fish_slots_layer.remove_child(child)
		child.queue_free()
	fish_slot_buttons.clear()
	fish_slot_views.clear()
	fish_slot_lock_views.clear()
	fish_slot_selection_frames.clear()
	fish_slot_ids.clear()

	var page_count := ceili(float(FishCatalogScript.FISH_TYPES.size()) / float(FISH_PAGE_SIZE))
	fish_page_index = clampi(fish_page_index, 0, page_count - 1)
	var first_index := fish_page_index * FISH_PAGE_SIZE
	var last_index := mini(first_index + FISH_PAGE_SIZE, FishCatalogScript.FISH_TYPES.size())
	for catalog_index in range(first_index, last_index):
		var fish: Dictionary = FishCatalogScript.FISH_TYPES[catalog_index]
		var local_index := catalog_index - first_index
		var column := local_index % 3
		var row := floori(float(local_index) / 3.0)
		var fish_id := str(fish.get("id", ""))
		var unlocked := is_fish_unlocked(fish_id)

		var slot := Control.new()
		slot.name = "FishSlot%d" % catalog_index
		slot.position = SLOT_ORIGIN + Vector2(column * SLOT_STEP.x, row * SLOT_STEP.y)
		slot.size = SLOT_SIZE
		slot.clip_contents = true
		fish_slots_layer.add_child(slot)

		var fish_view := Sprite2D.new()
		fish_view.name = "FishIcon"
		_fit_fish_sprite(
			fish_view,
			_fish_catalog_texture(fish),
			FISH_SLOT_ICON_CENTER,
			FISH_SLOT_ICON_MAX_SIZE * float(fish.get("fish_book_slot_scale", 1.0))
		)
		fish_view.material = FishCatalogScript.visual_material(fish)
		fish_view.modulate = Color.WHITE if unlocked else Color(0.30, 0.28, 0.25, 0.50)
		slot.add_child(fish_view)
		fish_slot_views.append(fish_view)

		var veil := ColorRect.new()
		veil.name = "FishLockedVeil"
		veil.color = Color(0.34, 0.29, 0.27, 0.28)
		veil.position = Vector2(3, 3)
		veil.size = Vector2(104, 104)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veil.visible = not unlocked
		slot.add_child(veil)

		var lock := Sprite2D.new()
		lock.name = "FishSlotLock"
		lock.texture = LOCK_TEXTURE
		lock.position = Vector2(39, 36)
		lock.centered = false
		lock.scale = Vector2(32.0 / LOCK_TEXTURE.get_width(), 48.0 / LOCK_TEXTURE.get_height())
		lock.visible = not unlocked
		slot.add_child(lock)
		fish_slot_lock_views.append(lock)

		var selection_frame := Panel.new()
		selection_frame.name = "FishSelectionFrame"
		selection_frame.position = Vector2(1, 1)
		selection_frame.size = Vector2(108, 108)
		selection_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selection_frame.add_theme_stylebox_override("panel", _fish_selection_style())
		selection_frame.visible = selected_fish_id == fish_id
		slot.add_child(selection_frame)
		fish_slot_selection_frames.append(selection_frame)

		var button := Button.new()
		button.name = "FishSlotButton%d" % catalog_index
		button.tooltip_text = GameFontStylesScript.display_text(
			str(fish.get("name", "")) if unlocked else FISH_LOCKED_MESSAGE_TEXT
		)
		button.position = Vector2.ZERO
		button.size = SLOT_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _transparent_button_style())
		button.add_theme_stylebox_override("hover", _slot_hover_style())
		button.add_theme_stylebox_override("pressed", _slot_hover_style())
		button.pressed.connect(func(): select_fish(fish_id))
		slot.add_child(button)
		fish_slot_buttons.append(button)
		fish_slot_ids.append(fish_id)

	fish_page_label.text = "PAGE %d / %d" % [fish_page_index + 1, page_count]
	fish_previous_button.disabled = fish_page_index <= 0
	fish_next_button.disabled = fish_page_index >= page_count - 1
	fish_next_arrow_label.modulate.a = 0.42 if fish_next_button.disabled else 1.0

func _change_fish_page(direction: int) -> void:
	var page_count := ceili(float(FishCatalogScript.FISH_TYPES.size()) / float(FISH_PAGE_SIZE))
	var next_page := clampi(fish_page_index + direction, 0, page_count - 1)
	if next_page == fish_page_index:
		return
	fish_page_index = next_page
	_rebuild_fish_catalog_page()

func _build_fish_detail_page() -> void:
	fish_detail_panel = Panel.new()
	fish_detail_panel.name = "FishDetailCard"
	fish_detail_panel.position = Vector2(679, 185)
	fish_detail_panel.size = Vector2(347, 414)
	fish_detail_panel.add_theme_stylebox_override("panel", _detail_card_style())
	add_child(fish_detail_panel)

	fish_detail_name_label = _make_label("", 27, Color("#56372f"))
	fish_detail_name_label.name = "FishDetailName"
	fish_detail_name_label.position = Vector2(22, 12)
	fish_detail_name_label.size = Vector2(303, 42)
	fish_detail_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_detail_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_detail_panel.add_child(fish_detail_name_label)

	fish_detail_view = Sprite2D.new()
	fish_detail_view.name = "FishDetailIcon"
	fish_detail_panel.add_child(fish_detail_view)

	# Locked fish use the same faded-under-a-veil treatment as locked cats. The
	# familiar warm lock stays crisp on the outermost layer so the species is
	# clearly unavailable without replacing its silhouette with an empty card.
	fish_detail_locked_veil = ColorRect.new()
	fish_detail_locked_veil.name = "FishDetailLockedVeil"
	fish_detail_locked_veil.color = FISH_LOCKED_DETAIL_VEIL_COLOR
	fish_detail_locked_veil.position = FISH_LOCKED_DETAIL_VEIL_POSITION
	fish_detail_locked_veil.size = FISH_LOCKED_DETAIL_VEIL_SIZE
	fish_detail_locked_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_detail_locked_veil.visible = false
	fish_detail_panel.add_child(fish_detail_locked_veil)

	fish_detail_lock_view = Sprite2D.new()
	fish_detail_lock_view.name = "FishDetailLock"
	_fit_fish_sprite(
		fish_detail_lock_view,
		LOCK_TEXTURE,
		FISH_LOCKED_DETAIL_LOCK_CENTER,
		FISH_LOCKED_DETAIL_LOCK_MAX_SIZE
	)
	fish_detail_lock_view.visible = false
	fish_detail_panel.add_child(fish_detail_lock_view)

	fish_detail_rarity_label = _make_label("", 20, Color("#5b382f"))
	fish_detail_rarity_label.name = "FishDetailRarity"
	fish_detail_rarity_label.position = FISH_RARITY_POSITION
	fish_detail_rarity_label.size = FISH_RARITY_SIZE
	fish_detail_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_detail_rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_detail_panel.add_child(fish_detail_rarity_label)

	fish_aquarium_capacity_label = _make_label(
		"REACH AQUARIUM CAPACITY",
		16,
		Color("#bd553f")
	)
	fish_aquarium_capacity_label.name = "FishAquariumCapacityMessage"
	fish_aquarium_capacity_label.position = FISH_AQUARIUM_CAPACITY_MESSAGE_POSITION
	fish_aquarium_capacity_label.size = FISH_AQUARIUM_CAPACITY_MESSAGE_SIZE
	fish_aquarium_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_aquarium_capacity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_aquarium_capacity_label.visible = false
	fish_detail_panel.add_child(fish_aquarium_capacity_label)

	fish_aquarium_button = _make_popup_button("ADD TO AQUARIUM")
	fish_aquarium_button.name = "FishAquariumToggleButton"
	fish_aquarium_button.position = FISH_AQUARIUM_BUTTON_POSITION
	fish_aquarium_button.size = FISH_AQUARIUM_BUTTON_SIZE
	fish_aquarium_button.add_theme_font_size_override("font_size", 21)
	fish_aquarium_button.pressed.connect(_on_fish_aquarium_button_pressed)
	fish_detail_panel.add_child(fish_aquarium_button)

	fish_detail_description_label = _make_label("", 17, Color("#56372f"))
	fish_detail_description_label.name = "FishDetailDescription"
	fish_detail_description_label.position = FISH_DESCRIPTION_POSITION
	fish_detail_description_label.size = FISH_DESCRIPTION_SIZE
	fish_detail_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_detail_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fish_detail_panel.add_child(fish_detail_description_label)

	fish_detail_locked_message_label = _make_label(
		FISH_LOCKED_MESSAGE_TEXT,
		FISH_LOCKED_MESSAGE_FONT_SIZE,
		Color("#56372f")
	)
	fish_detail_locked_message_label.name = "FishDetailLockedMessage"
	fish_detail_locked_message_label.position = FISH_LOCKED_MESSAGE_POSITION
	fish_detail_locked_message_label.size = FISH_LOCKED_MESSAGE_SIZE
	fish_detail_locked_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_detail_locked_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fish_detail_locked_message_label.visible = false
	fish_detail_panel.add_child(fish_detail_locked_message_label)

func select_fish(fish_id: String) -> void:
	var fish := FishCatalogScript.definition(fish_id)
	if str(fish.get("id", "")) != fish_id:
		return
	var unlocked := is_fish_unlocked(fish_id)
	selected_fish_id = fish_id
	fish_detail_name_label.text = GameFontStylesScript.display_text(str(fish.get("name", "")))
	fish_detail_name_label.visible = unlocked
	_fit_fish_sprite(
		fish_detail_view,
		_fish_catalog_texture(fish),
		FISH_DETAIL_ICON_CENTER if unlocked else FISH_LOCKED_DETAIL_ICON_CENTER,
		(
			FISH_DETAIL_ICON_MAX_SIZE if unlocked else FISH_LOCKED_DETAIL_ICON_MAX_SIZE
		) * float(fish.get("fish_book_detail_scale", 1.0))
	)
	fish_detail_view.material = FishCatalogScript.visual_material(fish)
	fish_detail_view.modulate = Color.WHITE if unlocked else FISH_LOCKED_DETAIL_ICON_MODULATE
	fish_detail_rarity_label.text = "RARITY LEVEL %d" % int(fish.get("rarity_level", 0))
	fish_detail_rarity_label.visible = unlocked
	fish_detail_description_label.text = GameFontStylesScript.display_text(
		str(fish.get("description", ""))
	)
	fish_detail_description_label.visible = unlocked
	_hide_fish_capacity_message()
	fish_aquarium_button.visible = unlocked
	fish_detail_locked_veil.visible = not unlocked
	fish_detail_lock_view.visible = not unlocked
	fish_detail_locked_message_label.visible = not unlocked
	if unlocked:
		_update_fish_aquarium_button()
	for index in range(fish_slot_selection_frames.size()):
		fish_slot_selection_frames[index].visible = (
			fish_slot_ids[index] == fish_id
		)

func _on_fish_aquarium_button_pressed() -> void:
	if selected_fish_id == "" or not is_fish_unlocked(selected_fish_id):
		return
	if aquarium_fish_ids.has(selected_fish_id):
		aquarium_fish_ids.erase(selected_fish_id)
	else:
		if aquarium_fish_ids.size() >= FishCatalogScript.AQUARIUM_CAPACITY:
			_show_fish_capacity_message()
			return
		aquarium_fish_ids.append(selected_fish_id)
	_hide_fish_capacity_message()
	_update_fish_aquarium_button()
	aquarium_fish_ids_changed.emit(aquarium_fish_ids.duplicate())

func _update_fish_aquarium_button() -> void:
	if not is_instance_valid(fish_aquarium_button):
		return
	fish_aquarium_button.text = (
		"REMOVE FROM AQUARIUM"
		if aquarium_fish_ids.has(selected_fish_id)
		else "ADD TO AQUARIUM"
	)

func _show_fish_capacity_message() -> void:
	if is_instance_valid(fish_aquarium_capacity_tween):
		fish_aquarium_capacity_tween.kill()
	fish_aquarium_capacity_label.visible = true
	fish_aquarium_capacity_label.modulate.a = 1.0
	fish_aquarium_capacity_tween = create_tween()
	fish_aquarium_capacity_tween.tween_interval(FISH_CAPACITY_MESSAGE_HOLD_SECONDS)
	fish_aquarium_capacity_tween.tween_property(
		fish_aquarium_capacity_label,
		"modulate:a",
		0.0,
		FISH_CAPACITY_MESSAGE_FADE_SECONDS
	)
	fish_aquarium_capacity_tween.tween_callback(
		func(): fish_aquarium_capacity_label.visible = false
	)

func _hide_fish_capacity_message() -> void:
	if not is_instance_valid(fish_aquarium_capacity_label):
		return
	if is_instance_valid(fish_aquarium_capacity_tween):
		fish_aquarium_capacity_tween.kill()
	fish_aquarium_capacity_tween = null
	fish_aquarium_capacity_label.visible = false
	fish_aquarium_capacity_label.modulate.a = 1.0

func is_fish_unlocked(fish_id: String) -> bool:
	return unlocked_fish_ids.has(fish_id)

func _fish_catalog_texture(fish: Dictionary) -> Texture2D:
	var texture: Texture2D = fish.get("texture")
	var region: Rect2 = fish.get("texture_region", Rect2())
	if region.size.x <= 0.0 or region.size.y <= 0.0:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas

func _fit_fish_sprite(
	sprite: Sprite2D,
	texture: Texture2D,
	center: Vector2,
	max_size: Vector2
) -> void:
	sprite.texture = texture
	sprite.centered = true
	sprite.position = center
	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		sprite.scale = Vector2.ONE
		return
	var fit_scale := minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	sprite.scale = Vector2.ONE * fit_scale

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = GameFontStylesScript.display_text(text)
	GameFontStylesScript.apply_regular(label)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_text_button(text: String) -> Button:
	var button := Button.new()
	_style_text_button(button, text)
	return button

func _style_text_button(button: Button, text: String) -> void:
	button.text = GameFontStylesScript.display_text(text)
	GameFontStylesScript.apply_regular(button)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("#5b382f"))
	button.add_theme_color_override("font_hover_color", Color("#5b382f"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 0.94, 0.80, 0.94)
	normal.border_color = Color("#b87948")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(15)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#fff7dc")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

func _make_popup_button(text: String, accent := false) -> Button:
	var button := Button.new()
	button.text = GameFontStylesScript.display_text(text)
	if accent:
		GameFontStylesScript.apply_button(button)
	else:
		GameFontStylesScript.apply_regular(button)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color("#fff9e8") if accent else Color("#654033"))
	button.add_theme_color_override("font_hover_color", Color.WHITE if accent else Color("#4f342c"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#86a857") if accent else Color("#fff5dc")
	normal.border_color = Color("#5d7c3d") if accent else Color("#bd835b")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(23)
	normal.shadow_color = Color(0.18, 0.09, 0.05, 0.18)
	normal.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#9cbd68") if accent else Color("#fffaf0")
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("#6f9148") if accent else Color("#f1d6ae")
	pressed.shadow_size = 1
	button.add_theme_stylebox_override("pressed", pressed)
	return button

func _detail_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.95, 0.81, 0.93)
	style.border_color = Color("#b77948")
	style.set_border_width_all(2)
	style.set_corner_radius_all(17)
	style.shadow_color = Color(0.20, 0.10, 0.06, 0.13)
	style.shadow_size = 7
	return style

func _fish_selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("#4f8c83")
	style.set_border_width_all(4)
	style.set_corner_radius_all(13)
	return style

func _transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.set_corner_radius_all(12)
	return style

func _slot_hover_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.88, 0.56, 0.17)
	style.set_corner_radius_all(12)
	return style

func _format_number(value: int) -> String:
	var digits := str(maxi(0, value))
	var result := ""
	while digits.length() > 3:
		result = "," + digits.right(3) + result
		digits = digits.substr(0, digits.length() - 3)
	return digits + result
