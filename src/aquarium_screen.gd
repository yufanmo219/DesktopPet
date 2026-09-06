class_name AquariumScreen
extends Control

## Aquarium screen with independently animated fish layered over clean artwork.

signal back_requested
signal fish_book_requested
signal animations_prepared

const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const AquariumFishActorScript = preload("res://src/aquarium_fish_actor.gd")

const BACKGROUND_TEXTURE: Texture2D = preload(
	"res://assets/ui/aquarium/aquarium_background_clean_v1.png"
)
const GREEN_FISH_LEFT_SHEET: Texture2D = preload(
	"res://assets/ui/aquarium/fish/green_fish/green_fish_swim_left_8f_v2.png"
)
const GREEN_FISH_RIGHT_SHEET: Texture2D = preload(
	"res://assets/ui/aquarium/fish/green_fish/green_fish_swim_right_8f_v4.png"
)
const GREEN_FISH_IDLE_LEFT_SHEET: Texture2D = preload(
	"res://assets/ui/aquarium/fish/green_fish/green_fish_idle_tail_left_8f_v1.png"
)
const GREEN_FISH_IDLE_RIGHT_SHEET: Texture2D = preload(
	"res://assets/ui/aquarium/fish/green_fish/green_fish_idle_tail_right_8f_v1.png"
)

const SPRITE_SHEET_COLUMNS := 4
const SPRITE_SHEET_ROWS := 2
const GREEN_FISH_FRAME_COUNT := SPRITE_SHEET_COLUMNS * SPRITE_SHEET_ROWS
const GREEN_FISH_FRAME_SIZE := Vector2(384, 512)
const GREEN_FISH_SCALE := Vector2(0.40, 0.40)
const GREEN_FISH_IDLE_SCALE := Vector2(0.385, 0.385)
const GREEN_FISH_ANIMATION_FPS := 8.0
const GREEN_FISH_IDLE_ANIMATION_FPS := 2.5

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
const MIN_SWIM_SPEED := 42.0
const MAX_SWIM_SPEED := 70.0
const MIN_HORIZONTAL_TRAVEL := 150.0
const TARGET_ARRIVAL_DISTANCE := 5.0
const STEERING_SPEED := 3.2
const REST_CHANCE := 0.55
const MIN_REST_SECONDS := 1.5
const MAX_REST_SECONDS := 4.0

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

enum FishMovementState {
	SWIMMING,
	RESTING
}

var rng := RandomNumberGenerator.new()
var aquarium_fish_ids: Array[String] = FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS.duplicate()
var green_fish: Sprite2D
var green_fish_left_frames: Array[Texture2D] = []
var green_fish_right_frames: Array[Texture2D] = []
var green_fish_left_offsets: Array[Vector2] = []
var green_fish_right_offsets: Array[Vector2] = []
var green_fish_idle_left_frames: Array[Texture2D] = []
var green_fish_idle_right_frames: Array[Texture2D] = []
var green_fish_idle_left_offsets: Array[Vector2] = []
var green_fish_idle_right_offsets: Array[Vector2] = []
var green_fish_frame := 0
var animation_elapsed := 0.0
var green_fish_idle_frame := 0
var idle_animation_elapsed := 0.0
var movement_state := FishMovementState.SWIMMING
var movement_target := Vector2.ZERO
var movement_velocity := Vector2.ZERO
var movement_speed := MIN_SWIM_SPEED
var rest_remaining := 0.0
var facing_right := true
var home_button: Button
var fish_book_button: Button
var fish_count_label: Label
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
	rng.randomize()
	_build_background()
	_build_live_ui()


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


func _process(delta: float) -> void:
	if not is_instance_valid(green_fish):
		return
	if movement_state == FishMovementState.RESTING:
		_update_idle_animation(delta)
		rest_remaining = maxf(0.0, rest_remaining - delta)
		movement_velocity = Vector2.ZERO
		green_fish.rotation = lerpf(green_fish.rotation, 0.0, minf(1.0, delta * STEERING_SPEED))
		if rest_remaining <= 0.0:
			_start_swimming(_random_swim_target(green_fish.position))
		return

	_update_swim_animation(delta)
	var to_target := movement_target - green_fish.position
	if to_target.length() <= TARGET_ARRIVAL_DISTANCE:
		green_fish.position = movement_target
		if rng.randf() < REST_CHANCE:
			_start_resting(rng.randf_range(MIN_REST_SECONDS, MAX_REST_SECONDS))
		else:
			_start_swimming(_random_swim_target(green_fish.position))
		return

	var desired_velocity := to_target.normalized() * movement_speed
	movement_velocity = movement_velocity.lerp(
		desired_velocity,
		minf(1.0, STEERING_SPEED * delta)
	)
	if absf(movement_velocity.x) > 1.0:
		_set_facing(movement_velocity.x > 0.0)
	green_fish.position += movement_velocity * delta
	green_fish.position.x = clampf(green_fish.position.x, SWIM_BOUNDS.position.x, SWIM_BOUNDS.end.x)
	green_fish.position.y = clampf(green_fish.position.y, SWIM_BOUNDS.position.y, SWIM_BOUNDS.end.y)
	var target_rotation := clampf(movement_velocity.y / maxf(movement_speed, 1.0), -1.0, 1.0) * 0.07
	green_fish.rotation = lerpf(
		green_fish.rotation,
		target_rotation,
		minf(1.0, delta * STEERING_SPEED)
	)


