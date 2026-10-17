class_name PetCatalog
extends RefCounted

const PetDefinitionScript = preload("res://src/pets/pet_definition.gd")
const PetAnimationClipScript = preload("res://src/pets/pet_animation_clip.gd")

static var _definitions_by_catalog_id: Dictionary = {}
static var _definitions_by_pet_id: Dictionary = {}
static var _ordered_definitions: Array[PetDefinition] = []


static func all_definitions() -> Array[PetDefinition]:
	_ensure_initialized()
	return _ordered_definitions.duplicate()


static func definition_by_catalog_id(catalog_id: String) -> PetDefinition:
	_ensure_initialized()
	return _definitions_by_catalog_id.get(catalog_id.to_lower())


static func definition_by_pet_id(pet_id: String) -> PetDefinition:
	_ensure_initialized()
	return _definitions_by_pet_id.get(pet_id.to_lower())


static func definition_or_default(pet_id: String) -> PetDefinition:
	var definition: PetDefinition = definition_by_pet_id(pet_id)
	return definition if definition != null else default_definition()


static func default_definition() -> PetDefinition:
	return definition_by_catalog_id("maple")


static func store_entries() -> Array:
	var entries: Array = []
	for definition in all_definitions():
		entries.append(definition.store_entry())
	return entries


static func catalog_ids() -> Array[String]:
	var ids: Array[String] = []
	for definition in all_definitions():
		ids.append(definition.catalog_id)
	return ids


static func catalog_id_for_pet_id(pet_id: String) -> String:
	var definition = definition_by_pet_id(pet_id)
	return definition.catalog_id if definition != null else ""


static func validation_errors() -> Array[String]:
	_ensure_initialized()
	var errors: Array[String] = []
	var seen_catalog_ids: Dictionary = {}
	var seen_pet_ids: Dictionary = {}
	for definition in _ordered_definitions:
		if seen_catalog_ids.has(definition.catalog_id):
			errors.append("duplicate catalog_id: %s" % definition.catalog_id)
		seen_catalog_ids[definition.catalog_id] = true
		if seen_pet_ids.has(definition.pet_id):
			errors.append("duplicate pet_id: %s" % definition.pet_id)
		seen_pet_ids[definition.pet_id] = true
		for error in definition.validation_errors():
			errors.append("%s: %s" % [definition.catalog_id, error])
	return errors


static func _ensure_initialized() -> void:
	if not _ordered_definitions.is_empty():
		return
	for definition in _build_definitions():
		_ordered_definitions.append(definition)
		_definitions_by_catalog_id[definition.catalog_id] = definition
		_definitions_by_pet_id[definition.pet_id] = definition


