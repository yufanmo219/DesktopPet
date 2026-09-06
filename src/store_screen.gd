class_name StoreScreen
extends Control

signal back_requested
signal aquarium_fish_ids_changed(fish_ids: Array[String])
signal cat_purchased(cat_id: String, remaining_experience: int)
signal cat_selected(cat_id: String)

const BACKGROUND_TEXTURE: Texture2D = preload("res://assets/ui/store/concepts/adopt_cat_store_background_v3.png")
const CAT_HEAD_TEXTURE: Texture2D = preload("res://assets/ui/store/cats/processed/orange_cat_head.png")
const CAT_BODY_TEXTURE: Texture2D = preload(
	"res://assets/ui/store/cats/processed/orange_cat_store_detail_front.png"
)
const MOCHI_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/mochi/store/mochi_store_portrait.png"
)
const MOCHI_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/mochi/mochi_front_sitting_eyelashes.png"
)
const BISCUIT_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/biscuit/store/biscuit_store_portrait.png"
)
const BISCUIT_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png"
)
const LUNA_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/russian_blue/store/luna_store_portrait.png"
)
const LUNA_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/russian_blue/fishing/default/luna_fishing_default.png"
)
const POPPY_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/blue_british/store/poppy_store_portrait.png"
)
const POPPY_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/blue_british/fishing/default/poppy_fishing_default.png"
)
const BLACK_CAT_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/black_cat/store/black_cat_store_portrait.png"
)
const BLACK_CAT_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/black_cat/fishing/default/black_cat_fishing_default.png"
)
const MAINE_COON_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/maine_coon/store/maine_coon_store_portrait.png"
)
const MAINE_COON_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/maine_coon/fishing/default/maine_coon_fishing_default.png"
)
const GOLDEN_MUNCHKIN_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/golden_munchkin/store/golden_munchkin_store_portrait.png"
)
const GOLDEN_MUNCHKIN_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/golden_munchkin/fishing/default/golden_munchkin_fishing_default.png"
)
const SIAMESE_STORE_PORTRAIT_TEXTURE: Texture2D = preload(
	"res://assets/pets/siamese/store/siamese_store_portrait.png"
)
const SIAMESE_STORE_DETAIL_TEXTURE: Texture2D = preload(
	"res://assets/pets/siamese/fishing/default/siamese_fishing_default.png"
)
const LOCK_TEXTURE: Texture2D = preload("res://assets/ui/store/overlays/processed/cat_lock_icon_simple_warm.png")
const CELEBRATION_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/popups/processed/fishing_success_popup_base.png"
)
const PURCHASE_CONFIRMATION_TEXTURE: Texture2D = preload(
	"res://assets/ui/store/popups/purchase_confirmation_frame_v3.png"
)
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")

const CAT_CATALOG_TITLE_TEXT := "Cat Shelter"
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
const CAT_DETAIL_VIEW_POSITION := Vector2(56, 0)
const CAT_DETAIL_VIEW_SIZE := Vector2(235, 235)
const CAT_DESCRIPTION_POSITION := Vector2(27, 222)
const CAT_DESCRIPTION_SIZE := Vector2(293, 72)
const CAT_ACTION_BUTTON_POSITION := Vector2(56, 345)
const CAT_ACTION_BUTTON_SIZE := Vector2(235, 52)
const CAT_ACTION_OWNED_FONT_SIZE := 24
const CAT_ACTION_LOCKED_FONT_SIZE := 20
const CAT_LOCKED_SLOT_MODULATE := Color(0.50, 0.47, 0.44, 0.64)
const CAT_LOCKED_SLOT_VEIL_COLOR := Color(0.34, 0.29, 0.27, 0.36)
const CAT_LOCKED_DETAIL_MODULATE := Color(0.34, 0.34, 0.34, 0.78)

