class_name AquariumScreen
extends Control

## Aquarium screen with independently animated fish layered over clean artwork.

signal back_requested
signal fish_book_requested
signal animations_prepared

const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const AquariumFishActorScript = preload("res://src/aquarium_fish_actor.gd")
const AquariumViewScene = preload("res://src/aquarium/aquarium_view.tscn")

const BACKGROUND_TEXTURE: Texture2D = preload(
	"res://assets/ui/aquarium/aquarium_background_clean_v1.png"
)

# Fish IDs are save-file keys; these exceptions map them to the approved
# animation folder names.
const FISH_ASSET_STEM_OVERRIDES := {
	"green": "green_fish",
	"coral": "coral_angelfish",
	"golden": "golden_ribbonfish",
	"blue_small": "blue_small_fish",
	"yellow_striped": "yellow_striped_fish",
	"silver_mackerel": "silver_blue_mackerel",
	"purple_butterfly": "purple_butterfly_fish"
}
const FISH_ASSET_VERSION := "v1"
const FISH_ASSET_VERSION_OVERRIDES := {
	"blue_small": "v3",
	"blue_spotted_stingray": "v2",
	"blue_tang": "v3",
	"brown_anglerfish": "v2",
	"coral": "v3",
	"electric_eel": "v3",
	"emerald_seahorse": "v2",
	"fire_dartfish": "v2",
	"golden": "v3",
	"golden_manta_ray": "v2",
	"leafy_seadragon": "v2",
	"mandarin_dragonet": "v2",
	"mint_catfish": "v2",
	"moray_eel": "v2",
	"moorish_idol": "v2",
	"neon_tetra": "v2",
	"peach_goby": "v3",
	"pink_salmon": "v5",
	"royal_gramma": "v2",
	"sapphire_discus": "v2",
	"silver_mackerel": "v3",
	"spotted_frogfish": "v2",
	"sunset_swordtail": "v2",
	"turquoise_guppy": "v3",
	"yellow_striped": "v3"
}
const FISH_START_POSITIONS: Array[Vector2] = [
	Vector2(150, 210),
	Vector2(395, 210),
	Vector2(640, 210),
	Vector2(885, 210),
	Vector2(1130, 210),
	Vector2(150, 450),
	Vector2(395, 450),
	Vector2(640, 450),
	Vector2(885, 450),
	Vector2(1130, 450)
]
const FISH_SCALE := Vector2(0.34, 0.34)
const FISH_SCALE_OVERRIDES := {
	# Green Fish fills much more of its source frames than the other species.
	"green": Vector2(0.24, 0.24)
}

# The target is the fish's visual center. These limits keep the complete fish
# inside the open water and away from the four UI plaques.
const SWIM_BOUNDS := Rect2(120, 155, 1040, 380)

const TITLE_POSITION := Vector2(47, 43)
const TITLE_SIZE := Vector2(305, 80)
const TITLE_FONT_SIZE := 34
const FISH_COUNT_POSITION := Vector2(1015, 43)
const FISH_COUNT_SIZE := Vector2(220, 80)
const FISH_COUNT_FONT_SIZE := 29
const HOME_BUTTON_POSITION := Vector2(43, 610)
const HOME_BUTTON_SIZE := Vector2(210, 66)
const FISH_BOOK_BUTTON_POSITION := Vector2(1027, 610)
const FISH_BOOK_BUTTON_SIZE := Vector2(208, 66)
const NAVIGATION_FONT_SIZE := 30
const TEXT_COLOR := Color("#5b382f")

var aquarium_fish_ids: Array[String] = FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS.duplicate()
var home_button: Button
var fish_book_button: Button
var fish_count_label: Label
var fish_layer: Control
var extra_fish_actors: Array[Sprite2D] = []
var animations_ready := false
var animations_loading := false
var loading_progress := 0.0


func configure(stats: Dictionary) -> void:
	var unique_unlocked_ids: Array[String] = []
	var raw_ids: Variant = stats.get("unlocked_fish_ids", FishCatalogScript.STARTER_FISH_IDS)
	if raw_ids is Array:
		for raw_id in raw_ids:
			var fish_id := str(raw_id)
			if FishCatalogScript.definition(fish_id).get("id", "") == fish_id and not unique_unlocked_ids.has(fish_id):
				unique_unlocked_ids.append(fish_id)
	if unique_unlocked_ids.is_empty():
		unique_unlocked_ids = FishCatalogScript.STARTER_FISH_IDS.duplicate()
	aquarium_fish_ids = FishCatalogScript.normalize_aquarium_fish_ids(
		stats.get(
			"aquarium_fish_ids",
			FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS
		),
		unique_unlocked_ids
	)
	if is_instance_valid(fish_count_label):
		fish_count_label.text = _fish_capacity_text()


func _fish_capacity_text() -> String:
	return "FISH CAP %d / %d" % [
		aquarium_fish_ids.size(),
		FishCatalogScript.AQUARIUM_CAPACITY
	]


func _ready() -> void:
	_ensure_view()
	_bind_view()
	_style_view()