static func _build_definitions() -> Array[PetDefinition]:
	var definitions: Array[PetDefinition] = []
	definitions.append(_definition(
		"maple",
		"default_orange_cat",
		"Maple",
		0,
		"Maple is a warm and curious orange tabby who loves cozy naps and little adventures. With a cheerful heart, Maple will always stay by your side.",
		{
			"idle": "res://assets/pets/current/orange_cat.png",
			"sleep": "res://assets/pets/current/sprites/orange_cat_sleep.png",
			"store_portrait": "res://assets/ui/store/cats/processed/orange_cat_head.png",
			"store_detail": "res://assets/ui/store/cats/processed/orange_cat_store_detail_front.png",
			"station": "res://assets/ui/desktop_station/orange_cat_grass_station_side_v1.png",
			"fishing_catch_failure": "res://assets/pets/current/sprites/orange_cat_cry.png",
			"fishing_round_failure": "res://assets/pets/current/sprites/orange_cat_cry.png"
		},
		{
			"interaction": _default_belly_frames(),
			"move_left": _numbered_frames("res://assets/pets/current/sprites/move_left", 12),
			"move_right": _numbered_frames("res://assets/pets/current/sprites/move_right", 12),
			"shy": _numbered_frames("res://assets/pets/current/sprites/shy", 6),
			"desktop_wink": _numbered_frames("res://assets/pets/current/sprites/desktop_wink", 9),
			"desktop_belly": _default_belly_frames(),
			"sleep_bubble": _numbered_frames("res://assets/pets/current/sprites/sleep_bubble/frames", 14),
			"fishing_default": _numbered_frames("res://assets/ui/fishing/animations/cooperative_v4/pet_frames", 6)
		},
		{"primary": "#f2b36f", "secondary": "#fff0d1", "accent": "#b95d3d", "motif": "MAPLE LEAF"},
		{
			"sleep_scale": 0.82,
			"desktop_idle_weights": {"desktop_wink": 0.68, "desktop_belly": 0.32},
			"clips": {
				"interaction": {"fps": 4.5, "layout_scale": 0.87},
				"move_left": {"fps": 7.0, "loop_start": 3, "layout_scale": 0.98},
				"move_right": {"fps": 7.0, "loop_start": 3, "layout_scale": 0.98},
				"shy": {"fps": 6.0, "layout_scale": 0.95},
				"desktop_wink": {"fps": 6.0, "layout_scale": 0.87},
				"desktop_belly": {"fps": 4.5, "layout_scale": 0.87},
				"sleep_bubble": {"fps": 5.0}
			}
		}
	))
	definitions.append(_definition(
		"mochi", "mochi", "Mochi", 500,
		"A gentle new companion is waiting to meet you.",
		{
			"idle": "res://assets/pets/mochi/home_tail_blink/frame_01.png",
			"sleep": "res://assets/pets/mochi/sleep/mochi_sleep.png",
			"store_portrait": "res://assets/pets/mochi/store/mochi_store_portrait.png",
			"store_detail": "res://assets/pets/mochi/mochi_front_sitting_eyelashes.png",
			"station": "res://assets/ui/desktop_station/mochi/mochi_lotus_pink_daybed_v1.png",
			"fishing_default": "res://assets/pets/mochi/fishing/default/mochi_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/mochi/fishing/cry_v2/frame_08.png",
			"fishing_round_failure": "res://assets/pets/mochi/fishing/failure/mochi_fishing_failure_static.png"
		},
		{
			"home_idle": _numbered_frames("res://assets/pets/mochi/home_tail_blink", 8),
			"sleep_effect": _numbered_frames("res://assets/pets/mochi/sleep/ear_twitch", 8),
			"interaction": _numbered_frames("res://assets/pets/mochi/side_lick_paw_v3", 12),
			"move_left": _numbered_frames("res://assets/pets/mochi/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/mochi/walk_right", 12),
			"fishing_success": _bookended_frames(
				"res://assets/pets/mochi/fishing/default/mochi_fishing_default.png",
				"res://assets/pets/mochi/fishing/success",
				2,
				7
			),
			"fishing_empty_catch": _prefixed_frames(
				"res://assets/pets/mochi/fishing/default/mochi_fishing_default.png",
				"res://assets/pets/mochi/fishing/cry_v2",
				2,
				8
			)
		},
		{"primary": "#c9b7df", "secondary": "#f5effc", "accent": "#71568f", "motif": "MOON"},
		{
			"sleep_effect_mode": "repeat",
			"desktop_idle_weights": {"home_idle": 1.0},
			"clips": {
				"home_idle": {
					"durations": [0.30, 0.10, 0.10, 0.15, 0.15, 0.10, 0.10, 0.40],
					"wait_min": 4.0,
					"wait_max": 8.0,
					"layout_scale": 0.95
				},
				"sleep_effect": {
					"durations": [0.40, 0.10, 0.10, 0.12, 0.12, 0.10, 0.10, 0.45],
					"wait_min": 3.5,
					"wait_max": 9.0,
					"layout_scale": 0.95
				},
				"interaction": {
					"durations": [0.45, 0.10, 0.10, 0.11, 0.14, 0.10, 0.14, 0.11, 0.10, 0.10, 0.11, 0.60],
					"layout_scale": 0.95,
					"visual_bounds_reference": "first"
				},
				"move_left": {"fps": 7.0, "layout_scale": 0.98},
				"move_right": {"fps": 7.0, "layout_scale": 0.98}
			}
		}
	))
	definitions.append(_definition(
		"biscuit", "biscuit", "Biscuit", 1500,
		"A playful new companion is waiting to meet you.",
		{
			"idle": "res://assets/pets/biscuit/home/biscuit_side_sitting.png",
			"sleep": "res://assets/pets/biscuit/sleep/biscuit_sleep.png",
			"store_portrait": "res://assets/pets/biscuit/store/biscuit_store_portrait.png",
			"store_detail": "res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png",
			"station": "res://assets/ui/desktop_station/biscuit/biscuit_cardboard_station.png",
			"fishing_default": "res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/biscuit/fishing/failure/biscuit_fishing_failure.png",
			"fishing_round_failure": "res://assets/pets/biscuit/fishing/failure/biscuit_fishing_failure.png"
		},
		{
			"interaction": _numbered_frames("res://assets/pets/biscuit/desktop/butterfly", 16),
			"move_left": _numbered_frames("res://assets/pets/biscuit/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/biscuit/walk_right", 12),
			"sleep_bubble": _numbered_frames("res://assets/pets/current/sprites/sleep_bubble/frames", 14),
			"fishing_success": _bookended_frames(
				"res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png",
				"res://assets/pets/biscuit/fishing/success_wink_v3",
				2,
				7
			)
		},
		{"primary": "#d9a85f", "secondary": "#fff0c9", "accent": "#81552d", "motif": "BISCUIT"},
		{
			"desktop_idle_weights": {"interaction": 1.0},
			"sleep_bubble_nose_position": Vector2(218.0, 398.0),
			"clips": {
				"interaction": {
					"durations": [
						0.35, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14,
						0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.55
					],
					"layout_scale": 0.95,
					"position_offset": Vector2(0.0, -8.0)
				},
				"move_left": {"fps": 7.0, "layout_scale": 0.98},
				"move_right": {"fps": 7.0, "layout_scale": 0.98},
				"sleep_bubble": {"fps": 5.0}
			}
		}
	))
	var luna_sleep_path := "res://assets/pets/russian_blue/sleep/luna_sleep_v2.png"
	var luna_sleep_effect: Array[String] = [luna_sleep_path]
	luna_sleep_effect.append_array(_numbered_frames_range(
		"res://assets/pets/russian_blue/sleep/face_wash_v2",
		2,
		11
	))
	luna_sleep_effect.append(luna_sleep_path)
	definitions.append(_definition(
		"luna", "luna", "Luna", 3000,
		"A dreamy new companion is waiting to meet you.",
		{
			"idle": "res://assets/pets/russian_blue/home/luna_side_sitting.png",
			"sleep": luna_sleep_path,
			"store_portrait": "res://assets/pets/russian_blue/store/luna_store_portrait.png",
			"store_detail": "res://assets/pets/russian_blue/fishing/default/luna_fishing_default.png",
			"station": "res://assets/ui/desktop_station/luna/luna_mushroom_grass_station_v1.png",
			"fishing_default": "res://assets/pets/russian_blue/fishing/default/luna_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/russian_blue/fishing/failure/luna_fishing_failure.png",
			"fishing_round_failure": "res://assets/pets/russian_blue/fishing/failure/luna_fishing_failure.png"
		},
		{
			"sleep_effect": luna_sleep_effect,
			"interaction": _numbered_frames("res://assets/pets/russian_blue/desktop/stretch_yawn", 12),
			"move_left": _numbered_frames("res://assets/pets/russian_blue/walk_left_v3", 12),
			"move_right": _numbered_frames("res://assets/pets/russian_blue/walk_right_v3", 12),
			"fishing_success": _bookended_frames(
				"res://assets/pets/russian_blue/fishing/default/luna_fishing_default.png",
				"res://assets/pets/russian_blue/fishing/success",
				2,
				7
			)
		},
		{"primary": "#7888bd", "secondary": "#e8edff", "accent": "#404f83", "motif": "STARS"},
		{
			"sleep_effect_mode": "repeat",
			"desktop_idle_weights": {"interaction": 1.0},
			"clips": {
				"sleep_effect": {
					"durations": [0.30, 0.18, 0.16, 0.18, 0.22, 0.35, 0.30, 0.22, 0.18, 0.16, 0.18, 0.40],
					"wait_min": 4.0,
					"wait_max": 10.0,
					"layout_scale": 0.95,
					"visual_bounds_reference": "sleep"
				},
				"interaction": {
					"durations": [0.40, 0.14, 0.14, 0.16, 0.18, 0.22, 0.24, 0.18, 0.16, 0.16, 0.20, 0.55],
					"layout_scale": 0.95,
					"layout_size_reference": "idle"
				},
				"move_left": {"fps": 12.0, "layout_scale": 0.98, "fixed_visual_bounds": Rect2(0.0, 0.0, 704.0, 500.0)},
				"move_right": {"fps": 12.0, "layout_scale": 0.98, "fixed_visual_bounds": Rect2(0.0, 0.0, 704.0, 500.0)}
			}
		}
	))
	definitions.append(_definition(
		"poppy", "poppy", "Poppy", 5000,
		"A cheerful new companion is waiting to meet you.",
		{
			"idle": "res://assets/pets/blue_british/home/poppy_side_sitting.png",
			"sleep": "res://assets/pets/blue_british/sleep/poppy_sleep.png",
			"store_portrait": "res://assets/pets/blue_british/store/poppy_store_portrait.png",
			"store_detail": "res://assets/pets/blue_british/fishing/default/poppy_fishing_default.png",
			"station": "res://assets/ui/desktop_station/blue_british/blue_british_mushroom_grass_station_v1.png",
			"fishing_default": "res://assets/pets/blue_british/fishing/default/poppy_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/blue_british/fishing/failure/poppy_fishing_failure.png",
			"fishing_round_failure": "res://assets/pets/blue_british/fishing/failure/poppy_fishing_failure.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/blue_british/sleep/face_rub", 12),
			"interaction": _numbered_frames("res://assets/pets/blue_british/desktop/teaser_play", 16),
			"move_left": _numbered_frames("res://assets/pets/blue_british/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/blue_british/walk_right", 12),
			"fishing_success": _numbered_frames("res://assets/pets/blue_british/fishing/success", 8)
		},
		{"primary": "#e78f9f", "secondary": "#ffe8ec", "accent": "#9b4156", "motif": "POPPY"},
		{
			"sleep_effect_mode": "repeat",
			"desktop_idle_weights": {"sleep_effect": 1.0},
			"clips": {
				"sleep_effect": {
					"durations": [0.22, 0.14, 0.14, 0.17, 0.16, 0.16, 0.18, 0.16, 0.16, 0.17, 0.18, 0.30],
					"wait_min": 4.0,
					"wait_max": 10.0,
					"layout_scale": 0.95,
					"layout_size_reference": "idle"
				},
				"interaction": {
					"durations": [0.75, 0.50, 0.36, 0.60, 0.44, 0.52, 0.42, 0.42, 0.32, 0.27, 0.27, 0.32, 0.45, 0.50, 0.65, 0.90],
					"layout_scale": 0.95,
					"layout_size_reference": "idle",
					"visual_bounds_reference": "first"
				},
				"move_left": {"fps": 7.0, "layout_scale": 0.98},
				"move_right": {"fps": 7.0, "layout_scale": 0.98}
			}
		}
	))
	definitions.append(_definition(
		"black_cat", "black_cat", "Sable", 7000,
		"A cool and distant companion with a quietly loyal heart.",
		{
			"idle": "res://assets/pets/black_cat/home/black_cat_side_sitting.png",
			"sleep": "res://assets/pets/black_cat/sleep/black_cat_sleep.png",
			"store_portrait": "res://assets/pets/black_cat/store/black_cat_store_portrait.png",
			"store_detail": "res://assets/pets/black_cat/fishing/default/black_cat_fishing_default.png",
			"station": "res://assets/ui/desktop_station/black_cat/black_cat_folded_blanket_station.png",
			"fishing_default": "res://assets/pets/black_cat/fishing/default/black_cat_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/black_cat/fishing/failure/black_cat_fishing_failure.png",
			"fishing_round_failure": "res://assets/pets/black_cat/fishing/failure/black_cat_fishing_failure.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/black_cat/sleep/fall_asleep", 8),
			"interaction": _numbered_frames("res://assets/pets/black_cat/fishing/success", 8),
			"move_left": _numbered_frames("res://assets/pets/black_cat/walk_left_v3", 12),
			"move_right": _numbered_frames("res://assets/pets/black_cat/walk_right_v3", 12),
			"fishing_success": _numbered_frames("res://assets/pets/black_cat/fishing/success", 8)
		},
		{"primary": "#5f6270", "secondary": "#e5e4e8", "accent": "#30323c", "motif": "MIDNIGHT"},
		{
			"sleep_effect_mode": "once_hold",
			"sleep_scale": 0.76,
			"linear_texture_filter": true,
			"desktop_idle_weights": {"interaction": 1.0},
			"clips": {
				"sleep_effect": {
					"durations": [0.48, 0.18, 0.22, 0.30, 0.34, 0.44, 0.50, 0.70],
					"layout_scale": 0.76
				},
				"interaction": {
					"durations": [0.34, 0.18, 0.22, 0.26, 0.24, 0.24, 0.30, 0.58],
					"layout_scale": 0.95,
					"layout_size_reference": "idle"
				},
				"move_left": {"fps": 10.0, "layout_scale": 0.98, "fixed_visual_bounds": Rect2(0.0, 0.0, 704.0, 500.0)},
				"move_right": {"fps": 10.0, "layout_scale": 0.98, "fixed_visual_bounds": Rect2(0.0, 0.0, 704.0, 500.0)}
			}
		}
	))
	definitions.append(_definition(
		"siamese", "siamese", "Pearl", 9000,
		"A graceful seal-point companion with bright sky-blue eyes and a curious, affectionate nature.",
		{
			"idle": "res://assets/pets/siamese/home/siamese_side_sitting.png",
			"sleep": "res://assets/pets/siamese/sleep/siamese_sleep.png",
			"store_portrait": "res://assets/pets/siamese/store/siamese_store_portrait.png",
			"store_detail": "res://assets/pets/siamese/fishing/default/siamese_fishing_default.png",
			"station": "res://assets/ui/desktop_station/siamese/siamese_tree_branch_station.png",
			"fishing_default": "res://assets/pets/siamese/fishing/default/siamese_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/siamese/fishing/failure/siamese_fishing_failure.png",
			"fishing_round_failure": "res://assets/pets/siamese/fishing/failure/siamese_fishing_failure.png"
		},
		{
			"interaction": _numbered_frames("res://assets/pets/siamese/desktop/treat", 12),
			"move_left": _numbered_frames("res://assets/pets/siamese/walk_left", 4),
			"move_right": _numbered_frames("res://assets/pets/siamese/walk_right", 4),
			"fishing_success": _numbered_frames("res://assets/pets/siamese/fishing/success", 8)
		},
		{"primary": "#c9b08b", "secondary": "#f7efe2", "accent": "#5a718c", "motif": "SIAMESE SILK"},
		{
			"sleep_effect_mode": "none",
			"clips": {
				"interaction": {
					"durations": [0.36, 0.22, 0.27, 0.10, 0.125, 0.09, 0.125, 0.09, 0.125, 0.13, 0.25, 0.65],
					"layout_scale": 0.95,
					"layout_size_reference": "idle",
					"visual_bounds_reference": "last"
				},
				"move_left": {"fps": 7.0, "layout_scale": 0.98},
				"move_right": {"fps": 7.0, "layout_scale": 0.98}
			}
		}
	))
	definitions.append(_definition(
		"golden_munchkin", "golden_munchkin", "Honey", 11000,
		"A round golden short-legged companion who loves soft blankets and cozy naps.",
		{
			"idle": "res://assets/pets/golden_munchkin/home/golden_munchkin_side_sitting.png",
			"sleep": "res://assets/pets/golden_munchkin/sleep/golden_munchkin_sleep.png",
			"store_portrait": "res://assets/pets/golden_munchkin/store/golden_munchkin_store_portrait.png",
			"store_detail": "res://assets/pets/golden_munchkin/fishing/default/golden_munchkin_fishing_default.png",
			"station": "res://assets/ui/desktop_station/golden_munchkin/golden_munchkin_ivory_blanket_station.png",
			"fishing_default": "res://assets/pets/golden_munchkin/fishing/default/golden_munchkin_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/golden_munchkin/fishing/failure/golden_munchkin_fishing_failure.png",
			"fishing_round_failure": "res://assets/pets/golden_munchkin/fishing/failure/golden_munchkin_fishing_failure.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/golden_munchkin/sleep/tail_sweep", 15),
			"interaction": _numbered_frames("res://assets/pets/golden_munchkin/desktop/failed_roll", 12),
			"move_left": _numbered_frames("res://assets/pets/golden_munchkin/move_left", 8),
			"move_right": _numbered_frames("res://assets/pets/golden_munchkin/move_right", 8),
			"fishing_success": _numbered_frames("res://assets/pets/golden_munchkin/fishing/success", 8)
		},
		{"primary": "#d6ad65", "secondary": "#fff8e7", "accent": "#8b6331", "motif": "IVORY CLOUD"},
		{
			"sleep_effect_mode": "none",
			"draw_ground_shadow": false,
			"clips": {
				"sleep_effect": {
					"durations": [0.26, 0.17, 0.17, 0.17, 0.52, 0.17, 0.17, 0.17, 0.24, 0.17, 0.17, 0.55, 0.18, 0.18, 0.30],
					"layout_scale": 0.95,
					"layout_size_reference": "sleep"
				},
				"interaction": {
					"durations": [0.60, 0.24, 0.22, 0.24, 0.22, 0.15, 0.20, 0.52, 0.26, 0.24, 0.24, 0.75],
					"layout_scale": 0.95,
					"layout_size_reference": "idle",
					"visual_bounds_reference": "first"
				},
				"move_left": {"fps": 7.0, "layout_scale": 0.98},
				"move_right": {"fps": 7.0, "layout_scale": 0.98}
			}
		}
	))
	definitions.append(_definition(
		"maine_coon", "maine_coon", "Cedar", 20000,
		"A gentle gray-and-white giant with a proud ruff and a soft heart.",
		{
			"idle": "res://assets/pets/maine_coon/home/maine_coon_side_sitting.png",
			"sleep": "res://assets/pets/maine_coon/sleep/maine_coon_sleep.png",
			"store_portrait": "res://assets/pets/maine_coon/store/maine_coon_store_portrait.png",
			"store_detail": "res://assets/pets/maine_coon/fishing/default/maine_coon_fishing_default.png",
			"station": "res://assets/ui/desktop_station/maine_coon/maine_coon_forest_wool_station.png",
			"fishing_default": "res://assets/pets/maine_coon/fishing/default/maine_coon_fishing_default.png",
			"fishing_catch_failure": "res://assets/pets/maine_coon/fishing/failure/maine_coon_fishing_failure.png",
			"fishing_round_failure": "res://assets/pets/maine_coon/fishing/failure/maine_coon_fishing_failure.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/maine_coon/sleep/paw_lick", 8),
			"interaction": _numbered_frames("res://assets/pets/maine_coon/desktop/nuzzle", 8),
			"move_left": _numbered_frames("res://assets/pets/maine_coon/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/maine_coon/walk_right", 12),
			"fishing_success": _numbered_frames("res://assets/pets/maine_coon/fishing/success", 8)
		},
		{"primary": "#667660", "secondary": "#f0eadc", "accent": "#34453a", "motif": "FOREST WOOL"},
		{
			"sleep_effect_mode": "once_hold",
			"draw_ground_shadow": false,
			"desktop_idle_weights": {"interaction": 1.0},
			"clips": {
				"sleep_effect": {
					"durations": [0.70, 0.28, 0.32, 0.40, 0.32, 0.26, 0.30, 0.95],
					"layout_scale": 0.95
				},
				"interaction": {
					"durations": [0.42, 0.18, 0.22, 0.25, 0.24, 0.35, 0.22, 0.68],
					"layout_scale": 0.95,
					"layout_size_reference": "idle",
					"visual_bounds_reference": "first"
				},
				"move_left": {"fps": 7.0, "layout_scale": 0.98},
				"move_right": {"fps": 7.0, "layout_scale": 0.98}
			}
		}
	))
	return definitions


