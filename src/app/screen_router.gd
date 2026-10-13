class_name ScreenRouter
extends Node

## Owns screen-root lifecycle and reusable screen instances.
##
## Feature screens never remove one another directly. The application opens a
## root through this router, which either disposes or caches the previous root.

signal screen_changed(
	previous_screen: StringName,
	current_screen: StringName,
	current_root: Control
)

var current_screen: StringName = ScreenId.NONE
var current_root: Control

var _host: Control
var _cached_roots: Dictionary = {}


func configure(host: Control) -> void:
	_host = host


func open_blank(screen_id: StringName, cache_previous := false) -> Control:
	var root := Control.new()
	root.name = _screen_root_name(screen_id)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return show_root(screen_id, root, cache_previous)


func show_root(
	screen_id: StringName,
	root: Control,
	cache_previous := false
) -> Control:
	assert(is_instance_valid(_host), "ScreenRouter must be configured before use")
	var previous_screen := current_screen
	_detach_current(cache_previous)
	if root.get_parent() != null:
		root.get_parent().remove_child(root)
	_host.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	current_screen = screen_id
	current_root = root
	screen_changed.emit(previous_screen, current_screen, current_root)
	return current_root


func restore(screen_id: StringName, cache_previous := false) -> Control:
	var root: Control = _cached_roots.get(screen_id)
	if not is_instance_valid(root):
		_cached_roots.erase(screen_id)
		return null
	_cached_roots.erase(screen_id)
	return show_root(screen_id, root, cache_previous)


func relabel_current(screen_id: StringName) -> void:
	if current_screen == screen_id:
		return
	var previous_screen := current_screen
	current_screen = screen_id
	screen_changed.emit(previous_screen, current_screen, current_root)


func has_cached(screen_id: StringName) -> bool:
	return is_instance_valid(_cached_roots.get(screen_id))


func cached_root(screen_id: StringName) -> Control:
	var root: Control = _cached_roots.get(screen_id)
	return root if is_instance_valid(root) else null


func discard_cached(screen_id: StringName) -> void:
	var root: Control = _cached_roots.get(screen_id)
	_cached_roots.erase(screen_id)
	if is_instance_valid(root):
		root.free()


func _detach_current(cache_current: bool) -> void:
	if not is_instance_valid(current_root):
		current_root = null
		return
	if current_root.get_parent() != null:
		current_root.get_parent().remove_child(current_root)
	if cache_current:
		discard_cached(current_screen)
		_cached_roots[current_screen] = current_root
	else:
		current_root.queue_free()
	current_root = null


func _screen_root_name(screen_id: StringName) -> String:
	if screen_id == ScreenId.NONE:
		return "EmptyScreenRoot"
	return "%sScreenRoot" % String(screen_id).to_pascal_case()


func _exit_tree() -> void:
	for root_value in _cached_roots.values():
		var root: Control = root_value
		if is_instance_valid(root):
			root.free()
	_cached_roots.clear()
