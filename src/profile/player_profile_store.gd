class_name PlayerProfileStore
extends RefCounted

## Runtime owner for the player's pet roster and active companion.
##
## The complete save Dictionary is preserved so fields owned by progression or
## future versions survive roster mutations byte-for-byte. This class only
## normalizes and changes pet_pool, active_pet_id, and owned_cat_ids.

const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")

const DEFAULT_CATALOG_ID := "maple"
const DEFAULT_PET_ID := "default_orange_cat"

var _save_snapshot: Dictionary = {}
var _pet_pool: Array = []
var _owned_cat_ids: Array[String] = []
var _active_pet_id := ""
var _max_pets := 9


func replace(value: Variant, max_pets: int, relock_development_catalog := false) -> void:
	_save_snapshot = value.duplicate(true) if value is Dictionary else {}
	_max_pets = maxi(1, max_pets)
	_owned_cat_ids = _normalize_owned_cat_ids(
		_save_snapshot.get("owned_cat_ids", [DEFAULT_CATALOG_ID])
	)
	_active_pet_id = str(_save_snapshot.get("active_pet_id", ""))
	if relock_development_catalog:
		_owned_cat_ids = [DEFAULT_CATALOG_ID]
		_active_pet_id = DEFAULT_PET_ID

	var normalized_candidates: Array = []
	var seen_pet_ids: Array[String] = []
	var raw_pool: Variant = _save_snapshot.get("pet_pool", [])
	if raw_pool is Array:
		for item in raw_pool:
			if not item is Dictionary:
				continue
			var pet: Dictionary = item.duplicate(true)
			if (
				relock_development_catalog
				and str(pet.get("type", "Cat")) == "Cat"
				and str(pet.get("id", "")) != DEFAULT_PET_ID
			):
				continue
			if str(pet.get("id", "")).is_empty():
				pet["id"] = _generated_pet_id(normalized_candidates.size())
			var pet_id := str(pet.get("id", ""))
			if seen_pet_ids.has(pet_id):
				continue
			pet["name"] = str(pet.get("name", "Mochi"))
			var definition = PetCatalogScript.definition_by_pet_id(pet_id)
			if definition != null:
				pet["name"] = definition.display_name
			pet["type"] = str(pet.get("type", "Cat"))
			pet.erase("personality")
			pet.erase("energy")
			normalized_candidates.append(pet)
			seen_pet_ids.append(pet_id)

	_pet_pool = normalized_candidates.slice(
		0,
		mini(_max_pets, normalized_candidates.size())
	)
	_retain_active_candidate(normalized_candidates)
	if pet_index(_active_pet_id) < 0:
		_active_pet_id = (
			str(_pet_pool[0].get("id", "")) if not _pet_pool.is_empty() else ""
		)


func snapshot() -> Dictionary:
	var result := _save_snapshot.duplicate(true)
	result["pet_pool"] = pet_pool()
	result["active_pet_id"] = _active_pet_id
	result["owned_cat_ids"] = owned_cat_ids()
	return result


func pet_pool() -> Array:
	return _pet_pool.duplicate(true)


func owned_cat_ids() -> Array[String]:
	return _owned_cat_ids.duplicate()


func active_pet_id() -> String:
	return _active_pet_id


func active_pet() -> Dictionary:
	var index := pet_index(_active_pet_id)
	return {} if index < 0 else _pet_pool[index].duplicate(true)


func pet_index(pet_id: String) -> int:
	for index in range(_pet_pool.size()):
		if str(_pet_pool[index].get("id", "")) == pet_id:
			return index
	return -1


func select_pet(pet_id: String) -> bool:
	if pet_index(pet_id) < 0:
		return false
	_active_pet_id = pet_id
	return true


func add_owned_cat(cat_id: String) -> bool:
	var normalized_id := cat_id.strip_edges().to_lower()
	if normalized_id.is_empty() or _owned_cat_ids.has(normalized_id):
		return false
	_owned_cat_ids.append(normalized_id)
	return true


func ensure_catalog_pet(cat_id: String, created_at: String) -> String:
	var definition = PetCatalogScript.definition_by_catalog_id(cat_id.to_lower())
	if definition == null:
		return ""
	var pet_id := str(definition.pet_id)
	if pet_index(pet_id) >= 0:
		return pet_id
	var pet: Dictionary = definition.save_profile()
	pet["created_at"] = created_at
	_pet_pool.append(pet)
	return pet_id


func ensure_default_pet(created_at: String) -> bool:
	var before := snapshot()
	if _pet_pool.is_empty():
		var default_pet: Dictionary = PetCatalogScript.default_definition().save_profile()
		default_pet["created_at"] = created_at
		_pet_pool.append(default_pet)
		_active_pet_id = str(default_pet.get("id", DEFAULT_PET_ID))
	elif pet_index(_active_pet_id) < 0:
		_active_pet_id = str(_pet_pool[0].get("id", DEFAULT_PET_ID))

	for cat_id in _owned_cat_ids:
		ensure_catalog_pet(cat_id, created_at)
	return snapshot() != before


func _retain_active_candidate(normalized_candidates: Array) -> void:
	if _active_pet_id.is_empty() or pet_index(_active_pet_id) >= 0:
		return
	var active_candidate: Dictionary = {}
	for candidate_value in normalized_candidates:
		var candidate: Dictionary = candidate_value
		if str(candidate.get("id", "")) == _active_pet_id:
			active_candidate = candidate
			break
	if active_candidate.is_empty():
		return
	if _pet_pool.size() >= _max_pets:
		_pet_pool[_max_pets - 1] = active_candidate
	else:
		_pet_pool.append(active_candidate)


func _normalize_owned_cat_ids(value: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if value is Array:
		for raw_id in value:
			var cat_id := str(raw_id).strip_edges().to_lower()
			if not cat_id.is_empty() and not normalized.has(cat_id):
				normalized.append(cat_id)
	if not normalized.has(DEFAULT_CATALOG_ID):
		normalized.push_front(DEFAULT_CATALOG_ID)
	return normalized


func _generated_pet_id(index: int) -> String:
	return "%d_%d" % [
		int(Time.get_unix_time_from_system() * 1000.0),
		index
	]
