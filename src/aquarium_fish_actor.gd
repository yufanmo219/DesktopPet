class_name AquariumFishActor
extends Sprite2D

## One independently moving aquarium fish with swim and tail-only idle cycles.

const SPRITE_SHEET_COLUMNS := 4
const SPRITE_SHEET_ROWS := 2
const FRAME_COUNT := SPRITE_SHEET_COLUMNS * SPRITE_SHEET_ROWS
const FRAME_SIZE := Vector2(384, 512)
const SWIM_ANIMATION_FPS := 8.0
const IDLE_ANIMATION_FPS := 2.5
const TARGET_ARRIVAL_DISTANCE := 5.0
const MIN_HORIZONTAL_TRAVEL := 120.0
const STEERING_SPEED := 3.2
const REST_CHANCE := 0.55
const MIN_REST_SECONDS := 1.5
const MAX_REST_SECONDS := 4.0

enum MovementState {
	SWIMMING,
	RESTING
}

var fish_id := ""
var swim_bounds := Rect2()
var base_scale := Vector2.ONE
var min_swim_speed := 42.0
var max_swim_speed := 70.0
var rng := RandomNumberGenerator.new()
var movement_state := MovementState.SWIMMING
var movement_target := Vector2.ZERO
var movement_velocity := Vector2.ZERO
var movement_speed := 42.0
var rest_remaining := 0.0
var facing_right := true
var swim_frame := 0
var swim_animation_elapsed := 0.0
var idle_frame := 0
var idle_animation_elapsed := 0.0
var configured := false

var swim_left_frames: Array[Texture2D] = []
var swim_right_frames: Array[Texture2D] = []
var swim_left_offsets: Array[Vector2] = []
var swim_right_offsets: Array[Vector2] = []
var idle_left_frames: Array[Texture2D] = []
var idle_right_frames: Array[Texture2D] = []
var idle_left_offsets: Array[Vector2] = []
var idle_right_offsets: Array[Vector2] = []


func configure(
	configured_fish_id: String,
	swim_left_sheet: Texture2D,
	swim_right_sheet: Texture2D,
	idle_left_sheet: Texture2D,
	idle_right_sheet: Texture2D,
	configured_bounds: Rect2,
	configured_scale: Vector2,
	initial_position: Vector2,
	speed_multiplier: float,
	random_seed: int
) -> void:
	_configure_base(
		configured_fish_id,
		configured_bounds,
		configured_scale,
		initial_position,
		speed_multiplier,
		random_seed
	)

	var left_swim := _make_animation_frames(swim_left_sheet)
	swim_left_frames = left_swim.frames
	swim_left_offsets = left_swim.offsets
	var right_swim := _make_animation_frames(swim_right_sheet)
	swim_right_frames = right_swim.frames
	swim_right_offsets = right_swim.offsets
	var left_idle := _make_idle_animation_frames(idle_left_sheet, false)
	idle_left_frames = left_idle.frames
	idle_left_offsets = left_idle.offsets
	var right_idle := _make_idle_animation_frames(idle_right_sheet, true)
	idle_right_frames = right_idle.frames
	idle_right_offsets = right_idle.offsets

	_finish_configuration()


func configure_async(
	configured_fish_id: String,
	swim_left_sheet: Texture2D,
	swim_right_sheet: Texture2D,
	idle_left_sheet: Texture2D,
	idle_right_sheet: Texture2D,
	configured_bounds: Rect2,
	configured_scale: Vector2,
	initial_position: Vector2,
	speed_multiplier: float,
	random_seed: int
) -> void:
	_configure_base(
		configured_fish_id,
		configured_bounds,
		configured_scale,
		initial_position,
		speed_multiplier,
		random_seed
	)

	var left_swim := _make_animation_frames(swim_left_sheet)
	swim_left_frames = left_swim.frames
	swim_left_offsets = left_swim.offsets
	await get_tree().process_frame

	var right_swim := _make_animation_frames(swim_right_sheet)
	swim_right_frames = right_swim.frames
	swim_right_offsets = right_swim.offsets
	await get_tree().process_frame

	var left_idle := _make_idle_animation_frames(idle_left_sheet, false)
	idle_left_frames = left_idle.frames
	idle_left_offsets = left_idle.offsets
	await get_tree().process_frame

	var right_idle := _make_idle_animation_frames(idle_right_sheet, true)
	idle_right_frames = right_idle.frames
	idle_right_offsets = right_idle.offsets
	await get_tree().process_frame

	_finish_configuration()


