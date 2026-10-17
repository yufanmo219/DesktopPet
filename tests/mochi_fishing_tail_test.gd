extends SceneTree

const FishingScript = preload("res://src/fishing_game.gd")
const CLIPPED_INDICES := [1, 2, 3, 5, 6, 7]
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var game := FishingScript.new()
	game.configure({"id": "mochi", "name": "Mochi"}, {"hearts": 5, "unlocked_fish_ids": ["green"]})
	var presentation: FishingPetPresentation = game.pet_presentation
	var frames := presentation.empty_catch_frames
	_check(frames.size() == 8, "Mochi must retain her eight-frame crying reaction")
	_check(frames[0] == presentation.default_texture, "The empty-net reaction must still start on the approved idle frame")
	for index in range(1, frames.size()):
		var image := Image.load_from_file(ProjectSettings.globalize_path(
			frames[index].resource_path
		))
		_check(image != null and not image.is_empty(), "Mochi cry frame %d must exist in the runtime asset set" % (index + 1))
		if image == null or image.is_empty():
			continue
		var bounds := image.get_used_rect()
		_check(image.get_size() == Vector2i(627, 627), "All cry frames must retain their fixed canvas")
		_check(Rect2i(16, 16, 595, 595).encloses(bounds), "The entire crying cat must have transparent padding")
		if index in CLIPPED_INDICES:
			_check(_left_edge_run(image, bounds) < 28, "Frame %d must have a curved left tail edge, not the old straight cutoff" % (index + 1))

	root.add_child(game)
	await process_frame
	game.set_process(false)
	game._start_round_from_goal_popup()
	game.spawn_timer.stop()
	game.state = game.GameState.LIFTING_NET
	var pet_position: Vector2 = game.pet_view.position
	var pet_size: Vector2 = game.pet_view.size
	var empty_catch: Array[TextureRect] = []
	await game._play_lift_animation(empty_catch, false)
	_check(game.pet_view.texture == frames[-1], "An empty net must finish on the restored crying frame")
	_check(game.pet_view.position == pet_position and game.pet_view.size == pet_size, "Restoring the tail must not shift or rescale the riverbank cat")
	_check(game._failure_cat_texture() == frames[-1], "The failed-catch popup must use the restored complete-tail frame")
	game._show_failure()
	_check(_contains_texture(game.result_overlay, frames[-1]), "The actual failed-catch overlay must display the restored frame")
	game._clear_result_overlay()
	game._show_round_failure()
	var round_cat: TextureRect = game.result_overlay.find_child("FishingRoundFailureCat", true, false)
	_check(round_cat.texture == presentation.round_failure_texture, "The already complete round-failure artwork must remain unchanged")
	_check(game.result_overlay.find_child("FishingRoundFailureHomeButton", true, false) != null and game.result_overlay.find_child("FishingRoundFailureRetryButton", true, false) != null, "Go Home and Try Again must remain available")
	game._clear_result_overlay()
	game._show_no_hearts_popup()
	var no_hearts_cat: TextureRect = game.result_overlay.find_child("FishingNoHeartsCat", true, false)
	_check(no_hearts_cat.texture == presentation.round_failure_texture, "No-hearts popup must retain the complete static cat")
	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("MOCHI FISHING TAIL TEST PASS: six clipped tails restored, original coat preserved, empty-net animation and failure popups verified")
		quit(0)
	else:
		print("MOCHI FISHING TAIL TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _left_edge_run(image: Image, bounds: Rect2i) -> int:
	var longest := 0
	var run := 0
	for y in range(bounds.position.y, bounds.end.y):
		if image.get_pixel(bounds.position.x, y).a > 0.5:
			run += 1
			longest = maxi(longest, run)
		else:
			run = 0
	return longest


func _contains_texture(node: Node, texture: Texture2D) -> bool:
	if node is TextureRect and node.texture == texture:
		return true
	for child in node.get_children():
		if _contains_texture(child, texture):
			return true
	return false
