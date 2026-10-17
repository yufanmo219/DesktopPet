class_name FishingPetPresentation
extends RefCounted

## Lazily loaded fishing-specific visuals for one PetDefinition.
##
## FishingGame asks for semantic reactions and never branches on a concrete
## pet ID. Pet-specific assets remain catalog data and only the active pet's
## fishing bundle is loaded.

var definition: PetDefinition
var default_texture: Texture2D
var default_frames: Array[Texture2D] = []
var success_frames: Array[Texture2D] = []
var empty_catch_frames: Array[Texture2D] = []
var catch_failure_texture: Texture2D
var round_failure_texture: Texture2D


func _init(configured_definition: PetDefinition = null) -> void:
	if configured_definition != null:
		configure(configured_definition)


func configure(configured_definition: PetDefinition) -> void:
	definition = configured_definition
	default_texture = _load_optional_texture("fishing_default")
	default_frames = definition.load_animation("fishing_default")
	success_frames = definition.load_animation("fishing_success")
	empty_catch_frames = definition.load_animation("fishing_empty_catch")
	catch_failure_texture = definition.load_texture("fishing_catch_failure")
	round_failure_texture = definition.load_texture("fishing_round_failure")


func default_frame(frame_index: int) -> Texture2D:
	if default_texture != null:
		return default_texture
	if default_frames.is_empty():
		return null
	return default_frames[clampi(frame_index, 0, default_frames.size() - 1)]


func reaction_frames(caught_any_fish: bool) -> Array[Texture2D]:
	return success_frames if caught_any_fish else empty_catch_frames


func _load_optional_texture(key: String) -> Texture2D:
	if definition.texture_path(key).is_empty():
		return null
	return definition.load_texture(key)
