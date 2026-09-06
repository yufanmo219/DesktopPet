extends SceneTree

const LevelCatalog = preload("res://src/fishing_level_catalog.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var expected_base_times := {
		0.95: 86,
		0.90: 78,
		0.85: 70,
		0.80: 66,
		0.75: 53
	}
	for pass_rate in expected_base_times:
		_check(
			LevelCatalog.base_time_for_pass_rate(float(pass_rate)) == int(expected_base_times[pass_rate]),
			"Pass rate %.0f%% should use a %d-second base time" % [
				float(pass_rate) * 100.0,
				int(expected_base_times[pass_rate])
			]
		)

	var representative_times := {
		1: 90,
		21: 73,
		61: 64,
		121: 65,
		171: 47,
		213: 43,
		214: 45,
		245: 42,
		450: 45
	}
	for level_number in representative_times:
		var config := LevelCatalog.level_config(int(level_number))
		_check(
			int(config.time_limit_seconds) == int(representative_times[level_number]),
			"Level %d should last %d seconds after breathing and rarity-tier adjustments" % [
				int(level_number),
				int(representative_times[level_number])
			]
		)

	var levels := LevelCatalog.all_levels()
	_check(
		levels.all(func(config): return int(config.time_limit_seconds) >= 30 and int(config.time_limit_seconds) <= 90),
		"Every campaign level must remain inside the 30-to-90-second limits"
	)
	var has_recovery_level := false
	for level_index in range(1, levels.size()):
		if int(levels[level_index].time_limit_seconds) > int(levels[level_index - 1].time_limit_seconds):
			has_recovery_level = true
			break
	_check(has_recovery_level, "The eight-level breathing pattern must continue to create recovery levels")

	if failures.is_empty():
		print("FISHING TIME BALANCE TEST PASS: 86/78/70/66/53 bases and level 213 = 43 seconds")
		quit(0)
	else:
		print("FISHING TIME BALANCE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
