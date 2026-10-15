class_name FishingSession
extends RefCounted

## Pure domain model for one fishing session.
##
## It owns round rules, deterministic planning, goals, retry assistance and
## reward idempotency. It intentionally has no Node, texture, audio, tween or
## scene-tree dependency.

const FishCatalogScript = preload("res://src/fish_catalog.gd")
const FishingLevelCatalogScript = preload("res://src/fishing_level_catalog.gd")

enum RoundState {
	PREPARING,
	RUNNING,
	SUCCEEDED,
	FAILED,
	ABANDONED
}

const MAX_ROUND_GOAL_TYPES := 3
const FIRST_LEVEL := 1
const DEFAULT_ROUND_TIME_LIMIT_SECONDS := FishingLevelCatalogScript.MAX_TIME_LIMIT_SECONDS
const DEFAULT_CATCH_SUCCESS_CHANCE := 0.98
const RETRY_ESCAPE_REDUCTION := 0.03
const FIRST_FISH_SPAWN_TIME_SECONDS := 0.25
const FINAL_FISH_SPAWN_TIME_FRACTION := 0.90
const FINAL_FISH_SPAWN_MIN_REMAINING_SECONDS := 3.0
const SPAWN_SLOT_RANDOM_MIN := 0.15
const SPAWN_SLOT_RANDOM_MAX := 0.85

var state := RoundState.PREPARING
var current_level := FIRST_LEVEL
var fish_caught := 0
var xp_earned := 0
var round_config: Dictionary = {}
var round_goals: Array[Dictionary] = []
var round_spawn_fish_ids: Array[String] = []
var round_time_limit_seconds := DEFAULT_ROUND_TIME_LIMIT_SECONDS
var round_difficulty_multiplier := 1.0
var round_target_pass_rate := 0.95
var round_catch_success_chance := DEFAULT_CATCH_SUCCESS_CHANCE
var current_level_retry_count := 0
var round_spawn_total_multiplier := FishingLevelCatalogScript.spawn_total_multiplier(0.95)
var round_xp_reward := 0
var round_completion_xp_awarded := false
var round_completion_pending := false
var round_time_remaining := float(DEFAULT_ROUND_TIME_LIMIT_SECONDS)
var round_started := false
var round_goal_counts: Dictionary = {}
var round_spawn_sequence: Array[String] = []
var round_spawn_times: Array[float] = []
var round_planned_spawn_counts: Dictionary = {}
var round_required_fish_total := 0
var round_total_spawn_count := 0
var round_retry_target_spawn_bonus_per_goal := 0
var next_spawn_index := 0
var rng := RandomNumberGenerator.new()


func load_level(level: int, retry_count: int) -> void:
	current_level = maxi(FIRST_LEVEL, level)
	current_level_retry_count = maxi(0, retry_count)
	round_config = FishingLevelCatalogScript.level_config(current_level)
	round_goals.clear()
	for goal in round_config.get("goals", []):
		round_goals.append(Dictionary(goal).duplicate(true))
	round_spawn_fish_ids.clear()
	for fish_id in round_config.get("spawn_fish_ids", []):
		round_spawn_fish_ids.append(str(fish_id))
	round_time_limit_seconds = clampi(
		int(round_config.get("time_limit_seconds", DEFAULT_ROUND_TIME_LIMIT_SECONDS)),
		FishingLevelCatalogScript.MIN_TIME_LIMIT_SECONDS,
		FishingLevelCatalogScript.MAX_TIME_LIMIT_SECONDS
	)
	round_difficulty_multiplier = maxf(
		0.75,
		float(round_config.get("difficulty_multiplier", 1.0))
	)
	round_target_pass_rate = clampf(
		float(round_config.get("target_pass_rate", 0.75)),
		0.0,
		1.0
	)
	update_catch_success_chance()
	round_spawn_total_multiplier = maxf(
		1.0,
		float(round_config.get(
			"spawn_total_multiplier",
			FishingLevelCatalogScript.spawn_total_multiplier(round_target_pass_rate)
		))
	)
	round_xp_reward = maxi(0, int(round_config.get("xp_reward", 0)))
	round_completion_xp_awarded = false
	round_completion_pending = false
	round_time_remaining = float(round_time_limit_seconds)
	round_started = false
	state = RoundState.PREPARING
	build_spawn_plan()