static func _definition(
	catalog_id: String,
	pet_id: String,
	display_name: String,
	price: int,
	description: String,
	texture_paths: Dictionary,
	animation_paths: Dictionary,
	station_theme: Dictionary,
	presentation: Dictionary = {}
) -> PetDefinition:
	var definition: PetDefinition = PetDefinitionScript.new()
	definition.catalog_id = catalog_id
	definition.pet_id = pet_id
	definition.display_name = display_name
	definition.species = "Cat"
	definition.price = price
	definition.description = description
	definition.texture_paths = texture_paths.duplicate(true)
	definition.animation_clips = _build_animation_clips(
		animation_paths,
		presentation.get("clips", {})
	)
	definition.station_theme = station_theme.duplicate(true)
	definition.sleep_effect_mode = str(
		presentation.get("sleep_effect_mode", "bubble")
	)
	definition.desktop_idle_weights = (
		presentation.get("desktop_idle_weights", {}) as Dictionary
	).duplicate(true)
	definition.idle_scale = float(presentation.get("idle_scale", 0.95))
	definition.sleep_scale = float(presentation.get("sleep_scale", 0.95))
	definition.sleep_bubble_nose_position = presentation.get(
		"sleep_bubble_nose_position",
		Vector2(374.0, 338.0)
	)
	definition.draw_ground_shadow = bool(
		presentation.get("draw_ground_shadow", true)
	)
	definition.linear_texture_filter = bool(
		presentation.get("linear_texture_filter", false)
	)
	return definition