func prepare_animations_async() -> void:
	if animations_ready:
		return
	if animations_loading:
		await animations_prepared
		return
	animations_loading = true
	loading_progress = 0.0

	var requested_paths: Array[String] = []
	for fish_id in aquarium_fish_ids:
		requested_paths.append_array(_fish_asset_paths(fish_id))
	var loaded_textures: Dictionary = {}
	var pending_paths: Array[String] = []
	for path in requested_paths:
		if ResourceLoader.has_cached(path):
			loaded_textures[path] = ResourceLoader.load(path, "Texture2D")
			continue
		var request_error := ResourceLoader.load_threaded_request(path, "Texture2D")
		if request_error == OK:
			pending_paths.append(path)
		else:
			push_warning("Could not start threaded aquarium load for %s: %s" % [
				path,
				error_string(request_error)
			])
			loaded_textures[path] = ResourceLoader.load(path, "Texture2D")

	while not pending_paths.is_empty():
		for path in pending_paths.duplicate():
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				loaded_textures[path] = ResourceLoader.load_threaded_get(path)
				pending_paths.erase(path)
			elif status in [
				ResourceLoader.THREAD_LOAD_FAILED,
				ResourceLoader.THREAD_LOAD_INVALID_RESOURCE
			]:
				push_warning("Threaded aquarium load failed for %s; using fallback." % path)
				loaded_textures[path] = ResourceLoader.load(path, "Texture2D")
				pending_paths.erase(path)
		loading_progress = (
			float(loaded_textures.size()) / maxf(float(requested_paths.size()), 1.0) * 0.65
		)
		await get_tree().process_frame

	await _build_aquarium_fish_animations_async(loaded_textures)
	animations_loading = false
	animations_ready = true
	loading_progress = 1.0
	animations_prepared.emit()


func _ensure_view() -> void:
	if get_node_or_null("AquariumView") == null:
		add_child(AquariumViewScene.instantiate())


func _bind_view() -> void:
	var view := get_node("AquariumView")
	fish_layer = view.get_node("AquariumFishLayer")
	fish_count_label = view.get_node("AquariumFishCount")
	home_button = view.get_node("AquariumHomeButton")
	fish_book_button = view.get_node("AquariumFishBookButton")


func _style_view() -> void:
	var title: Label = get_node("AquariumView/AquariumTitle")
	_style_label(title, "MY AQUARIUM", TITLE_FONT_SIZE)
	_style_label(fish_count_label, _fish_capacity_text(), FISH_COUNT_FONT_SIZE)
	_style_navigation_button(home_button, "← HOME")
	_style_navigation_button(fish_book_button, "FISH BOOK")
	home_button.pressed.connect(func(): back_requested.emit())
	fish_book_button.pressed.connect(func(): fish_book_requested.emit())


func _build_aquarium_fish_animations_async(loaded_textures: Dictionary) -> void:
	var fish_index := 0
	for fish_id in aquarium_fish_ids:
		var asset_paths := _fish_asset_paths(fish_id)
		var fish_definition: Dictionary = FishCatalogScript.definition(fish_id)
		var actor = AquariumFishActorScript.new()
		actor.name = "AquariumFish_%s" % fish_id
		actor.z_index = 2 + fish_index % 2
		actor.material = FishCatalogScript.visual_material(fish_definition)
		fish_layer.add_child(actor)
		await actor.configure_async(
			fish_id,
			loaded_textures[asset_paths[0]],
			loaded_textures[asset_paths[1]],
			loaded_textures[asset_paths[2]],
			loaded_textures[asset_paths[3]],
			SWIM_BOUNDS,
			_fish_scale(fish_id),
			FISH_START_POSITIONS[fish_index],
			float(fish_definition.get("speed_multiplier", 1.0)),
			12041 + fish_index * 7919
		)
		extra_fish_actors.append(actor)
		fish_index += 1
		loading_progress = 0.65 + 0.35 * float(fish_index) / float(aquarium_fish_ids.size())
		await get_tree().process_frame


func _fish_scale(fish_id: String) -> Vector2:
	return FISH_SCALE_OVERRIDES.get(fish_id, FISH_SCALE)


func _fish_asset_paths(fish_id: String) -> Array[String]:
	var asset_stem := str(FISH_ASSET_STEM_OVERRIDES.get(fish_id, fish_id))
	var asset_root := "res://assets/ui/aquarium/fish/%s/%s" % [asset_stem, asset_stem]
	if fish_id == "green":
		return [
			asset_root + "_swim_left_8f_v2.png",
			asset_root + "_swim_right_8f_v4.png",
			asset_root + "_idle_tail_left_8f_v1.png",
			asset_root + "_idle_tail_right_8f_v1.png"
		]
	var asset_version := str(
		FISH_ASSET_VERSION_OVERRIDES.get(fish_id, FISH_ASSET_VERSION)
	)
	return [
		asset_root + "_swim_left_8f_%s.png" % asset_version,
		asset_root + "_swim_right_8f_%s.png" % asset_version,
		asset_root + "_idle_tail_left_8f_%s.png" % asset_version,
		asset_root + "_idle_tail_right_8f_%s.png" % asset_version
	]


func _style_label(label: Label, label_text: String, font_size: int) -> void:
	label.text = GameFontStylesScript.display_text(label_text)
	GameFontStylesScript.apply_regular(label)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _style_navigation_button(button: Button, button_text: String) -> void:
	button.text = GameFontStylesScript.display_text(button_text)
	button.focus_mode = Control.FOCUS_NONE
	GameFontStylesScript.apply_regular(button)
	button.add_theme_font_size_override("font_size", NAVIGATION_FONT_SIZE)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", TEXT_COLOR)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(1.0, 0.96, 0.84, 0.22)
	hover.set_corner_radius_all(18)
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color(0.55, 0.34, 0.21, 0.12)
	button.add_theme_stylebox_override("pressed", pressed)
