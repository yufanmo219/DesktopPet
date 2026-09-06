extends SceneTree

const LevelCatalog = preload("res://src/fishing_level_catalog.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const FishingGameScript = preload("res://src/fishing_game.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run_tests() -> void:
	_check(LevelCatalog.MAX_SPAWN_FISH_TYPES == 15, "The per-level species cap should be fifteen")
	_check(
		LevelCatalog.guaranteed_target_spawn_count(8) == 10
		and LevelCatalog.guaranteed_target_spawn_count(10) == 12,
		"Every target species should reserve ceil(required count times 1.2) appearances"
	)
	_check(
		FishCatalogScript.SPAWN_WEIGHTS_BY_RARITY_LEVEL.size() == 16
		and is_equal_approx(FishCatalogScript.SPAWN_WEIGHTS_BY_RARITY_LEVEL.front(), 1.0)
		and is_equal_approx(FishCatalogScript.SPAWN_WEIGHTS_BY_RARITY_LEVEL.back(), 0.25),
		"The rarity weight curve should run from 1.00 to 0.25 across all sixteen tiers"
	)
	for fish in FishCatalogScript.FISH_TYPES:
		_check(
			is_equal_approx(
				float(fish.spawn_weight),
				FishCatalogScript.SPAWN_WEIGHTS_BY_RARITY_LEVEL[int(fish.rarity_level)]
			),
			"%s should use its rarity tier's balanced spawn weight" % str(fish.name)
		)
	var configs: Array[Dictionary] = LevelCatalog.all_levels()
	for level in range(451, 551):
		configs.append(LevelCatalog.level_config(level))
	for level in [1000, 10000]:
		configs.append(LevelCatalog.level_config(level))

	var all_spawned_species := {}
	var endless_spawned_species := {}
	var endless_pool_sets := {}
	for config in configs:
		var level := int(config.level)
		var available_ids := LevelCatalog.available_fish_ids(level)
		var pool: Array = config.spawn_fish_ids
		_check(
			pool.size() == mini(15, available_ids.size()),
			"Level %d should fill up to fifteen slots using available species only" % level
		)
		var unique_ids := {}
		for fish_id in pool:
			unique_ids[fish_id] = true
			all_spawned_species[fish_id] = true
			_check(available_ids.has(fish_id), "Level %d must not introduce fish early" % level)
			if level > LevelCatalog.TOTAL_LEVELS:
				endless_spawned_species[fish_id] = true
		_check(unique_ids.size() == pool.size(), "Level %d should not duplicate species slots" % level)
		for goal in config.goals:
			_check(pool.has(str(goal.fish_id)), "Level %d must keep every goal fish" % level)
		for fish_id in config.new_fish_ids:
			_check(pool.has(fish_id), "Level %d must keep newly introduced fish" % level)
		if available_ids.size() <= 15:
			_check(pool == available_ids, "Level %d's uncapped pool should remain unchanged" % level)
		if level > LevelCatalog.TOTAL_LEVELS:
			var sorted_pool := pool.duplicate()
			sorted_pool.sort()
			endless_pool_sets[JSON.stringify(sorted_pool)] = true

	_check(all_spawned_species.size() == FishCatalogScript.FISH_TYPES.size(), "All catalog species should remain obtainable")
	_check(endless_spawned_species.size() == FishCatalogScript.FISH_TYPES.size(), "Endless pools should draw from the full catalog, not the same first fifteen species")
	_check(endless_pool_sets.size() > 1, "The capped pool should vary between levels")
	_check(LevelCatalog.available_fish_ids(154).size() == 21, "The level 154 discovery catalog should still contain twenty-one fish")
	_check(LevelCatalog.level_config(154).spawn_fish_ids.size() == 15, "Level 154 should now spawn at most fifteen species")

	# Rebuilding the campaign cache simulates a fresh load, not just a cached read.
	LevelCatalog._cached_levels.clear()
	for config in configs:
		_check(config == LevelCatalog.level_config(int(config.level)), "Level %d should keep the same configuration after reloading" % int(config.level))

	# Exercise the real plan builder without starting a scene or touching a save.
	var game := FishingGameScript.new()
	for config in configs:
		game.current_level = int(config.level)
		game.current_level_retry_count = 0
		game.rng.seed = int(config.level)
		game._load_round_configuration()
		_check_spawn_plan(game)
	for level in [75, 81, 82, 149, 150, 154, 175, 449, 450, 451, 500, 10000]:
		var original_pool: Array = LevelCatalog.level_config(level).spawn_fish_ids
		for retry_count in [1, 3, 6, 10]:
			game.current_level = level
			game.current_level_retry_count = retry_count
			game.rng.seed = level * 10 + retry_count
			game._load_round_configuration()
			_check(game.round_spawn_fish_ids == original_pool, "Retry assistance should keep the same capped pool")
			_check_spawn_plan(game)
	game.free()

	if failures.is_empty():
		print("FISHING SPAWN POOL TEST PASS: 450 campaign levels, 102 endless levels, and retry assistance")
		quit(0)
	else:
		print("FISHING SPAWN POOL TEST FAIL: ", failures.size())
		quit(1)


func _check_spawn_plan(game: FishingGame) -> void:
	_check(game.round_planned_spawn_counts.size() <= 15, "The actual spawn plan must not exceed fifteen species")
	for fish_id in game.round_planned_spawn_counts:
		_check(game.round_spawn_fish_ids.has(fish_id), "The actual spawn plan must use only the capped pool")
	for goal in game.round_goals:
		_check(
			int(game.round_planned_spawn_counts.get(str(goal.fish_id), 0))
			>= LevelCatalog.guaranteed_target_spawn_count(int(goal.count))
			+ game.round_retry_target_spawn_bonus_per_goal,
			"Capping species must preserve goal quotas and temporary retry bonuses"
		)
	var expected_total := (
		ceili(float(game.round_required_fish_total) * game.round_spawn_total_multiplier)
		+ game.round_retry_target_spawn_bonus_per_goal * game.round_goals.size()
	)
	_check(game.round_total_spawn_count == expected_total, "The species cap must not change the total fish count")
	_check(game.round_spawn_sequence.size() == expected_total, "The plan must still contain the full fish count")
