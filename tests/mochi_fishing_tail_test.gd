extends SceneTree

const FishingScript = preload("res://src/fishing_game.gd")
const ORIGINAL_DIRECTORY := "res://dev_only/unused_assets/assets/pets/mochi/fishing/cry"
const CLIPPED_INDICES := [1, 2, 3, 5, 6, 7]
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var frames := FishingScript.MOCHI_FISHING_CRY_FRAMES
	_check(frames.size() == 8, "Mochi must retain her eight-frame crying reaction")
	_check(frames[0] == FishingScript.MOCHI_FISHING_DEFAULT_TEXTURE, "The empty-net reaction must still start on the approved idle frame")
	for index in range(1, frames.size()):
		var image := Image.load_from_file(ProjectSettings.globalize_path(
			frames[index].resource_path
		))
		var original := Image.load_from_file(ProjectSettings.globalize_path(
			"%s/frame_%02d.png" % [ORIGINAL_DIRECTORY, index + 1]
		))
		var bounds := image.get_used_rect()
		var old_bounds := original.get_used_rect()
		_check(image.get_size() == Vector2i(627, 627), "All cry frames must retain their fixed canvas")
		_check(bounds.position.y == old_bounds.position.y and bounds.end.y == old_bounds.end.y, "Tail repair must not move or resize Mochi")
		_check(Rect2i(16, 16, 595, 595).encloses(bounds), "The entire crying cat must have transparent padding")
		var changed_body_pixels := 0
		var unexpected_added_pixels := 0
		for y in range(image.get_height()):
			for x in range(image.get_width()):
				var old_pixel := original.get_pixel(x, y)
				var new_pixel := image.get_pixel(x, y)
				if old_pixel.a >= 0.99 and old_pixel != new_pixel:
					changed_body_pixels += 1
				if old_pixel.a == 0.0 and new_pixel.a > 0.01:
					if x >= old_bounds.position.x or x < old_bounds.position.x - 16 or y < 450 or y >= 590:
						unexpected_added_pixels += 1
		_check(changed_body_pixels == 0, "Frame %d must preserve original face, fur, body and visible tail pixels" % (index + 1))
		_check(unexpected_added_pixels == 0, "Frame %d may only restore the missing left-tail sliver, never another cat or the background" % (index + 1))
		if index in CLIPPED_INDICES:
			_check(bounds.position.x <= old_bounds.position.x - 6, "Frame %d must recover the tail beyond the old crop line" % (index + 1))
			_check(_left_edge_run(image, bounds) < 28, "Frame %d must have a curved left tail edge, not the old straight cutoff" % (index + 1))
		else:
			_check(image.get_data() == original.get_data(), "An already complete frame must remain identical")

	var game := FishingScript.new()
	game.configure({"id": "mochi", "name": "Mochi"}, {"hearts": 5, "unlocked_fish_ids": ["green"]})
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
	_check(round_cat.texture == FishingScript.MOCHI_FISHING_FAILURE_STATIC_TEXTURE, "The already complete round-failure artwork must remain unchanged")
	_check(game.result_overlay.find_child("FishingRoundFailureHomeButton", true, false) != null and game.result_overlay.find_child("FishingRoundFailureRetryButton", true, false) != null, "Go Home and Try Again must remain available")
	game._clear_result_overlay()
	game._show_no_hearts_popup()
	var no_hearts_cat: TextureRect = game.result_overlay.find_child("FishingNoHeartsCat", true, false)
	_check(no_hearts_cat.texture == FishingScript.MOCHI_FISHING_FAILURE_STATIC_TEXTURE, "No-hearts popup must retain the complete static cat")
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
