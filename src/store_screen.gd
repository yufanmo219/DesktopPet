class_name StoreScreen
extends Control

signal back_requested
signal cat_purchased(cat_id: String, remaining_experience: int)
signal cat_selected(cat_id: String)

const BACKGROUND_TEXTURE: Texture2D = preload("res://assets/ui/store/concepts/adopt_cat_store_background_v3.png")
const LOCK_TEXTURE: Texture2D = preload("res://assets/ui/store/overlays/processed/cat_lock_icon_simple_warm.png")
const CELEBRATION_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/popups/processed/fishing_success_popup_base.png"
)
const PURCHASE_CONFIRMATION_TEXTURE: Texture2D = preload(
	"res://assets/ui/store/popups/purchase_confirmation_frame_v3.png"
)
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")
const BookShellScene = preload("res://src/catalog/book_shell.tscn")

const CAT_CATALOG_TITLE_TEXT := "Cat Shelter"
const SLOT_ORIGIN := Vector2(266, 198)
const SLOT_SIZE := Vector2(110, 110)
const SLOT_STEP := Vector2(116.5, 117.0)
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

var CAT_CATALOG: Array = PetCatalogScript.store_entries()
var ONLINE_CAT_IDS: Array[String] = PetCatalogScript.catalog_ids()
var experience := 0
var owned_cat_ids: Array[String] = ["maple"]
var selected_cat_id := "maple"
var active_catalog_tab := "cats"

var slot_buttons: Array[Button] = []
var slot_lock_views: Array[Sprite2D] = []
var slot_selection_frames: Array[Panel] = []
var cat_grid_layer: Control
# Compatibility sentinels: the cat store never constructs Fish Book content.
var fish_grid_layer: Control
var fish_detail_panel: Panel
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
var experience_label: Label

func configure(stats: Dictionary, owned_ids: Array, _catalog_tab := "cats") -> void:
	experience = maxi(0, int(stats.get("experience", 0)))
	owned_cat_ids.clear()
	for raw_id in owned_ids:
		var cat_id := str(raw_id)
		if cat_id != "" and not owned_cat_ids.has(cat_id):
			owned_cat_ids.append(cat_id)
	if not owned_cat_ids.has("maple"):
		owned_cat_ids.push_front("maple")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_ensure_book_shell()
	_bind_book_shell()
	_build_catalog_grid()
	_build_detail_page()
	select_cat("maple")
	active_catalog_tab = "cats"
	store_home_button.move_to_front()

func _ensure_book_shell() -> void:
	if get_node_or_null("CatalogBookShell") == null:
		add_child(BookShellScene.instantiate())

func _bind_book_shell() -> void:
	store_title_label = $CatalogBookShell/CatalogTitle
	store_title_label.name = "StoreCatalogTitle"
	store_title_label.text = GameFontStylesScript.display_text("Cat Shelter")
	GameFontStylesScript.apply_accent(store_title_label)

	experience_label = $CatalogBookShell/ExperienceLabel
	experience_label.name = "StoreExperienceLabel"
	experience_label.text = GameFontStylesScript.display_text(
		"Your XP: %s" % _format_number(experience)
	)
	GameFontStylesScript.apply_accent(experience_label)

	store_home_button = $CatalogBookShell/BackButton
	store_home_button.name = "StoreHomeButton"
	_style_text_button(store_home_button, "← Home")
	store_home_button.pressed.connect(func(): back_requested.emit())

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

func _build_detail_page() -> void:
	cat_detail_panel = Panel.new()
	cat_detail_panel.name = "CatDetailCard"
	cat_detail_panel.position = Vector2(679, 185)
	cat_detail_panel.size = Vector2(347, 414)
	cat_detail_panel.add_theme_stylebox_override("panel", _detail_card_style())
	add_child(cat_detail_panel)

	detail_cat_view = Sprite2D.new()
	detail_cat_view.name = "DetailCat"
	var default_detail_texture := _cat_detail_texture("maple")
	detail_cat_view.texture = default_detail_texture
	detail_cat_view.position = CAT_DETAIL_VIEW_POSITION
	detail_cat_view.centered = false
	detail_cat_view.scale = Vector2(
		CAT_DETAIL_VIEW_SIZE.x / default_detail_texture.get_width(),
		CAT_DETAIL_VIEW_SIZE.y / default_detail_texture.get_height()
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
	var definition = PetCatalogScript.definition_by_catalog_id(cat_id)
	if definition == null:
		definition = PetCatalogScript.default_definition()
	return definition.load_texture("store_portrait")

func _cat_detail_texture(cat_id: String) -> Texture2D:
	var definition = PetCatalogScript.definition_by_catalog_id(cat_id)
	if definition == null:
		definition = PetCatalogScript.default_definition()
	return definition.load_texture("store_detail")

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
