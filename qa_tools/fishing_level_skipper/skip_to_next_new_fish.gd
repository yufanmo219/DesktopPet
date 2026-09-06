extends SceneTree

## Standalone QA save helper. Nothing in the shipped game references this file.
## Run without --apply for a read-only preview; --apply writes the confirmed plan.

const LevelCatalog = preload("res://src/fishing_level_catalog.gd")
const FishCatalog = preload("res://src/fish_catalog.gd")
const DEFAULT_SAVE_PATH := "user://desktop_pet_save.json"
const PROGRESS_SAVE_KEY := "progress_stats"
const LEGACY_PROGRESS_SAVE_KEY := "pinball_stats"


func _initialize() -> void:
	var arguments := OS.get_cmdline_user_args()
	var should_apply := arguments.has("--apply")
	var save_path := ProjectSettings.globalize_path(DEFAULT_SAVE_PATH)
	for argument in arguments:
		if argument.begins_with("--save-path="):
			save_path = argument.trim_prefix("--save-path=")

	var result := apply_to_save_file(save_path) if should_apply else preview_save_file(save_path)
	_print_result(result, should_apply)
	quit(0 if bool(result.get("ok", false)) else 1)


static func next_new_fish_level(current_level: int) -> int:
	var first_candidate := maxi(1, current_level)
	for level_number in range(first_candidate, LevelCatalog.TOTAL_LEVELS + 1):
		if not LevelCatalog.newly_introduced_fish_ids(level_number).is_empty():
			return level_number
	return -1


static func build_skip_plan(current_level: int) -> Dictionary:
	var safe_current := maxi(1, current_level)
	var target_level := next_new_fish_level(safe_current)
	if target_level < 0:
		return {
			"can_skip": false,
			"current_level": safe_current,
			"reason": "There are no later campaign levels that introduce a new fish."
		}
	if target_level == safe_current:
		return {
			"can_skip": false,
			"current_level": safe_current,
			"target_level": target_level,
			"new_fish_ids": LevelCatalog.newly_introduced_fish_ids(target_level),
			"reason": "The current level already introduces a new fish."
		}

	var xp_gain := 0
	for level_number in range(safe_current, target_level):
		xp_gain += maxi(0, int(LevelCatalog.level_config(level_number).get("xp_reward", 0)))
	return {
		"can_skip": true,
		"current_level": safe_current,
		"target_level": target_level,
		"first_skipped_level": safe_current,
		"last_skipped_level": target_level - 1,
		"skipped_level_count": target_level - safe_current,
		"xp_gain": xp_gain,
		"new_fish_ids": LevelCatalog.newly_introduced_fish_ids(target_level)
	}


static func preview_save_file(save_path: String) -> Dictionary:
	var loaded := _read_save_file(save_path)
	if not bool(loaded.get("ok", false)):
		return loaded
	var save_data: Dictionary = loaded.data
	var raw_stats: Variant = save_data.get(
		PROGRESS_SAVE_KEY,
		save_data.get(LEGACY_PROGRESS_SAVE_KEY, {})
	)
	if not raw_stats is Dictionary:
		return {"ok": false, "message": "The save has no valid progress_stats object."}
	var stats: Dictionary = raw_stats
	var plan := build_skip_plan(int(stats.get("fishing_level", 1)))
	return {
		"ok": true,
		"changed": false,
		"save_path": save_path,
		"experience_before": maxi(0, int(stats.get("experience", 0))),
		"plan": plan
	}


static func apply_to_save_data(save_data: Dictionary, plan: Dictionary, now_unix: int) -> Dictionary:
	var changed_data := save_data.duplicate(true)
	if not bool(plan.get("can_skip", false)):
		return changed_data
	var raw_stats: Variant = changed_data.get(
		PROGRESS_SAVE_KEY,
		changed_data.get(LEGACY_PROGRESS_SAVE_KEY, {})
	)
	var stats: Dictionary = raw_stats.duplicate(true) if raw_stats is Dictionary else {}
	stats["fishing_level"] = int(plan.target_level)
	stats["experience"] = maxi(0, int(stats.get("experience", 0))) + int(plan.xp_gain)
	# A skipped current attempt is settled as a pass, just like normal success.
	stats.erase("fishing_retry_level")
	stats.erase("fishing_retry_count")
	changed_data[PROGRESS_SAVE_KEY] = stats
	changed_data.erase(LEGACY_PROGRESS_SAVE_KEY)
	changed_data["last_updated_unix"] = now_unix
	return changed_data


