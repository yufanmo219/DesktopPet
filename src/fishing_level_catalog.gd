class_name FishingLevelCatalog
extends RefCounted

## Deterministic 450-level fishing campaign followed by endless random levels.
##
## Fish "rarity levels" (0-15) are separate from playable campaign levels
## (1-450). Every new species is guaranteed to be a goal on its discovery
## level, so the full collection is introduced gradually rather than by chance.

const FishCatalogScript = preload("res://src/fish_catalog.gd")

const TOTAL_LEVELS := 450
const ENDLESS_START_LEVEL := TOTAL_LEVELS + 1
const ENDLESS_MIN_GOAL_TYPES := 2
const ENDLESS_MAX_GOAL_TYPES := 3
const ENDLESS_MIN_XP_REWARD := 200
const ENDLESS_MAX_XP_REWARD := 230
const LEGACY_XP_SCALING_LEVELS := 200
const MIN_TIME_LIMIT_SECONDS := 30
const MAX_TIME_LIMIT_SECONDS := 90
const MIN_GOAL_TYPES := 1
const MAX_GOAL_TYPES := 3
const MAX_SPAWN_FISH_TYPES := 15
const MAX_GOAL_COUNT := 12
const MIN_ESCAPE_CHANCE := 0.02
const MAX_ESCAPE_CHANCE := 0.15
const TARGET_SPAWN_GUARANTEE_MULTIPLIER := 1.2

# Target first-attempt completion rates. These are balancing targets rather
# than forced win rolls: the generator translates them into time, goal count,
# catch forgiveness, goal-fish frequency, and overall swim speed.
const TARGET_PASS_RATE_BANDS: Array[Dictionary] = [
	{"first_level": 1, "last_level": 20, "rate": 0.95},
	{"first_level": 21, "last_level": 60, "rate": 0.90},
	{"first_level": 61, "last_level": 120, "rate": 0.85},
	{"first_level": 121, "last_level": 170, "rate": 0.80},
	{"first_level": 171, "last_level": 450, "rate": 0.75}
]

# Approved base time for each first-attempt pass-rate band. Keeping this as an
# explicit table prevents interpolation from silently changing the values.
const PASS_RATE_BASE_TIME_BANDS: Array[Dictionary] = [
	{"minimum_rate": 0.95, "seconds": 86},
	{"minimum_rate": 0.90, "seconds": 78},
	{"minimum_rate": 0.85, "seconds": 70},
	{"minimum_rate": 0.80, "seconds": 66},
	{"minimum_rate": 0.75, "seconds": 53}
]

# A repeating breathing pattern keeps the campaign from feeling like a single
# straight countdown. Positive entries create recovery levels; negative ones
# create small challenge peaks while remaining inside the 30-90 second range.
const TIME_VARIATION_PATTERN: Array[int] = [4, 2, 0, -2, -4, -1, 2, 0]

# Green Fish is the only species known before play. Every other species is
# introduced by a campaign goal, including Coral Angelfish and Golden
# Ribbonfish on level 1. Completing a whole rarity level adds a small global
# difficulty step to every later playable level.
const DISCOVERY_LEVEL_BY_FISH_ID := {
	"green": 1,
	"coral": 2,
	"golden": 3,
	"blue_small": 5,
	"yellow_striped": 9,
	"pink_salmon": 13,
	"blue_tang": 17,
	"peach_goby": 25,
	"silver_mackerel": 30,
	"turquoise_guppy": 35,
	"clownfish": 40,
	"red_cardinalfish": 50,
	"mint_catfish": 57,
	"yellow_boxfish": 64,
	"red_white_koi": 75,
	"purple_butterfly": 82,
	"round_pufferfish": 89,
	"lavender_moonfish": 105,
	"deep_blue_tuna": 115,
	"lionfish": 135,
	"starlight_fish": 150,
	"brown_anglerfish": 175,
	"neon_tetra": 205,
	"zebra_danio": 213,
	"black_molly": 221,
	"sunset_swordtail": 229,
	"ruby_betta": 237,
	"fire_dartfish": 245,
	"sapphire_discus": 253,
	"royal_gramma": 261,
	"mandarin_dragonet": 269,
	"rainbow_parrotfish": 277,
	"picasso_triggerfish": 285,
	"moorish_idol": 293,
	"spotted_frogfish": 301,
	"silver_flyingfish": 309,
	"glass_knifefish": 317,
	"electric_eel": 325,
	"emerald_seahorse": 333,
	"blue_spotted_stingray": 341,
	"moray_eel": 350,
	"spotted_gar": 359,
	"red_arowana": 368,
	"golden_manta_ray": 377,
	"baby_whale_shark": 386,
	"hammerhead_shark": 395,
	"giant_arapaima": 404,
	"ancient_sturgeon": 413,
	"ocean_sunfish": 422,
	"leafy_seadragon": 431,
	"sawfish": 440,
	"coelacanth": 449
}