func _build_background() -> void:
	var background := TextureRect.new()
	background.name = "AquariumBackground"
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _build_live_ui() -> void:
	var title := _make_label("MY AQUARIUM", TITLE_FONT_SIZE)
	title.name = "AquariumTitle"
	title.position = TITLE_POSITION
	title.size = TITLE_SIZE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	fish_count_label = _make_label(
		_fish_capacity_text(),
		FISH_COUNT_FONT_SIZE
	)
	fish_count_label.name = "AquariumFishCount"
	fish_count_label.position = FISH_COUNT_POSITION
	fish_count_label.size = FISH_COUNT_SIZE
	fish_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(fish_count_label)

	home_button = _make_navigation_button("← HOME")
	home_button.name = "AquariumHomeButton"
	home_button.position = HOME_BUTTON_POSITION
	home_button.size = HOME_BUTTON_SIZE
	home_button.pressed.connect(func(): back_requested.emit())
	add_child(home_button)

	fish_book_button = _make_navigation_button("FISH BOOK")
	fish_book_button.name = "AquariumFishBookButton"
	fish_book_button.position = FISH_BOOK_BUTTON_POSITION
	fish_book_button.size = FISH_BOOK_BUTTON_SIZE
	fish_book_button.pressed.connect(func(): fish_book_requested.emit())
	add_child(fish_book_button)


func _build_green_fish_animation() -> void:
	var left_animation := _make_animation_frames(GREEN_FISH_LEFT_SHEET)
	green_fish_left_frames = left_animation.frames
	green_fish_left_offsets = left_animation.offsets
	var right_animation := _make_animation_frames(GREEN_FISH_RIGHT_SHEET)
	green_fish_right_frames = right_animation.frames
	green_fish_right_offsets = right_animation.offsets
	var idle_left_animation := _make_idle_animation_frames(GREEN_FISH_IDLE_LEFT_SHEET, false)
	green_fish_idle_left_frames = idle_left_animation.frames
	green_fish_idle_left_offsets = idle_left_animation.offsets
	var idle_right_animation := _make_idle_animation_frames(GREEN_FISH_IDLE_RIGHT_SHEET, true)
	green_fish_idle_right_frames = idle_right_animation.frames
	green_fish_idle_right_offsets = idle_right_animation.offsets

	green_fish = Sprite2D.new()
	green_fish.name = "GreenFish"
	green_fish.scale = GREEN_FISH_SCALE
	green_fish.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	green_fish.z_index = 2
	green_fish.position = SWIM_BOUNDS.get_center()
	add_child(green_fish)
	_set_facing(true)
	_set_swim_animation_frame(0)


func _build_aquarium_fish_animations_async(loaded_textures: Dictionary) -> void:
	var fish_index := 0
	for fish_id in aquarium_fish_ids:
		var asset_paths := _fish_asset_paths(fish_id)
		var fish_definition: Dictionary = FishCatalogScript.definition(fish_id)
		var actor = AquariumFishActorScript.new()
		actor.name = "AquariumFish_%s" % fish_id
		actor.z_index = 2 + fish_index % 2
		actor.material = FishCatalogScript.visual_material(fish_definition)
		add_child(actor)
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


func _make_animation_frames(sheet: Texture2D) -> Dictionary:
	var frames: Array[Texture2D] = []
	var offsets: Array[Vector2] = []
	for frame_index in range(GREEN_FISH_FRAME_COUNT):
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = sheet
		atlas_texture.region = Rect2(
			Vector2(
				(frame_index % SPRITE_SHEET_COLUMNS) * GREEN_FISH_FRAME_SIZE.x,
				floori(float(frame_index) / SPRITE_SHEET_COLUMNS) * GREEN_FISH_FRAME_SIZE.y
			),
			GREEN_FISH_FRAME_SIZE
		)
		frames.append(atlas_texture)
		var used_rect := atlas_texture.get_image().get_used_rect()
		var visual_center := Vector2(used_rect.position) + Vector2(used_rect.size) * 0.5
		offsets.append(GREEN_FISH_FRAME_SIZE * 0.5 - visual_center)
	return {"frames": frames, "offsets": offsets}


