extends SceneTree

const FishBookScreenScript = preload("res://src/fish_book_screen.gd")


func _fail(message: String) -> void:
	push_error(message)
	quit(1)


func _initialize() -> void:
	var fish_book = FishBookScreenScript.new()
	fish_book.configure_book(
		{
			"experience": 0,
			"unlocked_fish_ids": ["green"],
			"aquarium_fish_ids": ["green"],
		}
	)
	root.add_child(fish_book)
	await process_frame

	if fish_book.fish_slot_views.size() != 9:
		_fail("Fish Book must build all nine slots on its first page")
		return
	var green_slot: Sprite2D = fish_book.fish_slot_views[0]
	var expected_slot_scale := minf(
		fish_book.FISH_SLOT_ICON_MAX_SIZE.x / green_slot.texture.get_size().x,
		fish_book.FISH_SLOT_ICON_MAX_SIZE.y / green_slot.texture.get_size().y
	) * 0.72
	if not is_equal_approx(green_slot.scale.x, expected_slot_scale):
		_fail("Green Fish's left-page icon must be 72% of its former size")
		return

	var green_detail: Sprite2D = fish_book.fish_detail_view
	var expected_detail_scale := minf(
		fish_book.FISH_DETAIL_ICON_MAX_SIZE.x / green_detail.texture.get_size().x,
		fish_book.FISH_DETAIL_ICON_MAX_SIZE.y / green_detail.texture.get_size().y
	) * 0.52
	if not is_equal_approx(green_detail.scale.x, expected_detail_scale):
		_fail("Green Fish's right-page detail image must be 52% of its former size")
		return
	if green_slot.position != fish_book.FISH_SLOT_ICON_CENTER:
		_fail("Shrinking Green Fish must not move the left-page icon")
		return
	if green_detail.position != fish_book.FISH_DETAIL_ICON_CENTER:
		_fail("Shrinking Green Fish must not move the right-page detail image")
		return

	print("GREEN FISH BOOK SCALE TEST PASS: both Fish Book images shrink independently without moving")
	quit(0)
