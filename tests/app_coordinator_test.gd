extends SceneTree

const AppCoordinatorScript = preload("res://src/app/app_coordinator.gd")


class FakeMusicManager:
	extends Node

	var events: Array[String] = []


	func play_home_music() -> void:
		events.append("play_home")


	func play_fishing_music() -> void:
		events.append("play_fishing")


	func play_aquarium_music() -> void:
		events.append("play_aquarium")


	func play_shop_music() -> void:
		events.append("play_shop")


	func stop_aquarium_music() -> void:
		events.append("stop_aquarium")


	func stop_music(fade_seconds := 0.8) -> void:
		events.append("stop_music:%s" % fade_seconds)


var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func run_tests() -> void:
	var host := Control.new()
	root.add_child(host)
	var music := FakeMusicManager.new()
	root.add_child(music)
	var coordinator: AppCoordinator = AppCoordinatorScript.new()
	root.add_child(coordinator)
	coordinator.configure(host, music)

	var home_root := coordinator.open_screen(ScreenId.HOME)
	_check(
		coordinator.router.current_screen == ScreenId.HOME
		and home_root.get_parent() == host
		and music.events == ["play_home"],
		"Opening HOME should attach one root and start HOME music"
	)

	var aquarium_root := coordinator.open_screen(ScreenId.AQUARIUM)
	var aquarium_marker := Node.new()
	aquarium_marker.name = "CachedAquariumMarker"
	aquarium_root.add_child(aquarium_marker)
	_check(
		music.events.slice(-2) == ["stop_music:0.8", "play_aquarium"],
		"HOME to AQUARIUM should stop the old track before starting the new one"
	)

	coordinator.open_screen(ScreenId.HOME)
	_check(
		coordinator.has_cached(ScreenId.AQUARIUM)
		and aquarium_root.get_parent() == null,
		"Leaving AQUARIUM should cache its detached screen root"
	)
	var restored_root := coordinator.restore_screen(ScreenId.AQUARIUM)
	_check(
		restored_root == aquarium_root
		and restored_root.get_node_or_null("CachedAquariumMarker") == aquarium_marker,
		"Restoring AQUARIUM should preserve the same prepared screen tree"
	)

	coordinator.open_screen(ScreenId.PET_POOL)
	coordinator.open_screen(ScreenId.DESKTOP_WIDGET)
	_check(
		music.events.back().begins_with("stop_music:0"),
		"Desktop mode should cancel any pending music fade immediately"
	)

	coordinator.discard_cached(ScreenId.AQUARIUM)
	_check(
		not coordinator.has_cached(ScreenId.AQUARIUM),
		"Cached screens should support explicit invalidation"
	)

	coordinator.queue_free()
	host.queue_free()
	music.queue_free()
	await process_frame
	if failures.is_empty():
		print("APP COORDINATOR TEST PASS: routing, caching, music policy, and invalidation")
		quit(0)
	else:
		print("APP COORDINATOR TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
