extends SceneTree

const StoreScene = preload("res://src/store/store_screen.tscn")
const FishBookScene = preload("res://src/fish_book/fish_book_screen.tscn")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func run_tests() -> void:
	var store: StoreScreen = StoreScene.instantiate()
	store.configure({"experience": 2500}, ["maple"])
	root.add_child(store)
	await process_frame
	_check(
		store.get_node_or_null("CatalogBookShell") != null
		and store.cat_grid_layer != null
		and store.fish_grid_layer == null,
		"Store scene should compose the shared shell with cat-only content"
	)
	_check(
		store.store_title_label.text == "CAT SHELTER"
		and store.experience_label.text == "YOUR XP: 2,500",
		"Store scene should bind its own title and progression data"
	)

	var fish_book: FishBookScreen = FishBookScene.instantiate()
	fish_book.configure_book({
		"experience": 137,
		"unlocked_fish_ids": ["green"],
		"aquarium_fish_ids": ["green"]
	})
	root.add_child(fish_book)
	await process_frame
	_check(
		fish_book.get_node_or_null("CatalogBookShell") != null
		and fish_book.fish_grid_layer != null
		and fish_book.cat_grid_layer == null,
		"Fish Book scene should compose the shared shell with fish-only content"
	)
	_check(
		fish_book.store_title_label.text == "FISHIPEDIA"
		and fish_book.experience_label.text == "YOUR XP: 137",
		"Fish Book should bind its own title without inheriting StoreScreen"
	)
	_check(
		fish_book.get_script().resource_path == "res://src/fish_book_screen.gd"
		and fish_book.get_script() != store.get_script(),
		"Fish Book must remain an independent feature type"
	)

	store.queue_free()
	fish_book.queue_free()
	await process_frame
	if failures.is_empty():
		print("CATALOG SCENE STRUCTURE TEST PASS: shared shell and independent features")
		quit(0)
	else:
		print("CATALOG SCENE STRUCTURE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
