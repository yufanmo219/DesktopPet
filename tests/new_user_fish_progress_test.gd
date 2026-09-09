extends SceneTree

const FishCatalogScript = preload("res://src/fish_catalog.gd")
const FishingLevelCatalogScript = preload("res://src/fishing_level_catalog.gd")
const FishingGameScript = preload("res://src/fishing_game.gd")
const AquariumScreenScript = preload("res://src/aquarium_screen.gd")
const FishBookScreenScript = preload("res://src/fish_book_screen.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	var fresh_stats: Dictionary = game.get_progress_stats()
	if not fresh_stats.unlocked_fish_ids.is_empty():
		_fail("A new player must begin with every fish undiscovered")
		return
	if not fresh_stats.aquarium_fish_ids.is_empty():
		_fail("A new player's aquarium must begin empty")
		return
	if not FishCatalogScript.STARTER_FISH_IDS.is_empty():
		_fail("The fish catalog must not grant a starter discovery")
		return
	if not FishCatalogScript.DEFAULT_AQUARIUM_FISH_IDS.is_empty():
		_fail("The fish catalog must not grant a default aquarium fish")
		return
	if FishingLevelCatalogScript.newly_introduced_fish_ids(1) != ["green"]:
		_fail("Green Fish must be a new level-one discovery")
		return

	var existing_stats: Dictionary = game._normalize_progress_stats({
		"experience": 321,
		"fishing_level": 42,
		"unlocked_fish_ids": ["green", "coral"],
		"aquarium_fish_ids": ["coral"]
	})
	if (
		existing_stats.unlocked_fish_ids != ["green", "coral"]
		or existing_stats.aquarium_fish_ids != ["coral"]
	):
		_fail("Normalizing progression must preserve an existing player's discoveries and aquarium")
		return

	var aquarium = AquariumScreenScript.new()
	aquarium.configure(fresh_stats)
	root.add_child(aquarium)
	await process_frame
	await aquarium.prepare_animations_async()
	if not aquarium.extra_fish_actors.is_empty():
		_fail("The new-player aquarium must render no fish actors")
		return
	if aquarium.fish_count_label.text != "FISH CAP 0 / 10":
		_fail("The empty aquarium must display FISH CAP 0 / 10")
		return
	aquarium.queue_free()
	await process_frame

	var fish_book = FishBookScreenScript.new()
	fish_book.configure_book(fresh_stats)
	root.add_child(fish_book)
	await process_frame
	if fish_book.fish_slot_lock_views.filter(func(lock): return lock.visible).size() != 9:
		_fail("Every fish on the first Fishipedia page must be locked for a new player")
		return
	if (
		fish_book.selected_fish_id != "green"
		or not fish_book.fish_detail_lock_view.visible
		or not fish_book.fish_detail_locked_veil.visible
		or fish_book.fish_aquarium_button.visible
	):
		_fail("Green Fish details must use the locked treatment until it is caught")
		return
	fish_book.queue_free()
	await process_frame

	var fishing_game = FishingGameScript.new()
	fishing_game.configure(
		{"id": "default_orange_cat", "name": "Maple", "type": "Cat"},
		fresh_stats
	)
	root.add_child(fishing_game)
	await process_frame
	fishing_game.resolve_catch_for_test(true, 0)
	if (
		fishing_game.result_overlay == null
		or fishing_game.result_overlay.name != "FishingNewFishPopupOverlay"
	):
		_fail("A new player's first Green Fish catch must show the new-fish congratulations popup")
		return
	if (
		fishing_game.unlocked_fish_ids != ["green"]
		or fishing_game.shared_stats.get("unlocked_fish_ids", []) != ["green"]
	):
		_fail("The first Green Fish catch must persist the discovery")
		return

	print("NEW USER FISH PROGRESS TEST PASS: empty aquarium, fully locked Fishipedia, preserved saves, and first-catch discovery")
	quit(0)