const CAT_CATALOG := [
	{
		"id": "maple",
		"name": "Maple",
		"price": 0,
		"description": "Maple is a warm and curious orange tabby who loves cozy naps and little adventures. With a cheerful heart, Maple will always stay by your side."
	},
	{"id": "mochi", "name": "Mochi", "price": 500, "description": "A gentle new companion is waiting to meet you."},
	{"id": "biscuit", "name": "Biscuit", "price": 1500, "description": "A playful new companion is waiting to meet you."},
	{"id": "luna", "name": "Luna", "price": 3000, "description": "A dreamy new companion is waiting to meet you."},
	{"id": "poppy", "name": "Poppy", "price": 5000, "description": "A cheerful new companion is waiting to meet you."},
	{"id": "black_cat", "name": "Sable", "price": 7000, "description": "A cool and distant companion with a quietly loyal heart."},
	{"id": "siamese", "name": "Pearl", "price": 9000, "description": "A graceful seal-point companion with bright sky-blue eyes and a curious, affectionate nature."},
	{"id": "golden_munchkin", "name": "Honey", "price": 11000, "description": "A round golden short-legged companion who loves soft blankets and cozy naps."},
	{"id": "maine_coon", "name": "Cedar", "price": 20000, "description": "A gentle gray-and-white giant with a proud ruff and a soft heart."}
]
const ONLINE_CAT_IDS := [
	"maple", "mochi", "biscuit", "luna", "poppy", "black_cat", "siamese",
	"golden_munchkin", "maine_coon"
]

var experience := 0
var owned_cat_ids: Array[String] = ["maple"]
var selected_cat_id := "maple"
var unlocked_fish_ids: Array[String] = FishCatalogScript.STARTER_FISH_IDS.duplicate()
var selected_fish_id := "green"
var aquarium_fish_ids: Array[String] = FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS.duplicate()
var active_catalog_tab := "cats"
var initial_catalog_tab := "cats"
var fish_page_index := 0

var slot_buttons: Array[Button] = []
var slot_lock_views: Array[Sprite2D] = []
var slot_selection_frames: Array[Panel] = []
var cat_grid_layer: Control
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

var cat_detail_panel: Panel
var detail_cat_view: Sprite2D
var detail_description_label: Label
var detail_veil: ColorRect
var detail_lock_view: Sprite2D
var detail_unlock_button: Button
var detail_unlock_label: Label
var detail_locked := false
var purchase_popup: Control
var purchase_popup_stage := ""
var purchase_popup_cat_id := ""
var purchase_confirmation_label: Label
var purchase_yes_button: Button
var purchase_cancel_button: Button
var congratulations_cat_view: TextureRect
var congratulations_name_label: Label
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
var experience_label: Label


func configure(stats: Dictionary, owned_ids: Array, catalog_tab := "cats") -> void:
	experience = maxi(0, int(stats.get("experience", 0)))
	initial_catalog_tab = "fish" if catalog_tab == "fish" else "cats"
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
	owned_cat_ids.clear()
	for raw_id in owned_ids:
		var cat_id := str(raw_id)
		if cat_id != "" and not owned_cat_ids.has(cat_id):
			owned_cat_ids.append(cat_id)
	if not owned_cat_ids.has("maple"):
		owned_cat_ids.push_front("maple")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_background()
	_build_header()
	if initial_catalog_tab == "fish":
		_build_fish_catalog()
		_build_fish_detail_page()
		select_fish("green")
	else:
		_build_catalog_grid()
		_build_detail_page()
		select_cat("maple")
	_switch_catalog_tab(initial_catalog_tab)
	store_home_button.move_to_front()