func start_round() -> void:
	round_time_remaining = float(round_time_limit_seconds)
	round_started = true
	next_spawn_index = 0
	state = RoundState.RUNNING


func advance_time(delta: float) -> bool:
	if not round_started or state != RoundState.RUNNING or round_time_remaining <= 0.0:
		return false
	round_time_remaining = maxf(0.0, round_time_remaining - maxf(0.0, delta))
	return round_time_remaining <= 0.0


func reset_goal_progress() -> void:
	round_goal_counts.clear()
	var visible_goal_count := mini(round_goals.size(), MAX_ROUND_GOAL_TYPES)
	for index in range(visible_goal_count):
		var fish_id := str(round_goals[index].get("fish_id", "green"))
		round_goal_counts[fish_id] = 0


func record_catches(caught_fishes: Array[Dictionary]) -> void:
	fish_caught += caught_fishes.size()
	for fish in caught_fishes:
		var fish_id := str(fish.get("id", ""))
		if not round_goal_counts.has(fish_id):
			continue
		var required_count := required_goal_count(fish_id)
		var current_count := int(round_goal_counts.get(fish_id, 0))
		round_goal_counts[fish_id] = mini(required_count, current_count + 1)
	round_completion_pending = goals_completed()


func required_goal_count(fish_id: String) -> int:
	for goal in round_goals:
		if str(goal.get("fish_id", "")) == fish_id:
			return maxi(0, int(goal.get("count", 0)))
	return 0


func goals_completed() -> bool:
	var visible_goal_count := mini(round_goals.size(), MAX_ROUND_GOAL_TYPES)
	for index in range(visible_goal_count):
		var goal: Dictionary = round_goals[index]
		var fish_id := str(goal.get("fish_id", "green"))
		var required_count := maxi(0, int(goal.get("count", 0)))
		if int(round_goal_counts.get(fish_id, 0)) < required_count:
			return false
	return true


func finish_round(preserve_time_remaining := false) -> bool:
	if not preserve_time_remaining:
		round_time_remaining = 0.0
	round_started = false
	round_completion_pending = false
	if goals_completed():
		state = RoundState.SUCCEEDED
		return true
	record_failed_attempt()
	state = RoundState.FAILED
	return false


func abandon_round() -> void:
	round_started = false
	round_completion_pending = false
	state = RoundState.ABANDONED


func prepare_retry() -> void:
	fish_caught = 0
	xp_earned = 0
	round_completion_pending = false
	round_completion_xp_awarded = false
	round_time_remaining = float(round_time_limit_seconds)
	round_started = false
	state = RoundState.PREPARING
	build_spawn_plan()
	reset_goal_progress()


func advance_to_next_level(saved_level: int) -> void:
	current_level = maxi(
		maxi(current_level + 1, saved_level),
		FIRST_LEVEL
	)
	fish_caught = 0
	xp_earned = 0
	load_level(current_level, 0)
	reset_goal_progress()


func claim_completion_xp() -> int:
	if round_completion_xp_awarded:
		return 0
	round_completion_xp_awarded = true
	xp_earned = round_xp_reward
	return round_xp_reward


func catch_succeeds(fish_is_inside_net: bool, roll: float) -> bool:
	return fish_is_inside_net and roll < round_catch_success_chance


func update_catch_success_chance() -> void:
	var base_catch_chance := clampf(
		float(round_config.get("catch_success_chance", DEFAULT_CATCH_SUCCESS_CHANCE)),
		0.0,
		1.0
	)
	var base_escape_chance := 1.0 - base_catch_chance
	var assisted_escape_chance := maxf(
		0.0,
		base_escape_chance - float(current_level_retry_count) * RETRY_ESCAPE_REDUCTION
	)
	round_catch_success_chance = 1.0 - assisted_escape_chance


func record_failed_attempt() -> void:
	current_level_retry_count += 1
	update_catch_success_chance()


func retry_target_spawn_bonus_per_goal() -> int:
	var base_catch_chance := clampf(
		float(round_config.get("catch_success_chance", DEFAULT_CATCH_SUCCESS_CHANCE)),
		0.0,
		1.0
	)
	var base_escape_chance := 1.0 - base_catch_chance
	var retries_until_guaranteed := ceili(
		maxf(0.0, base_escape_chance - 0.000001) / RETRY_ESCAPE_REDUCTION
	)
	return maxi(0, current_level_retry_count - retries_until_guaranteed)


