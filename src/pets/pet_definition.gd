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
var animation_paths: Dictionary = {}
var station_theme: Dictionary = {}


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
	var paths: Array[String] = []
	var raw_paths: Variant = animation_paths.get(key, [])
	if raw_paths is Array:
		for raw_path in raw_paths:
			paths.append(str(raw_path))
	return paths


func load_animation(key: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for path in animation_path_list(key):
		var resource := ResourceLoader.load(path, "Texture2D")
		if not resource is Texture2D:
			push_error("Pet '%s' could not load animation '%s' frame %s." % [
				pet_id,
				key,
				path
			])
			continue
		frames.append(resource)
	return frames


func all_asset_paths() -> Array[String]:
	var paths: Array[String] = []
	for raw_path in texture_paths.values():
		var path := str(raw_path)
		if not path.is_empty() and not paths.has(path):
			paths.append(path)
	for animation_key in animation_paths:
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
	for required_key in ["idle", "sleep", "store_portrait", "store_detail", "station"]:
		if texture_path(required_key).is_empty():
			errors.append("missing required texture '%s'" % required_key)
	for required_key in ["interaction", "move_left", "move_right"]:
		if animation_path_list(required_key).is_empty():
			errors.append("missing required animation '%s'" % required_key)
	for required_key in ["primary", "secondary", "accent", "motif"]:
		if str(station_theme.get(required_key, "")).is_empty():
			errors.append("missing station theme value '%s'" % required_key)
	for path in all_asset_paths():
		if not ResourceLoader.exists(path, "Texture2D"):
			errors.append("asset does not exist: %s" % path)
	return errors