func _build_background() -> void:
	var background := TextureRect.new()
	background.name = "StoreBackground"
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _build_header() -> void:
	var showing_fish_book := initial_catalog_tab == "fish"
	store_title_label = _make_label(
		FISH_CATALOG_TITLE_TEXT if showing_fish_book else CAT_CATALOG_TITLE_TEXT,
		34,
		Color("#5b382f")
	)
	GameFontStylesScript.apply_accent(store_title_label)
	store_title_label.name = "StoreCatalogTitle"
	store_title_label.position = Vector2(112, 68)
	store_title_label.size = Vector2(274, 62)
	store_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	store_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	store_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(store_title_label)

	experience_label = _make_label("Your XP: %s" % _format_number(experience), 29, Color("#5b382f"))
	GameFontStylesScript.apply_accent(experience_label)
	experience_label.name = "StoreExperienceLabel"
	experience_label.position = Vector2(918, 70)
	experience_label.size = Vector2(267, 43)
	experience_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	experience_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(experience_label)

	store_home_button = _make_text_button("← Aquarium" if showing_fish_book else "← Home")
	store_home_button.name = "FishBookAquariumButton" if showing_fish_book else "StoreHomeButton"
	store_home_button.position = Vector2(42, 641)
	store_home_button.size = Vector2(164, 49)
	store_home_button.pressed.connect(func(): back_requested.emit())
	add_child(store_home_button)


func _switch_catalog_tab(tab_id: String) -> void:
	active_catalog_tab = "fish" if tab_id == "fish" else "cats"
	var showing_fish := active_catalog_tab == "fish"
	if is_instance_valid(cat_grid_layer):
		cat_grid_layer.visible = not showing_fish
	if is_instance_valid(cat_detail_panel):
		cat_detail_panel.visible = not showing_fish
	if is_instance_valid(fish_grid_layer):
		fish_grid_layer.visible = showing_fish
	if is_instance_valid(fish_detail_panel):
		fish_detail_panel.visible = showing_fish
	store_title_label.text = GameFontStylesScript.display_text(
		FISH_CATALOG_TITLE_TEXT if showing_fish else CAT_CATALOG_TITLE_TEXT
	)


func _build_catalog_grid() -> void:
	cat_grid_layer = Control.new()
	cat_grid_layer.name = "CatCatalogGrid"
	cat_grid_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cat_grid_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cat_grid_layer)
	for index in range(CAT_CATALOG.size()):
		var cat: Dictionary = CAT_CATALOG[index]
		var column := index % 3
		var row := floori(float(index) / 3.0)
		var slot := Control.new()
		slot.name = "CatSlot%d" % index
		slot.position = SLOT_ORIGIN + Vector2(column * SLOT_STEP.x, row * SLOT_STEP.y)
		slot.size = SLOT_SIZE
		cat_grid_layer.add_child(slot)

		var name_label := _make_label(str(cat.name), 18, Color("#5b382f"))
		name_label.position = Vector2(4, 2)
		name_label.size = Vector2(102, 23)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(name_label)

		var head := Sprite2D.new()
		head.name = "CatHead"
		var head_texture := _cat_head_texture(str(cat.id))
		head.texture = head_texture
		head.position = Vector2(15, 25)
		head.centered = false
		head.scale = Vector2(80.0 / head_texture.get_width(), 80.0 / head_texture.get_height())
		if not is_cat_owned(str(cat.id)):
			head.modulate = CAT_LOCKED_SLOT_MODULATE
		slot.add_child(head)

		var veil := ColorRect.new()
		veil.name = "LockedVeil"
		veil.color = CAT_LOCKED_SLOT_VEIL_COLOR
		veil.position = Vector2(3, 3)
		veil.size = Vector2(104, 104)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		veil.visible = not is_cat_owned(str(cat.id))
		slot.add_child(veil)

		var lock := Sprite2D.new()
		lock.name = "SlotLock"
		lock.texture = LOCK_TEXTURE
		lock.position = Vector2(39, 39)
		lock.centered = false
		lock.scale = Vector2(32.0 / LOCK_TEXTURE.get_width(), 48.0 / LOCK_TEXTURE.get_height())
		lock.visible = not is_cat_owned(str(cat.id))
		slot.add_child(lock)
		slot_lock_views.append(lock)

		var selection_frame := Panel.new()
		selection_frame.name = "SelectionFrame"
		selection_frame.position = Vector2(1, 1)
		selection_frame.size = Vector2(108, 108)
		selection_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selection_frame.add_theme_stylebox_override("panel", _selection_style())
		slot.add_child(selection_frame)
		slot_selection_frames.append(selection_frame)

		var button := Button.new()
		button.name = "CatSlotButton%d" % index
		button.tooltip_text = GameFontStylesScript.display_text(cat.name)
		button.position = Vector2.ZERO
		button.size = SLOT_SIZE
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_stylebox_override("normal", _transparent_button_style())
		button.add_theme_stylebox_override("hover", _slot_hover_style())
		button.add_theme_stylebox_override("pressed", _slot_hover_style())
		var cat_id := str(cat.id)
		button.pressed.connect(func(): select_cat(cat_id))
		slot.add_child(button)
		slot_buttons.append(button)


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