func build_spawn_plan() -> void:
	round_spawn_sequence.clear()
	round_spawn_times.clear()
	round_planned_spawn_counts.clear()
	round_required_fish_total = 0
	round_total_spawn_count = 0
	round_retry_target_spawn_bonus_per_goal = retry_target_spawn_bonus_per_goal()
	next_spawn_index = 0

	var target_spawn_quotas: Dictionary = {}
	var reserved_target_total := 0
	for goal in round_goals:
		var fish_id := str(goal.get("fish_id", "green"))
		var required_count := maxi(1, int(goal.get("count", 1)))
		round_required_fish_total += required_count
		var target_spawn_quota := (
			FishingLevelCatalogScript.guaranteed_target_spawn_count(required_count)
			+ round_retry_target_spawn_bonus_per_goal
		)
		target_spawn_quotas[fish_id] = target_spawn_quota
		reserved_target_total += target_spawn_quota

	var retry_target_spawn_bonus_total := (
		round_retry_target_spawn_bonus_per_goal * round_goals.size()
	)
	round_total_spawn_count = maxi(
		reserved_target_total,
		ceili(float(round_required_fish_total) * round_spawn_total_multiplier)
		+ retry_target_spawn_bonus_total
	)
	if round_total_spawn_count <= 0:
		return

	for goal in round_goals:
		var fish_id := str(goal.get("fish_id", "green"))
		var spawn_quota := int(target_spawn_quotas.get(fish_id, 0))
		for _copy_index in range(spawn_quota):
			round_spawn_sequence.append(fish_id)

	while round_spawn_sequence.size() < round_total_spawn_count:
		round_spawn_sequence.append(weighted_random_fish_id(round_spawn_fish_ids))
	shuffle_fish_ids(round_spawn_sequence)
	for fish_id in round_spawn_sequence:
		round_planned_spawn_counts[fish_id] = int(
			round_planned_spawn_counts.get(fish_id, 0)
		) + 1
	build_spawn_times(round_spawn_sequence.size())


func weighted_random_fish_id(candidate_ids: Array[String]) -> String:
	if candidate_ids.is_empty():
		return "green"
	var total_weight := 0.0
	for fish_id in candidate_ids:
		total_weight += maxf(
			0.001,
			float(FishCatalogScript.definition(fish_id).get("spawn_weight", 1.0))
		)
	var roll := rng.randf() * total_weight
	for fish_id in candidate_ids:
		roll -= maxf(
			0.001,
			float(FishCatalogScript.definition(fish_id).get("spawn_weight", 1.0))
		)
		if roll <= 0.0:
			return fish_id
	return candidate_ids.back()


func shuffle_fish_ids(fish_ids: Array) -> void:
	for index in range(fish_ids.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held_fish_id = fish_ids[index]
		fish_ids[index] = fish_ids[swap_index]
		fish_ids[swap_index] = held_fish_id


func build_spawn_times(spawn_count: int) -> void:
	round_spawn_times.clear()
	if spawn_count <= 0:
		return
	var final_spawn_time := minf(
		float(round_time_limit_seconds) * FINAL_FISH_SPAWN_TIME_FRACTION,
		float(round_time_limit_seconds) - FINAL_FISH_SPAWN_MIN_REMAINING_SECONDS
	)
	final_spawn_time = maxf(FIRST_FISH_SPAWN_TIME_SECONDS, final_spawn_time)
	if spawn_count == 1:
		round_spawn_times.append(rng.randf_range(
			FIRST_FISH_SPAWN_TIME_SECONDS,
			final_spawn_time
		))
		return
	var spawn_window := final_spawn_time - FIRST_FISH_SPAWN_TIME_SECONDS
	var slot_duration := spawn_window / float(spawn_count)
	for spawn_index in range(spawn_count):
		var slot_start := FIRST_FISH_SPAWN_TIME_SECONDS + slot_duration * float(spawn_index)
		round_spawn_times.append(
			slot_start
			+ slot_duration * rng.randf_range(
				SPAWN_SLOT_RANDOM_MIN,
				SPAWN_SLOT_RANDOM_MAX
			)
		)
