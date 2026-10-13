extends SceneTree

const PlayerProfileStoreScript = preload(
	"res://src/profile/player_profile_store.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var store = PlayerProfileStoreScript.new()
	var crowded_pool: Array = []
	for index in range(9):
		crowded_pool.append({
			"id": "legacy_%d" % index,
			"name": "Legacy %d" % index,
			"type": "Cat"
		})
	crowded_pool.append({
		"id": "siamese",
		"name": "Old Siamese Name",
		"type": "Cat",
		"energy": 4
	})
	store.replace({
		"version": 8,
		"pet_pool": crowded_pool,
		"active_pet_id": "siamese",
		"owned_cat_ids": ["siamese", "siamese"],
		"progress_stats": {"experience": 4321},
		"future_root_field": {"cloud_revision": 7}
	}, 9)
	var normalized := store.snapshot()
	_check(
		store.pet_pool().size() == 9
		and store.active_pet().get("id", "") == "siamese"
		and store.active_pet().get("name", "") == "Pearl"
		and not store.active_pet().has("energy"),
		"Profile normalization should retain and canonicalize an active pet beyond capacity"
	)
	_check(
		store.owned_cat_ids() == ["maple", "siamese"]
		and normalized.progress_stats == {"experience": 4321}
		and normalized.future_root_field == {"cloud_revision": 7},
		"Roster changes should normalize ownership while preserving unrelated save fields"
	)

	store.replace({
		"pet_pool": [],
		"active_pet_id": "",
		"owned_cat_ids": ["maple", "mochi"],
		"progress_stats": {"future_progress": true}
	}, 9)
	_check(
		store.ensure_default_pet("2026-10-13T10:00:00")
		and store.pet_index("default_orange_cat") >= 0
		and store.pet_index("mochi") >= 0
		and store.select_pet("mochi")
		and store.active_pet().get("name", "") == "Mochi",
		"Profile store should materialize owned catalog pets and select them"
	)
	_check(
		store.snapshot().progress_stats == {"future_progress": true},
		"Selecting a pet must not mutate shared progression"
	)

	store.replace({
		"pet_pool": [
			{"id": "mochi", "name": "Mochi", "type": "Cat"},
			{"id": "legacy_bird", "name": "Peanut", "type": "Bird"}
		],
		"active_pet_id": "mochi",
		"owned_cat_ids": ["maple", "mochi", "biscuit"]
	}, 9, true)
	_check(
		store.owned_cat_ids() == ["maple"]
		and store.pet_index("mochi") < 0
		and store.pet_index("legacy_bird") >= 0,
		"Development-catalog relock should remove granted cats but preserve non-cat pets"
	)

	if failures.is_empty():
		print("PLAYER PROFILE STORE TEST PASS: roster invariants and save-field isolation")
		quit(0)
	else:
		print("PLAYER PROFILE STORE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