func _build_detail_page() -> void:
	cat_detail_panel = Panel.new()
	cat_detail_panel.name = "CatDetailCard"
	cat_detail_panel.position = Vector2(679, 185)
	cat_detail_panel.size = Vector2(347, 414)
	cat_detail_panel.add_theme_stylebox_override("panel", _detail_card_style())
	add_child(cat_detail_panel)

	detail_cat_view = Sprite2D.new()
	detail_cat_view.name = "DetailCat"
	detail_cat_view.texture = CAT_BODY_TEXTURE
	detail_cat_view.position = CAT_DETAIL_VIEW_POSITION
	detail_cat_view.centered = false
	detail_cat_view.scale = Vector2(
		CAT_DETAIL_VIEW_SIZE.x / CAT_BODY_TEXTURE.get_width(),
		CAT_DETAIL_VIEW_SIZE.y / CAT_BODY_TEXTURE.get_height()
	)
	cat_detail_panel.add_child(detail_cat_view)

	detail_description_label = _make_label("", 18, Color("#56372f"))
	detail_description_label.name = "CatDescription"
	detail_description_label.position = CAT_DESCRIPTION_POSITION
	detail_description_label.size = CAT_DESCRIPTION_SIZE
	detail_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cat_detail_panel.add_child(detail_description_label)

	detail_veil = ColorRect.new()
	detail_veil.name = "DetailLockedVeil"
	detail_veil.color = Color.TRANSPARENT
	detail_veil.position = Vector2(9, 9)
	detail_veil.size = Vector2(329, 304)
	detail_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_veil.visible = false
	cat_detail_panel.add_child(detail_veil)

	detail_lock_view = Sprite2D.new()
	detail_lock_view.name = "DetailLock"
	detail_lock_view.texture = LOCK_TEXTURE
	detail_lock_view.position = Vector2(132, 105)
	detail_lock_view.centered = false
	detail_lock_view.scale = Vector2(83.0 / LOCK_TEXTURE.get_width(), 112.0 / LOCK_TEXTURE.get_height())
	cat_detail_panel.add_child(detail_lock_view)

	detail_unlock_button = _make_popup_button("", true)
	detail_unlock_button.name = "UnlockButton"
	detail_unlock_button.position = CAT_ACTION_BUTTON_POSITION
	detail_unlock_button.size = CAT_ACTION_BUTTON_SIZE
	detail_unlock_button.tooltip_text = "PREVIEW THIS CAT'S UNLOCK"
	detail_unlock_button.pressed.connect(_on_cat_detail_action_pressed)
	cat_detail_panel.add_child(detail_unlock_button)

	detail_unlock_label = _make_label("", CAT_ACTION_OWNED_FONT_SIZE, Color("#fff8dc"))
	GameFontStylesScript.apply_button(detail_unlock_label)
	detail_unlock_label.name = "UnlockButtonLabel"
	detail_unlock_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_unlock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail_unlock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_unlock_label.add_theme_color_override("font_shadow_color", Color(0.19, 0.25, 0.08, 0.65))
	detail_unlock_label.add_theme_constant_override("shadow_offset_x", 1)
	detail_unlock_label.add_theme_constant_override("shadow_offset_y", 2)
	detail_unlock_button.add_child(detail_unlock_label)