func _configure_base(
	configured_fish_id: String,
	configured_bounds: Rect2,
	configured_scale: Vector2,
	initial_position: Vector2,
	speed_multiplier: float,
	random_seed: int
) -> void:
	fish_id = configured_fish_id
	swim_bounds = configured_bounds
	base_scale = configured_scale
	position = initial_position
	scale = base_scale
	min_swim_speed = 42.0 * speed_multiplier
	max_swim_speed = 70.0 * speed_multiplier
	rng.seed = random_seed
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR



func _finish_configuration() -> void:
	configured = true
	_start_swimming(_random_swim_target(position))


func _process(delta: float) -> void:
	if not configured:
		return
	if movement_state == MovementState.RESTING:
		_update_idle_animation(delta)
		rest_remaining = maxf(0.0, rest_remaining - delta)
		movement_velocity = Vector2.ZERO
		rotation = lerpf(rotation, 0.0, minf(1.0, delta * STEERING_SPEED))
		if rest_remaining <= 0.0:
			_start_swimming(_random_swim_target(position))
		return

	_update_swim_animation(delta)
	var to_target := movement_target - position
	if to_target.length() <= TARGET_ARRIVAL_DISTANCE:
		position = movement_target
		if rng.randf() < REST_CHANCE:
			_start_resting(rng.randf_range(MIN_REST_SECONDS, MAX_REST_SECONDS))
		else:
			_start_swimming(_random_swim_target(position))
		return

	var desired_velocity := to_target.normalized() * movement_speed
	movement_velocity = movement_velocity.lerp(
		desired_velocity,
		minf(1.0, STEERING_SPEED * delta)
	)
	if absf(movement_velocity.x) > 1.0:
		_set_facing(movement_velocity.x > 0.0)
	position += movement_velocity * delta
	position.x = clampf(position.x, swim_bounds.position.x, swim_bounds.end.x)
	position.y = clampf(position.y, swim_bounds.position.y, swim_bounds.end.y)
	var target_rotation := clampf(
		movement_velocity.y / maxf(movement_speed, 1.0),
		-1.0,
		1.0
	) * 0.07
	rotation = lerpf(rotation, target_rotation, minf(1.0, delta * STEERING_SPEED))


func _make_animation_frames(sheet: Texture2D) -> Dictionary:
	var frames: Array[Texture2D] = []
	var offsets: Array[Vector2] = []
	for frame_index in range(FRAME_COUNT):
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = sheet
		atlas_texture.filter_clip = true
		atlas_texture.region = Rect2(
			Vector2(
				(frame_index % SPRITE_SHEET_COLUMNS) * FRAME_SIZE.x,
				floori(float(frame_index) / SPRITE_SHEET_COLUMNS) * FRAME_SIZE.y
			),
			FRAME_SIZE
		)
		frames.append(atlas_texture)
		var used_rect := atlas_texture.get_image().get_used_rect()
		var visual_center := Vector2(used_rect.position) + Vector2(used_rect.size) * 0.5
		offsets.append(FRAME_SIZE * 0.5 - visual_center)
	return {"frames": frames, "offsets": offsets}


