class_name DesktopWindowHost
extends Node

## Owns native desktop windows and isolates platform-specific window behavior.
##
## Pet behavior never belongs here. The companion controller decides where
## windows should move; this host only creates, positions, layers, and restores
## them.

var station_window: Window
var pet_window: Window
var pet_window_raise_pending := false

var _main_window: Window
var _normal_window_size := Vector2i(1152, 648)
var _normal_window_position := Vector2i.ZERO
var _normal_window_min_size := Vector2i(960, 540)
var _normal_content_scale_size := Vector2i(1280, 720)
var _normal_window_unresizable := false

var normal_window_unresizable: bool:
	get:
		return _normal_window_unresizable


func capture_main_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_main_window = get_window()
	_normal_window_size = _main_window.size
	_normal_window_position = _main_window.position
	_normal_window_min_size = _main_window.min_size
	_normal_content_scale_size = _main_window.content_scale_size
	_normal_window_unresizable = _main_window.unresizable


func create_station_window(
	pixel_size: Vector2,
	logical_size: Vector2i,
	position: Vector2
) -> Window:
	destroy_station_window()
	if DisplayServer.get_name() == "headless":
		return null
	station_window = _make_transparent_window(
		"DesktopStationWindow",
		pixel_size,
		logical_size,
		position
	)
	station_window.focus_entered.connect(schedule_pet_window_raise)
	add_child(station_window)
	apply_station_transparency()
	return station_window


func create_pet_window(
	pixel_size: Vector2,
	logical_size: Vector2i,
	position: Vector2
) -> Window:
	destroy_pet_window()
	if DisplayServer.get_name() == "headless":
		return null
	pet_window = _make_transparent_window(
		"DesktopPetWindow",
		pixel_size,
		logical_size,
		position
	)
	add_child(pet_window)
	apply_pet_transparency()
	return pet_window


func _make_transparent_window(
	window_name: String,
	pixel_size: Vector2,
	logical_size: Vector2i,
	position: Vector2
) -> Window:
	var window := Window.new()
	window.name = window_name
	window.visible = false
	window.size = Vector2i(pixel_size)
	window.content_scale_size = logical_size
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	window.force_native = true
	window.transparent_bg = true
	window.borderless = true
	window.transparent = true
	window.transient = false
	window.transient_to_focused = false
	window.always_on_top = true
	window.unresizable = true
	window.position = Vector2i(position)
	return window


func apply_station_transparency() -> void:
	if not is_instance_valid(station_window):
		return
	station_window.transparent_bg = true
	station_window.borderless = true
	station_window.transparent = true
	station_window.always_on_top = true
	station_window.unresizable = true


func apply_pet_transparency() -> void:
	if not is_instance_valid(pet_window):
		return
	pet_window.transparent_bg = true
	pet_window.borderless = true
	pet_window.transparent = true
	pet_window.always_on_top = true
	pet_window.unresizable = true


func show_windows(station_position: Vector2, pet_position: Vector2) -> void:
	if is_instance_valid(station_window):
		apply_station_transparency()
		station_window.show()
		call_deferred("_settle_initial_window_order", station_position, pet_position)
		call_deferred("apply_station_transparency")
	if is_instance_valid(pet_window):
		apply_pet_transparency()
		pet_window.show()
		call_deferred("apply_pet_transparency")
		schedule_pet_window_raise()
	if is_instance_valid(station_window):
		station_window.grab_focus()
		call_deferred("schedule_pet_window_raise")


func _settle_initial_window_order(
	station_position: Vector2,
	pet_position: Vector2
) -> void:
	if not is_instance_valid(station_window):
		return
	station_window.position = Vector2i(station_position) + Vector2i.RIGHT
	if is_instance_valid(pet_window):
		pet_window.position = Vector2i(pet_position) + Vector2i.RIGHT
	call_deferred("_finish_initial_window_order", station_position, pet_position)


func _finish_initial_window_order(
	station_position: Vector2,
	pet_position: Vector2
) -> void:
	if not is_instance_valid(station_window):
		return
	station_window.position = Vector2i(station_position)
	if is_instance_valid(pet_window):
		pet_window.position = Vector2i(pet_position)
	schedule_pet_window_raise()


func set_station_position(position: Vector2) -> void:
	if is_instance_valid(station_window):
		station_window.position = Vector2i(position)


func set_pet_position(position: Vector2) -> void:
	if is_instance_valid(pet_window):
		pet_window.position = Vector2i(position)
	schedule_pet_window_raise()


func schedule_pet_window_raise() -> void:
	if pet_window_raise_pending or not is_instance_valid(pet_window):
		return
	pet_window_raise_pending = true
	call_deferred("_defer_pet_window_raise_once")


func _defer_pet_window_raise_once() -> void:
	call_deferred("_raise_pet_window_above_station")


func _raise_pet_window_above_station() -> void:
	pet_window_raise_pending = false
	if not is_instance_valid(pet_window) or not pet_window.visible:
		return
	if is_instance_valid(station_window) and station_window.visible:
		station_window.always_on_top = false
		station_window.always_on_top = true
	pet_window.always_on_top = false
	pet_window.always_on_top = true


func park_main_window(desktop_rect: Rect2) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not is_instance_valid(_main_window):
		_main_window = get_window()
	_main_window.unresizable = true
	_main_window.borderless = true
	_main_window.always_on_top = false
	get_viewport().transparent_bg = true
	_main_window.transparent = true
	_main_window.min_size = Vector2i.ONE
	_main_window.content_scale_size = Vector2i.ONE
	_main_window.size = Vector2i.ONE
	_main_window.position = Vector2i(desktop_rect.position) - Vector2i(4096, 4096)


func restore_main_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not is_instance_valid(_main_window):
		_main_window = get_window()
	_main_window.show()
	_main_window.transparent = false
	get_viewport().transparent_bg = false
	get_viewport().gui_embed_subwindows = true
	_main_window.borderless = false
	_main_window.always_on_top = false
	_main_window.unresizable = _normal_window_unresizable
	_main_window.min_size = _normal_window_min_size
	_main_window.content_scale_size = _normal_content_scale_size
	_main_window.size = _normal_window_size
	_main_window.position = _normal_window_position


func destroy_pet_window() -> void:
	if is_instance_valid(pet_window):
		pet_window.hide()
		pet_window.queue_free()
	pet_window = null
	pet_window_raise_pending = false


func destroy_station_window() -> void:
	if is_instance_valid(station_window):
		station_window.hide()
		station_window.queue_free()
	station_window = null


func shutdown() -> void:
	destroy_pet_window()
	destroy_station_window()
	restore_main_window()