func select_cat(cat_id: String) -> void:
	var catalog_index := get_catalog_index(cat_id)
	if catalog_index < 0:
		return
	selected_cat_id = cat_id
	var cat: Dictionary = CAT_CATALOG[catalog_index]
	detail_locked = not is_cat_owned(cat_id)
	var detail_texture := _cat_detail_texture(cat_id)
	detail_cat_view.texture = detail_texture
	detail_cat_view.scale = Vector2(
		CAT_DETAIL_VIEW_SIZE.x / detail_texture.get_width(),
		CAT_DETAIL_VIEW_SIZE.y / detail_texture.get_height()
	)
	detail_cat_view.modulate = Color.WHITE if not detail_locked else CAT_LOCKED_DETAIL_MODULATE
	detail_description_label.text = GameFontStylesScript.display_text(cat.description)
	detail_description_label.visible = not detail_locked
	# Locked cats are tinted through their own alpha silhouette, matching the
	# Fish Book treatment without drawing a rectangular veil over the card.
	detail_veil.visible = false
	detail_lock_view.visible = detail_locked
	detail_unlock_button.visible = detail_locked or cat_id in ONLINE_CAT_IDS
	detail_unlock_button.disabled = detail_locked and experience < int(cat.price)
	detail_unlock_button.tooltip_text = (
		"NOT ENOUGH XP"
		if detail_unlock_button.disabled
		else "UNLOCK THIS CAT" if detail_locked
		else "CARRY %s" % str(cat.name).to_upper()
	)
	detail_unlock_label.add_theme_font_size_override(
		"font_size",
		CAT_ACTION_LOCKED_FONT_SIZE if detail_locked else CAT_ACTION_OWNED_FONT_SIZE
	)
	detail_unlock_label.text = GameFontStylesScript.display_text(
		"Unlock with %s XP" % _format_number(int(cat.price))
		if detail_locked
		else "Carry %s" % str(cat.name)
	)
	for index in range(slot_selection_frames.size()):
		slot_selection_frames[index].visible = index == catalog_index


func _on_cat_detail_action_pressed() -> void:
	if detail_locked:
		_show_purchase_confirmation()
	elif selected_cat_id in ONLINE_CAT_IDS:
		cat_selected.emit(selected_cat_id)


func _show_purchase_confirmation() -> void:
	var catalog_index := get_catalog_index(selected_cat_id)
	if catalog_index < 0 or not detail_locked:
		return
	_close_purchase_popup()
	var cat: Dictionary = CAT_CATALOG[catalog_index]
	if experience < int(cat.price):
		return
	purchase_popup_stage = "confirmation"
	purchase_popup_cat_id = str(cat.id)
	purchase_popup = _make_popup_overlay("PurchaseConfirmationPopup")

	var card := Control.new()
	card.name = "PurchaseConfirmationCard"
	card.position = Vector2(330, 205)
	card.size = Vector2(620, 310)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	purchase_popup.add_child(card)

	var confirmation_background := TextureRect.new()
	confirmation_background.name = "ConfirmationBackground"
	confirmation_background.texture = PURCHASE_CONFIRMATION_TEXTURE
	confirmation_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	confirmation_background.stretch_mode = TextureRect.STRETCH_SCALE
	confirmation_background.position = Vector2(-35, -22)
	confirmation_background.size = Vector2(691, 357)
	confirmation_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(confirmation_background)

	purchase_confirmation_label = _make_label(
		"Are you sure you want to purchase %s\nwith %s XP?" % [
			str(cat.name), _format_number(int(cat.price))
		],
		31,
		Color("#5b382f")
	)
	purchase_confirmation_label.name = "PurchaseConfirmationLabel"
	purchase_confirmation_label.position = Vector2(25, 48)
	purchase_confirmation_label.size = Vector2(570, 110)
	purchase_confirmation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purchase_confirmation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purchase_confirmation_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	purchase_confirmation_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(purchase_confirmation_label)

	purchase_yes_button = _make_popup_button("Yes", true)
	purchase_yes_button.name = "PurchaseYesButton"
	purchase_yes_button.position = Vector2(70, 207)
	purchase_yes_button.size = Vector2(200, 58)
	purchase_yes_button.pressed.connect(_show_purchase_congratulations)
	card.add_child(purchase_yes_button)

	purchase_cancel_button = _make_popup_button("Cancel")
	purchase_cancel_button.name = "PurchaseCancelButton"
	purchase_cancel_button.position = Vector2(350, 207)
	purchase_cancel_button.size = Vector2(200, 58)
	purchase_cancel_button.pressed.connect(_close_purchase_popup)
	card.add_child(purchase_cancel_button)