static func _build_animation_clips(
	animation_paths: Dictionary,
	clip_configs: Dictionary
) -> Dictionary:
	var clips: Dictionary = {}
	for raw_key in animation_paths:
		var key := str(raw_key)
		var paths: Array[String] = []
		var raw_paths: Variant = animation_paths.get(raw_key, [])
		if raw_paths is Array:
			for raw_path in raw_paths:
				paths.append(str(raw_path))
		var config: Dictionary = clip_configs.get(key, {})
		clips[key] = _animation_clip(key, paths, config)
	return clips


static func _animation_clip(
	clip_id: String,
	frame_paths: Array[String],
	config: Dictionary
) -> PetAnimationClip:
	var clip: PetAnimationClip = PetAnimationClipScript.new()
	clip.clip_id = clip_id
	clip.frame_paths = frame_paths.duplicate()
	var raw_durations: Variant = config.get("durations", [])
	if raw_durations is Array:
		for raw_duration in raw_durations:
			clip.frame_durations.append(float(raw_duration))
	clip.fps = float(config.get("fps", 0.0))
	clip.loop_start_frame = int(config.get("loop_start", 0))
	clip.wait_min = float(config.get("wait_min", 0.0))
	clip.wait_max = float(config.get("wait_max", clip.wait_min))
	clip.layout_scale = float(config.get("layout_scale", 0.82))
	clip.layout_size_reference = str(
		config.get("layout_size_reference", "current")
	)
	clip.visual_bounds_reference = str(
		config.get("visual_bounds_reference", "current")
	)
	if config.has("fixed_visual_bounds"):
		clip.fixed_visual_bounds = config["fixed_visual_bounds"]
		clip.uses_fixed_visual_bounds = true
	clip.position_offset = config.get("position_offset", Vector2.ZERO)
	return clip


