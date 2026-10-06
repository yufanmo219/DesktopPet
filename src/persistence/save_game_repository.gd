class_name SaveGameRepository
extends RefCounted

## Durable JSON persistence for player-owned state.
##
## Writes are staged and validated before replacing the primary save. The last
## valid primary is kept as a backup, and a valid backup is restored whenever
## the primary cannot be parsed.

enum LoadStatus {
	NOT_FOUND,
	LOADED,
	RECOVERED_BACKUP,
	FUTURE_VERSION,
	INVALID
}


class LoadResult:
	extends RefCounted

	var status: int
	var data: Dictionary
	var message: String
	var source_path: String


	func _init(
		status_value: int,
		data_value: Dictionary = {},
		message_value := "",
		source_path_value := ""
	) -> void:
		status = status_value
		data = data_value
		message = message_value
		source_path = source_path_value


	func has_data() -> bool:
		return status in [
			LoadStatus.LOADED,
			LoadStatus.RECOVERED_BACKUP,
			LoadStatus.FUTURE_VERSION
		]


var primary_path: String
var backup_path: String
var temporary_path: String
var last_error_message := ""


func _init(configured_primary_path: String) -> void:
	primary_path = configured_primary_path
	backup_path = "%s.bak" % primary_path
	temporary_path = "%s.tmp" % primary_path


func load(supported_version: int) -> LoadResult:
	last_error_message = ""
	var primary_exists := FileAccess.file_exists(primary_path)
	var backup_exists := FileAccess.file_exists(backup_path)
	var primary_candidate := _read_dictionary(primary_path)
	if bool(primary_candidate.valid):
		return _make_versioned_result(
			primary_candidate.data,
			supported_version,
			LoadStatus.LOADED,
			primary_path
		)

	var backup_candidate := _read_dictionary(backup_path)
	if bool(backup_candidate.valid):
		var restore_error := _restore_backup_to_primary()
		var recovery_message := "Recovered the player save from its last valid backup."
		if restore_error != OK:
			recovery_message += " The primary file could not be repaired: %s." % error_string(
				restore_error
			)
		return _make_versioned_result(
			backup_candidate.data,
			supported_version,
			LoadStatus.RECOVERED_BACKUP,
			backup_path,
			recovery_message
		)

	if not primary_exists and not backup_exists:
		return LoadResult.new(LoadStatus.NOT_FOUND)

	var messages: Array[String] = []
	if primary_exists:
		messages.append(str(primary_candidate.message))
	if backup_exists:
		messages.append(str(backup_candidate.message))
	last_error_message = " ".join(messages)
	return LoadResult.new(
		LoadStatus.INVALID,
		{},
		last_error_message
	)


func save(data: Dictionary) -> Error:
	last_error_message = ""
	var serialized := JSON.stringify(data, "  ")
	var serialized_candidate := _parse_dictionary(serialized, "serialized save data")
	if not bool(serialized_candidate.valid):
		return _fail(
			ERR_INVALID_DATA,
			"Refused to write invalid save data: %s" % str(serialized_candidate.message)
		)

	var temporary_file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		return _fail(
			FileAccess.get_open_error(),
			"Could not open the temporary save file for writing."
		)
	temporary_file.store_string(serialized)
	temporary_file.flush()
	var write_error := temporary_file.get_error()
	temporary_file.close()
	if write_error != OK:
		_remove_temporary_file()
		return _fail(write_error, "Could not finish writing the temporary save file.")

	var written_candidate := _read_dictionary(temporary_path)
	if not bool(written_candidate.valid):
		_remove_temporary_file()
		return _fail(
			ERR_INVALID_DATA,
			"Temporary save verification failed: %s" % str(written_candidate.message)
		)

	# Never replace a known-good backup with a corrupt primary. This matters when
	# an external interruption damages the primary after startup but before the
	# next autosave.
	if FileAccess.file_exists(primary_path):
		var current_primary := _read_dictionary(primary_path)
		if bool(current_primary.valid):
			var backup_error := DirAccess.copy_absolute(primary_path, backup_path)
			if backup_error != OK:
				_remove_temporary_file()
				return _fail(backup_error, "Could not preserve the previous player save.")

	var replace_error := DirAccess.rename_absolute(temporary_path, primary_path)
	if replace_error != OK:
		_remove_temporary_file()
		return _fail(replace_error, "Could not atomically replace the player save.")
	return OK


func _make_versioned_result(
	data: Dictionary,
	supported_version: int,
	normal_status: int,
	source_path: String,
	message := ""
) -> LoadResult:
	var saved_version := int(data.get("version", 0))
	if saved_version > supported_version:
		return LoadResult.new(
			LoadStatus.FUTURE_VERSION,
			data.duplicate(true),
			"Save version %d is newer than supported version %d. Saving is disabled." % [
				saved_version,
				supported_version
			],
			source_path
		)
	return LoadResult.new(
		normal_status,
		data.duplicate(true),
		message,
		source_path
	)


func _read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"valid": false,
			"data": {},
			"message": "Save file does not exist: %s" % path
		}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"valid": false,
			"data": {},
			"message": "Could not open %s: %s" % [
				path,
				error_string(FileAccess.get_open_error())
			]
		}
	var text := file.get_as_text()
	file.close()
	return _parse_dictionary(text, path)


func _parse_dictionary(text: String, source_label: String) -> Dictionary:
	var parser := JSON.new()
	var parse_error := parser.parse(text)
	if parse_error != OK:
		return {
			"valid": false,
			"data": {},
			"message": "Invalid JSON in %s at line %d: %s" % [
				source_label,
				parser.get_error_line(),
				parser.get_error_message()
			]
		}
	if not parser.data is Dictionary:
		return {
			"valid": false,
			"data": {},
			"message": "Expected a JSON object in %s." % source_label
		}
	return {
		"valid": true,
		"data": Dictionary(parser.data),
		"message": ""
	}


func _restore_backup_to_primary() -> Error:
	var copy_error := DirAccess.copy_absolute(backup_path, temporary_path)
	if copy_error != OK:
		return copy_error
	var temporary_candidate := _read_dictionary(temporary_path)
	if not bool(temporary_candidate.valid):
		_remove_temporary_file()
		return ERR_INVALID_DATA
	var replace_error := DirAccess.rename_absolute(temporary_path, primary_path)
	if replace_error != OK:
		_remove_temporary_file()
	return replace_error


func _remove_temporary_file() -> void:
	if FileAccess.file_exists(temporary_path):
		DirAccess.remove_absolute(temporary_path)


func _fail(error: Error, message: String) -> Error:
	last_error_message = "%s (%s)" % [message, error_string(error)]
	return error