func _make_idle_animation_frames(sheet: Texture2D, frames_face_right: bool) -> Dictionary:
	var animation := _make_animation_frames(sheet)
	var frames: Array[Texture2D] = animation.frames
	var offsets: Array[Vector2] = []
	var reference_bounds: Rect2i = frames[0].get_image().get_used_rect()
	var reference_center := Vector2(reference_bounds.position) + Vector2(reference_bounds.size) * 0.5
	var base_offset := FRAME_SIZE * 0.5 - reference_center
	var reference_anchor := _idle_body_anchor(reference_bounds, frames_face_right)
	for frame in frames:
		var frame_bounds: Rect2i = frame.get_image().get_used_rect()
		var frame_anchor := _idle_body_anchor(frame_bounds, frames_face_right)
		offsets.append(base_offset + reference_anchor - frame_anchor)
	return {"frames": frames, "offsets": offsets}


func _idle_body_anchor(bounds: Rect2i, frames_face_right: bool) -> Vector2:
	return Vector2(bounds.end.x if frames_face_right else bounds.position.x, bounds.position.y)


func _start_swimming(target: Vector2) -> void:
	movement_state = MovementState.SWIMMING
	scale = base_scale
	movement_target = Vector2(
		clampf(target.x, swim_bounds.position.x, swim_bounds.end.x),
		clampf(target.y, swim_bounds.position.y, swim_bounds.end.y)
	)
	movement_speed = rng.randf_range(min_swim_speed, max_swim_speed)
	rest_remaining = 0.0
	swim_frame = 0
	swim_animation_elapsed = 0.0
	if absf(movement_target.x - position.x) > 1.0:
		_set_facing(movement_target.x > position.x)
	_set_swim_animation_frame(swim_frame)


func _start_resting(duration: float) -> void:
	movement_state = MovementState.RESTING
	scale = base_scale
	rest_remaining = maxf(0.0, duration)
	movement_velocity = Vector2.ZERO
	idle_frame = 0
	idle_animation_elapsed = 0.0
	_set_idle_animation_frame(idle_frame)


func _random_swim_target(origin: Vector2) -> Vector2:
	var target := swim_bounds.get_center()
	for attempt in range(8):
		target = Vector2(
			rng.randf_range(swim_bounds.position.x, swim_bounds.end.x),
			rng.randf_range(swim_bounds.position.y, swim_bounds.end.y)
		)
		if absf(target.x - origin.x) >= MIN_HORIZONTAL_TRAVEL:
			break
	return target


func _update_swim_animation(delta: float) -> void:
	swim_animation_elapsed += delta
	var frame_duration := 1.0 / SWIM_ANIMATION_FPS
	while swim_animation_elapsed >= frame_duration:
		swim_animation_elapsed -= frame_duration
		swim_frame = (swim_frame + 1) % FRAME_COUNT
		_set_swim_animation_frame(swim_frame)


func _update_idle_animation(delta: float) -> void:
	idle_animation_elapsed += delta
	var frame_duration := 1.0 / IDLE_ANIMATION_FPS
	while idle_animation_elapsed >= frame_duration:
		idle_animation_elapsed -= frame_duration
		idle_frame = (idle_frame + 1) % FRAME_COUNT
		_set_idle_animation_frame(idle_frame)


func _set_facing(should_face_right: bool) -> void:
	facing_right = should_face_right
	if movement_state == MovementState.RESTING:
		_set_idle_animation_frame(idle_frame)
	else:
		_set_swim_animation_frame(swim_frame)


func _set_swim_animation_frame(frame_index: int) -> void:
	var frames := swim_right_frames if facing_right else swim_left_frames
	var offsets := swim_right_offsets if facing_right else swim_left_offsets
	_set_frame(frames, offsets, frame_index)


func _set_idle_animation_frame(frame_index: int) -> void:
	var frames := idle_right_frames if facing_right else idle_left_frames
	var offsets := idle_right_offsets if facing_right else idle_left_offsets
	_set_frame(frames, offsets, frame_index)


func _set_frame(
	frames: Array[Texture2D],
	offsets: Array[Vector2],
	frame_index: int
) -> void:
	if frames.is_empty():
		return
	var safe_index := posmod(frame_index, frames.size())
	texture = frames[safe_index]
	offset = offsets[safe_index]