static func _numbered_frames(directory: String, count: int) -> Array[String]:
	return _numbered_frames_range(directory, 1, count)


static func _numbered_frames_range(
	directory: String,
	first_frame: int,
	last_frame: int
) -> Array[String]:
	var paths: Array[String] = []
	for frame_number in range(first_frame, last_frame + 1):
		paths.append("%s/frame_%02d.png" % [directory, frame_number])
	return paths


static func _default_belly_frames() -> Array[String]:
	var roll_frames := _numbered_frames("res://assets/pets/current/sprites/desktop_roll", 6)
	var frames: Array[String] = roll_frames.duplicate()
	frames.append_array(_numbered_frames(
		"res://assets/pets/current/sprites/desktop_biscuit",
		9
	))
	for index in range(roll_frames.size() - 1, -1, -1):
		frames.append(roll_frames[index])
	return frames


static func _prefixed_frames(
	first_path: String,
	directory: String,
	first_frame: int,
	last_frame: int
) -> Array[String]:
	var frames: Array[String] = [first_path]
	frames.append_array(_numbered_frames_range(directory, first_frame, last_frame))
	return frames


static func _bookended_frames(
	bookend_path: String,
	directory: String,
	first_frame: int,
	last_frame: int
) -> Array[String]:
	var frames := _prefixed_frames(
		bookend_path,
		directory,
		first_frame,
		last_frame
	)
	frames.append(bookend_path)
	return frames
