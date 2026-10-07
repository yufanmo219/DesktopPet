class_name PetCatalog
extends RefCounted

const PetDefinitionScript = preload("res://src/pets/pet_definition.gd")

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
			"station": "res://assets/ui/desktop_station/orange_cat_grass_station_side_v1.png"
		},
		{
			"interaction": _default_belly_frames(),
			"move_left": _numbered_frames("res://assets/pets/current/sprites/move_left", 12),
			"move_right": _numbered_frames("res://assets/pets/current/sprites/move_right", 12),
			"shy": _numbered_frames("res://assets/pets/current/sprites/shy", 6),
			"desktop_wink": _numbered_frames("res://assets/pets/current/sprites/desktop_wink", 9),
			"desktop_belly": _default_belly_frames(),
			"sleep_bubble": _numbered_frames("res://assets/pets/current/sprites/sleep_bubble/frames", 14)
		},
		{"primary": "#f2b36f", "secondary": "#fff0d1", "accent": "#b95d3d", "motif": "MAPLE LEAF"}
	))
	definitions.append(_definition(
		"mochi", "mochi", "Mochi", 500,
		"A gentle new companion is waiting to meet you.",
		{
			"idle": "res://assets/pets/mochi/home_tail_blink/frame_01.png",
			"sleep": "res://assets/pets/mochi/sleep/mochi_sleep.png",
			"store_portrait": "res://assets/pets/mochi/store/mochi_store_portrait.png",
			"store_detail": "res://assets/pets/mochi/mochi_front_sitting_eyelashes.png",
			"station": "res://assets/ui/desktop_station/mochi/mochi_lotus_pink_daybed_v1.png"
		},
		{
			"home_idle": _numbered_frames("res://assets/pets/mochi/home_tail_blink", 8),
			"sleep_effect": _numbered_frames("res://assets/pets/mochi/sleep/ear_twitch", 8),
			"interaction": _numbered_frames("res://assets/pets/mochi/side_lick_paw_v3", 12),
			"move_left": _numbered_frames("res://assets/pets/mochi/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/mochi/walk_right", 12)
		},
		{"primary": "#c9b7df", "secondary": "#f5effc", "accent": "#71568f", "motif": "MOON"}
	))
	definitions.append(_definition(
		"biscuit", "biscuit", "Biscuit", 1500,
		"A playful new companion is waiting to meet you.",
		{
			"idle": "res://assets/pets/biscuit/home/biscuit_side_sitting.png",
			"sleep": "res://assets/pets/biscuit/sleep/biscuit_sleep.png",
			"store_portrait": "res://assets/pets/biscuit/store/biscuit_store_portrait.png",
			"store_detail": "res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png",
			"station": "res://assets/ui/desktop_station/biscuit/biscuit_cardboard_station.png"
		},
		{
			"interaction": _numbered_frames("res://assets/pets/biscuit/desktop/butterfly", 16),
			"move_left": _numbered_frames("res://assets/pets/biscuit/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/biscuit/walk_right", 12),
			"sleep_bubble": _numbered_frames("res://assets/pets/current/sprites/sleep_bubble/frames", 14)
		},
		{"primary": "#d9a85f", "secondary": "#fff0c9", "accent": "#81552d", "motif": "BISCUIT"}
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
			"station": "res://assets/ui/desktop_station/luna/luna_mushroom_grass_station_v1.png"
		},
		{
			"sleep_effect": luna_sleep_effect,
			"interaction": _numbered_frames("res://assets/pets/russian_blue/desktop/stretch_yawn", 12),
			"move_left": _numbered_frames("res://assets/pets/russian_blue/walk_left_v3", 12),
			"move_right": _numbered_frames("res://assets/pets/russian_blue/walk_right_v3", 12)
		},
		{"primary": "#7888bd", "secondary": "#e8edff", "accent": "#404f83", "motif": "STARS"}
	))
	definitions.append(_definition(
		"poppy", "poppy", "Poppy", 5000,
		"A cheerful new companion is waiting to meet you.",
		{
			"idle": "res://assets/pets/blue_british/home/poppy_side_sitting.png",
			"sleep": "res://assets/pets/blue_british/sleep/poppy_sleep.png",
			"store_portrait": "res://assets/pets/blue_british/store/poppy_store_portrait.png",
			"store_detail": "res://assets/pets/blue_british/fishing/default/poppy_fishing_default.png",
			"station": "res://assets/ui/desktop_station/blue_british/blue_british_mushroom_grass_station_v1.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/blue_british/sleep/face_rub", 12),
			"interaction": _numbered_frames("res://assets/pets/blue_british/desktop/teaser_play", 16),
			"move_left": _numbered_frames("res://assets/pets/blue_british/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/blue_british/walk_right", 12)
		},
		{"primary": "#e78f9f", "secondary": "#ffe8ec", "accent": "#9b4156", "motif": "POPPY"}
	))
	definitions.append(_definition(
		"black_cat", "black_cat", "Sable", 7000,
		"A cool and distant companion with a quietly loyal heart.",
		{
			"idle": "res://assets/pets/black_cat/home/black_cat_side_sitting.png",
			"sleep": "res://assets/pets/black_cat/sleep/black_cat_sleep.png",
			"store_portrait": "res://assets/pets/black_cat/store/black_cat_store_portrait.png",
			"store_detail": "res://assets/pets/black_cat/fishing/default/black_cat_fishing_default.png",
			"station": "res://assets/ui/desktop_station/black_cat/black_cat_folded_blanket_station.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/black_cat/sleep/fall_asleep", 8),
			"interaction": _numbered_frames("res://assets/pets/black_cat/fishing/success", 8),
			"move_left": _numbered_frames("res://assets/pets/black_cat/walk_left_v3", 12),
			"move_right": _numbered_frames("res://assets/pets/black_cat/walk_right_v3", 12)
		},
		{"primary": "#5f6270", "secondary": "#e5e4e8", "accent": "#30323c", "motif": "MIDNIGHT"}
	))
	definitions.append(_definition(
		"siamese", "siamese", "Pearl", 9000,
		"A graceful seal-point companion with bright sky-blue eyes and a curious, affectionate nature.",
		{
			"idle": "res://assets/pets/siamese/home/siamese_side_sitting.png",
			"sleep": "res://assets/pets/siamese/sleep/siamese_sleep.png",
			"store_portrait": "res://assets/pets/siamese/store/siamese_store_portrait.png",
			"store_detail": "res://assets/pets/siamese/fishing/default/siamese_fishing_default.png",
			"station": "res://assets/ui/desktop_station/siamese/siamese_tree_branch_station.png"
		},
		{
			"interaction": _numbered_frames("res://assets/pets/siamese/desktop/treat", 12),
			"move_left": _numbered_frames("res://assets/pets/siamese/walk_left", 4),
			"move_right": _numbered_frames("res://assets/pets/siamese/walk_right", 4)
		},
		{"primary": "#c9b08b", "secondary": "#f7efe2", "accent": "#5a718c", "motif": "SIAMESE SILK"}
	))
	definitions.append(_definition(
		"golden_munchkin", "golden_munchkin", "Honey", 11000,
		"A round golden short-legged companion who loves soft blankets and cozy naps.",
		{
			"idle": "res://assets/pets/golden_munchkin/home/golden_munchkin_side_sitting.png",
			"sleep": "res://assets/pets/golden_munchkin/sleep/golden_munchkin_sleep.png",
			"store_portrait": "res://assets/pets/golden_munchkin/store/golden_munchkin_store_portrait.png",
			"store_detail": "res://assets/pets/golden_munchkin/fishing/default/golden_munchkin_fishing_default.png",
			"station": "res://assets/ui/desktop_station/golden_munchkin/golden_munchkin_ivory_blanket_station.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/golden_munchkin/sleep/tail_sweep", 15),
			"interaction": _numbered_frames("res://assets/pets/golden_munchkin/desktop/failed_roll", 12),
			"move_left": _numbered_frames("res://assets/pets/golden_munchkin/move_left", 8),
			"move_right": _numbered_frames("res://assets/pets/golden_munchkin/move_right", 8)
		},
		{"primary": "#d6ad65", "secondary": "#fff8e7", "accent": "#8b6331", "motif": "IVORY CLOUD"}
	))
	definitions.append(_definition(
		"maine_coon", "maine_coon", "Cedar", 20000,
		"A gentle gray-and-white giant with a proud ruff and a soft heart.",
		{
			"idle": "res://assets/pets/maine_coon/home/maine_coon_side_sitting.png",
			"sleep": "res://assets/pets/maine_coon/sleep/maine_coon_sleep.png",
			"store_portrait": "res://assets/pets/maine_coon/store/maine_coon_store_portrait.png",
			"store_detail": "res://assets/pets/maine_coon/fishing/default/maine_coon_fishing_default.png",
			"station": "res://assets/ui/desktop_station/maine_coon/maine_coon_forest_wool_station.png"
		},
		{
			"sleep_effect": _numbered_frames("res://assets/pets/maine_coon/sleep/paw_lick", 8),
			"interaction": _numbered_frames("res://assets/pets/maine_coon/desktop/nuzzle", 8),
			"move_left": _numbered_frames("res://assets/pets/maine_coon/walk_left", 12),
			"move_right": _numbered_frames("res://assets/pets/maine_coon/walk_right", 12)
		},
		{"primary": "#667660", "secondary": "#f0eadc", "accent": "#34453a", "motif": "FOREST WOOL"}
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
	station_theme: Dictionary
) -> PetDefinition:
	var definition: PetDefinition = PetDefinitionScript.new()
	definition.catalog_id = catalog_id
	definition.pet_id = pet_id
	definition.display_name = display_name
	definition.species = "Cat"
	definition.price = price
	definition.description = description
	definition.texture_paths = texture_paths.duplicate(true)
	definition.animation_paths = animation_paths.duplicate(true)
	definition.station_theme = station_theme.duplicate(true)
	return definition


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