# Index is the fish rarity level. Entries mark the playable level on which the
# final species in that tier is first shown to the player.
const RARITY_LEVEL_COMPLETION_LEVELS: Array[int] = [
	1,
	17,
	40,
	64,
	89,
	115,
	150,
	213,
	245,
	277,
	309,
	341,
	368,
	395,
	422,
	449
]

static var _cached_levels: Array[Dictionary] = []


static func all_levels() -> Array[Dictionary]:
	_ensure_cache()
	var result: Array[Dictionary] = []
	for level_config in _cached_levels:
		result.append(level_config.duplicate(true))
	return result


static func level_config(level_number: int) -> Dictionary:
	_ensure_cache()
	var safe_level := maxi(level_number, 1)
	if safe_level > TOTAL_LEVELS:
		return _build_endless_level(safe_level)
	return _cached_levels[safe_level - 1].duplicate(true)


static func discovery_level(fish_id: String) -> int:
	return int(DISCOVERY_LEVEL_BY_FISH_ID.get(fish_id, TOTAL_LEVELS))


static func target_pass_rate(level_number: int) -> float:
	var safe_level := clampi(level_number, 1, TOTAL_LEVELS)
	for band in TARGET_PASS_RATE_BANDS:
		if safe_level >= int(band.first_level) and safe_level <= int(band.last_level):
			return float(band.rate)
	return 0.75


static func base_time_for_pass_rate(pass_rate: float) -> int:
	for band in PASS_RATE_BASE_TIME_BANDS:
		if pass_rate >= float(band.minimum_rate):
			return int(band.seconds)
	return 53


static func spawn_total_multiplier(pass_rate: float) -> float:
	if pass_rate >= 0.95:
		return 10
	if pass_rate >= 0.90:
		return 9
	if pass_rate >= 0.85:
		return 8
	if pass_rate >= 0.80:
		return 7.5
	return 7.5


static func guaranteed_target_spawn_count(required_count: int) -> int:
	return ceili(
		float(maxi(1, required_count))
		* TARGET_SPAWN_GUARANTEE_MULTIPLIER
	)


static func escape_chance(level_number: int) -> float:
	var safe_level := clampi(level_number, 1, TOTAL_LEVELS)
	var campaign_progress := float(safe_level - 1) / float(TOTAL_LEVELS - 1)
	return lerpf(MIN_ESCAPE_CHANCE, MAX_ESCAPE_CHANCE, campaign_progress)


static func available_fish_ids(level_number: int) -> Array[String]:
	var safe_level := clampi(level_number, 1, TOTAL_LEVELS)
	var result: Array[String] = []
	for fish in FishCatalogScript.FISH_TYPES:
		var fish_id := str(fish.get("id", ""))
		if discovery_level(fish_id) <= safe_level:
			result.append(fish_id)
	return result


static func _select_spawn_fish_ids(
	level_number: int,
	available_ids: Array[String],
	goal_ids: Array[String]
) -> Array[String]:
	if available_ids.size() <= MAX_SPAWN_FISH_TYPES:
		return available_ids.duplicate()

	# Keep all goals (including newly introduced species), then fill the other
	# slots from the full available catalog. Never truncate the catalog itself.
	var result: Array[String] = goal_ids.duplicate()
	var other_ids: Array[String] = []
	for fish_id in available_ids:
		if not result.has(fish_id):
			other_ids.append(fish_id)

	# A separate level seed keeps retries/reloads stable without changing the
	# existing goal selection or endless-level rewards.
	var pool_rng := RandomNumberGenerator.new()
	pool_rng.seed = level_number * 15485863 + 32452843
	for index in range(other_ids.size() - 1, 0, -1):
		var swap_index := pool_rng.randi_range(0, index)
		var held_fish_id := other_ids[index]
		other_ids[index] = other_ids[swap_index]
		other_ids[swap_index] = held_fish_id
	for fish_id in other_ids:
		if result.size() >= MAX_SPAWN_FISH_TYPES:
			break
		result.append(fish_id)
	return result


