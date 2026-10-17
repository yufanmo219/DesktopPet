extends SceneTree

const AvatarScript = preload("res://src/pet_avatar.gd")
const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error(message)


func _run() -> void:
	var definitions := PetCatalogScript.all_definitions()
	_check(definitions.size() == 9, "The pet catalog should contain all nine adoptable cats")
	_check(
		PetCatalogScript.catalog_ids() == [
			"maple", "mochi", "biscuit", "luna", "poppy", "black_cat",
			"siamese", "golden_munchkin", "maine_coon"
		],
		"Catalog order should preserve Store pricing and save-file IDs"
	)
	_check(
		PetCatalogScript.validation_errors().is_empty(),
		"Every pet definition should have unique IDs and valid assets"
	)
	var sable = PetCatalogScript.definition_by_catalog_id("black_cat")
	_check(
		sable.pet_id == "black_cat"
		and sable.display_name == "Sable"
		and sable.price == 7000
		and sable.save_profile() == {"id": "black_cat", "name": "Sable", "type": "Cat"},
		"One definition should drive Store metadata and save profiles"
	)
	_check(
		PetCatalogScript.definition_by_pet_id("default_orange_cat").catalog_id == "maple",
		"Maple's legacy pet ID should map to the stable Store catalog ID"
	)

	var avatar := AvatarScript.new()
	_check(
		avatar.idle_texture == null
		and avatar.animation_frames("move_left").is_empty(),
		"Constructing the avatar script should not eagerly load pet textures"
	)
	avatar.set_pet({"id": "luna", "name": "Luna", "type": "Cat"})
	_check(
		avatar.loaded_asset_pet_id == "luna"
		and avatar.idle_texture != null
		and avatar.animation_frames("move_left").size() == 12
		and avatar.animation_frames("interaction").size() == 12,
		"Selecting Luna should load Luna's bundle without loading Maple or Biscuit"
	)
	avatar.set_pet({"id": "biscuit", "name": "Biscuit", "type": "Cat"})
	_check(
		avatar.loaded_asset_pet_id == "biscuit"
		and avatar.idle_texture != null
		and avatar.animation_frames("interaction").size() == 16
		and avatar.animation_frames("sleep_bubble").size() == 14
		and avatar.animation_frames("sleep_effect").is_empty(),
		"Switching cats should release the previous bundle and load only the next one"
	)
	avatar.set_pet({"id": "legacy_unknown", "name": "Legacy", "type": "Cat"})
	_check(
		avatar.loaded_asset_pet_id == "default_orange_cat"
		and avatar.idle_texture != null
		and avatar.animation_frames("move_left").size() == 12,
		"Unknown legacy pets should safely fall back to Maple's visual bundle"
	)
	avatar.free()

	if failures.is_empty():
		print("PET CATALOG TEST PASS: typed definitions, valid paths, stable save IDs, and active-pet-only loading")
		quit(0)
	else:
		print("PET CATALOG TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