func _show_purchase_congratulations() -> void:
	var catalog_index := get_catalog_index(purchase_popup_cat_id)
	if catalog_index < 0:
		return
	var cat: Dictionary = CAT_CATALOG[catalog_index]
	var cat_id := str(cat.id)
	var price := int(cat.price)
	if is_cat_owned(cat_id) or experience < price:
		_close_purchase_popup()
		select_cat(cat_id)
		return
	experience -= price
	owned_cat_ids.append(cat_id)
	_update_purchased_cat_slot(catalog_index)
	if is_instance_valid(experience_label):
		experience_label.text = GameFontStylesScript.display_text(
			"Your XP: %s" % _format_number(experience)
		)
	select_cat(cat_id)
	cat_purchased.emit(cat_id, experience)
	_close_purchase_popup()
	purchase_popup_stage = "congratulations"
	purchase_popup_cat_id = cat_id
	purchase_popup = _make_popup_overlay("PurchaseCongratulationsPopup")
	purchase_popup.gui_input.connect(_on_congratulations_popup_input)

	var celebration_card := Control.new()
	celebration_card.name = "PurchaseCongratulationsCard"
	celebration_card.position = Vector2(280, 34)
	celebration_card.size = Vector2(720, 652)
	celebration_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	purchase_popup.add_child(celebration_card)

	var celebration_background := TextureRect.new()
	celebration_background.name = "CelebrationBackground"
	celebration_background.texture = CELEBRATION_POPUP_TEXTURE
	celebration_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	celebration_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	celebration_background.stretch_mode = TextureRect.STRETCH_SCALE
	celebration_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_card.add_child(celebration_background)

	var title := _make_label("Congratulations!", 50, Color("#6a3e2e"))
	GameFontStylesScript.apply_accent(title)
	title.name = "CongratulationsTitle"
	title.position = Vector2(80, 65)
	title.size = Vector2(560, 58)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_card.add_child(title)

	var subtitle := _make_label("You now own", 32, Color("#785244"))
	subtitle.name = "CongratulationsSubtitle"
	subtitle.position = Vector2(80, 121)
	subtitle.size = Vector2(560, 42)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_card.add_child(subtitle)

	congratulations_cat_view = TextureRect.new()
	congratulations_cat_view.name = "CongratulationsCat"
	congratulations_cat_view.texture = _cat_detail_texture(cat_id)
	congratulations_cat_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	congratulations_cat_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	congratulations_cat_view.position = Vector2(195, 151)
	congratulations_cat_view.size = Vector2(330, 330)
	congratulations_cat_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_card.add_child(congratulations_cat_view)

	congratulations_name_label = _make_label("%s!" % str(cat.name), 48, Color("#6a3e2e"))
	GameFontStylesScript.apply_accent(congratulations_name_label)
	congratulations_name_label.name = "CongratulationsCatName"
	congratulations_name_label.position = Vector2(80, 510)
	congratulations_name_label.size = Vector2(560, 55)
	congratulations_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	congratulations_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	congratulations_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	celebration_card.add_child(congratulations_name_label)


func _update_purchased_cat_slot(catalog_index: int) -> void:
	if not is_instance_valid(cat_grid_layer):
		return
	var slot := cat_grid_layer.get_node_or_null("CatSlot%d" % catalog_index)
	if slot == null:
		return
	var head := slot.get_node_or_null("CatHead") as Sprite2D
	if is_instance_valid(head):
		head.modulate = Color.WHITE
	var veil := slot.get_node_or_null("LockedVeil") as ColorRect
	if is_instance_valid(veil):
		veil.visible = false
	var lock := slot.get_node_or_null("SlotLock") as Sprite2D
	if is_instance_valid(lock):
		lock.visible = false


