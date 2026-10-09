extends SceneTree

const GameStateStoreScript = preload("res://src/progression/game_state_store.gd")
const HeartServiceScript = preload("res://src/progression/heart_service.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _service(stats: Dictionary, interval := 15):
	var store = GameStateStoreScript.new()
	store.replace(stats, false)
	return HeartServiceScript.new(store, interval)


func _run() -> void:
	var service = _service({"hearts": 5})
	_check(service.spend(100), "A full heart meter should pay one heart")
	_check(
		service.heart_count() == 4 and service.next_restore_unix() == 115,
		"The first spent heart should start one recovery interval"
	)
	_check(not service.restore_at(114), "Recovery should not finish early")
	_check(
		service.restore_at(115) and service.heart_count() == 5
		and service.next_restore_unix() == 0,
		"A due heart should restore and clear the deadline when full"
	)

	var offline = _service({"hearts": 1, "next_heart_restore_unix": 115})
	_check(
		offline.restore_at(160) and offline.heart_count() == 5,
		"Offline recovery should restore every elapsed interval up to the cap"
	)
	_check(not offline.restore_at(160), "Repeating the same recovery should be idempotent")

	var empty = _service({"hearts": 0, "next_heart_restore_unix": 215})
	_check(not empty.spend(200), "An empty heart meter cannot be charged")
	_check(
		empty.seconds_until_next(200) == 15,
		"The countdown should be derived from the supplied clock"
	)

	var rolled_back = _service({"hearts": 2, "next_heart_restore_unix": 9999})
	_check(
		rolled_back.restore_at(300)
		and rolled_back.next_restore_unix() == 315,
		"A far-future deadline should be clamped after a clock rollback"
	)

	if failures.is_empty():
		print("HEART SERVICE TEST PASS")
		quit(0)
	else:
		print("HEART SERVICE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
