class_name PlayerProgress
extends RefCounted

## Typed, persistence-compatible player progression.
##
## The save file remains a Dictionary at the repository boundary. Inside the
## application this object owns normalization and progression invariants so UI
## screens do not need to know the storage schema.

const FishCatalogScript = preload("res://src/fish_catalog.gd")

const DEFAULT_HEARTS := 5
const DEFAULT_FISHING_LEVEL := 1

var experience := 0
var hearts := DEFAULT_HEARTS
var next_heart_restore_unix := 0
var fishing_level := DEFAULT_FISHING_LEVEL
var fishing_retry_level := 0
var fishing_retry_count := 0
var unlocked_fish_ids: Array[String] = []
var aquarium_fish_ids: Array[String] = []

var _extra_fields: Dictionary = {}


func load_dictionary(value: Variant) -> void:
	var source: Dictionary = value if value is Dictionary else {}
	_extra_fields = source.duplicate(true)
	_extra_fields.erase("successful_returns")
	_extra_fields.erase("best_combo")
	for field_name in [
		"experience",
		"hearts",
		"next_heart_restore_unix",
		"fishing_level",
		"fishing_retry_level",
		"fishing_retry_count",
		"unlocked_fish_ids",
		"aquarium_fish_ids"
	]:
		_extra_fields.erase(field_name)

	experience = maxi(0, int(source.get("experience", 0)))
	hearts = clampi(int(source.get("hearts", DEFAULT_HEARTS)), 0, DEFAULT_HEARTS)
	next_heart_restore_unix = maxi(0, int(source.get("next_heart_restore_unix", 0)))
	fishing_level = maxi(
		DEFAULT_FISHING_LEVEL,
		int(source.get("fishing_level", DEFAULT_FISHING_LEVEL))
	)
	fishing_retry_level = maxi(0, int(source.get("fishing_retry_level", 0)))
	fishing_retry_count = maxi(0, int(source.get("fishing_retry_count", 0)))

	unlocked_fish_ids = _normalized_unique_ids(
		FishCatalogScript.STARTER_FISH_IDS,
		source.get("unlocked_fish_ids", [])
	)
	aquarium_fish_ids = FishCatalogScript.normalize_aquarium_fish_ids(
		source.get(
			"aquarium_fish_ids",
			FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS
		),
		unlocked_fish_ids
	)
	_normalize_retry_state()


func to_dictionary() -> Dictionary:
	var result := _extra_fields.duplicate(true)
	result["experience"] = experience
	result["hearts"] = hearts
	result["next_heart_restore_unix"] = next_heart_restore_unix
	result["fishing_level"] = fishing_level
	if fishing_retry_count > 0:
		result["fishing_retry_level"] = fishing_retry_level
		result["fishing_retry_count"] = fishing_retry_count
	else:
		result.erase("fishing_retry_level")
		result.erase("fishing_retry_count")
	result["unlocked_fish_ids"] = unlocked_fish_ids.duplicate()
	result["aquarium_fish_ids"] = aquarium_fish_ids.duplicate()
	return result


func add_experience(amount: int) -> int:
	experience = maxi(0, experience + amount)
	return experience


func set_experience(value: int) -> void:
	experience = maxi(0, value)


func advance_fishing_level(next_level: int) -> int:
	fishing_level = maxi(fishing_level, maxi(DEFAULT_FISHING_LEVEL, next_level))
	return fishing_level


func set_retry(level: int, count: int) -> void:
	fishing_retry_count = maxi(0, count)
	fishing_retry_level = maxi(0, level) if fishing_retry_count > 0 else 0
	_normalize_retry_state()


func clear_retry() -> void:
	fishing_retry_level = 0
	fishing_retry_count = 0


func unlock_fish(fish_id: String) -> bool:
	var normalized_id := fish_id.strip_edges()
	if normalized_id.is_empty() or unlocked_fish_ids.has(normalized_id):
		return false
	unlocked_fish_ids.append(normalized_id)
	return true


func replace_unlocked_fish_ids(ids: Variant) -> void:
	unlocked_fish_ids = _normalized_unique_ids(FishCatalogScript.STARTER_FISH_IDS, ids)
	aquarium_fish_ids = FishCatalogScript.normalize_aquarium_fish_ids(
		aquarium_fish_ids,
		unlocked_fish_ids
	)


func replace_aquarium_fish_ids(ids: Variant) -> void:
	aquarium_fish_ids = FishCatalogScript.normalize_aquarium_fish_ids(
		ids,
		unlocked_fish_ids
	)


func set_hearts(value: int, next_restore_unix: int) -> void:
	hearts = clampi(value, 0, DEFAULT_HEARTS)
	next_heart_restore_unix = (
		0 if hearts >= DEFAULT_HEARTS else maxi(0, next_restore_unix)
	)


func _normalize_retry_state() -> void:
	if fishing_retry_count <= 0 or fishing_retry_level <= 0:
		clear_retry()


static func _normalized_unique_ids(default_ids: Variant, ids: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if default_ids is Array:
		for raw_id in default_ids:
			var default_id := str(raw_id)
			if not default_id.is_empty() and not normalized.has(default_id):
				normalized.append(default_id)
	if ids is Array:
		for raw_id in ids:
			var fish_id := str(raw_id)
			if not fish_id.is_empty() and not normalized.has(fish_id):
				normalized.append(fish_id)
	return normalized