static func newly_introduced_fish_ids(level_number: int) -> Array[String]:
	if level_number > TOTAL_LEVELS:
		return []
	var safe_level := clampi(level_number, 1, TOTAL_LEVELS)
	var result: Array[String] = []
	for fish in FishCatalogScript.FISH_TYPES:
		var fish_id := str(fish.get("id", ""))
		if discovery_level(fish_id) == safe_level and not FishCatalogScript.STARTER_FISH_IDS.has(fish_id):
			result.append(fish_id)
	return result


static func completed_rarity_level_count(level_number: int) -> int:
	var safe_level := clampi(level_number, 1, TOTAL_LEVELS)
	var completed := 0
	# Rarity level 0 is the starter baseline, so only levels 1-15 add bumps.
	for rarity_level in range(1, RARITY_LEVEL_COMPLETION_LEVELS.size()):
		if safe_level > RARITY_LEVEL_COMPLETION_LEVELS[rarity_level]:
			completed += 1
	return completed


static func _ensure_cache() -> void:
	if _cached_levels.size() == TOTAL_LEVELS:
		return
	_cached_levels.clear()
	for level_number in range(1, TOTAL_LEVELS + 1):
		_cached_levels.append(_build_level(level_number))


static func _build_level(level_number: int) -> Dictionary:
	var fish_ids := available_fish_ids(level_number)
	var introduced_ids := newly_introduced_fish_ids(level_number)
	var pass_rate := target_pass_rate(level_number)
	var goal_type_count := _goal_type_count(level_number)
	goal_type_count = maxi(goal_type_count, introduced_ids.size())
	goal_type_count = clampi(goal_type_count, MIN_GOAL_TYPES, MAX_GOAL_TYPES)

	var selected_goal_ids: Array[String] = []
	for fish_id in introduced_ids:
		selected_goal_ids.append(fish_id)

	var cursor := ((level_number - 1) * 7 + completed_rarity_level_count(level_number) * 3) % fish_ids.size()
	var attempts := 0
	while selected_goal_ids.size() < goal_type_count and attempts < fish_ids.size() * 2:
		var candidate := fish_ids[cursor % fish_ids.size()]
		if not selected_goal_ids.has(candidate):
			selected_goal_ids.append(candidate)
		cursor += 5
		attempts += 1

	var goals: Array[Dictionary] = []
	for fish_id in selected_goal_ids:
		goals.append({
			"fish_id": fish_id,
			"count": _goal_count(level_number, fish_id, goal_type_count, pass_rate)
		})

	var completed_tiers := completed_rarity_level_count(level_number)
	return {
		"level": level_number,
		"target_pass_rate": pass_rate,
		"time_limit_seconds": _time_limit_seconds(level_number, completed_tiers, pass_rate),
		"xp_reward": _xp_reward(level_number, completed_tiers, goals.size()),
		"goals": goals,
		"spawn_fish_ids": _select_spawn_fish_ids(level_number, fish_ids, selected_goal_ids),
		"new_fish_ids": introduced_ids,
		"completed_rarity_levels": completed_tiers,
		"catch_success_chance": 1.0 - escape_chance(level_number),
		"spawn_total_multiplier": spawn_total_multiplier(pass_rate),
		"difficulty_multiplier": 0.92 + (0.95 - pass_rate) + float(completed_tiers) * 0.01
	}


