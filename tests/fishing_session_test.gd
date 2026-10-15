extends SceneTree

const FishingSessionScript = preload("res://src/fishing/fishing_session.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var session = FishingSessionScript.new()
	session.rng.seed = 12345
	session.load_level(1, 0)
	session.reset_goal_progress()
	_check(
		session.round_goals.size() >= 1
		and session.round_spawn_sequence.size() == session.round_total_spawn_count,
		"Loading a level should build its goals and complete deterministic spawn plan"
	)
	var first_plan: Array[String] = session.round_spawn_sequence.duplicate()
	var first_times: Array[float] = session.round_spawn_times.duplicate()
	var repeated = FishingSessionScript.new()
	repeated.rng.seed = 12345
	repeated.load_level(1, 0)
	_check(
		repeated.round_spawn_sequence == first_plan
		and repeated.round_spawn_times == first_times,
		"The same injected seed should reproduce the same plan"
	)
	repeated.start_round()
	repeated.abandon_round()
	_check(
		repeated.state == repeated.RoundState.ABANDONED and not repeated.round_started,
		"Abandoning a round should be an explicit terminal session transition"
	)

	session.start_round()
	var before: float = session.round_time_remaining
	_check(
		not session.advance_time(1.25)
		and is_equal_approx(session.round_time_remaining, before - 1.25),
		"A running session should own its countdown"
	)
	var goal: Dictionary = session.round_goals[0]
	var fish := FishCatalogScript.definition(str(goal.fish_id))
	var catches: Array[Dictionary] = []
	for _index in range(int(goal.count)):
		catches.append(fish)
	session.record_catches(catches)
	_check(
		session.fish_caught == catches.size()
		and int(session.round_goal_counts[str(goal.fish_id)]) == int(goal.count),
		"Catches should update both session totals and capped goal progress"
	)

	for other_goal_index in range(1, session.round_goals.size()):
		var other_goal: Dictionary = session.round_goals[other_goal_index]
		session.round_goal_counts[str(other_goal.fish_id)] = int(other_goal.count)
	_check(session.goals_completed(), "Completing every goal should settle the round successfully")
	_check(session.finish_round(true), "A completed round should return success")
	var reward := session.claim_completion_xp()
	_check(
		reward == session.round_xp_reward and session.claim_completion_xp() == 0,
		"Completion XP should be claimable exactly once"
	)

	var failed = FishingSessionScript.new()
	failed.rng.seed = 9
	failed.load_level(1, 0)
	failed.reset_goal_progress()
	var base_chance: float = failed.round_catch_success_chance
	_check(not failed.finish_round(), "Missing goals should fail the round")
	_check(
		failed.current_level_retry_count == 1
		and failed.round_catch_success_chance >= base_chance,
		"A failed round should record retry assistance"
	)
	failed.prepare_retry()
	_check(
		failed.state == failed.RoundState.PREPARING
		and failed.fish_caught == 0
		and failed.round_goal_counts.values().all(func(value): return int(value) == 0),
		"Preparing a retry should reset transient round state without losing assistance"
	)

	if failures.is_empty():
		print("FISHING SESSION TEST PASS")
		quit(0)
	else:
		print("FISHING SESSION TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