func _make_popup_overlay(node_name: String) -> Control:
	var overlay := Control.new()
	overlay.name = node_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var dimmer := ColorRect.new()
	dimmer.name = "PopupDimmer"
	dimmer.color = Color(0.10, 0.07, 0.05, 0.46)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dimmer)
	return overlay


func _close_purchase_popup() -> void:
	if is_instance_valid(purchase_popup):
		purchase_popup.queue_free()
	purchase_popup = null
	purchase_popup_stage = ""
	purchase_popup_cat_id = ""
	purchase_confirmation_label = null
	purchase_yes_button = null
	purchase_cancel_button = null
	congratulations_cat_view = null
	congratulations_name_label = null


func _on_congratulations_popup_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_purchase_popup()


func is_cat_owned(cat_id: String) -> bool:
	return owned_cat_ids.has(cat_id)


func _cat_head_texture(cat_id: String) -> Texture2D:
	if cat_id == "mochi":
		return MOCHI_STORE_PORTRAIT_TEXTURE
	if cat_id == "biscuit":
		return BISCUIT_STORE_PORTRAIT_TEXTURE
	if cat_id == "luna":
		return LUNA_STORE_PORTRAIT_TEXTURE
	if cat_id == "poppy":
		return POPPY_STORE_PORTRAIT_TEXTURE
	if cat_id == "black_cat":
		return BLACK_CAT_STORE_PORTRAIT_TEXTURE
	if cat_id == "maine_coon":
		return MAINE_COON_STORE_PORTRAIT_TEXTURE
	if cat_id == "golden_munchkin":
		return GOLDEN_MUNCHKIN_STORE_PORTRAIT_TEXTURE
	if cat_id == "siamese":
		return SIAMESE_STORE_PORTRAIT_TEXTURE
	return CAT_HEAD_TEXTURE


func _cat_detail_texture(cat_id: String) -> Texture2D:
	if cat_id == "mochi":
		return MOCHI_STORE_DETAIL_TEXTURE
	if cat_id == "biscuit":
		return BISCUIT_STORE_DETAIL_TEXTURE
	if cat_id == "luna":
		return LUNA_STORE_DETAIL_TEXTURE
	if cat_id == "poppy":
		return POPPY_STORE_DETAIL_TEXTURE
	if cat_id == "black_cat":
		return BLACK_CAT_STORE_DETAIL_TEXTURE
	if cat_id == "maine_coon":
		return MAINE_COON_STORE_DETAIL_TEXTURE
	if cat_id == "golden_munchkin":
		return GOLDEN_MUNCHKIN_STORE_DETAIL_TEXTURE
	if cat_id == "siamese":
		return SIAMESE_STORE_DETAIL_TEXTURE
	return CAT_BODY_TEXTURE


func get_catalog_index(cat_id: String) -> int:
	for index in range(CAT_CATALOG.size()):
		if str(CAT_CATALOG[index].id) == cat_id:
			return index
	return -1


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = GameFontStylesScript.display_text(text)
	GameFontStylesScript.apply_regular(label)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_text_button(text: String) -> Button:
	var button := Button.new()
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
	return button


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


func _celebration_shadow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.29, 0.16, 0.10, 0.19)
	style.set_corner_radius_all(13)
	return style


func _detail_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.95, 0.81, 0.93)
	style.border_color = Color("#b77948")
	style.set_border_width_all(2)
	style.set_corner_radius_all(17)
	style.shadow_color = Color(0.20, 0.10, 0.06, 0.13)
	style.shadow_size = 7
	return style


func _selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("#e89d42")
	style.set_border_width_all(3)
	style.set_corner_radius_all(13)
	return style


func _fish_selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("#4f8c83")
	style.set_border_width_all(4)
	style.set_corner_radius_all(13)
	return style


func _fish_rarity_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f4ddaf")
	style.border_color = Color("#b87948")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
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
