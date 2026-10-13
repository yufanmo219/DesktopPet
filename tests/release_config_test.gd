extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var presets := ConfigFile.new()
	_check(
		presets.load("res://export_presets.cfg") == OK,
		"Shared export presets should be readable"
	)
	_check(
		presets.get_value("preset.0", "name", "") == "Windows Desktop"
		and presets.get_value("preset.0", "export_path", "") == "build/windows/Desktop Pet.exe"
		and presets.get_value("preset.0.options", "binary_format/architecture", "") == "x86_64",
		"Windows QA export should use the shared x86_64 preset"
	)
	_check(
		presets.get_value("preset.1", "name", "") == "macOS"
		and presets.get_value("preset.1", "export_path", "") == "build/macos/Desktop Pet.zip"
		and presets.get_value("preset.1.options", "binary_format/architecture", "") == "universal"
		and bool(presets.get_value("preset.1.options", "entitlements/hardened_runtime", false)),
		"macOS QA export should use a universal hardened-runtime preset"
	)
	var excluded := str(presets.get_value("preset.0", "exclude_filter", ""))
	_check(
		excluded.contains("tests/*")
		and excluded.contains("tools/*")
		and excluded.contains("dev_only/*")
		and excluded.contains("build/*"),
		"Exports should exclude tests, tooling, archives, and generated builds"
	)
	_check(
		FileAccess.file_exists("res://.github/workflows/ci.yml")
		and FileAccess.file_exists("res://.github/workflows/qa-builds.yml")
		and FileAccess.file_exists("res://tools/export_builds.py"),
		"CI, QA export workflow, and local export entry point should travel together"
	)

	if failures.is_empty():
		print("RELEASE CONFIG TEST PASS: shared Windows/macOS presets and automation")
		quit(0)
	else:
		print("RELEASE CONFIG TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