static func _build_endless_level(level_number: int) -> Dictionary:
	var safe_level := maxi(level_number, ENDLESS_START_LEVEL)
	var level_450: Dictionary = _cached_levels[TOTAL_LEVELS - 1]
	var rng := RandomNumberGenerator.new()
	# A level-number seed keeps the selection random-looking but stable if the
	# player closes and reopens the game before completing the same level.
	rng.seed = safe_level * 104729 + 7103

	var fish_ids := available_fish_ids(TOTAL_LEVELS)
	for index in range(fish_ids.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held_fish_id := fish_ids[index]
		fish_ids[index] = fish_ids[swap_index]
		fish_ids[swap_index] = held_fish_id

	var goal_type_count := rng.randi_range(
		ENDLESS_MIN_GOAL_TYPES,
		ENDLESS_MAX_GOAL_TYPES
	)
	var selected_goal_ids: Array[String] = []
	for index in range(goal_type_count):
		selected_goal_ids.append(fish_ids[index])

	var goals: Array[Dictionary] = []
	var pass_rate := float(level_450.get("target_pass_rate", 0.75))
	for fish_id in selected_goal_ids:
		goals.append({
			"fish_id": fish_id,
			"count": _goal_count(TOTAL_LEVELS, fish_id, goal_type_count, pass_rate)
		})

	return {
		"level": safe_level,
		"target_pass_rate": pass_rate,
		"time_limit_seconds": int(level_450.get("time_limit_seconds", 30)),
		"xp_reward": rng.randi_range(ENDLESS_MIN_XP_REWARD, ENDLESS_MAX_XP_REWARD),
		"goals": goals,
		"spawn_fish_ids": _select_spawn_fish_ids(
			safe_level, available_fish_ids(TOTAL_LEVELS), selected_goal_ids
		),
		"new_fish_ids": [],
		"completed_rarity_levels": int(level_450.get("completed_rarity_levels", 15)),
		"catch_success_chance": float(level_450.get("catch_success_chance", 0.80)),
		"spawn_total_multiplier": float(level_450.get(
			"spawn_total_multiplier",
			spawn_total_multiplier(pass_rate)
		)),
		"difficulty_multiplier": float(level_450.get("difficulty_multiplier", 1.0)),
		"is_endless": true
	}


static func _goal_type_count(level_number: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = level_number * 104729 + 7103

	if level_number <= 2:
		return 1
	if level_number <= 10:
		return rng.randi_range(1, 2)
	if level_number <= 50:
		return rng.randi_range(1, 3)
	if level_number <= 120:
		return rng.randi_range(2, 3)
	return 3


static func _goal_count(
	level_number: int,
	fish_id: String,
	goal_type_count: int,
	pass_rate: float
) -> int:
	var fish := FishCatalogScript.definition(fish_id)
	var rarity_level := int(fish.get("rarity_level", 0))
	var base_count := FishCatalogScript.base_goal_count(fish_id)
	var campaign_bonus := mini(3, floori(float(level_number - 1) / 55.0))
	var tier_bonus := floori(float(completed_rarity_level_count(level_number)) / 3.0)
	var crowded_goal_reduction := 1 if goal_type_count >= 3 else 0
	var rare_fish_reduction := floori(float(rarity_level) / 3.0)
	var pass_rate_reduction := 1 if pass_rate >= 0.90 else 0
	return clampi(
		base_count + campaign_bonus + tier_bonus - crowded_goal_reduction - rare_fish_reduction - pass_rate_reduction,
		1,
		MAX_GOAL_COUNT
	)


static func _time_limit_seconds(
	level_number: int,
	completed_tiers: int,
	pass_rate: float
) -> int:
	var band_base_time := base_time_for_pass_rate(pass_rate)
	var breathing_adjustment := TIME_VARIATION_PATTERN[(level_number - 1) % TIME_VARIATION_PATTERN.size()]
	# Preserve breathing room in the late campaign instead of flattening every
	# post-tier-10 level against the 30-second minimum.
	var milestone_penalty := mini(completed_tiers, 10)
	return clampi(
		band_base_time + breathing_adjustment - milestone_penalty,
		MIN_TIME_LIMIT_SECONDS,
		MAX_TIME_LIMIT_SECONDS
	)


static func _xp_reward(
	level_number: int,
	completed_tiers: int,
	goal_type_count: int
) -> int:
	# Keep the reward curve of levels 1-200 unchanged, then continue that same
	# per-level slope through the extended campaign.
	var campaign_reward := roundi(
		float(level_number - 1) * 55.0 / float(LEGACY_XP_SCALING_LEVELS - 1)
	)
	return 25 + campaign_reward + completed_tiers * 5 + goal_type_count * 3
