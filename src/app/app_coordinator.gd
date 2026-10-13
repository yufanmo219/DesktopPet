class_name AppCoordinator
extends Node

## Application-level screen and music coordinator.
##
## Main composes feature screens and responds to their signals. This class owns
## the cross-cutting transition policy: screen lifetime, Aquarium caching and
## which background track belongs to each screen.

signal screen_changed(screen_name: String)

var router: ScreenRouter
var _music_manager


func configure(screen_host: Control, music_manager: Node = null) -> void:
	_music_manager = music_manager
	router = ScreenRouter.new()
	router.name = "ScreenRouter"
	add_child(router)
	router.configure(screen_host)
	router.screen_changed.connect(_on_router_screen_changed)


func open_screen(screen_id: StringName) -> Control:
	_transition_music(router.current_screen, screen_id)
	return router.open_blank(
		screen_id,
		ScreenId.should_cache(router.current_screen)
	)


func restore_screen(screen_id: StringName) -> Control:
	if not router.has_cached(screen_id):
		return null
	_transition_music(router.current_screen, screen_id)
	return router.restore(
		screen_id,
		ScreenId.should_cache(router.current_screen)
	)


func relabel_current(screen_id: StringName) -> void:
	# AQUARIUM_LOADING and AQUARIUM intentionally share one music policy, so a
	# loading-to-ready relabel must not restart the same track.
	router.relabel_current(screen_id)


func has_cached(screen_id: StringName) -> bool:
	return router.has_cached(screen_id)


func cached_root(screen_id: StringName) -> Control:
	return router.cached_root(screen_id)


func discard_cached(screen_id: StringName) -> void:
	router.discard_cached(screen_id)


func _transition_music(previous_screen: StringName, next_screen: StringName) -> void:
	if _music_manager == null:
		return
	if next_screen == ScreenId.DESKTOP_WIDGET:
		# Desktop Companion must be silent immediately, including when it is
		# entered while a previous screen's fade is still active.
		_music_manager.stop_music(0.0)
		return
	var previous_track := _music_track(previous_screen)
	var next_track := _music_track(next_screen)
	if previous_track == next_track:
		return
	if previous_track == &"aquarium":
		_music_manager.stop_aquarium_music()
	elif previous_track != &"":
		_music_manager.stop_music()

	match next_track:
		&"home":
			_music_manager.play_home_music()
		&"fishing":
			_music_manager.play_fishing_music()
		&"aquarium":
			_music_manager.play_aquarium_music()
		&"shop":
			_music_manager.play_shop_music()


func _music_track(screen_id: StringName) -> StringName:
	match screen_id:
		ScreenId.HOME:
			return &"home"
		ScreenId.FISHING:
			return &"fishing"
		ScreenId.AQUARIUM_LOADING, ScreenId.AQUARIUM:
			return &"aquarium"
		ScreenId.STORE, ScreenId.FISH_BOOK:
			return &"shop"
		_:
			return &""


func _on_router_screen_changed(
	_previous_screen: StringName,
	current_screen: StringName,
	_current_root: Control
) -> void:
	screen_changed.emit(String(current_screen))