func _make_idle_animation_frames(sheet: Texture2D, frames_face_right: bool) -> Dictionary:
	var animation := _make_animation_frames(sheet)
	var frames: Array[Texture2D] = animation.frames
	var offsets: Array[Vector2] = []
	var reference_bounds: Rect2i = frames[0].get_image().get_used_rect()
	var reference_center := Vector2(reference_bounds.position) + Vector2(reference_bounds.size) * 0.5
	var base_offset := GREEN_FISH_FRAME_SIZE * 0.5 - reference_center
	var reference_anchor := _idle_body_anchor(reference_bounds, frames_face_right)
	for frame in frames:
		var frame_bounds: Rect2i = frame.get_image().get_used_rect()
		var frame_anchor := _idle_body_anchor(frame_bounds, frames_face_right)
		offsets.append(base_offset + reference_anchor - frame_anchor)
	return {"frames": frames, "offsets": offsets}


func _idle_body_anchor(bounds: Rect2i, frames_face_right: bool) -> Vector2:
	# The nose and dorsal-fin top belong to the motionless body. Locking those
	# landmarks prevents the body from shifting while the tail changes width.
	return Vector2(bounds.end.x if frames_face_right else bounds.position.x, bounds.position.y)


func _make_label(label_text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = GameFontStylesScript.display_text(label_text)
	GameFontStylesScript.apply_regular(label)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_navigation_button(button_text: String) -> Button:
	var button := Button.new()
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
	return button


func _start_swimming(target: Vector2) -> void:
	movement_state = FishMovementState.SWIMMING
	green_fish.scale = GREEN_FISH_SCALE
	movement_target = Vector2(
		clampf(target.x, SWIM_BOUNDS.position.x, SWIM_BOUNDS.end.x),
		clampf(target.y, SWIM_BOUNDS.position.y, SWIM_BOUNDS.end.y)
	)
	movement_speed = rng.randf_range(MIN_SWIM_SPEED, MAX_SWIM_SPEED)
	rest_remaining = 0.0
	green_fish_frame = 0
	animation_elapsed = 0.0
	if absf(movement_target.x - green_fish.position.x) > 1.0:
		_set_facing(movement_target.x > green_fish.position.x)
	_set_swim_animation_frame(green_fish_frame)


func _start_resting(duration: float) -> void:
	movement_state = FishMovementState.RESTING
	green_fish.scale = GREEN_FISH_IDLE_SCALE
	rest_remaining = maxf(0.0, duration)
	movement_velocity = Vector2.ZERO
	green_fish_idle_frame = 0
	idle_animation_elapsed = 0.0
	_set_idle_animation_frame(green_fish_idle_frame)


func _random_swim_target(origin: Vector2) -> Vector2:
	var target := SWIM_BOUNDS.get_center()
	for attempt in range(8):
		target = Vector2(
			rng.randf_range(SWIM_BOUNDS.position.x, SWIM_BOUNDS.end.x),
			rng.randf_range(SWIM_BOUNDS.position.y, SWIM_BOUNDS.end.y)
		)
		if absf(target.x - origin.x) >= MIN_HORIZONTAL_TRAVEL:
			break
	return target


func _update_swim_animation(delta: float) -> void:
	animation_elapsed += delta
	var frame_duration := 1.0 / GREEN_FISH_ANIMATION_FPS
	while animation_elapsed >= frame_duration:
		animation_elapsed -= frame_duration
		green_fish_frame = (green_fish_frame + 1) % GREEN_FISH_FRAME_COUNT
		_set_swim_animation_frame(green_fish_frame)


func _update_idle_animation(delta: float) -> void:
	idle_animation_elapsed += delta
	var frame_duration := 1.0 / GREEN_FISH_IDLE_ANIMATION_FPS
	while idle_animation_elapsed >= frame_duration:
		idle_animation_elapsed -= frame_duration
		green_fish_idle_frame = (green_fish_idle_frame + 1) % GREEN_FISH_FRAME_COUNT
		_set_idle_animation_frame(green_fish_idle_frame)


func _set_facing(should_face_right: bool) -> void:
	facing_right = should_face_right
	if movement_state == FishMovementState.RESTING:
		_set_idle_animation_frame(green_fish_idle_frame)
	else:
		_set_swim_animation_frame(green_fish_frame)


func _set_swim_animation_frame(frame_index: int) -> void:
	if not is_instance_valid(green_fish):
		return
	var frames := green_fish_right_frames if facing_right else green_fish_left_frames
	var offsets := green_fish_right_offsets if facing_right else green_fish_left_offsets
	if frames.is_empty():
		return
	var safe_index := posmod(frame_index, frames.size())
	green_fish.texture = frames[safe_index]
	green_fish.offset = offsets[safe_index]


func _set_idle_animation_frame(frame_index: int) -> void:
	if not is_instance_valid(green_fish):
		return
	var frames := green_fish_idle_right_frames if facing_right else green_fish_idle_left_frames
	var offsets := green_fish_idle_right_offsets if facing_right else green_fish_idle_left_offsets
	if frames.is_empty():
		return
	var safe_index := posmod(frame_index, frames.size())
	green_fish.texture = frames[safe_index]
	green_fish.offset = offsets[safe_index]
