class_name GameStateStore
extends RefCounted

## Single runtime owner for shared player progression.
##
## Screens receive this store instead of passing mutable Dictionaries between
## one another. A Dictionary snapshot is exposed only for persistence and for
## compatibility with screens that have not yet migrated.

signal progress_changed(snapshot: Dictionary)

const PlayerProgressScript = preload("res://src/progression/player_progress.gd")

var progress = PlayerProgressScript.new()


func replace(value: Variant, notify := true) -> bool:
	var replacement = PlayerProgressScript.new()
	replacement.load_dictionary(value)
	var changed: bool = replacement.to_dictionary() != progress.to_dictionary()
	progress = replacement
	if changed and notify:
		_emit_changed()
	return changed


func merge(patch: Dictionary) -> bool:
	var merged := snapshot()
	for key in patch:
		merged[key] = patch[key]
	return replace(merged)


func snapshot() -> Dictionary:
	return progress.to_dictionary()


func add_experience(amount: int) -> int:
	var previous: int = progress.experience
	var current: int = progress.add_experience(amount)
	_emit_if(previous != current)
	return current


func set_experience(value: int) -> void:
	var previous: int = progress.experience
	progress.set_experience(value)
	_emit_if(previous != progress.experience)


func advance_fishing_level(next_level: int) -> int:
	var previous: int = progress.fishing_level
	var current: int = progress.advance_fishing_level(next_level)
	_emit_if(previous != current)
	return current


func set_retry(level: int, count: int) -> void:
	var previous_level: int = progress.fishing_retry_level
	var previous_count: int = progress.fishing_retry_count
	progress.set_retry(level, count)
	_emit_if(
		previous_level != progress.fishing_retry_level
		or previous_count != progress.fishing_retry_count
	)


func clear_retry() -> void:
	set_retry(0, 0)


func unlock_fish(fish_id: String) -> bool:
	var changed: bool = progress.unlock_fish(fish_id)
	_emit_if(changed)
	return changed


func replace_unlocked_fish_ids(ids: Variant) -> void:
	var previous: Array[String] = progress.unlocked_fish_ids.duplicate()
	progress.replace_unlocked_fish_ids(ids)
	_emit_if(previous != progress.unlocked_fish_ids)


func replace_aquarium_fish_ids(ids: Variant) -> void:
	var previous: Array[String] = progress.aquarium_fish_ids.duplicate()
	progress.replace_aquarium_fish_ids(ids)
	_emit_if(previous != progress.aquarium_fish_ids)


func set_hearts(value: int, next_restore_unix: int) -> void:
	var previous_hearts: int = progress.hearts
	var previous_deadline: int = progress.next_heart_restore_unix
	progress.set_hearts(value, next_restore_unix)
	_emit_if(
		previous_hearts != progress.hearts
		or previous_deadline != progress.next_heart_restore_unix
	)


func _emit_if(condition: bool) -> void:
	if condition:
		_emit_changed()


func _emit_changed() -> void:
	progress_changed.emit(snapshot())
