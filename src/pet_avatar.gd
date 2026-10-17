class_name PetAvatar
extends Control

const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")
const GameFontStylesScript = preload("res://src/game_font_styles.gd")

const MOVE_SECONDS := 1.15
const DEFAULT_INTERACTION_FPS := 4.5
const DESKTOP_IDLE_MIN_WAIT := 7.0
const DESKTOP_IDLE_MAX_WAIT := 15.0
const SLEEP_BUBBLE_MIN_WAIT := 3.0
const SLEEP_BUBBLE_MAX_WAIT := 8.0
const SLEEP_BUBBLE_FRAME_ANCHOR := Vector2(10.0, 70.0)
const SHADOW_CENTER_Y_RATIO := 0.91

var mood := "idle"
var pet_id := "default_orange_cat"
var pet_definition: PetDefinition
var loaded_asset_pet_id := ""
var idle_texture: Texture2D
var sleep_texture: Texture2D
var loaded_animation_frames: Dictionary = {}

var home_idle_enabled := false
var home_idle_playing := false
var home_idle_frame := 0
var home_idle_frame_elapsed := 0.0
var home_idle_wait_remaining := 0.0

var cat_sprite: Sprite2D
var sleep_bubble_sprite: Sprite2D
var mood_badge: Label

var move_direction := "right"
var move_frame := 0
var move_frame_elapsed := 0.0
var move_time_remaining := 0.0

var interaction_animation_active := false
var interaction_frames: Array[Texture2D] = []
var interaction_frame := 0
var interaction_frame_elapsed := 0.0

var shy_frame := 0
var shy_frame_elapsed := 0.0

var desktop_idle_enabled := false
var desktop_idle_animation := ""
var desktop_idle_frames: Array[Texture2D] = []
var desktop_idle_frame := 0
var desktop_idle_frame_elapsed := 0.0
var desktop_idle_wait_remaining := 0.0

var sleep_bubble_frame := 0
var sleep_bubble_frame_elapsed := 0.0
var sleep_bubble_active := false
var sleep_bubble_wait_remaining := 0.0

var sleep_effect_playing := false
var sleep_effect_visible := false
var sleep_effect_frame := 0
var sleep_effect_frame_elapsed := 0.0
var sleep_effect_wait_remaining := 0.0

var active_clip_key := ""
static var texture_visual_bounds_cache: Dictionary = {}


func _load_pet_assets(requested_pet_id: String) -> void:
	var definition: PetDefinition = PetCatalogScript.definition_or_default(requested_pet_id)
	if definition == pet_definition and loaded_asset_pet_id == definition.pet_id:
		return
	_clear_pet_assets()
	pet_definition = definition
	pet_id = definition.pet_id
	loaded_asset_pet_id = definition.pet_id
	idle_texture = definition.load_texture("idle")
	sleep_texture = definition.load_texture("sleep")
	for animation_key in definition.animation_keys():
		loaded_animation_frames[animation_key] = definition.load_animation(animation_key)


func _clear_pet_assets() -> void:
	idle_texture = null
	sleep_texture = null
	loaded_animation_frames.clear()
	active_clip_key = ""


func animation_clip(key: String) -> PetAnimationClip:
	return pet_definition.animation_clip(key) if pet_definition != null else null