static func apply_to_save_file(save_path: String, now_unix := -1) -> Dictionary:
	var preview := preview_save_file(save_path)
	if not bool(preview.get("ok", false)):
		return preview
	var plan: Dictionary = preview.plan
	if not bool(plan.get("can_skip", false)):
		preview["message"] = str(plan.get("reason", "Nothing to skip."))
		return preview

	var loaded := _read_save_file(save_path)
	if not bool(loaded.get("ok", false)):
		return loaded
	var save_data: Dictionary = loaded.data
	var timestamp := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	var backup_path := _unique_backup_path(save_path, timestamp)
	var copy_error := DirAccess.copy_absolute(save_path, backup_path)
	if copy_error != OK:
		return {
			"ok": false,
			"message": "Could not create a safety backup (error %d). The save was not changed." % copy_error
		}

	var changed_data := apply_to_save_data(save_data, plan, timestamp)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"backup_path": backup_path,
			"message": "Could not open the save for writing. The untouched backup is available."
		}
	file.store_string(JSON.stringify(changed_data, "  "))
	file.close()
	if FileAccess.get_open_error() != OK:
		return {
			"ok": false,
			"backup_path": backup_path,
			"message": "The save write failed. Restore the safety backup before playing."
		}

	return {
		"ok": true,
		"changed": true,
		"save_path": save_path,
		"backup_path": backup_path,
		"experience_before": int(preview.experience_before),
		"experience_after": int(preview.experience_before) + int(plan.xp_gain),
		"plan": plan
	}


static func _read_save_file(save_path: String) -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {"ok": false, "message": "Save not found: %s" % save_path}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Could not read save: %s" % save_path}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {"ok": false, "message": "The save is not valid JSON. Nothing was changed."}
	if not parsed.has("pet_pool"):
		return {"ok": false, "message": "This does not look like a Desktop Pet save. Nothing was changed."}
	return {"ok": true, "data": parsed}


static func _unique_backup_path(save_path: String, timestamp: int) -> String:
	var base := "%s.qa_before_level_skip_%d" % [save_path.get_basename(), timestamp]
	var candidate := base + ".json"
	var suffix := 2
	while FileAccess.file_exists(candidate):
		candidate = "%s_%d.json" % [base, suffix]
		suffix += 1
	return candidate


static func _fish_names(fish_ids: Array) -> String:
	var names: Array[String] = []
	for fish_id_value in fish_ids:
		var fish_id := str(fish_id_value)
		names.append(str(FishCatalog.definition(fish_id).get("name", fish_id)))
	return ", ".join(names)


static func _print_result(result: Dictionary, was_apply: bool) -> void:
	print("\n=== FISHING QA: SKIP TO NEXT NEW FISH ===")
	if not bool(result.get("ok", false)):
		printerr("ERROR: %s" % str(result.get("message", "Unknown error")))
		return
	var plan: Dictionary = result.get("plan", {})
	print("Save: %s" % str(result.get("save_path", "")))
	print("Current playable level: %d" % int(plan.get("current_level", 1)))
	if not bool(plan.get("can_skip", false)):
		print("No change: %s" % str(plan.get("reason", "Nothing to skip.")))
		if plan.has("new_fish_ids"):
			print("New fish here: %s" % _fish_names(plan.new_fish_ids))
		return
	print("Skip and settle levels: %d-%d (%d levels)" % [
		int(plan.first_skipped_level),
		int(plan.last_skipped_level),
		int(plan.skipped_level_count)
	])
	print("Next playable level: %d" % int(plan.target_level))
	print("New fish there: %s" % _fish_names(plan.new_fish_ids))
	print("XP: %d + %d = %d" % [
		int(result.experience_before),
		int(plan.xp_gain),
		int(result.get("experience_after", int(result.experience_before) + int(plan.xp_gain)))
	])
	if was_apply and bool(result.get("changed", false)):
		print("\nAPPLIED. Safety backup: %s" % str(result.backup_path))
	else:
		print("\nPREVIEW ONLY. The save has not been changed.")
