extends SceneTree

const MainScript = preload("res://src/main.gd")
const SaveGameRepositoryScript = preload("res://src/persistence/save_game_repository.gd")

var failures: Array[String] = []
var test_path := ""


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error(message)


func _run() -> void:
	test_path = OS.get_temp_dir().path_join(
		"desktop_pet_save_repository_test_%d.json" % OS.get_process_id()
	)
	_cleanup()
	var repository = SaveGameRepositoryScript.new(test_path)

	var first_save := _save_fixture(8, 1)
	_check(repository.save(first_save) == OK, "The first save should be written successfully")
	_check(_read_json(test_path).get("sequence", 0) == 1, "The primary save should contain the first snapshot")

	var second_save := _save_fixture(8, 2)
	_check(repository.save(second_save) == OK, "A later save should replace the primary")
	_check(_read_json(test_path).get("sequence", 0) == 2, "The primary should contain the newest snapshot")
	_check(_read_json(repository.backup_path).get("sequence", 0) == 1, "The previous valid primary should be retained as backup")

	_write_text(test_path, "{ interrupted")
	var recovered = repository.load(8)
	_check(
		recovered.status == SaveGameRepositoryScript.LoadStatus.RECOVERED_BACKUP,
		"A corrupt primary should recover from the backup"
	)
	_check(recovered.data.get("sequence", 0) == 1, "Recovery should return the last valid backup")
	_check(_read_json(test_path).get("sequence", 0) == 1, "Recovery should repair the primary file")

	var future_save := _save_fixture(99, 3)
	_write_text(test_path, JSON.stringify(future_save, "  "))
	var future_result = repository.load(8)
	_check(
		future_result.status == SaveGameRepositoryScript.LoadStatus.FUTURE_VERSION,
		"A newer save schema should be detected before migration"
	)
	_check(future_result.data.get("version", 0) == 99, "Future-version data should remain intact")

	var game = MainScript.new()
	game.save_repository = repository
	game.save_enabled = true
	game.load_save()
	_check(game.save_read_only, "Main should enter read-only mode for a future save")
	_check(game.save_data.get("version", 0) == 99, "Main should preserve the future schema version in memory")
	var future_text_before := _read_text(test_path)
	game.save_data["sequence"] = 999
	game.save_game()
	_check(_read_text(test_path) == future_text_before, "Read-only mode must never overwrite a future save")
	game.free()

	_write_text(test_path, "not json")
	_write_text(repository.backup_path, "also not json")
	var invalid_result = repository.load(8)
	_check(
		invalid_result.status == SaveGameRepositoryScript.LoadStatus.INVALID,
		"Two invalid save files should report an explicit invalid result"
	)
	_check(not invalid_result.message.is_empty(), "Invalid save diagnostics should explain the failure")

	_cleanup()
	if failures.is_empty():
		print("SAVE GAME REPOSITORY TEST PASS: staged writes, backup rotation, recovery, validation, and future-version read-only protection")
		quit(0)
	else:
		print("SAVE GAME REPOSITORY TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _save_fixture(version: int, sequence: int) -> Dictionary:
	return {
		"version": version,
		"sequence": sequence,
		"pet_pool": [{
			"id": "default_orange_cat",
			"name": "Maple",
			"type": "Cat"
		}],
		"active_pet_id": "default_orange_cat",
		"owned_cat_ids": ["maple"],
		"progress_stats": {
			"experience": 0,
			"hearts": 5,
			"next_heart_restore_unix": 0,
			"fishing_level": 1,
			"unlocked_fish_ids": [],
			"aquarium_fish_ids": []
		}
	}


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "Test fixture should open for writing: %s" % path)
	if file == null:
		return
	file.store_string(text)
	file.flush()
	file.close()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	_check(file != null, "Test fixture should open for reading: %s" % path)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _read_json(path: String) -> Dictionary:
	var parsed = JSON.parse_string(_read_text(path))
	return parsed if parsed is Dictionary else {}


func _cleanup() -> void:
	for path in [test_path, "%s.bak" % test_path, "%s.tmp" % test_path]:
		if path != "" and FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
