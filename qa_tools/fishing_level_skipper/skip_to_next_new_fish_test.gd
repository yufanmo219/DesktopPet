extends SceneTree

const SkipTool = preload("res://qa_tools/fishing_level_skipper/skip_to_next_new_fish.gd")
const LevelCatalog = preload("res://src/fishing_level_catalog.gd")
const TEST_SAVE := "/private/tmp/desktop_pet_qa_skip_test.json"
const TEST_TIME := 1800000000
var failures: Array[String] = []


func _initialize() -> void:
	var plan := SkipTool.build_skip_plan(176)
	_check(bool(plan.can_skip), "Level 176 should be skippable")
	_check(int(plan.target_level) == 205, "Level 205 should be the next new-fish level")
	_check(plan.new_fish_ids == ["neon_tetra"], "Level 205 should introduce Neon Tetra")
	_check(int(plan.skipped_level_count) == 29, "Levels 176-204 should be settled")
	var independent_xp_sum := 0
	for level_number in range(176, 205):
		independent_xp_sum += int(LevelCatalog.level_config(level_number).xp_reward)
	_check(int(plan.xp_gain) == independent_xp_sum, "XP must equal every existing skipped-level reward exactly once")

	var already_new := SkipTool.build_skip_plan(205)
	_check(not bool(already_new.can_skip) and int(already_new.target_level) == 205, "A new-fish level must never be skipped")
	var campaign_end := SkipTool.build_skip_plan(450)
	_check(not bool(campaign_end.can_skip), "No endless level may be treated as a new-fish level")

	var original := {
		"version": 8,
		"active_pet_id": "luna",
		"owned_cat_ids": ["maple", "luna"],
		"pet_pool": [{"id": "luna", "name": "Luna", "type": "Cat"}],
		"last_updated_unix": 17,
		"progress_stats": {
			"experience": 3201,
			"fishing_level": 176,
			"fishing_retry_level": 176,
			"fishing_retry_count": 5,
			"hearts": 4,
			"next_heart_restore_unix": 12345,
			"unlocked_fish_ids": ["green", "brown_anglerfish"],
			"aquarium_fish_ids": ["green"]
		}
	}
	var changed := SkipTool.apply_to_save_data(original, plan, TEST_TIME)
	_check(int(changed.progress_stats.fishing_level) == 205, "The next playable level must be the new-fish level")
	_check(int(changed.progress_stats.experience) == 3201 + independent_xp_sum, "Skipped XP must add to existing XP")
	_check(not changed.progress_stats.has("fishing_retry_level") and not changed.progress_stats.has("fishing_retry_count"), "Passing the skipped range must clear temporary retry assistance")
	_check(int(changed.progress_stats.hearts) == 4 and int(changed.progress_stats.next_heart_restore_unix) == 12345, "Hearts must not change")
	_check(changed.progress_stats.unlocked_fish_ids == original.progress_stats.unlocked_fish_ids and changed.progress_stats.aquarium_fish_ids == original.progress_stats.aquarium_fish_ids, "Fish book and aquarium must not change")
	_check(changed.owned_cat_ids == original.owned_cat_ids and changed.pet_pool == original.pet_pool and changed.active_pet_id == original.active_pet_id, "Cats must not change")
	_check(int(changed.last_updated_unix) == TEST_TIME, "Only the normal save timestamp may update outside progress stats")
	_check(int(original.progress_stats.fishing_level) == 176 and int(original.progress_stats.experience) == 3201, "Planning must not mutate the source data")

	_write_json(TEST_SAVE, original)
	var original_file_text := FileAccess.get_file_as_string(TEST_SAVE)
	var file_result := SkipTool.apply_to_save_file(TEST_SAVE, TEST_TIME)
	_check(bool(file_result.ok) and bool(file_result.changed), "Confirmed application should write a temporary save")
	_check(FileAccess.file_exists(str(file_result.backup_path)), "A safety backup must exist before application")
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE))
	_check(saved is Dictionary and int(saved.progress_stats.fishing_level) == 205, "The temporary save should contain the new level")
	_check(FileAccess.get_file_as_string(str(file_result.backup_path)) == original_file_text, "The backup must be a byte-for-byte copy of the pre-skip save")

	DirAccess.remove_absolute(TEST_SAVE)
	if file_result.has("backup_path"):
		DirAccess.remove_absolute(str(file_result.backup_path))

	if failures.is_empty():
		print("FISHING QA SKIPPER TEST PASS: discovery targeting, exact XP, protected fields, retry reset, backup and campaign boundaries")
		quit(0)
	else:
		print("FISHING QA SKIPPER TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "  "))
	file.close()
