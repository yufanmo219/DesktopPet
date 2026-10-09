extends SceneTree

const PlayerProgressScript = preload("res://src/progression/player_progress.gd")
const GameStateStoreScript = preload("res://src/progression/game_state_store.gd")

var failures: Array[String] = []
var notification_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var progress = PlayerProgressScript.new()
	progress.load_dictionary({
		"experience": -5,
		"hearts": 99,
		"fishing_level": 0,
		"fishing_retry_level": 1,
		"fishing_retry_count": -3,
		"unlocked_fish_ids": ["green", "green", "coral"],
		"aquarium_fish_ids": ["coral", "locked"],
		"future_progress": {"perfect_catches": 7},
		"successful_returns": 10,
		"best_combo": 4
	})
	var normalized := progress.to_dictionary()
	_check(
		normalized.experience == 0
		and normalized.hearts == 5
		and normalized.fishing_level == 1
		and normalized.unlocked_fish_ids == ["green", "coral"]
		and normalized.aquarium_fish_ids == ["coral"],
		"PlayerProgress should enforce progression bounds and collection invariants"
	)
	_check(
		normalized.future_progress == {"perfect_catches": 7}
		and not normalized.has("successful_returns")
		and not normalized.has("best_combo")
		and not normalized.has("fishing_retry_count"),
		"PlayerProgress should preserve future fields while removing retired or empty state"
	)

	var store = GameStateStoreScript.new()
	store.progress_changed.connect(func(_snapshot): notification_count += 1)
	store.replace(normalized, false)
	store.add_experience(25)
	store.add_experience(0)
	_check(
		store.snapshot().experience == 25 and notification_count == 1,
		"GameStateStore should publish each real mutation exactly once"
	)
	_check(store.unlock_fish("golden"), "A new discovery should be accepted")
	_check(not store.unlock_fish("golden"), "Duplicate discoveries should be ignored")
	store.replace_aquarium_fish_ids(["golden", "missing"])
	_check(
		store.snapshot().aquarium_fish_ids == ["golden"],
		"Aquarium contents should remain limited to unlocked fish"
	)

	if failures.is_empty():
		print("PLAYER PROGRESS TEST PASS")
		quit(0)
	else:
		print("PLAYER PROGRESS TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