func animation_frames(key: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	var raw_frames: Variant = loaded_animation_frames.get(key, [])
	if raw_frames is Array:
		for frame in raw_frames:
			if frame is Texture2D:
				frames.append(frame)
	return frames


func _ready() -> void:
	_load_pet_assets(pet_id)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	cat_sprite = Sprite2D.new()
	cat_sprite.texture = idle_texture
	cat_sprite.centered = true
	add_child(cat_sprite)

	sleep_bubble_sprite = Sprite2D.new()
	sleep_bubble_sprite.name = "SleepBubble"
	sleep_bubble_sprite.centered = false
	sleep_bubble_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sleep_bubble_sprite.z_index = 1
	cat_sprite.add_child(sleep_bubble_sprite)

	mood_badge = Label.new()
	GameFontStylesScript.apply_regular(mood_badge)
	mood_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mood_badge.add_theme_font_size_override("font_size", 24)
	mood_badge.add_theme_color_override("font_color", Color("#5c3546"))
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(1.0, 0.96, 0.87, 0.92)
	badge_style.set_corner_radius_all(14)
	badge_style.content_margin_left = 12
	badge_style.content_margin_right = 12
	mood_badge.add_theme_stylebox_override("normal", badge_style)
	add_child(mood_badge)
	_update_visuals()


func set_pet(data: Dictionary) -> void:
	var requested_id := str(data.get("id", "default_orange_cat")).to_lower()
	_load_pet_assets(requested_id)
	move_time_remaining = 0.0
	move_frame = 0
	move_frame_elapsed = 0.0
	_stop_home_idle_animation()
	_stop_desktop_idle_animation()
	_reset_sleep_effect()
	interaction_animation_active = false
	interaction_frames = []
	interaction_frame = 0
	interaction_frame_elapsed = 0.0
	if home_idle_enabled:
		_schedule_next_home_idle()
	if mood == "sleep":
		_schedule_sleep_behavior()
	_update_visuals()


func set_home_idle_enabled(enabled: bool) -> void:
	home_idle_enabled = enabled
	_stop_home_idle_animation()
	if enabled:
		_schedule_next_home_idle()
	_apply_current_texture()


func set_mood(value: String) -> void:
	var mood_changed := mood != value
	mood = value
	if mood != "idle":
		_stop_desktop_idle_animation()
	if mood == "sleep":
		move_time_remaining = 0.0
		if mood_changed:
			_schedule_sleep_behavior()
	elif mood_changed:
		_reset_sleep_effect()
		_reset_sleep_bubble()
	if mood == "blush" and mood_changed:
		shy_frame = 0
		shy_frame_elapsed = 0.0
	_update_visuals()


func play_move(movement: Vector2) -> void:
	if mood == "sleep" or movement.length_squared() < 0.01:
		return
	_stop_desktop_idle_animation()
	var next_direction := move_direction
	if movement.x < -0.01:
		next_direction = "left"
	elif movement.x > 0.01:
		next_direction = "right"
	if move_time_remaining <= 0.0 or move_direction != next_direction:
		move_frame = 0
		move_frame_elapsed = 0.0
	move_direction = next_direction
	move_time_remaining = MOVE_SECONDS
	_apply_current_texture()


func stop_move() -> void:
	move_time_remaining = 0.0
	move_frame_elapsed = 0.0
	_apply_current_texture()


func play_belly_roll() -> void:
	stop_move()
	_stop_desktop_idle_animation()
	interaction_frames = animation_frames("interaction")
	if interaction_frames.is_empty():
		return
	interaction_animation_active = true
	interaction_frame = 0
	interaction_frame_elapsed = 0.0
	_apply_current_texture()
	_update_visuals()


func is_playing_interaction() -> bool:
	return interaction_animation_active


func _process(delta: float) -> void:
	if interaction_animation_active:
		_process_interaction_animation(delta)
	elif mood == "sleep":
		_process_sleep_behavior(delta)
	elif mood == "blush":
		_process_shy_animation(delta)
	elif move_time_remaining > 0.0:
		_process_move_animation(delta)
	elif desktop_idle_enabled and mood == "idle":
		_process_desktop_idle(delta)
	elif home_idle_enabled and mood == "idle":
		_process_home_idle(delta)
	elif is_instance_valid(cat_sprite) and cat_sprite.texture != idle_texture:
		_apply_current_texture()
	_update_layout()
	queue_redraw()


func _process_shy_animation(delta: float) -> void:
	var frames := animation_frames("shy")
	if frames.is_empty():
		return
	var clip := animation_clip("shy")
	shy_frame_elapsed += delta
	var frame_duration := clip.frame_duration(shy_frame, 6.0)
	while shy_frame_elapsed >= frame_duration:
		shy_frame_elapsed -= frame_duration
		shy_frame = (shy_frame + 1) % frames.size()
		frame_duration = clip.frame_duration(shy_frame, 6.0)
	_apply_current_texture()


func _process_move_animation(delta: float) -> void:
	move_time_remaining = maxf(0.0, move_time_remaining - delta)
	var clip_key := _move_clip_key()
	var frames := animation_frames(clip_key)
	var clip := animation_clip(clip_key)
	if frames.is_empty() or clip == null:
		return
	move_frame_elapsed += delta
	var frame_duration := clip.frame_duration(move_frame, 7.0)
	while move_frame_elapsed >= frame_duration:
		move_frame_elapsed -= frame_duration
		move_frame += 1
		if move_frame >= frames.size():
			move_frame = clampi(clip.loop_start_frame, 0, frames.size() - 1)
		frame_duration = clip.frame_duration(move_frame, 7.0)
	_apply_current_texture()


func _update_visuals() -> void:
	if not is_instance_valid(cat_sprite):
		return
	cat_sprite.modulate = Color.WHITE
	cat_sprite.rotation = 0.0
	match mood:
		"blush": mood_badge.text = "FEELING SHY..."
		"roll_eyes": mood_badge.text = "...REALLY?"
		"blink": mood_badge.text = "BLINK!"
		"happy": mood_badge.text = "HAPPY!"
		_: mood_badge.text = ""
	mood_badge.visible = (
		mood != "follow"
		and not mood_badge.text.is_empty()
		and not interaction_animation_active
	)
	_apply_current_texture()
	_update_layout()


func _apply_current_texture() -> void:
	if not is_instance_valid(cat_sprite):
		return
	active_clip_key = ""
	if interaction_animation_active and not interaction_frames.is_empty():
		active_clip_key = "interaction"
		cat_sprite.texture = interaction_frames[interaction_frame]
	elif mood == "sleep":
		var effect_frames := animation_frames("sleep_effect")
		if sleep_effect_visible and not effect_frames.is_empty():
			active_clip_key = "sleep_effect"
			cat_sprite.texture = effect_frames[sleep_effect_frame]
		else:
			cat_sprite.texture = sleep_texture
	elif mood == "blush" and not animation_frames("shy").is_empty():
		active_clip_key = "shy"
		cat_sprite.texture = animation_frames("shy")[shy_frame]
	elif move_time_remaining > 0.0 and not animation_frames(_move_clip_key()).is_empty():
		active_clip_key = _move_clip_key()
		cat_sprite.texture = animation_frames(active_clip_key)[move_frame]
	elif not desktop_idle_animation.is_empty() and not desktop_idle_frames.is_empty():
		active_clip_key = desktop_idle_animation
		cat_sprite.texture = desktop_idle_frames[desktop_idle_frame]
	elif home_idle_playing and not animation_frames("home_idle").is_empty():
		active_clip_key = "home_idle"
		cat_sprite.texture = animation_frames("home_idle")[home_idle_frame]
	else:
		cat_sprite.texture = idle_texture
	cat_sprite.texture_filter = (
		CanvasItem.TEXTURE_FILTER_LINEAR
		if pet_definition != null and pet_definition.linear_texture_filter
		else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	)
	_update_sleep_bubble()


func _move_clip_key() -> String:
	return "move_left" if move_direction == "left" else "move_right"


func _process_home_idle(delta: float) -> void:
	var frames := animation_frames("home_idle")
	var clip := animation_clip("home_idle")
	if frames.is_empty() or clip == null:
		return
	if not home_idle_playing:
		home_idle_wait_remaining = maxf(0.0, home_idle_wait_remaining - delta)
		if home_idle_wait_remaining <= 0.0:
			home_idle_playing = true
			home_idle_frame = 0
			home_idle_frame_elapsed = 0.0
			_apply_current_texture()
		return
	home_idle_frame_elapsed += delta
	var frame_duration := clip.frame_duration(home_idle_frame, 6.0)
	while home_idle_frame_elapsed >= frame_duration:
		home_idle_frame_elapsed -= frame_duration
		if home_idle_frame >= frames.size() - 1:
			_stop_home_idle_animation()
			_schedule_next_home_idle()
			_apply_current_texture()
			return
		home_idle_frame += 1
		frame_duration = clip.frame_duration(home_idle_frame, 6.0)
	_apply_current_texture()


func _stop_home_idle_animation() -> void:
	home_idle_playing = false
	home_idle_frame = 0
	home_idle_frame_elapsed = 0.0


func _schedule_next_home_idle() -> void:
	var clip := animation_clip("home_idle")
	if clip == null:
		home_idle_wait_remaining = 0.0
		return
	home_idle_wait_remaining = randf_range(clip.wait_min, clip.wait_max)


func _process_interaction_animation(delta: float) -> void:
	var clip := animation_clip("interaction")
	if clip == null or interaction_frames.is_empty():
		interaction_animation_active = false
		return
	interaction_frame_elapsed += delta
	var frame_duration := clip.frame_duration(interaction_frame, DEFAULT_INTERACTION_FPS)
	while interaction_frame_elapsed >= frame_duration:
		interaction_frame_elapsed -= frame_duration
		if interaction_frame >= interaction_frames.size() - 1:
			interaction_animation_active = false
			interaction_frames = []
			interaction_frame = 0
			interaction_frame_elapsed = 0.0
			if desktop_idle_enabled and mood == "idle":
				_schedule_next_desktop_idle()
			_update_visuals()
			return
		interaction_frame += 1
		frame_duration = clip.frame_duration(interaction_frame, DEFAULT_INTERACTION_FPS)
	_apply_current_texture()


func set_desktop_idle_enabled(enabled: bool) -> void:
	if desktop_idle_enabled == enabled:
		return
	desktop_idle_enabled = enabled
	if enabled:
		_schedule_next_desktop_idle()
	else:
		_stop_desktop_idle_animation()
		desktop_idle_wait_remaining = 0.0
	_apply_current_texture()


func _process_desktop_idle(delta: float) -> void:
	if desktop_idle_animation.is_empty():
		desktop_idle_wait_remaining = maxf(0.0, desktop_idle_wait_remaining - delta)
		if desktop_idle_wait_remaining <= 0.0:
			var clip_key := _choose_desktop_idle_clip()
			if clip_key.is_empty():
				_schedule_next_desktop_idle()
				return
			_start_desktop_idle_animation(clip_key)
		return
	var clip := animation_clip(desktop_idle_animation)
	if clip == null or desktop_idle_frames.is_empty():
		_stop_desktop_idle_animation()
		return
	desktop_idle_frame_elapsed += delta
	var frame_duration := clip.frame_duration(desktop_idle_frame, 6.0)
	while desktop_idle_frame_elapsed >= frame_duration:
		desktop_idle_frame_elapsed -= frame_duration
		if desktop_idle_frame >= desktop_idle_frames.size() - 1:
			_stop_desktop_idle_animation()
			_schedule_next_desktop_idle()
			_apply_current_texture()
			return
		desktop_idle_frame += 1
		frame_duration = clip.frame_duration(desktop_idle_frame, 6.0)
	_apply_current_texture()


func _choose_desktop_idle_clip() -> String:
	if pet_definition == null or pet_definition.desktop_idle_weights.is_empty():
		return ""
	var total_weight := 0.0
	for raw_weight in pet_definition.desktop_idle_weights.values():
		total_weight += maxf(float(raw_weight), 0.0)
	if total_weight <= 0.0:
		return ""
	var roll := randf() * total_weight
	for raw_key in pet_definition.desktop_idle_weights:
		var key := str(raw_key)
		roll -= maxf(float(pet_definition.desktop_idle_weights[raw_key]), 0.0)
		if roll <= 0.0:
			return key
	return str(pet_definition.desktop_idle_weights.keys().back())


func _start_desktop_idle_animation(animation_name: String) -> void:
	var frames := animation_frames(animation_name)
	if frames.is_empty():
		return
	desktop_idle_animation = animation_name
	desktop_idle_frames = frames
	desktop_idle_frame = 0
	desktop_idle_frame_elapsed = 0.0
	_apply_current_texture()


func _stop_desktop_idle_animation() -> void:
	desktop_idle_animation = ""
	desktop_idle_frames = []
	desktop_idle_frame = 0
	desktop_idle_frame_elapsed = 0.0


func _schedule_next_desktop_idle() -> void:
	desktop_idle_wait_remaining = randf_range(DESKTOP_IDLE_MIN_WAIT, DESKTOP_IDLE_MAX_WAIT)


func _process_sleep_behavior(delta: float) -> void:
	if pet_definition == null:
		return
	match pet_definition.sleep_effect_mode:
		"bubble": _process_sleep_bubble(delta)
		"repeat", "once_hold": _process_sleep_effect(delta)


func _schedule_sleep_behavior() -> void:
	_reset_sleep_effect()
	_reset_sleep_bubble()
	if pet_definition == null:
		return
	match pet_definition.sleep_effect_mode:
		"bubble": _schedule_next_sleep_bubble()
		"repeat": _schedule_next_sleep_effect()
		"once_hold": _start_sleep_effect()


func _process_sleep_effect(delta: float) -> void:
	var frames := animation_frames("sleep_effect")
	var clip := animation_clip("sleep_effect")
	if frames.is_empty() or clip == null:
		return
	if not sleep_effect_playing:
		if pet_definition.sleep_effect_mode != "repeat":
			return
		sleep_effect_wait_remaining = maxf(0.0, sleep_effect_wait_remaining - delta)
		if sleep_effect_wait_remaining <= 0.0:
			_start_sleep_effect()
		return
	sleep_effect_frame_elapsed += delta
	var frame_duration := clip.frame_duration(sleep_effect_frame, 6.0)
	while sleep_effect_frame_elapsed >= frame_duration:
		sleep_effect_frame_elapsed -= frame_duration
		if sleep_effect_frame >= frames.size() - 1:
			sleep_effect_playing = false
			sleep_effect_visible = false
			sleep_effect_frame = 0
			sleep_effect_frame_elapsed = 0.0
			if pet_definition.sleep_effect_mode == "repeat":
				_schedule_next_sleep_effect()
			_apply_current_texture()
			return
		sleep_effect_frame += 1
		frame_duration = clip.frame_duration(sleep_effect_frame, 6.0)
	_apply_current_texture()


func _start_sleep_effect() -> void:
	if animation_frames("sleep_effect").is_empty():
		return
	sleep_effect_playing = true
	sleep_effect_visible = true
	sleep_effect_frame = 0
	sleep_effect_frame_elapsed = 0.0
	_apply_current_texture()


func _schedule_next_sleep_effect() -> void:
	var clip := animation_clip("sleep_effect")
	if clip == null:
		return
	sleep_effect_playing = false
	sleep_effect_visible = false
	sleep_effect_frame = 0
	sleep_effect_frame_elapsed = 0.0
	sleep_effect_wait_remaining = randf_range(clip.wait_min, clip.wait_max)


func _reset_sleep_effect() -> void:
	sleep_effect_playing = false
	sleep_effect_visible = false
	sleep_effect_frame = 0
	sleep_effect_frame_elapsed = 0.0
	sleep_effect_wait_remaining = 0.0


func _update_sleep_bubble() -> void:
	if not is_instance_valid(sleep_bubble_sprite):
		return
	var frames := animation_frames("sleep_bubble")
	if frames.is_empty() or pet_definition == null:
		sleep_bubble_sprite.visible = false
		sleep_bubble_sprite.texture = null
		return
	sleep_bubble_sprite.position = (
		pet_definition.sleep_bubble_nose_position
		- sleep_texture.get_size() * 0.5
		- SLEEP_BUBBLE_FRAME_ANCHOR
	)
	sleep_bubble_sprite.visible = (
		mood == "sleep"
		and sleep_bubble_active
		and not interaction_animation_active
		and pet_definition.sleep_effect_mode == "bubble"
	)
	sleep_bubble_sprite.texture = frames[sleep_bubble_frame]


func _process_sleep_bubble(delta: float) -> void:
	var frames := animation_frames("sleep_bubble")
	var clip := animation_clip("sleep_bubble")
	if frames.is_empty() or clip == null:
		return
	if not sleep_bubble_active:
		sleep_bubble_wait_remaining = maxf(0.0, sleep_bubble_wait_remaining - delta)
		if sleep_bubble_wait_remaining <= 0.0:
			sleep_bubble_active = true
			sleep_bubble_frame = 0
			sleep_bubble_frame_elapsed = 0.0
			_update_sleep_bubble()
		return
	sleep_bubble_frame_elapsed += delta
	var frame_duration := clip.frame_duration(sleep_bubble_frame, 5.0)
	while sleep_bubble_frame_elapsed >= frame_duration:
		sleep_bubble_frame_elapsed -= frame_duration
		if sleep_bubble_frame >= frames.size() - 1:
			_schedule_next_sleep_bubble()
			return
		sleep_bubble_frame += 1
		frame_duration = clip.frame_duration(sleep_bubble_frame, 5.0)
	_update_sleep_bubble()


func _schedule_next_sleep_bubble() -> void:
	sleep_bubble_active = false
	sleep_bubble_frame = 0
	sleep_bubble_frame_elapsed = 0.0
	sleep_bubble_wait_remaining = randf_range(SLEEP_BUBBLE_MIN_WAIT, SLEEP_BUBBLE_MAX_WAIT)
	_update_sleep_bubble()


func _reset_sleep_bubble() -> void:
	sleep_bubble_active = false
	sleep_bubble_frame = 0
	sleep_bubble_frame_elapsed = 0.0
	sleep_bubble_wait_remaining = 0.0
	_update_sleep_bubble()


func _update_layout() -> void:
	if not is_instance_valid(cat_sprite) or cat_sprite.texture == null:
		return
	var safe_size := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	var texture_size := cat_sprite.texture.get_size()
	var clip := animation_clip(active_clip_key) if not active_clip_key.is_empty() else null
	var layout_texture := cat_sprite.texture
	var scale_multiplier := 0.82
	if clip != null:
		layout_texture = _reference_texture(clip.layout_size_reference, active_clip_key)
		scale_multiplier = clip.layout_scale
	elif mood == "sleep":
		layout_texture = sleep_texture
		scale_multiplier = pet_definition.sleep_scale
	else:
		layout_texture = idle_texture
		scale_multiplier = pet_definition.idle_scale
	var layout_texture_size := layout_texture.get_size()
	var scale_value := minf(
		safe_size.x / layout_texture_size.x,
		safe_size.y / layout_texture_size.y
	) * scale_multiplier
	var visual_bounds := _visual_bounds_for_clip(clip, active_clip_key)
	var texture_center := texture_size * 0.5
	var visual_center_x := visual_bounds.position.x + visual_bounds.size.x * 0.5
	var visual_bottom := visual_bounds.position.y + visual_bounds.size.y
	cat_sprite.scale = Vector2.ONE * scale_value
	cat_sprite.position = Vector2(
		safe_size.x * 0.5 - (visual_center_x - texture_center.x) * scale_value,
		safe_size.y * SHADOW_CENTER_Y_RATIO - (visual_bottom - texture_center.y) * scale_value
	)
	if clip != null and interaction_animation_active:
		cat_sprite.position += clip.position_offset
	var badge_width := minf(184.0, safe_size.x * 0.90)
	mood_badge.position = Vector2(safe_size.x * 0.5 - badge_width * 0.5, 4.0)
	mood_badge.size = Vector2(badge_width, 40.0)


func _reference_texture(reference: String, clip_key: String) -> Texture2D:
	match reference:
		"idle": return idle_texture
		"sleep": return sleep_texture
		"first":
			var first_frames := animation_frames(clip_key)
			return first_frames.front() if not first_frames.is_empty() else cat_sprite.texture
		"last":
			var last_frames := animation_frames(clip_key)
			return last_frames.back() if not last_frames.is_empty() else cat_sprite.texture
	return cat_sprite.texture


func _visual_bounds_for_clip(clip: PetAnimationClip, clip_key: String) -> Rect2:
	if clip == null:
		return _get_texture_visual_bounds(cat_sprite.texture)
	if clip.uses_fixed_visual_bounds:
		return clip.fixed_visual_bounds
	return _get_texture_visual_bounds(
		_reference_texture(clip.visual_bounds_reference, clip_key)
	)


func _get_texture_visual_bounds(texture: Texture2D) -> Rect2:
	var cache_key := texture.resource_path
	if texture_visual_bounds_cache.has(cache_key):
		return texture_visual_bounds_cache[cache_key]
	var image := texture.get_image()
	var used_rect := image.get_used_rect()
	var bounds := Rect2(used_rect)
	if bounds.size == Vector2.ZERO:
		bounds = Rect2(Vector2.ZERO, texture.get_size())
	texture_visual_bounds_cache[cache_key] = bounds
	return bounds


func _draw() -> void:
	if pet_definition == null or not pet_definition.draw_ground_shadow:
		return
	var shadow_center := Vector2(size.x * 0.5, size.y * SHADOW_CENTER_Y_RATIO)
	var shadow_radius := Vector2(size.x * 0.28, maxf(8.0, size.y * 0.035))
	var points := PackedVector2Array()
	for index in range(36):
		var angle := TAU * float(index) / 36.0
		points.append(shadow_center + Vector2(
			cos(angle) * shadow_radius.x,
			sin(angle) * shadow_radius.y
		))
	draw_colored_polygon(points, Color(0.20, 0.12, 0.16, 0.16))
