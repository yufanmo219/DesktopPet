class_name PetDefinition
extends Resource

## Lightweight, platform-neutral definition for one adoptable pet.
##
## Definitions keep resource paths instead of loaded textures. Screens and
## actors load only the assets they actually display.

var catalog_id := ""
var pet_id := ""
var display_name := ""
var species := "Cat"
var price := 0
var description := ""
var texture_paths: Dictionary = {}
var animation_clips: Dictionary = {}
var station_theme: Dictionary = {}
var sleep_effect_mode := "bubble"
var desktop_idle_weights: Dictionary = {}
var idle_scale := 0.95
var sleep_scale := 0.95
var sleep_bubble_nose_position := Vector2(374.0, 338.0)
var draw_ground_shadow := true
var linear_texture_filter := false


func save_profile() -> Dictionary:
	return {
		"id": pet_id,
		"name": display_name,
		"type": species
	}


func store_entry() -> Dictionary:
	return {
		"id": catalog_id,
		"name": display_name,
		"price": price,
		"description": description
	}


func texture_path(key: String) -> String:
	return str(texture_paths.get(key, ""))


func load_texture(key: String) -> Texture2D:
	var path := texture_path(key)
	if path.is_empty():
		push_error("Pet '%s' does not define texture '%s'." % [pet_id, key])
		return null
	var resource := ResourceLoader.load(path, "Texture2D")
	if not resource is Texture2D:
		push_error("Pet '%s' could not load texture '%s' from %s." % [pet_id, key, path])
		return null
	return resource


func animation_path_list(key: String) -> Array[String]:
	var clip := animation_clip(key)
	if clip != null:
		return clip.frame_paths.duplicate()
	var empty_paths: Array[String] = []
	return empty_paths


func animation_clip(key: String) -> PetAnimationClip:
	return animation_clips.get(key) as PetAnimationClip


func animation_keys() -> Array[String]:
	var keys: Array[String] = []
	for raw_key in animation_clips:
		keys.append(str(raw_key))
	return keys


func load_animation(key: String) -> Array[Texture2D]:
	var clip := animation_clip(key)
	if clip != null:
		return clip.load_frames(pet_id)
	var empty_frames: Array[Texture2D] = []
	return empty_frames


func all_asset_paths() -> Array[String]:
	var paths: Array[String] = []
	for raw_path in texture_paths.values():
		var path := str(raw_path)
		if not path.is_empty() and not paths.has(path):
			paths.append(path)
	for animation_key in animation_clips:
		for path in animation_path_list(str(animation_key)):
			if not path.is_empty() and not paths.has(path):
				paths.append(path)
	return paths


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if catalog_id.is_empty():
		errors.append("catalog_id is required")
	if pet_id.is_empty():
		errors.append("pet_id is required")
	if display_name.is_empty():
		errors.append("display_name is required")
	if species.is_empty():
		errors.append("species is required")
	if price < 0:
		errors.append("price cannot be negative")
	for required_key in [
		"idle",
		"sleep",
		"store_portrait",
		"store_detail",
		"station",
		"fishing_catch_failure",
		"fishing_round_failure"
	]:
		if texture_path(required_key).is_empty():
			errors.append("missing required texture '%s'" % required_key)
	for required_key in ["interaction", "move_left", "move_right"]:
		if animation_path_list(required_key).is_empty():
			errors.append("missing required animation '%s'" % required_key)
	if texture_path("fishing_default").is_empty() and animation_path_list("fishing_default").is_empty():
		errors.append("missing fishing default presentation")
	for animation_key in animation_clips:
		var clip := animation_clip(str(animation_key))
		if clip == null:
			errors.append("animation '%s' is not a PetAnimationClip" % animation_key)
			continue
		for error in clip.validation_errors():
			errors.append("animation '%s': %s" % [animation_key, error])
	if sleep_effect_mode not in ["bubble", "repeat", "once_hold", "none"]:
		errors.append("unsupported sleep_effect_mode '%s'" % sleep_effect_mode)
	for raw_key in desktop_idle_weights:
		var key := str(raw_key)
		if animation_clip(key) == null:
			errors.append("desktop idle animation does not exist: %s" % key)
		if float(desktop_idle_weights.get(raw_key, 0.0)) <= 0.0:
			errors.append("desktop idle weight must be positive: %s" % key)
	for required_key in ["primary", "secondary", "accent", "motif"]:
		if str(station_theme.get(required_key, "")).is_empty():
			errors.append("missing station theme value '%s'" % required_key)
	for raw_path in texture_paths.values():
		var path := str(raw_path)
		if not ResourceLoader.exists(path, "Texture2D"):
			errors.append("asset does not exist: %s" % path)
	return errors
