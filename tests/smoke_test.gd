extends SceneTree

const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const FishingLevelCatalogScript = preload("res://src/fishing_level_catalog.gd")
const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("run_tests")


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func pet_texture(catalog_id: String, key: String) -> Texture2D:
	return PetCatalogScript.definition_by_catalog_id(catalog_id).load_texture(key)


func wait_for_screen(game: Node, screen_name: String, maximum_frames := 600) -> bool:
	for _frame_index in range(maximum_frames):
		if game.current_screen == screen_name:
			return true
		await process_frame
	return false


func alpha_difference_in_right_region(
	first_texture: Texture2D,
	second_texture: Texture2D,
	start_x: int
) -> int:
	var first_image := first_texture.get_image()
	var second_image := second_texture.get_image()
	var difference := 0
	for y in range(mini(first_image.get_height(), second_image.get_height())):
		for x in range(start_x, mini(first_image.get_width(), second_image.get_width())):
			if absf(first_image.get_pixel(x, y).a - second_image.get_pixel(x, y).a) > 0.125:
				difference += 1
	return difference


func maximum_alpha_difference_in_right_region(
	frames: Array[Texture2D],
	start_x: int
) -> int:
	var maximum_difference := 0
	for first_index in range(frames.size()):
		for second_index in range(first_index + 1, frames.size()):
			maximum_difference = maxi(
				maximum_difference,
				alpha_difference_in_right_region(
					frames[first_index],
					frames[second_index],
					start_x
				)
			)
	return maximum_difference


func _image_region_difference_count(
	first_image: Image,
	second_image: Image,
	region: Rect2i,
	tolerance := 0.01
) -> int:
	var difference := 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var first_pixel := first_image.get_pixel(x, y)
			var second_pixel := second_image.get_pixel(x, y)
			if (
				absf(first_pixel.r - second_pixel.r)
				+ absf(first_pixel.g - second_pixel.g)
				+ absf(first_pixel.b - second_pixel.b)
				+ absf(first_pixel.a - second_pixel.a)
				> tolerance
			):
				difference += 1
	return difference


func _texture_lower_half_has_green_chroma(texture: Texture2D) -> bool:
	var image := texture.get_image()
	var start_y := roundi(float(image.get_height()) * 0.55)
	for y in range(start_y, image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if (
				pixel.a > 0.05
				and pixel.g > 0.29
				and pixel.g - maxf(pixel.r, pixel.b) > 0.12
			):
				return true
	return false


func _texture_bottom_band_has_green_chroma(texture: Texture2D) -> bool:
	var image := texture.get_image()
	var start_y := roundi(float(image.get_height()) * 0.78)
	for y in range(start_y, image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if (
				pixel.a > 0.03
				and pixel.g > 0.70
				and pixel.r < 0.28
				and pixel.b < 0.28
			):
				return true
	return false


func _texture_has_green_chroma(texture: Texture2D) -> bool:
	var image := texture.get_image()
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.03 and pixel.g - maxf(pixel.r, pixel.b) > 0.04:
				return true
	return false


func _walk_lower_center_transparent_ratio(texture: Texture2D) -> float:
	var image := texture.get_image()
	var used_rect := image.get_used_rect()
	var start_x := used_rect.position.x + roundi(float(used_rect.size.x) * 0.10)
	var end_x := used_rect.position.x + roundi(float(used_rect.size.x) * 0.90)
	var start_y := used_rect.position.y + roundi(float(used_rect.size.y) * 0.60)
	var transparent_pixels := 0
	var total_pixels := 0
	for y in range(start_y, used_rect.end.y):
		for x in range(start_x, end_x):
			total_pixels += 1
			if image.get_pixel(x, y).a < 0.03:
				transparent_pixels += 1
	return float(transparent_pixels) / maxf(float(total_pixels), 1.0)


func _walk_has_unsupported_floor_shadow(texture: Texture2D) -> bool:
	var image := texture.get_image()
	var used_rect := image.get_used_rect()
	var center_start_x := used_rect.position.x + roundi(float(used_rect.size.x) * 0.10)
	var center_end_x := used_rect.position.x + roundi(float(used_rect.size.x) * 0.90)
	var short_floor_columns := 0
	for x in range(center_start_x, center_end_x):
		var first_visible_y := -1
		var last_visible_y := -1
		for y in range(image.get_height()):
			if image.get_pixel(x, y).a > 32.0 / 255.0:
				if first_visible_y < 0:
					first_visible_y = y
				last_visible_y = y
		if (
			first_visible_y >= 0
			and last_visible_y >= roundi(float(image.get_height()) * 0.70)
			and last_visible_y - first_visible_y <= 28
		):
			short_floor_columns += 1
	return short_floor_columns > 2


func _texture_top_band_has_blue_fragment(texture: Texture2D) -> bool:
	var image := texture.get_image()
	for y in range(mini(90, image.get_height())):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.05 and pixel.b >= pixel.r + 0.03 and pixel.b >= pixel.g:
				return true
	return false


func _black_cat_sleep_lower_edge_is_clean(texture: Texture2D) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(texture.resource_path))
	for y in range(roundi(image.get_height() * 0.63) + 1, image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if (
				pixel.a <= 0.0
				or not (
					pixel.get_luminance() > 80.0 / 255.0
					or (
						pixel.r >= pixel.b - 1.0 / 255.0
						and pixel.get_luminance() > 55.0 / 255.0
					)
				)
			):
				continue
			var touches_transparency := false
			for neighbor_y in range(maxi(0, y - 2), mini(image.get_height(), y + 3)):
				for neighbor_x in range(maxi(0, x - 2), mini(image.get_width(), x + 3)):
					if image.get_pixel(neighbor_x, neighbor_y).a <= 0.0:
						touches_transparency = true
						break
				if touches_transparency:
					break
			if touches_transparency:
				return false
	return true


func _station_art_is_standardized(
	station_art: Control,
	expected_texture: Texture2D,
	expected_position: Vector2,
	expected_size: Vector2
) -> bool:
	if (
		station_art == null
		or station_art.position != expected_position
		or station_art.size != expected_size
	):
		return false
	var artwork := station_art.get_node_or_null("Artwork") as TextureRect
	if artwork == null or not artwork.texture is AtlasTexture:
		return false
	var cropped_texture := artwork.texture as AtlasTexture
	return (
		cropped_texture.atlas == expected_texture
		and is_equal_approx(
			artwork.position.y + artwork.size.y,
			expected_size.y
		)
	)


func run_tests() -> void:
	check(
		GameFontStylesScript.REGULAR_FONT.resource_path.ends_with("yufan_original_handwriting.ttf"),
		"The game should use the vector TTF instead of the legacy bitmap font atlas"
	)
	for required_character in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?.,:'+ -/%←()":
		if required_character != " ":
			check(
				GameFontStylesScript.REGULAR_FONT.has_char(required_character.unicode_at(0)),
				"The vector handwriting font should contain %s" % required_character
			)
	var music_manager = root.get_node_or_null("MusicManager")
	if music_manager == null:
		var music_manager_scene: PackedScene = load("res://src/music_manager.tscn")
		music_manager = music_manager_scene.instantiate()
		root.add_child(music_manager)
		await process_frame
	var packed: PackedScene = load("res://main.tscn")
	var game = packed.instantiate()
	var desktop: DesktopCompanionController = game.desktop_controller
	root.add_child(game)
	await process_frame
	check(game.current_screen == "home", "Normal startup should bypass title and creator screens")
	check(
		game.get_progress_stats().unlocked_fish_ids.is_empty()
		and game.get_progress_stats().aquarium_fish_ids.is_empty(),
		"A new player should begin with every fish undiscovered and an empty aquarium"
	)
	var music_bus_index := AudioServer.get_bus_index(&"Music")
	check(music_bus_index >= 0, "The project should provide a dedicated Music audio bus")
	var sfx_bus_index := AudioServer.get_bus_index(&"SFX")
	check(sfx_bus_index >= 0, "The project should provide a dedicated SFX audio bus")
	check(
		music_manager.music_player.bus == &"Music",
		"Background music should play through the dedicated Music bus"
	)
	check(
		music_manager.home_music != null
		and music_manager.home_music.loop_mode == AudioStreamWAV.LOOP_FORWARD
		and music_manager.home_music.loop_begin == 0
		and music_manager.home_music.loop_end > 0,
		"The approved HOME WAV should use a forward resource loop across the prepared seamless track"
	)
	check(
		music_manager.fishing_music != null
		and music_manager.fishing_music.loop_mode == AudioStreamWAV.LOOP_FORWARD
		and music_manager.fishing_music.loop_begin == 0
		and music_manager.fishing_music.loop_end > 0,
		"Cats Fishing Day should use a forward resource loop across the prepared seamless track"
	)
	check(
		music_manager.aquarium_music != null
		and music_manager.aquarium_music.loop_mode == AudioStreamWAV.LOOP_FORWARD
		and music_manager.aquarium_music.loop_begin == 0
		and music_manager.aquarium_music.loop_end > 0,
		"Cats Aquarium should loop directly across the full approved WAV"
	)
	check(
		music_manager.shop_music != null
		and music_manager.shop_music.loop_mode == AudioStreamWAV.LOOP_FORWARD
		and music_manager.shop_music.loop_begin == 0
		and music_manager.shop_music.loop_end > 0,
		"Cozy Cat Boutique should loop directly across the full approved WAV"
	)
	check(
		music_manager.is_home_music_active(),
		"HOME music should begin when the game opens directly on HOME"
	)
	game.save_enabled = false
	game.save_data = {
		"version": 7,
		"pet_pool": [],
		"active_pet_id": "",
		"owned_cat_ids": ["maple"],
		"progress_stats": {"experience": 0},
		"last_updated_unix": int(Time.get_unix_time_from_system())
	}
	game.save_data.erase(game.PROGRESS_SAVE_KEY)
	game.save_data[game.LEGACY_PROGRESS_SAVE_KEY] = {
		"experience": 137,
		"fishing_level": 19,
		"successful_returns": 6,
		"best_combo": 4
	}
	game.normalize_save_data()
	check(
		int(game.get_progress_stats().experience) == 137
		and int(game.get_progress_stats().fishing_level) == 19
		and not game.save_data.has(game.LEGACY_PROGRESS_SAVE_KEY)
		and not game.get_progress_stats().has("successful_returns")
		and not game.get_progress_stats().has("best_combo"),
		"Legacy shared progress should migrate once without changing active fishing values"
	)
	game.save_data[game.PROGRESS_SAVE_KEY] = game._normalize_progress_stats({
		"experience": 0,
		"fishing_level": 1,
		"unlocked_fish_ids": ["green"],
		"aquarium_fish_ids": ["green"]
	})
	var future_progress: Dictionary = game._normalize_progress_stats({
		"experience": 91,
		"fishing_level": 12,
		"future_fishing_progress": {"perfect_catches": 7}
	})
	check(
		future_progress.get("future_fishing_progress", {}) == {"perfect_catches": 7},
		"Progress normalization should preserve fields added by future fishing features"
	)
	game.preview_session = true
	game.save_enabled = true
	check(not game._can_write_save(), "A screen-preview session must never write over the player's real save")
	game.preview_session = false
	game.save_enabled = false
	var startup_normalization_snapshot: Dictionary = game.save_data.duplicate(true)
	var overflow_pet_pool: Array = []
	for overflow_index in range(game.MAX_PETS):
		overflow_pet_pool.append({
			"id": "older_pet_%d" % overflow_index,
			"name": "Older Pet %d" % overflow_index,
			"type": "Cat"
		})
	overflow_pet_pool.append({"id": "siamese", "name": "Pearl", "type": "Cat"})
	game.save_data = {
		"version": 7,
		"pet_pool": overflow_pet_pool,
		"active_pet_id": "siamese",
		"owned_cat_ids": ["maple", "siamese"],
		"progress_stats": {"experience": 4321, "fishing_level": 77}
	}
	game.normalize_save_data()
	check(
		str(game.get_active_pet().get("id", "")) == "siamese"
		and game.get_pet_pool().size() == game.MAX_PETS
		and int(game.get_progress_stats().experience) == 4321
		and int(game.get_progress_stats().fishing_level) == 77,
		"Startup normalization must retain the last carried cat even when it was beyond the old pool limit"
	)
	game.save_data = {
		"version": 7,
		"pet_pool": [
			{"id": "black_cat", "name": "Black Cat", "type": "Cat"},
			{"id": "maine_coon", "name": "Maine Coon", "type": "Cat"},
			{"id": "golden_munchkin", "name": "Golden Munchkin", "type": "Cat"},
			{"id": "siamese", "name": "Siamese", "type": "Cat"}
		],
		"active_pet_id": "siamese",
		"owned_cat_ids": ["maple", "black_cat", "maine_coon", "golden_munchkin", "siamese"],
		"progress_stats": {"experience": 4321, "fishing_level": 77}
	}
	game.normalize_save_data()
	var migrated_black_cat: Dictionary = game.get_pet_pool().filter(
		func(pet): return str(pet.id) == "black_cat"
	).front()
	var migrated_maine_coon: Dictionary = game.get_pet_pool().filter(
		func(pet): return str(pet.id) == "maine_coon"
	).front()
	var migrated_golden_munchkin: Dictionary = game.get_pet_pool().filter(
		func(pet): return str(pet.id) == "golden_munchkin"
	).front()
	check(
		str(migrated_black_cat.get("name", "")) == "Sable"
		and str(migrated_maine_coon.get("name", "")) == "Cedar"
		and str(migrated_golden_munchkin.get("name", "")) == "Honey"
		and str(game.get_active_pet().get("name", "")) == "Pearl"
		and int(game.get_progress_stats().experience) == 4321
		and int(game.get_progress_stats().fishing_level) == 77,
		"Renamed cat saves should migrate to Sable, Cedar, Honey and Pearl without resetting progress"
	)
	game.save_data = startup_normalization_snapshot

	game.show_home()
	await process_frame
	check(game.current_screen == "home", "A fresh launch should go directly to Home")
	check(game.get_pet_pool().size() == 1, "A fresh save should start with Maple only")
	check(game.get_active_pet().name == "Maple", "The default orange cat should be Maple and active")
	check(not game.get_active_pet().has("personality"), "Pet data should not contain the removed personality feature")
	check(game.get_owned_cat_ids() == ["maple"], "A fresh save should only own Maple")
	check(game.find_children("*", "LineEdit", true, false).is_empty(), "Home should not expose the removed pet creator")

	game.show_pet_pool()
	await process_frame
	check(
		not music_manager.is_home_music_active(),
		"Leaving HOME should begin fading out the HOME-only music"
	)
	check(game.find_children("*", "PetAvatar", true, false).size() == 1, "A fresh pet pool should only show Maple")
	var pool_buttons: Array[Node] = game.content.find_children("*", "Button", true, false)
	check(not pool_buttons.any(func(button): return button.text.contains("CREATE")), "Pet pool should not offer pet creation")

	game.show_home()
	await process_frame
	check(
		music_manager.is_home_music_active(),
		"Returning HOME should resume the HOME music without a scene-local player"
	)
	check(game.current_screen == "home", "Selected pet should enter Home")
	check(not game.get_active_pet().has("energy"), "New pet data should not contain the removed Energy resource")
	check(game.get_home_background_texture(12) == game.HOME_DAY_TEXTURE, "Home should use the daytime background at noon")
	check(game.get_home_background_texture(23) == game.HOME_NIGHT_TEXTURE, "Home should use the nighttime background late at night")
	check(game.HOME_DAY_TEXTURE.resource_path.ends_with("home_day_layout_v3.png") and game.HOME_NIGHT_TEXTURE.resource_path.ends_with("home_night_layout_v3.png"), "Home should use the revised two-frame backgrounds")
	var home_buttons: Array[Node] = game.content.find_children("*", "Button", true, false)
	check(home_buttons.size() == 4, "Home should show four actions after removing the title route")
	check(not home_buttons.any(func(button): return button.text == "RETURN TO TITLE"), "Home should not link to the removed title screen")
	var home_labels: Array[Node] = game.content.find_children("*", "Label", true, false)
	check(home_labels.any(func(label): return label.text == "MAPLE IS HERE!"), "Home should show the pet-name header on one line")
	check(home_labels.any(func(label): return label.text == "WELCOME HOME!!"), "Home should show the welcome sign")
	var welcome_home_label: Label = home_labels.filter(
		func(label): return label.text == "WELCOME HOME!!"
	).front()
	check(
		welcome_home_label.get_theme_color("font_color") == game.HOME_WELCOME_TEXT_COLOR,
		"The Home welcome sign should keep its dedicated warm cream-yellow fill after applying the accent font style"
	)
	check(not home_labels.any(func(label): return label.text == "ENERGY"), "Home should not show the removed Energy label")
	check(game.home_xp_label != null and game.home_xp_label.text == "0", "Home should show the current XP value")
	check(
		game.home_xp_label.get_theme_font("font") == GameFontStylesScript.ACCENT_FONT,
		"Home XP should use the original coral shadow font"
	)
	check(
		home_buttons.filter(func(button): return button.text == "KEEP AS DESKTOP COMPANION").all(func(button): return button.get_theme_font("font") == GameFontStylesScript.BUTTON_FONT)
		and home_buttons.filter(func(button): return button.text != "KEEP AS DESKTOP COMPANION").all(func(button): return button.get_theme_font("font") == GameFontStylesScript.REGULAR_FONT),
		"Home should reserve the readable white shadow font for the colored accent button"
	)
	check(
		home_labels.all(func(label): return label.text == label.text.to_upper()),
		"Every visible Home label should be uppercase"
	)
	var xp_row = game.content.find_child("HomeXPRow", true, false)
	var actions_layer = game.content.find_child("HomeActionsLayer", true, false)
	check(xp_row != null and actions_layer != null, "Home should place XP and actions in separate layout regions")
	check(home_buttons.all(func(button): return button.global_position.y >= xp_row.global_position.y + xp_row.size.y), "All Home actions should move below the XP row")
	check(home_buttons.all(func(button): return button.get_theme_stylebox("normal") is StyleBoxFlat), "Home actions should draw real buttons over the blank main background panel")
	var adopt_buttons := home_buttons.filter(func(button): return button.text == "ADOPT ANOTHER CAT")
	check(adopt_buttons.size() == 1, "Home should replace Choose another pet with Adopt another cat")
	var aquarium_buttons := home_buttons.filter(func(button): return button.text == "MY AQUARIUM")
	check(aquarium_buttons.size() == 1, "Home should expose exactly one My Aquarium action")
	aquarium_buttons[0].emit_signal("pressed")
	await process_frame
	check(
		music_manager.is_aquarium_music_active()
		and music_manager.music_player.stream == music_manager.aquarium_music,
		"Opening Aquarium should switch the Music bus player to Cats Aquarium"
	)
	check(game.current_screen == "aquarium_loading", "The first aquarium visit should show its loading layer")
	check(game.aquarium_loading_screen != null, "The aquarium loading layer should remain visible while animation data is prepared")
	check(game.aquarium_loading_screen.message_label.text == "PREPARING THE AQUARIUM...", "The aquarium loading layer should show the approved message")
	check(game.aquarium_loading_screen.background.color == game.aquarium_loading_screen.BACKGROUND_COLOR, "The aquarium loading layer should use the approved deep gray")
	check(game.aquarium_loading_screen.hourglass.size == Vector2(128, 128), "The aquarium loading hourglass should remain compact")
	var loading_hourglass_rotation: float = game.aquarium_loading_screen.hourglass.rotation
	await process_frame
	check(not is_equal_approx(game.aquarium_loading_screen.hourglass.rotation, loading_hourglass_rotation), "The aquarium loading hourglass should keep rotating while fish data is prepared")
	check(await wait_for_screen(game, "aquarium"), "My Aquarium should open after its animation data is ready")
	check(game.aquarium_screen != null and game.aquarium_loading_screen == null, "The loading layer should be removed when the aquarium is ready")
	var aquarium = game.aquarium_screen
	var aquarium_instance_id: int = aquarium.get_instance_id()
	check(aquarium.get_script().resource_path == "res://src/aquarium_screen.gd", "The aquarium should live in its own readable component")
	check(aquarium.BACKGROUND_TEXTURE.resource_path.ends_with("aquarium_background_clean_v1.png"), "The aquarium should use a clean fish-free background layer")
	check(aquarium.extra_fish_actors.size() == 1, "An existing aquarium selection should retain Green Fish")
	var expected_aquarium_fish_ids := ["green"]
	check(
		aquarium.extra_fish_actors.map(func(actor): return actor.fish_id) == expected_aquarium_fish_ids,
		"The aquarium should render the fish IDs selected in the Fish Book"
	)
	var green_aquarium_fish = aquarium.extra_fish_actors[0]
	check(
		green_aquarium_fish.scale.is_equal_approx(Vector2(0.24, 0.24)),
		"Green Fish should be normalized to the same visible size as the other aquarium fish"
	)
	check(
		aquarium._fish_asset_paths("green")[0].ends_with("green_fish_swim_left_8f_v2.png")
		and aquarium._fish_asset_paths("green")[1].ends_with("green_fish_swim_right_8f_v4.png"),
		"Green Fish should use the repaired swim sheets with complete mouths and tails"
	)
	check(
		aquarium._fish_asset_paths("pink_salmon").all(func(path): return path.contains("_v5.png"))
		and aquarium._fish_asset_paths("mint_catfish").all(func(path): return path.contains("_v2.png")),
		"Pink Salmon and Mint Catfish should use aquarium animations rebuilt from their new long-body art"
	)
	for rebuilt_fish_id in ["pink_salmon", "mint_catfish"]:
		var rebuilt_paths: Array[String] = aquarium._fish_asset_paths(rebuilt_fish_id)
		var rebuilt_swim = green_aquarium_fish._make_animation_frames(load(rebuilt_paths[0]))
		var rebuilt_idle = green_aquarium_fish._make_idle_animation_frames(
			load(rebuilt_paths[2]),
			false
		)
		var rebuilt_first_bounds: Rect2i = rebuilt_swim.frames[0].get_image().get_used_rect()
		check(
			rebuilt_swim.frames.size() == 8
			and rebuilt_idle.frames.size() == 8
			and float(rebuilt_first_bounds.size.x) / rebuilt_first_bounds.size.y > 2.2
			and maximum_alpha_difference_in_right_region(rebuilt_swim.frames, 230) > 1000
			and maximum_alpha_difference_in_right_region(rebuilt_idle.frames, 230) > 1000,
			"%s should keep its new long silhouette through distinct swim and idle-tail frames" % rebuilt_fish_id
		)
	var all_catalog_fish_ids: Array[String] = []
	for catalog_fish in FishCatalogScript.FISH_TYPES:
		var catalog_fish_id := str(catalog_fish.id)
		all_catalog_fish_ids.append(catalog_fish_id)
		var catalog_animation_paths: Array[String] = aquarium._fish_asset_paths(catalog_fish_id)
		check(
			catalog_animation_paths.size() == 4
			and catalog_animation_paths.all(func(path): return ResourceLoader.exists(path)),
			"Every catalog fish should have four aquarium animation sheets"
		)
	check(
		FishCatalogScript.normalize_aquarium_fish_ids(
			all_catalog_fish_ids,
			all_catalog_fish_ids
		).size() == FishCatalogScript.AQUARIUM_CAPACITY,
		"Aquarium save data should enforce the ten-fish capacity"
	)
	for aquarium_fish in aquarium.extra_fish_actors:
		var expected_asset_paths: Array[String] = aquarium._fish_asset_paths(aquarium_fish.fish_id)
		check(
			aquarium_fish.swim_left_frames[0].atlas.resource_path == expected_asset_paths[0]
			and aquarium_fish.swim_right_frames[0].atlas.resource_path == expected_asset_paths[1]
			and aquarium_fish.idle_left_frames[0].atlas.resource_path == expected_asset_paths[2]
			and aquarium_fish.idle_right_frames[0].atlas.resource_path == expected_asset_paths[3],
			"Every aquarium fish should use its approved animation sheets"
		)
		check(
			aquarium_fish.swim_left_frames.size() == 8
			and aquarium_fish.swim_right_frames.size() == 8
			and aquarium_fish.idle_left_frames.size() == 8
			and aquarium_fish.idle_right_frames.size() == 8,
			"Every aquarium fish should have four complete eight-frame animations"
		)
		check(
			aquarium_fish.swim_left_frames.all(func(frame): return frame.filter_clip)
			and aquarium_fish.swim_right_frames.all(func(frame): return frame.filter_clip),
			"Aquarium animation frames should not sample stray pixels from neighboring cells"
		)
		check(aquarium.SWIM_BOUNDS.has_point(aquarium_fish.position), "Every selected fish should start inside the aquarium water")
		var rest_position: Vector2 = aquarium_fish.position
		aquarium_fish._start_resting(2.0)
		aquarium_fish._process(1.0 / aquarium_fish.IDLE_ANIMATION_FPS + 0.01)
		check(
			aquarium_fish.position.is_equal_approx(rest_position)
			and aquarium_fish.idle_frame == 1,
			"Every aquarium fish should hold position while its idle tail advances"
		)
		check(
			maximum_alpha_difference_in_right_region(
				aquarium_fish.swim_left_frames,
				230
			) > 1000,
			"%s should visibly animate while swimming" % aquarium_fish.fish_id
		)
		check(
			maximum_alpha_difference_in_right_region(
				aquarium_fish.idle_left_frames,
				230
			) > 1000,
			"%s should visibly animate its tail while resting" % aquarium_fish.fish_id
		)
	check(aquarium.fish_count_label.text == "FISH CAP 1 / 10", "A saved aquarium should show its actual occupied capacity instead of collection progress")
	aquarium.fish_book_button.emit_signal("pressed")
	await process_frame
	check(
		music_manager.is_shop_music_active()
		and music_manager.music_player.stream == music_manager.shop_music,
		"Opening the Fish Store should switch the Music bus player to Cozy Cat Boutique"
	)
	check(game.current_screen == "fish_book" and game.fish_book_screen != null, "The aquarium Fish Book button should open a dedicated fish encyclopedia screen")
	check(game.cached_aquarium_screen.get_instance_id() == aquarium_instance_id and game.cached_aquarium_screen.get_parent() == null, "Opening the Fish Book should cache the aquarium without destroying it")
	var fish_book = game.fish_book_screen
	check(fish_book.get_script().resource_path == "res://src/fish_book_screen.gd", "The fish encyclopedia should have its own screen component")
	check(fish_book.active_catalog_tab == "fish" and fish_book.fish_grid_layer.visible, "The dedicated Fish Book should open directly on the fish encyclopedia")
	check(fish_book.store_title_label.text == "FISHIPEDIA", "The dedicated Fish Book should show the renamed Fishipedia title")
	check(fish_book.cat_grid_layer == null and fish_book.cat_detail_panel == null, "The Fish Book should not construct the cat-adoption catalog")
	check(fish_book.find_child("CatsCatalogTab", true, false) == null and fish_book.find_child("FishCatalogTab", true, false) == null, "The dedicated Fish Book should not expose catalog-switching bookmarks")
	check(fish_book.store_home_button.text == "← AQUARIUM", "The Fish Book back button should point to the aquarium")
	check(fish_book.fish_slot_buttons.size() == 9 and fish_book.fish_page_label.text == "PAGE 1 / 6", "The fish encyclopedia should show nine fish per page across six pages")
	check(
		fish_book.fish_next_button.text == ""
		and fish_book.fish_next_arrow_label.text == "←"
		and fish_book.fish_next_arrow_label.scale.x < 0.0
		and fish_book.fish_next_arrow_label.get_theme_font("font") == GameFontStylesScript.REGULAR_FONT,
		"The Fish Book right arrow should mirror the user's handwritten left-arrow glyph"
	)
	check(fish_book.fish_slot_views.size() == 9 and fish_book.fish_slot_views.all(func(view): return view.texture.get_size().x * view.scale.x <= fish_book.FISH_SLOT_ICON_MAX_SIZE.x + 0.01 and view.texture.get_size().y * view.scale.y <= fish_book.FISH_SLOT_ICON_MAX_SIZE.y + 0.01), "Every fish icon should be scaled completely inside its encyclopedia square")
	check(
		fish_book.find_children("FishSlotName", "Label", true, false).is_empty()
		and fish_book.fish_slot_views.all(func(view): return view.position == fish_book.FISH_SLOT_ICON_CENTER),
		"Fish encyclopedia grid slots should show centered fish art without species-name labels"
	)
	check(fish_book.fish_slot_lock_views.filter(func(lock): return lock.visible).size() == 8, "A save containing only Green Fish should keep the other first-page species locked")
	check(fish_book.selected_fish_id == "green" and fish_book.fish_detail_rarity_label.text == "RARITY LEVEL 0", "The fish detail page should begin with the discovered green fish and its rarity")
	check(fish_book.fish_detail_view.texture.get_size().x * fish_book.fish_detail_view.scale.x <= fish_book.FISH_DETAIL_ICON_MAX_SIZE.x + 0.01 and fish_book.fish_detail_view.texture.get_size().y * fish_book.fish_detail_view.scale.y <= fish_book.FISH_DETAIL_ICON_MAX_SIZE.y + 0.01, "The selected fish should remain inside the right-page detail image area")
	check(fish_book.fish_detail_description_label.text == FishCatalogScript.definition("green").description, "The fish detail page should show the selected species' humorous description")
	check(not fish_book.fish_detail_description_label.text.contains("XP:") and not fish_book.fish_detail_description_label.text.contains("XP "), "The fish encyclopedia should not advertise removed per-fish XP values")
	check(
		fish_book.fish_aquarium_button.text == "REMOVE FROM AQUARIUM"
		and fish_book.fish_aquarium_button.position == fish_book.FISH_AQUARIUM_BUTTON_POSITION
		and fish_book.fish_detail_description_label.position == fish_book.FISH_DESCRIPTION_POSITION
		and fish_book.fish_detail_rarity_label.position == fish_book.FISH_RARITY_POSITION,
		"The fish detail card should follow the approved name, fish, aquarium button, description, and rarity layout"
	)
	check(
		not fish_book.fish_detail_lock_view.visible
		and not fish_book.fish_detail_locked_veil.visible
		and not fish_book.fish_detail_locked_message_label.visible,
		"Discovered fish should not show the locked detail treatment"
	)
	fish_book.fish_slot_buttons[1].emit_signal("pressed")
	check(
		fish_book.selected_fish_id == "coral"
		and fish_book.fish_detail_view.modulate == fish_book.FISH_LOCKED_DETAIL_ICON_MODULATE
		and fish_book.fish_detail_locked_veil.visible
		and fish_book.fish_detail_lock_view.visible
		and fish_book.fish_detail_locked_message_label.visible
		and fish_book.fish_detail_locked_message_label.text == "FISH MORE TO UNLOCK",
		"Selecting an undiscovered fish should show its faded silhouette, current lock, and unlock hint"
	)
	check(
		not fish_book.fish_detail_name_label.visible
		and not fish_book.fish_detail_rarity_label.visible
		and not fish_book.fish_detail_description_label.visible
		and not fish_book.fish_aquarium_button.visible
		and fish_book.fish_detail_lock_view.get_index() > fish_book.fish_detail_view.get_index(),
		"Locked fish details should hide identifying and aquarium controls while keeping the lock above the fish"
	)
	check(
		fish_book.fish_slot_selection_frames[1].visible,
		"An undiscovered fish slot should remain selectable so its locked detail state can be inspected"
	)
	fish_book.select_fish("green")
	check(
		fish_book.fish_detail_name_label.visible
		and fish_book.fish_detail_rarity_label.visible
		and fish_book.fish_detail_description_label.visible
		and fish_book.fish_aquarium_button.visible
		and fish_book.fish_detail_view.modulate == Color.WHITE
		and not fish_book.fish_detail_lock_view.visible
		and not fish_book.fish_detail_locked_message_label.visible,
		"Returning to a discovered fish should fully restore its normal detail layout"
	)
	fish_book.fish_aquarium_button.emit_signal("pressed")
	check(
		fish_book.aquarium_fish_ids.is_empty()
		and game.get_progress_stats().aquarium_fish_ids.is_empty()
		and fish_book.fish_aquarium_button.text == "ADD TO AQUARIUM",
		"Removing a fish should update the button and persisted aquarium list"
	)
	check(not is_instance_valid(game.cached_aquarium_screen), "Changing aquarium fish should invalidate the old cached aquarium")
	fish_book.fish_aquarium_button.emit_signal("pressed")
	check(
		fish_book.aquarium_fish_ids == ["green"]
		and game.get_progress_stats().aquarium_fish_ids == ["green"]
		and fish_book.fish_aquarium_button.text == "REMOVE FROM AQUARIUM",
		"Adding a discovered fish should persist it and change the button to Remove"
	)
	var capacity_test_ids: Array[String] = []
	for fish_index in range(FishCatalogScript.AQUARIUM_CAPACITY + 1):
		capacity_test_ids.append(str(FishCatalogScript.FISH_TYPES[fish_index].id))
	fish_book.unlocked_fish_ids.clear()
	for fish_id in capacity_test_ids:
		fish_book.unlocked_fish_ids.append(fish_id)
	fish_book.aquarium_fish_ids.clear()
	for fish_index in range(FishCatalogScript.AQUARIUM_CAPACITY):
		fish_book.aquarium_fish_ids.append(capacity_test_ids[fish_index])
	fish_book.select_fish(capacity_test_ids[FishCatalogScript.AQUARIUM_CAPACITY])
	fish_book.fish_aquarium_button.emit_signal("pressed")
	check(
		fish_book.aquarium_fish_ids.size() == FishCatalogScript.AQUARIUM_CAPACITY
		and fish_book.fish_aquarium_capacity_label.visible
		and fish_book.fish_aquarium_capacity_label.text == "REACH AQUARIUM CAPACITY",
		"Adding beyond ten fish should show the capacity message without changing the aquarium"
	)
	await create_timer(
		fish_book.FISH_CAPACITY_MESSAGE_HOLD_SECONDS
		+ fish_book.FISH_CAPACITY_MESSAGE_FADE_SECONDS
		+ 0.1
	).timeout
	check(not fish_book.fish_aquarium_capacity_label.visible, "The aquarium capacity message should quickly disappear")
	fish_book.unlocked_fish_ids.clear()
	fish_book.unlocked_fish_ids.append("green")
	fish_book.aquarium_fish_ids.clear()
	fish_book.aquarium_fish_ids.append("green")
	fish_book.select_fish("green")
	fish_book.fish_next_button.emit_signal("pressed")
	check(fish_book.fish_page_index == 1 and fish_book.fish_slot_lock_views.filter(func(lock): return lock.visible).size() == 9, "Undiscovered species on later encyclopedia pages should remain locked")
	fish_book.store_home_button.emit_signal("pressed")
	await process_frame
	check(game.current_screen == "aquarium_loading", "Changing the selected fish should rebuild the aquarium behind its loading screen")
	check(await wait_for_screen(game, "aquarium"), "The Fish Book back button should return to the rebuilt aquarium")
	check(game.aquarium_screen != null and game.aquarium_screen.get_instance_id() != aquarium_instance_id, "A changed aquarium should replace the stale cached instance")
	var rebuilt_aquarium_instance_id: int = game.aquarium_screen.get_instance_id()
	game.aquarium_screen.home_button.emit_signal("pressed")
	await process_frame
	check(
		not music_manager.is_aquarium_music_active(),
		"Leaving Aquarium should begin fading out Cats Aquarium"
	)
	check(game.current_screen == "home", "The aquarium Home button should return Home")
	home_buttons = game.content.find_children("*", "Button", true, false)
	aquarium_buttons = home_buttons.filter(func(button): return button.text == "MY AQUARIUM")
	aquarium_buttons[0].emit_signal("pressed")
	await process_frame
	check(game.current_screen == "aquarium" and game.aquarium_screen.get_instance_id() == rebuilt_aquarium_instance_id, "Reopening My Aquarium from Home should reuse the rebuilt cached aquarium")
	game.aquarium_screen.home_button.emit_signal("pressed")
	await process_frame
	check(game.current_screen == "home", "The cached aquarium should still return Home")
	home_buttons = game.content.find_children("*", "Button", true, false)
	var adoption_stats: Dictionary = game.get_progress_stats()
	adoption_stats["experience"] = 1000
	game.save_data["progress_stats"] = adoption_stats
	adopt_buttons = home_buttons.filter(func(button): return button.text == "ADOPT ANOTHER CAT")
	adopt_buttons[0].emit_signal("pressed")
	await process_frame
	check(
		music_manager.is_shop_music_active()
		and music_manager.music_player.stream == music_manager.shop_music,
		"Opening Adopt Another Cat should reuse Cozy Cat Boutique"
	)
	check(game.current_screen == "store" and game.store_screen != null, "The Home adoption button should open the new Store screen")
	var store = game.store_screen
	check(store.CAT_CATALOG.size() == 9 and store.slot_buttons.size() == 9, "The Store should show nine selectable cat slots")
	var sable_catalog_entries: Array = store.CAT_CATALOG.filter(
		func(cat): return str(cat.id) == "black_cat"
	)
	check(
		sable_catalog_entries.size() == 1
		and str(sable_catalog_entries[0].name) == "Sable"
		and PetCatalogScript.definition_by_catalog_id("black_cat").display_name == "Sable",
		"The black cat should display as Sable in both the Store and carried-pet profile"
	)
	var cedar_catalog_entries: Array = store.CAT_CATALOG.filter(
		func(cat): return str(cat.id) == "maine_coon"
	)
	check(
		cedar_catalog_entries.size() == 1
		and str(cedar_catalog_entries[0].name) == "Cedar"
		and PetCatalogScript.definition_by_catalog_id("maine_coon").display_name == "Cedar",
		"The Maine Coon should display as Cedar in both the Store and carried-pet profile"
	)
	var honey_catalog_entries: Array = store.CAT_CATALOG.filter(
		func(cat): return str(cat.id) == "golden_munchkin"
	)
	check(
		honey_catalog_entries.size() == 1
		and str(honey_catalog_entries[0].name) == "Honey"
		and PetCatalogScript.definition_by_catalog_id("golden_munchkin").display_name == "Honey",
		"The Golden Munchkin should display as Honey in both the Store and carried-pet profile"
	)
	var pearl_catalog_entries: Array = store.CAT_CATALOG.filter(
		func(cat): return str(cat.id) == "siamese"
	)
	check(
		pearl_catalog_entries.size() == 1
		and str(pearl_catalog_entries[0].name) == "Pearl"
		and PetCatalogScript.definition_by_catalog_id("siamese").display_name == "Pearl",
		"The Siamese cat should display as Pearl in both the Store and carried-pet profile"
	)
	var total_cat_unlock_xp := 0
	var previous_cat_price := -1
	for cat in store.CAT_CATALOG:
		var cat_price := int(cat.price)
		total_cat_unlock_xp += cat_price
		check(cat_price >= previous_cat_price, "Cat unlock prices should increase through the catalog")
		previous_cat_price = cat_price
	var campaign_xp_total := 0
	for level_config in FishingLevelCatalogScript.all_levels():
		campaign_xp_total += int(level_config.xp_reward)
	check(total_cat_unlock_xp == 57000 and total_cat_unlock_xp <= campaign_xp_total, "All nine cats should cost 57,000 XP so the first 450 fishing levels can unlock the full catalog")
	check(store.BACKGROUND_TEXTURE.resource_path.ends_with("adopt_cat_store_background_v3.png"), "The Store should use the approved upright-book background")
	check(store.store_title_label.text == "CAT SHELTER", "The cat encyclopedia should show the renamed Cat Shelter title")
	check(
		store.is_cat_owned("maple")
		and store.CAT_CATALOG.slice(1).all(func(cat): return not store.is_cat_owned(str(cat.id))),
		"Every cat except Maple should begin locked"
	)
	check(store.slot_lock_views.filter(func(lock): return lock.visible).size() == 8, "All eight unowned cats should remain visibly locked")
	check(store.selected_cat_id == "maple" and not store.detail_locked, "The Store should initially show Maple's owned full-body detail")
	check(store.detail_unlock_label.text == "CARRY MAPLE", "Owned cats should use the named Carry action")
	check(store.detail_description_label.visible and store.detail_description_label.text.begins_with("MAPLE IS"), "Owned Maple should show an editable description label")
	store.slot_buttons[3].emit_signal("pressed")
	var luna_slot_head: Sprite2D = store.cat_grid_layer.get_node("CatSlot3/CatHead")
	check(
		store.selected_cat_id == "luna"
		and store.detail_locked
		and luna_slot_head.texture == pet_texture("luna", "store_portrait")
		and store.detail_cat_view.texture == pet_texture("luna", "store_detail")
		and store.detail_unlock_label.text == "UNLOCK WITH 3,000 XP",
		"Locked Luna should show her Russian Blue artwork and unlock price"
	)
	store.slot_buttons[4].emit_signal("pressed")
	var poppy_slot_head: Sprite2D = store.cat_grid_layer.get_node("CatSlot4/CatHead")
	check(
		store.selected_cat_id == "poppy"
		and store.detail_locked
		and poppy_slot_head.texture == pet_texture("poppy", "store_portrait")
		and store.detail_cat_view.texture == pet_texture("poppy", "store_detail")
		and store.detail_unlock_label.text == "UNLOCK WITH 5,000 XP",
		"Locked Poppy should show her own artwork and unlock price"
	)
	store.slot_buttons[0].emit_signal("pressed")
	check(store.active_catalog_tab == "cats" and store.cat_grid_layer.visible, "The adoption screen should remain on the cat encyclopedia")
	check(store.find_child("CatsCatalogTab", true, false) == null and store.find_child("FishCatalogTab", true, false) == null, "Adopt Another Cat should no longer expose the Fish Book entry")
	check(store.fish_grid_layer == null and store.fish_detail_panel == null, "The adoption screen should not construct fish encyclopedia content")
	store.slot_buttons[1].emit_signal("pressed")
	check(store.selected_cat_id == "mochi" and store.detail_locked, "Selecting an unowned placeholder should switch to the locked detail state")
	var mochi_slot_head: Sprite2D = store.cat_grid_layer.get_node("CatSlot1/CatHead")
	check(
		mochi_slot_head.texture == pet_texture("mochi", "store_portrait")
		and store.detail_cat_view.texture == pet_texture("mochi", "store_detail"),
		"Mochi should use her head portrait in the slot and her approved front-sitting art in the detail card"
	)
	check(
		store.detail_description_label.position == store.CAT_DESCRIPTION_POSITION
		and store.detail_unlock_button.position == store.CAT_ACTION_BUTTON_POSITION
		and store.detail_unlock_button.size == store.CAT_ACTION_BUTTON_SIZE
		and store.detail_description_label.position.y + store.detail_description_label.size.y
			<= store.detail_unlock_button.position.y,
		"The cat description and smaller action button should no longer overlap: description=%s/%s button=%s/%s" % [
			store.detail_description_label.position,
			store.detail_description_label.size,
			store.detail_unlock_button.position,
			store.detail_unlock_button.size
		]
	)
	check(
		not store.detail_veil.visible
		and store.detail_cat_view.modulate == store.CAT_LOCKED_DETAIL_MODULATE
		and store.detail_lock_view.visible
		and store.detail_unlock_button.visible,
		"The locked detail should gray the cat silhouette without drawing a rectangular veil"
	)
	var mochi_slot_veil: ColorRect = store.cat_grid_layer.get_node("CatSlot1/LockedVeil")
	check(
		mochi_slot_head.modulate == store.CAT_LOCKED_SLOT_MODULATE
		and mochi_slot_veil.color == store.CAT_LOCKED_SLOT_VEIL_COLOR,
		"Locked cat slots should use the stronger thumbnail treatment"
	)
	check(not store.detail_description_label.visible, "Locked cats should hide the owned description")
	check(store.detail_unlock_label.text == "UNLOCK WITH 500 XP", "Unlock price text should remain a separate editable Godot label")
	store.detail_unlock_button.emit_signal("pressed")
	check(store.purchase_popup_stage == "confirmation" and store.purchase_popup != null, "Unlock should open the purchase confirmation popup")
	check(store.purchase_confirmation_label.text.contains("MOCHI") and store.purchase_confirmation_label.text.contains("500 XP"), "The confirmation popup should use the selected cat name and XP price placeholders")
	check(store.purchase_confirmation_label.text.count("\n") == 1 and store.purchase_confirmation_label.autowrap_mode == TextServer.AUTOWRAP_OFF, "The compact confirmation message should stay on exactly two lines")
	check(store.purchase_yes_button.text == "YES" and store.purchase_cancel_button.text == "CANCEL", "The confirmation popup should offer Yes and Cancel")
	var confirmation_card = store.purchase_popup.find_child("PurchaseConfirmationCard", true, false)
	check(confirmation_card is Control and confirmation_card.size == Vector2(620, 310), "Confirmation should keep the compact first-version dimensions")
	var confirmation_background = store.purchase_popup.find_child("ConfirmationBackground", true, false)
	check(confirmation_background is TextureRect and confirmation_background.texture == store.PURCHASE_CONFIRMATION_TEXTURE, "Confirmation should use the clean cream-and-gold outer frame without the bottom inset panel")
	check(confirmation_background.position == Vector2(-35, -22) and confirmation_background.size == Vector2(691, 357), "The visible ornate frame should fill the original 620 by 310 confirmation dimensions")
	check(confirmation_background.texture != store.CELEBRATION_POPUP_TEXTURE, "Confirmation should not contain the congratulations confetti artwork")
	check(store.detail_unlock_button.get_theme_stylebox("normal").bg_color == store.purchase_yes_button.get_theme_stylebox("normal").bg_color, "The Store unlock button should use the same green style as the confirmation Yes button")
	store.purchase_cancel_button.emit_signal("pressed")
	check(store.purchase_popup == null and store.purchase_popup_stage == "", "Cancel should dismiss the purchase confirmation")
	store.detail_unlock_button.emit_signal("pressed")
	store.purchase_yes_button.emit_signal("pressed")
	check(store.purchase_popup_stage == "congratulations" and store.purchase_popup != null, "Yes should replace the confirmation with the congratulations popup")
	var celebration_background = store.purchase_popup.find_child("CelebrationBackground", true, false)
	check(celebration_background is TextureRect and celebration_background.texture == store.CELEBRATION_POPUP_TEXTURE, "The congratulations popup should reuse Fishing's confetti celebration artwork")
	check(store.congratulations_cat_view.texture == pet_texture("mochi", "store_detail") and store.congratulations_name_label.text == "MOCHI!", "The congratulations popup should show Mochi's full-body art and name")
	var congratulations_labels: Array[Node] = store.purchase_popup.find_children("*", "Label", true, false)
	check(congratulations_labels.any(func(label): return label.text == "CONGRATULATIONS!") and congratulations_labels.any(func(label): return label.text == "YOU NOW OWN"), "The congratulations popup should show only the requested ownership heading")
	check(store.is_cat_owned("mochi") and store.experience == 500, "Confirming a purchase should deduct Mochi's 500 XP and unlock the cat")
	check(store.detail_unlock_label.text == "CARRY MOCHI", "Purchasing Mochi should expose the named Carry action")
	check(game.get_progress_stats().experience == 500 and game.get_owned_cat_ids().has("mochi"), "A purchased cat and the remaining XP should persist in the main save data")
	check(
		game.get_pet_index("mochi") >= 0
		and str(game.get_active_pet().get("id", "")) == "mochi",
		"Purchasing Mochi should add her to the pet pool and make her available immediately"
	)
	check(not store.slot_lock_views[1].visible and not store.detail_locked, "Purchasing a cat should immediately remove its catalog lock")
	store._close_purchase_popup()
	await process_frame
	store.slot_buttons[2].emit_signal("pressed")
	var biscuit_slot_head: Sprite2D = store.cat_grid_layer.get_node("CatSlot2/CatHead")
	check(
		biscuit_slot_head.texture == pet_texture("biscuit", "store_portrait")
		and store.detail_cat_view.texture == pet_texture("biscuit", "store_detail"),
		"Biscuit should use her calico head portrait in the slot and front-sitting art in the detail card"
	)
	check(store.detail_unlock_button.disabled and store.detail_unlock_label.text == "UNLOCK WITH 1,500 XP", "A cat that costs more than the player's remaining XP should stay visibly priced but disabled")
	var biscuit_purchase_stats: Dictionary = game.get_progress_stats()
	biscuit_purchase_stats["experience"] = 2000
	game.save_data["progress_stats"] = biscuit_purchase_stats
	store.experience = 2000
	store.select_cat("biscuit")
	store.detail_unlock_button.emit_signal("pressed")
	check(
		store.purchase_popup_stage == "confirmation"
		and store.purchase_confirmation_label.text.contains("BISCUIT")
		and store.purchase_confirmation_label.text.contains("1,500 XP"),
		"Unlocking Biscuit should use her name and price in the confirmation popup"
	)
	store.purchase_yes_button.emit_signal("pressed")
	check(
		store.is_cat_owned("biscuit")
		and store.experience == 500
		and store.congratulations_cat_view.texture == pet_texture("biscuit", "store_detail")
		and store.congratulations_name_label.text == "BISCUIT!",
		"Confirming Biscuit should unlock her and show her own full-body celebration art"
	)
	check(
		game.get_owned_cat_ids().has("biscuit")
		and game.get_pet_index("biscuit") >= 0
		and str(game.get_active_pet().get("id", "")) == "biscuit"
		and game.get_progress_stats().experience == 500,
		"Purchasing Biscuit should add her to the pet pool without resetting shared progress"
	)
	store._close_purchase_popup()
	await process_frame
	var store_home_button: Button = store.find_child("StoreHomeButton", true, false)
	check(store_home_button == store.store_home_button and store_home_button.get_index() > store.cat_grid_layer.get_index(), "The Store Home button should remain on top of the full-screen cat catalog layer")
	check(store.cat_grid_layer.mouse_filter == Control.MOUSE_FILTER_IGNORE, "The empty full-screen cat catalog layer should not intercept the Store Home button's mouse clicks")
	store_home_button.emit_signal("pressed")
	await process_frame
	check(game.current_screen == "home", "The Store Home button should return to Home")
	check(game.avatar.mood == "idle", "The Home cat should begin awake and standing after entering the page")
	check(game.avatar.cat_sprite.texture == game.avatar.BISCUIT_IDLE_TEXTURE, "Purchased Biscuit should arrive Home in her approved side-sitting pose")
	check(game.avatar.home_idle_enabled, "Home should enable the active pet's occasional idle animation")
	game.avatar.set_desktop_idle_enabled(true)
	game.avatar.desktop_idle_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.desktop_idle_animation == "biscuit_butterfly"
		and game.avatar.cat_sprite.texture == game.avatar.BISCUIT_BUTTERFLY_FRAMES[0]
		and game.avatar.BISCUIT_BUTTERFLY_FRAMES.size() == 16,
		"An active Desktop Biscuit should occasionally follow and reach for the pink butterfly"
	)
	game.avatar.set_desktop_idle_enabled(false)
	game.avatar.set_mood("sleep")
	check(
		game.avatar.cat_sprite.texture == game.avatar.BISCUIT_SLEEP_TEXTURE
		and not game.avatar.sleep_bubble_sprite.visible,
		"Inactive Biscuit should use her fixed side-sleep pose with the nose bubble initially hidden"
	)
	check(
		game.avatar.sleep_bubble_wait_remaining >= game.avatar.SLEEP_BUBBLE_MIN_WAIT
		and game.avatar.sleep_bubble_wait_remaining <= game.avatar.SLEEP_BUBBLE_MAX_WAIT,
		"Sleeping Biscuit should schedule Maple's nose-bubble animation after a random quiet interval"
	)
	game.avatar.sleep_bubble_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.sleep_bubble_active
		and game.avatar.sleep_bubble_sprite.visible
		and game.avatar.sleep_bubble_sprite.texture == game.avatar.SLEEP_BUBBLE_FRAMES[0],
		"Biscuit should reuse Maple's animated sleeping nose bubble"
	)
	check(
		(
			game.avatar.sleep_bubble_sprite.position
			+ game.avatar.SLEEP_BUBBLE_FRAME_ANCHOR
			+ game.avatar.BISCUIT_SLEEP_TEXTURE.get_size() * 0.5
		).is_equal_approx(game.avatar.BISCUIT_SLEEP_BUBBLE_NOSE_POSITION),
		"Biscuit's bubble point should stay anchored directly to her own nostril"
	)
	game.avatar.set_mood("idle")
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.BISCUIT_MOVE_LEFT_FRAMES
		and game.avatar.BISCUIT_MOVE_LEFT_FRAMES.size() == 12,
		"Biscuit should use her approved playful left-walk animation"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.BISCUIT_MOVE_RIGHT_FRAMES
		and game.avatar.BISCUIT_MOVE_RIGHT_FRAMES.size() == 12,
		"Biscuit should use her approved playful right-walk animation"
	)
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.BISCUIT_BUTTERFLY_FRAMES[0],
		"Double-clicking Biscuit should replay her own butterfly interaction instead of Maple's art"
	)
	var biscuit_interaction_scale: Vector2 = game.avatar.cat_sprite.scale
	game.avatar.interaction_animation_active = false
	game.avatar._apply_current_texture()
	game.avatar._update_layout()
	check(
		game.avatar.cat_sprite.texture == game.avatar.BISCUIT_IDLE_TEXTURE
		and game.avatar.cat_sprite.scale.is_equal_approx(biscuit_interaction_scale),
		"Biscuit's butterfly interaction should stay the same size as her default side-sitting pose"
	)
	var biscuit_station_art: Control = desktop._make_station_top_art(
		"biscuit",
		desktop.get_desktop_station_theme("biscuit")
	)
	check(
		_station_art_is_standardized(
			biscuit_station_art,
			pet_texture("biscuit", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"Biscuit's Desktop Station should use her worn cardboard play-box scene"
	)
	biscuit_station_art.free()
	game.avatar.set_pet({"id": "luna", "name": "Luna", "type": "Cat"})
	game.avatar.set_mood("idle")
	var luna_idle_scale: Vector2 = game.avatar.cat_sprite.scale
	check(
		game.avatar.cat_sprite.texture == game.avatar.LUNA_IDLE_TEXTURE,
		"Luna should use her approved slim side-sitting pose at Home and on Desktop"
	)
	check(
		not _texture_lower_half_has_green_chroma(game.avatar.LUNA_IDLE_TEXTURE),
		"Luna's side-sitting feet and tail should not retain green-screen pixels"
	)
	game.avatar.set_desktop_idle_enabled(true)
	game.avatar.desktop_idle_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.desktop_idle_animation == "luna_stretch_yawn"
		and game.avatar.cat_sprite.texture == game.avatar.LUNA_STRETCH_YAWN_FRAMES[0]
		and game.avatar.LUNA_STRETCH_YAWN_FRAMES.size() == 12,
		"An active Desktop Luna should occasionally play her stretch-and-yawn animation"
	)
	game.avatar.set_desktop_idle_enabled(false)
	game.avatar.set_mood("sleep")
	check(
		game.avatar.cat_sprite.texture == game.avatar.LUNA_SLEEP_TEXTURE
		and not game.avatar.sleep_bubble_sprite.visible,
		"Inactive Luna should use her own sleeping pose without another cat's nose bubble"
	)
	check(
		game.avatar.luna_sleep_idle_wait_remaining >= game.avatar.LUNA_SLEEP_IDLE_MIN_WAIT
		and game.avatar.luna_sleep_idle_wait_remaining <= game.avatar.LUNA_SLEEP_IDLE_MAX_WAIT,
		"Sleeping Luna should schedule her subtle custom sleep animation"
	)
	game.avatar.luna_sleep_idle_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.luna_sleep_idle_playing
		and game.avatar.cat_sprite.texture == game.avatar.LUNA_SLEEP_IDLE_FRAMES[0]
		and game.avatar.LUNA_SLEEP_IDLE_FRAMES.size() == 12,
		"Luna's random sleeping animation should begin on its first fixed-canvas frame"
	)
	game.avatar.set_mood("idle")
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.LUNA_MOVE_LEFT_FRAMES
		and game.avatar.LUNA_MOVE_LEFT_FRAMES.size() == 12,
		"Luna should use her approved slimmer left-walk animation"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.LUNA_MOVE_RIGHT_FRAMES
		and game.avatar.LUNA_MOVE_RIGHT_FRAMES.size() == 12,
		"Luna should use her approved slimmer right-walk animation"
	)
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.LUNA_STRETCH_YAWN_FRAMES[0]
		and game.avatar.cat_sprite.scale.is_equal_approx(luna_idle_scale),
		"Double-clicking Luna should replay her stretch without shrinking from her idle size"
	)
	check(
		game.avatar.LUNA_STRETCH_YAWN_FRAMES.all(
			func(frame): return not _texture_bottom_band_has_green_chroma(frame)
		),
		"Every Luna stretch frame should be free of green-screen residue near her feet"
	)
	var luna_station_art: Control = desktop._make_station_top_art(
		"luna",
		desktop.get_desktop_station_theme("luna")
	)
	check(
		_station_art_is_standardized(
			luna_station_art,
			pet_texture("luna", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"Luna's Desktop Station should use her dark iridescent green velvet cushion"
	)
	luna_station_art.free()
	game.avatar.set_pet({"id": "poppy", "name": "Poppy", "type": "Cat"})
	game.avatar.set_mood("idle")
	check(
		game.avatar.cat_sprite.texture == game.avatar.POPPY_IDLE_TEXTURE,
		"Poppy should use her approved side-sitting pose at Home and on Desktop"
	)
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.POPPY_MOVE_LEFT_FRAMES
		and game.avatar.POPPY_MOVE_LEFT_FRAMES.size() == 12,
		"Poppy should use her fixed-canvas left-walk animation"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.POPPY_MOVE_RIGHT_FRAMES
		and game.avatar.POPPY_MOVE_RIGHT_FRAMES.size() == 12,
		"Poppy should use her fixed-canvas right-walk animation"
	)
	game.avatar.stop_move()
	game.avatar._update_layout()
	var poppy_idle_scale: Vector2 = game.avatar.cat_sprite.scale
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.POPPY_TEASER_PLAY_FRAMES[0]
		and game.avatar.POPPY_TEASER_PLAY_FRAMES.size() == 16
		and game.avatar.POPPY_TEASER_PLAY_FRAME_DURATIONS.size() == 16,
		"Double-clicking Poppy should start her sixteen-frame teaser-wand interaction"
	)
	check(
		game.avatar.cat_sprite.scale.is_equal_approx(poppy_idle_scale)
		and game.avatar.POPPY_TEASER_PLAY_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(640, 640)
		),
		"Poppy's teaser interaction should keep her seated scale on one fixed canvas"
	)
	check(
		game.avatar.POPPY_TEASER_PLAY_FRAMES.all(
			func(frame): return (
				not _texture_has_green_chroma(frame)
				and not _texture_top_band_has_blue_fragment(frame)
			)
		),
		"Poppy's teaser frames should contain no green spill or top-edge cat fragments"
	)
	for teaser_frame_index in range(game.avatar.POPPY_TEASER_PLAY_FRAMES.size()):
		game.avatar._process(
			float(game.avatar.POPPY_TEASER_PLAY_FRAME_DURATIONS[teaser_frame_index]) + 0.01
		)
	check(
		not game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.POPPY_IDLE_TEXTURE,
		"Poppy's teaser interaction should finish once and return to her side-sitting pose"
	)
	game.avatar.set_mood("sleep")
	check(
		game.avatar.cat_sprite.texture == game.avatar.POPPY_SLEEP_TEXTURE
		and not game.avatar.sleep_bubble_sprite.visible,
		"Inactive Poppy should use her horizontal sleeping pose without another cat's sleep bubble"
	)
	game.avatar.poppy_sleep_face_rub_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.poppy_sleep_face_rub_playing
		and game.avatar.cat_sprite.texture == game.avatar.POPPY_SLEEP_FACE_RUB_FRAMES[0]
		and game.avatar.POPPY_SLEEP_FACE_RUB_FRAMES.size() == 12,
		"Sleeping Poppy should occasionally play her aligned face-rub animation"
	)
	var poppy_station_art: Control = desktop._make_station_top_art(
		"poppy",
		desktop.get_desktop_station_theme("poppy")
	)
	check(
		_station_art_is_standardized(
			poppy_station_art,
			pet_texture("poppy", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"Poppy's Desktop Station should use her grass-and-mushroom scene"
	)
	var poppy_station_artwork := poppy_station_art.get_node("Artwork") as TextureRect
	var poppy_station_region := (poppy_station_artwork.texture as AtlasTexture).region
	check(
		poppy_station_region.end.y <= 510.0
		and is_equal_approx(
			poppy_station_artwork.position.y + poppy_station_artwork.size.y,
			desktop.STATION_CONTROLS_Y
		),
		"Poppy's visible grass should ignore transparent residue and sit flush against the controls panel"
	)
	poppy_station_art.free()
	game.avatar.set_pet({"id": "black_cat", "name": "", "type": "Cat"})
	game.avatar.set_mood("idle")
	check(
		game.avatar.cat_sprite.texture == game.avatar.BLACK_CAT_IDLE_TEXTURE,
		"The black cat should use her approved slim side-sitting pose at Home and on Desktop"
	)
	check(
		game.avatar.cat_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
		"Sable's side-sitting pose must keep smooth paw and tail edges at Home as well as on Desktop"
	)
	var black_cat_idle_image: Image = game.avatar.BLACK_CAT_IDLE_TEXTURE.get_image()
	var black_cat_eye_pixels_opaque := true
	for eye_rect in [Rect2i(330, 142, 40, 23), Rect2i(386, 116, 23, 29)]:
		for eye_y in range(eye_rect.position.y, eye_rect.end.y):
			for eye_x in range(eye_rect.position.x, eye_rect.end.x):
				if black_cat_idle_image.get_pixel(eye_x, eye_y).a < 0.999:
					black_cat_eye_pixels_opaque = false
	check(
		black_cat_eye_pixels_opaque,
		"The black cat's blue and gold eyes should not contain transparent gray desktop speckles"
	)
	var black_cat_tail_is_clean := true
	for tail_y in range(390, black_cat_idle_image.get_height()):
		for tail_x in range(black_cat_idle_image.get_width()):
			var tail_pixel: Color = black_cat_idle_image.get_pixel(tail_x, tail_y)
			if tail_pixel.a > 0.0 and tail_pixel.get_luminance() > 120.0 / 255.0:
				black_cat_tail_is_clean = false
	check(
		black_cat_tail_is_clean,
		"The black cat's seated tail should have a smooth black edge without pale ground pixels"
	)
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.BLACK_CAT_MOVE_LEFT_FRAMES
		and game.avatar.BLACK_CAT_MOVE_LEFT_FRAMES.size() == 12
		and game.avatar.BLACK_CAT_MOVE_LEFT_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(704, 512)
		),
		"The black cat should use twelve fixed-canvas left-walk frames"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.BLACK_CAT_MOVE_RIGHT_FRAMES
		and game.avatar.BLACK_CAT_MOVE_RIGHT_FRAMES.size() == 12
		and game.avatar.BLACK_CAT_MOVE_RIGHT_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(704, 512)
		),
		"The black cat should use twelve genuinely directional fixed-canvas right-walk frames"
	)
	game.avatar.stop_move()
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.BLACK_CAT_LICK_PAW_FRAMES[0]
		and game.avatar.BLACK_CAT_LICK_PAW_FRAMES.size() == 8,
		"Double-clicking the black cat should replay her aloof paw-lick instead of Maple's art"
	)
	check(
		game.avatar.BLACK_CAT_LICK_PAW_FRAMES[5].get_image().get_data()
		== game.avatar.BLACK_CAT_LICK_PAW_FRAMES[4].get_image().get_data(),
		"The black cat's paw-lick hold frame should keep the same raised right paw instead of switching paws"
	)
	game.avatar.interaction_animation_active = false
	game.avatar.set_mood("sleep")
	var black_cat_sleep_texture_size: Vector2 = game.avatar.cat_sprite.texture.get_size()
	var black_cat_expected_sleep_scale: float = minf(
		game.avatar.size.x / black_cat_sleep_texture_size.x,
		game.avatar.size.y / black_cat_sleep_texture_size.y
	) * game.avatar.BLACK_CAT_SLEEP_SCALE_MULTIPLIER
	check(
		game.avatar.black_cat_fall_asleep_playing
		and game.avatar.cat_sprite.texture == game.avatar.BLACK_CAT_FALL_ASLEEP_FRAMES[0]
		and game.avatar.BLACK_CAT_FALL_ASLEEP_FRAMES.size() == 8
		and is_equal_approx(game.avatar.BLACK_CAT_SLEEP_SCALE_MULTIPLIER, 0.76)
		and is_equal_approx(
			game.avatar.cat_sprite.scale.x,
			black_cat_expected_sleep_scale
		)
		and not game.avatar.sleep_bubble_sprite.visible,
		"The black cat should begin her lazy blink-and-lower sleep animation at the twenty-percent-smaller size"
	)
	check(
		game.avatar.BLACK_CAT_FALL_ASLEEP_FRAMES.all(
			func(frame): return _black_cat_sleep_lower_edge_is_clean(frame)
		)
		and _black_cat_sleep_lower_edge_is_clean(game.avatar.BLACK_CAT_SLEEP_TEXTURE),
		"Black-cat sleep frames should erase the complete warm ground shadow and debris below the cat"
	)
	check(
		game.avatar.cat_sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR,
		"Sable's complete sleep sequence must use linear filtering so the lower silhouette stays smooth"
	)
	for black_sleep_frame_index in range(game.avatar.BLACK_CAT_FALL_ASLEEP_FRAMES.size()):
		game.avatar._process(
			float(game.avatar.BLACK_CAT_FALL_ASLEEP_FRAME_DURATIONS[black_sleep_frame_index])
			+ 0.01
		)
	check(
		not game.avatar.black_cat_fall_asleep_playing
		and game.avatar.cat_sprite.texture == game.avatar.BLACK_CAT_SLEEP_TEXTURE,
		"The black cat should finish with her head on both paws and remain asleep"
	)
	var black_cat_station_art: Control = desktop._make_station_top_art(
		"black_cat",
		desktop.get_desktop_station_theme("black_cat")
	)
	check(
		_station_art_is_standardized(
			black_cat_station_art,
			pet_texture("black_cat", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"The black cat's Desktop Station should use the low front-facing folded gray blanket"
	)
	black_cat_station_art.free()
	var black_cat_store = load("res://src/store_screen.gd").new()
	check(
		black_cat_store._cat_head_texture("black_cat")
		== pet_texture("black_cat", "store_portrait")
		and black_cat_store._cat_detail_texture("black_cat")
		== pet_texture("black_cat", "store_detail")
		and pet_texture("black_cat", "store_detail").resource_path.ends_with(
			"black_cat_fishing_default.png"
		),
		"The black cat Store slot should use the head portrait and the detail card should use her front-facing full body"
	)
	black_cat_store.free()
	game.avatar.set_pet({"id": "maine_coon", "name": "Cedar", "type": "Cat"})
	game.avatar.set_mood("idle")
	check(
		game.avatar.cat_sprite.texture == game.avatar.MAINE_COON_IDLE_TEXTURE
		and game.avatar.MAINE_COON_IDLE_TEXTURE.get_image().get_used_rect().size.x <= 300
		and game.avatar.MAINE_COON_IDLE_TEXTURE.get_image().get_used_rect().end.y == 500
		and not game.avatar._should_draw_ground_shadow(),
		"The Maine Coon should use the approved grounded, shadow-free side-sitting Home pose"
	)
	var maine_coon_idle_scale: Vector2 = game.avatar.cat_sprite.scale
	var maine_coon_idle_visible_height: int = (
		game.avatar.MAINE_COON_IDLE_TEXTURE.get_image().get_used_rect().size.y
	)
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.MAINE_COON_MOVE_LEFT_FRAMES
		and game.avatar.MAINE_COON_MOVE_LEFT_FRAMES.size() == 12
		and game.avatar.MAINE_COON_MOVE_LEFT_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(704, 512)
				and _walk_lower_center_transparent_ratio(frame) >= 0.25
				and frame.get_image().get_used_rect().end.y >= 498
				and frame.get_image().get_used_rect().end.y <= 500
				and not _walk_has_unsupported_floor_shadow(frame)
			)
		),
		"The Maine Coon should use the approved grounded, shadow-free twelve-frame left walk with transparent gaps between every leg"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.MAINE_COON_MOVE_RIGHT_FRAMES
		and game.avatar.MAINE_COON_MOVE_RIGHT_FRAMES.size() == 12
		and game.avatar.MAINE_COON_MOVE_RIGHT_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(704, 512)
				and _walk_lower_center_transparent_ratio(frame) >= 0.25
				and frame.get_image().get_used_rect().end.y >= 498
				and frame.get_image().get_used_rect().end.y <= 500
				and not _walk_has_unsupported_floor_shadow(frame)
			)
		),
		"The Maine Coon should use the approved grounded, shadow-free twelve-frame right walk with transparent gaps between every leg"
	)
	game.avatar.stop_move()
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.MAINE_COON_NUZZLE_FRAMES[0]
		and game.avatar.MAINE_COON_NUZZLE_FRAMES.size() == 8
		and game.avatar.cat_sprite.scale.is_equal_approx(maine_coon_idle_scale)
		and absi(
			game.avatar.MAINE_COON_NUZZLE_FRAMES[0].get_image().get_used_rect().size.y
			- maine_coon_idle_visible_height
		) <= 2,
		"Double-clicking the Maine Coon should play her full-size forehead-nuzzle and paw-touch animation"
	)
	game.avatar.interaction_animation_active = false
	game.avatar.set_mood("sleep")
	check(
		game.avatar.maine_coon_sleep_paw_lick_playing
		and game.avatar.cat_sprite.texture == game.avatar.MAINE_COON_SLEEP_PAW_LICK_FRAMES[0]
		and game.avatar.MAINE_COON_SLEEP_PAW_LICK_FRAMES.size() == 8
		and not game.avatar.sleep_bubble_sprite.visible,
		"The Maine Coon should begin her aligned raise-head-and-lick-paw sleep animation"
	)
	for maine_sleep_frame_index in range(game.avatar.MAINE_COON_SLEEP_PAW_LICK_FRAMES.size()):
		game.avatar._process(
			float(game.avatar.MAINE_COON_SLEEP_PAW_LICK_FRAME_DURATIONS[maine_sleep_frame_index])
			+ 0.01
		)
	check(
		not game.avatar.maine_coon_sleep_paw_lick_playing
		and game.avatar.cat_sprite.texture == game.avatar.MAINE_COON_SLEEP_TEXTURE,
		"The Maine Coon should settle back into the approved fixed-position sleeping pose"
	)
	var maine_coon_station_art: Control = desktop._make_station_top_art(
		"maine_coon",
		desktop.get_desktop_station_theme("maine_coon")
	)
	check(
		_station_art_is_standardized(
			maine_coon_station_art,
			pet_texture("maine_coon", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"The Maine Coon's Desktop Station should use the low front-facing forest wool mat"
	)
	maine_coon_station_art.free()
	var maine_coon_store = load("res://src/store_screen.gd").new()
	check(
		maine_coon_store._cat_head_texture("maine_coon")
		== pet_texture("maine_coon", "store_portrait")
		and maine_coon_store._cat_detail_texture("maine_coon")
		== pet_texture("maine_coon", "store_detail")
		and pet_texture("maine_coon", "store_detail").resource_path.ends_with(
			"maine_coon_fishing_default.png"
		),
		"The Maine Coon Store slot should use her portrait and front-facing full body"
	)
	maine_coon_store.free()
	game.avatar.set_pet({"id": "golden_munchkin", "name": "Honey", "type": "Cat"})
	game.avatar.set_mood("idle")
	check(
		game.avatar.cat_sprite.texture == game.avatar.GOLDEN_MUNCHKIN_IDLE_TEXTURE
		and not game.avatar._should_draw_ground_shadow()
		and not _walk_has_unsupported_floor_shadow(
			game.avatar.GOLDEN_MUNCHKIN_IDLE_TEXTURE
		),
		"The Golden Munchkin should use the approved shadow-free side-sitting Home pose"
	)
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.GOLDEN_MUNCHKIN_MOVE_LEFT_FRAMES
		and game.avatar.GOLDEN_MUNCHKIN_MOVE_LEFT_FRAMES.size() == 8
		and game.avatar.GOLDEN_MUNCHKIN_MOVE_LEFT_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(704, 512)
				and not _walk_has_unsupported_floor_shadow(frame)
			)
		),
		"The Golden Munchkin should use the approved shadow-free eight-frame left walk"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.GOLDEN_MUNCHKIN_MOVE_RIGHT_FRAMES
		and game.avatar.GOLDEN_MUNCHKIN_MOVE_RIGHT_FRAMES.size() == 8
		and game.avatar.GOLDEN_MUNCHKIN_MOVE_RIGHT_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(704, 512)
				and not _walk_has_unsupported_floor_shadow(frame)
			)
		),
		"The Golden Munchkin should use the approved shadow-free eight-frame right walk"
	)
	game.avatar.stop_move()
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES[0]
		and game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES.size() == 12
		and game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAME_DURATIONS.size() == 12
		and game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(640, 512)
		),
		"Double-clicking the Golden Munchkin should use her approved short-legged failed-roll animation"
	)
	var golden_failed_roll_position: Vector2 = game.avatar.cat_sprite.position
	var golden_failed_roll_scale: Vector2 = game.avatar.cat_sprite.scale
	var golden_failed_roll_canvas_is_safe := true
	for golden_failed_roll_texture in game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES:
		var golden_failed_roll_bounds: Rect2i = golden_failed_roll_texture.get_image().get_used_rect()
		if (
			golden_failed_roll_bounds.position.x <= 4
			or golden_failed_roll_bounds.end.x >= 636
			or absi(golden_failed_roll_bounds.end.y - 500) > 2
		):
			golden_failed_roll_canvas_is_safe = false
	check(
		golden_failed_roll_canvas_is_safe
		and game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES[6].get_image().get_used_rect().size.x > 400
		and game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES.all(
			func(frame): return not _walk_has_unsupported_floor_shadow(frame)
		),
		"Golden Munchkin failed-roll frames should keep complete tails, transparent floors, and the corrected seventh-frame hindquarters inside one fixed canvas"
	)
	for golden_failed_roll_index in range(
		game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES.size() - 1
	):
		game.avatar._process(
			float(
				game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAME_DURATIONS[
					golden_failed_roll_index
				]
			) + 0.001
		)
		check(
			game.avatar.cat_sprite.position.is_equal_approx(golden_failed_roll_position)
			and game.avatar.cat_sprite.scale.is_equal_approx(golden_failed_roll_scale),
			"Golden Munchkin's failed-roll body anchor and scale should remain fixed through every frame"
		)
	game.avatar._process(
		float(game.avatar.GOLDEN_MUNCHKIN_FAILED_ROLL_FRAME_DURATIONS[-1]) + 0.02
	)
	check(
		not game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.GOLDEN_MUNCHKIN_IDLE_TEXTURE,
		"Golden Munchkin's failed roll should finish once and return to her side-sitting pose"
	)
	game.avatar.set_mood("sleep")
	check(
		not game.avatar.golden_munchkin_sleep_tail_playing
		and game.avatar.cat_sprite.texture == game.avatar.GOLDEN_MUNCHKIN_SLEEP_TEXTURE
		and game.avatar.GOLDEN_MUNCHKIN_SLEEP_TEXTURE.get_size() == Vector2(640, 512)
		and game.avatar.GOLDEN_MUNCHKIN_SLEEP_TEXTURE.get_image().get_used_rect().position.y >= 220
		and not _walk_has_unsupported_floor_shadow(
			game.avatar.GOLDEN_MUNCHKIN_SLEEP_TEXTURE
		)
		and not game.avatar.sleep_bubble_sprite.visible,
		"The sleeping Golden Munchkin should use only the selected shadow-free static low belly-up photo"
	)
	game.avatar._process(
		float(game.avatar.GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAME_DURATIONS[0]) + 0.01
	)
	check(
		not game.avatar.golden_munchkin_sleep_tail_playing
		and game.avatar.cat_sprite.texture == game.avatar.GOLDEN_MUNCHKIN_SLEEP_TEXTURE,
		"The Golden Munchkin sleep photo should remain static after animation time passes"
	)
	game.avatar.set_mood("idle")
	game.avatar.set_desktop_idle_enabled(true)
	game.avatar.desktop_idle_animation = ""
	game.avatar.desktop_idle_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.desktop_idle_animation == ""
		and game.avatar.cat_sprite.texture == game.avatar.GOLDEN_MUNCHKIN_IDLE_TEXTURE,
		"Golden Munchkin idle should never reuse the removed sleep tail animation"
	)
	var golden_munchkin_station_art: Control = desktop._make_station_top_art(
		"golden_munchkin",
		desktop.get_desktop_station_theme("golden_munchkin")
	)
	check(
		_station_art_is_standardized(
			golden_munchkin_station_art,
			pet_texture("golden_munchkin", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"The Golden Munchkin's Desktop Station should use her low ivory fluffy blanket"
	)
	golden_munchkin_station_art.free()
	var golden_munchkin_store = load("res://src/store_screen.gd").new()
	check(
		golden_munchkin_store._cat_head_texture("golden_munchkin")
		== pet_texture("golden_munchkin", "store_portrait")
		and golden_munchkin_store._cat_detail_texture("golden_munchkin")
		== pet_texture("golden_munchkin", "store_detail")
		and pet_texture("golden_munchkin", "store_detail").resource_path.ends_with(
			"golden_munchkin_fishing_default.png"
		)
		and golden_munchkin_store.get_catalog_index("golden_munchkin") == 7,
		"The Golden Munchkin Store slot should use her head portrait and front-facing full body"
	)
	check(
		game.avatar.GOLDEN_MUNCHKIN_IDLE_TEXTURE.get_image().get_used_rect().size.x >= 400
		and not _walk_has_unsupported_floor_shadow(game.avatar.GOLDEN_MUNCHKIN_IDLE_TEXTURE),
		"The Golden Munchkin Home side pose should retain the complete tail and omit its baked floor shadow"
	)
	golden_munchkin_store.free()
	game.avatar.set_pet({"id": "siamese", "name": "Pearl", "type": "Cat"})
	game.avatar.set_mood("idle")
	check(
		game.avatar.cat_sprite.texture == game.avatar.SIAMESE_IDLE_TEXTURE
		and game.avatar.SIAMESE_IDLE_TEXTURE.get_size() == Vector2(512, 512)
		and game.avatar.SIAMESE_IDLE_TEXTURE.get_image().get_pixel(0, 0).a == 0.0,
		"The Siamese should use her approved transparent side-sitting pose at Home and on Desktop"
	)
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.SIAMESE_MOVE_LEFT_FRAMES
		and game.avatar.SIAMESE_MOVE_LEFT_FRAMES.size() == 4
		and game.avatar.SIAMESE_MOVE_LEFT_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(704, 512)
				and frame.get_image().get_pixel(0, 0).a == 0.0
			)
		),
		"The Siamese should use her approved four-frame transparent left walk"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.SIAMESE_MOVE_RIGHT_FRAMES
		and game.avatar.SIAMESE_MOVE_RIGHT_FRAMES.size() == 4
		and game.avatar.SIAMESE_MOVE_RIGHT_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(704, 512)
				and frame.get_image().get_pixel(0, 0).a == 0.0
			)
		),
		"The Siamese should use her approved four-frame transparent right walk"
	)
	game.avatar.stop_move()
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.SIAMESE_TREAT_FRAMES[0]
		and game.avatar.SIAMESE_TREAT_FRAMES.size() == 12
		and game.avatar.SIAMESE_TREAT_FRAME_DURATIONS.size() == 12
		and game.avatar.SIAMESE_TREAT_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(640, 512)
				and frame.get_image().get_pixel(0, 0).a == 0.0
				and frame.get_image().get_used_rect().size.x <= 450
			)
		),
		"Double-clicking the Siamese should play twelve transparent cat-treat frames without retained panel backgrounds"
	)
	var siamese_treat_body_rect := Rect2i(0, 280, 640, 232)
	var siamese_treat_tube_rect := Rect2i(450, 185, 37, 55)
	var siamese_treat_body_reference: PackedByteArray = (
		game.avatar.SIAMESE_TREAT_FRAMES[0].get_image()
		.get_region(siamese_treat_body_rect)
		.get_data()
	)
	var siamese_treat_tube_reference: PackedByteArray = (
		game.avatar.SIAMESE_TREAT_FRAMES[0].get_image()
		.get_region(siamese_treat_tube_rect)
		.get_data()
	)
	var siamese_treat_body_is_fixed := true
	var siamese_treat_tube_is_fixed := true
	var siamese_treat_tube_is_removed := true
	for siamese_asset_index in range(game.avatar.SIAMESE_TREAT_FRAMES.size()):
		var siamese_treat_image: Image = game.avatar.SIAMESE_TREAT_FRAMES[siamese_asset_index].get_image()
		if (
			siamese_treat_image.get_region(siamese_treat_body_rect).get_data()
			!= siamese_treat_body_reference
		):
			siamese_treat_body_is_fixed = false
		if siamese_asset_index < 9:
			if (
				siamese_treat_image.get_region(siamese_treat_tube_rect).get_data()
				!= siamese_treat_tube_reference
			):
				siamese_treat_tube_is_fixed = false
		else:
			for treat_y in range(siamese_treat_tube_rect.position.y, siamese_treat_tube_rect.end.y):
				for treat_x in range(siamese_treat_tube_rect.position.x, siamese_treat_tube_rect.end.x):
					if siamese_treat_image.get_pixel(treat_x, treat_y).a > 0.03:
						siamese_treat_tube_is_removed = false
	check(
		siamese_treat_body_is_fixed
		and siamese_treat_tube_is_fixed
		and siamese_treat_tube_is_removed,
		"The Siamese treat interaction should lock her body and treat while allowing only the head animation, then remove the treat"
	)
	var siamese_treat_position: Vector2 = game.avatar.cat_sprite.position
	var siamese_treat_scale: Vector2 = game.avatar.cat_sprite.scale
	for siamese_treat_index in range(game.avatar.SIAMESE_TREAT_FRAMES.size()):
		game.avatar._process(
			float(game.avatar.SIAMESE_TREAT_FRAME_DURATIONS[siamese_treat_index]) + 0.01
		)
		if siamese_treat_index < game.avatar.SIAMESE_TREAT_FRAMES.size() - 1:
			check(
				game.avatar.cat_sprite.position.is_equal_approx(siamese_treat_position)
				and game.avatar.cat_sprite.scale.is_equal_approx(siamese_treat_scale),
				"The Siamese cat-treat interaction should keep her body anchor and scale fixed"
			)
	check(
		not game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.SIAMESE_IDLE_TEXTURE,
		"The Siamese cat-treat interaction should finish once and return to her side-sitting pose"
	)
	game.avatar.set_mood("sleep")
	game.avatar._process(1.0)
	check(
		game.avatar.cat_sprite.texture == game.avatar.SIAMESE_SLEEP_TEXTURE
		and game.avatar.SIAMESE_SLEEP_TEXTURE.get_size() == Vector2(640, 512)
		and not game.avatar.sleep_bubble_sprite.visible,
		"Sleeping Siamese should use only the approved static sleep photo"
	)
	var siamese_station_art: Control = desktop._make_station_top_art(
		"siamese",
		desktop.get_desktop_station_theme("siamese")
	)
	check(
		_station_art_is_standardized(
			siamese_station_art,
			pet_texture("siamese", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"The Siamese Desktop Station should use her low front-facing tree branch"
	)
	siamese_station_art.free()
	var siamese_store = load("res://src/store_screen.gd").new()
	check(
		siamese_store._cat_head_texture("siamese")
		== pet_texture("siamese", "store_portrait")
		and siamese_store._cat_detail_texture("siamese")
		== pet_texture("siamese", "store_detail")
		and pet_texture("siamese", "store_detail").resource_path.ends_with(
			"siamese_fishing_default.png"
		)
		and siamese_store.get_catalog_index("siamese") == 6
		and int(siamese_store.CAT_CATALOG[6].price) == 9000
		and siamese_store.get_catalog_index("maine_coon") == 8
		and int(siamese_store.CAT_CATALOG[8].price) == 20000,
		"Pearl should use her approved art and unlock in Cedar's former 9,000 XP slot before Cedar at 20,000 XP"
	)
	siamese_store.free()
	var progress_before_cat_switch: Dictionary = game.save_data.get(
		"progress_stats", {}
	).duplicate(true)
	var guarded_progress := progress_before_cat_switch.duplicate(true)
	guarded_progress["cat_switch_regression_marker"] = {
		"fishing_level": int(guarded_progress.get("fishing_level", 1)),
		"experience": int(guarded_progress.get("experience", 0))
	}
	game.save_data["progress_stats"] = guarded_progress
	game._on_store_cat_selected("maple")
	await process_frame
	check(
		str(game.get_active_pet().get("id", "")) == "default_orange_cat"
		and game.save_data.get("progress_stats", {}) == guarded_progress,
		"Carrying Maple should preserve every shared XP and fishing progress field"
	)
	game._on_store_cat_selected("mochi")
	await process_frame
	check(
		str(game.get_active_pet().get("id", "")) == "mochi"
		and game.save_data.get("progress_stats", {}) == guarded_progress,
		"Carrying Mochi should preserve every shared XP and fishing progress field"
	)
	game._on_store_cat_selected("biscuit")
	await process_frame
	check(
		str(game.get_active_pet().get("id", "")) == "biscuit"
		and game.save_data.get("progress_stats", {}) == guarded_progress,
		"Carrying Biscuit should preserve every shared XP and fishing progress field"
	)
	game._on_store_cat_selected("luna")
	await process_frame
	check(
		str(game.get_active_pet().get("id", "")) == "luna"
		and game.save_data.get("progress_stats", {}) == guarded_progress,
		"Carrying direct-unlocked Luna should preserve every shared XP and fishing progress field"
	)
	game._on_store_cat_selected("maine_coon")
	await process_frame
	check(
		str(game.get_active_pet().get("id", "")) == "maine_coon"
		and game.save_data.get("progress_stats", {}) == guarded_progress,
		"Carrying the Maine Coon should preserve XP and every shared fishing or aquarium field"
	)
	game._on_store_cat_selected("golden_munchkin")
	await process_frame
	check(
		str(game.get_active_pet().get("id", "")) == "golden_munchkin"
		and game.save_data.get("progress_stats", {}) == guarded_progress,
		"Carrying the Golden Munchkin should preserve XP and every shared fishing or aquarium field"
	)
	game._on_store_cat_selected("siamese")
	await process_frame
	check(
		str(game.get_active_pet().get("id", "")) == "siamese"
		and game.save_data.get("progress_stats", {}) == guarded_progress,
		"Carrying the Siamese should preserve XP and every shared fishing or aquarium field"
	)
	check(
		game._apply_desktop_launch_pet_override("biscuit")
		and str(game.get_active_pet().get("id", "")) == "biscuit",
		"The external Desktop process should honor the cat ID passed by its launcher"
	)
	check(
		not game._apply_desktop_launch_pet_override("missing_cat")
		and str(game.get_active_pet().get("id", "")) == "biscuit",
		"An invalid Desktop launch cat ID should not replace the selected companion"
	)
	game._apply_desktop_launch_pet_override("luna")
	game.save_data["progress_stats"] = progress_before_cat_switch
	game.avatar.set_pet({"id": "mochi", "name": "Mochi", "type": "Cat"})
	game.avatar.set_mood("idle")
	check(
		game.avatar.cat_sprite.texture == game.avatar.MOCHI_HOME_TAIL_BLINK_FRAMES[0]
		and game.avatar.MOCHI_HOME_TAIL_BLINK_FRAMES.size() == 8,
		"Mochi should use the eight-frame blink and tail-tip Home animation"
	)
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar.set_pet({"id": "mochi", "name": "Mochi", "type": "Cat"})
	check(
		game.avatar.move_time_remaining == 0.0
		and game.avatar.cat_sprite.texture == game.avatar.MOCHI_HOME_TAIL_BLINK_FRAMES[0],
		"Rebuilding Mochi should clear stale walking state and restore her seated pose"
	)
	game.avatar.set_desktop_idle_enabled(true)
	check(
		game.avatar.cat_sprite.texture == game.avatar.MOCHI_HOME_TAIL_BLINK_FRAMES[0],
		"Mochi should keep the approved default seated pose in Desktop Companion mode"
	)
	game.avatar.desktop_idle_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.desktop_idle_animation == "mochi_tail_blink"
		and game.avatar.cat_sprite.texture == game.avatar.MOCHI_HOME_TAIL_BLINK_FRAMES[0],
		"An active Mochi should occasionally begin her blink and tail-tip animation"
	)
	game.avatar.set_desktop_idle_enabled(false)
	game.avatar.home_idle_wait_remaining = 0.0
	game.avatar._process(0.01)
	game.avatar._process(float(game.avatar.MOCHI_HOME_IDLE_FRAME_DURATIONS[0]) + 0.01)
	check(
		game.avatar.home_idle_playing and game.avatar.home_idle_frame == 1
		and game.avatar.cat_sprite.texture == game.avatar.MOCHI_HOME_TAIL_BLINK_FRAMES[1],
		"Mochi's Home idle should advance through its custom animation frames"
	)
	game.avatar.set_mood("sleep")
	check(
		game.avatar.cat_sprite.texture == game.avatar.MOCHI_SLEEP_TEXTURE
		and not game.avatar.sleep_bubble_sprite.visible,
		"Inactive Mochi should curl up asleep without using Maple's nose-bubble effect"
	)
	check(
		game.avatar.mochi_sleep_ear_twitch_wait_remaining >= game.avatar.MOCHI_SLEEP_EAR_TWITCH_MIN_WAIT
		and game.avatar.mochi_sleep_ear_twitch_wait_remaining <= game.avatar.MOCHI_SLEEP_EAR_TWITCH_MAX_WAIT,
		"Sleeping Mochi should schedule the ear twitch after a random quiet interval"
	)
	game.avatar.mochi_sleep_ear_twitch_wait_remaining = 0.0
	game.avatar._process(0.01)
	check(
		game.avatar.mochi_sleep_ear_twitch_playing
		and game.avatar.cat_sprite.texture == game.avatar.MOCHI_SLEEP_EAR_TWITCH_FRAMES[0],
		"Mochi's sleeping ear-twitch animation should play only after its random wait"
	)
	game.avatar._process(float(game.avatar.MOCHI_SLEEP_EAR_TWITCH_FRAME_DURATIONS[0]) + 0.01)
	check(
		game.avatar.mochi_sleep_ear_twitch_frame == 1
		and game.avatar.cat_sprite.texture == game.avatar.MOCHI_SLEEP_EAR_TWITCH_FRAMES[1],
		"Mochi's sleeping ear twitch should advance through the custom frames"
	)
	game.avatar.set_mood("idle")
	game.avatar.play_move(Vector2.LEFT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.MOCHI_MOVE_LEFT_FRAMES
		and game.avatar.MOCHI_MOVE_LEFT_FRAMES.size() == 12,
		"Mochi should use the second-version left walk while following or returning"
	)
	game.avatar.stop_move()
	game.avatar.play_move(Vector2.RIGHT)
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(
		game.avatar.cat_sprite.texture in game.avatar.MOCHI_MOVE_RIGHT_FRAMES
		and game.avatar.MOCHI_MOVE_RIGHT_FRAMES.size() == 12,
		"Mochi should use the second-version right walk while following or returning"
	)
	game.avatar.play_belly_roll()
	check(
		game.avatar.is_playing_interaction()
		and game.avatar.cat_sprite.texture == game.avatar.MOCHI_LICK_PAW_FRAMES[0],
		"Double-clicking Mochi should start her paw-licking interaction"
	)
	game.avatar._process(float(game.avatar.MOCHI_LICK_PAW_FRAME_DURATIONS[0]) + 0.01)
	check(
		game.avatar.interaction_frame == 1
		and game.avatar.cat_sprite.texture == game.avatar.MOCHI_LICK_PAW_FRAMES[1],
		"Mochi's paw-licking interaction should advance through its own frames"
	)
	var mochi_station_art: Control = desktop._make_station_top_art(
		"mochi",
		desktop.get_desktop_station_theme("mochi")
	)
	check(
		_station_art_is_standardized(
			mochi_station_art,
			pet_texture("mochi", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"Mochi's Desktop Station should use the pale lotus-pink daybed"
	)
	mochi_station_art.free()
	check(game.select_pet("default_orange_cat"), "Maple should remain selectable after Mochi comes online")
	game.avatar.set_pet({"id": "default_orange_cat", "name": "Maple", "type": "Cat"})
	game.avatar.set_mood("idle")
	check(not game.avatar.sleep_bubble_sprite.visible, "The standing Home cat should not show a sleeping nose bubble")
	game.avatar.set_mood("sleep")
	check(game.avatar.cat_sprite.texture == game.avatar.SLEEP_TEXTURE, "Sleep mood should use the curled sleeping sprite")
	check(game.avatar.mood_badge.text == "" and not game.avatar.mood_badge.visible, "Sleeping pets should not show a ZZZ badge above their heads")
	check(game.avatar.SLEEP_BUBBLE_FRAMES.size() == 14, "The sleeping nose bubble should use a smooth fourteen-frame breathing cycle")
	check(game.avatar.sleep_bubble_sprite.get_parent() == game.avatar.cat_sprite, "The sleeping bubble should remain attached to the cat sprite")
	check(not game.avatar.sleep_bubble_sprite.visible and game.avatar.sleep_bubble_sprite.z_index > 0, "Entering sleep should keep the occasional nose bubble hidden at first")
	check(
		game.avatar.sleep_bubble_wait_remaining >= game.avatar.SLEEP_BUBBLE_MIN_WAIT
		and game.avatar.sleep_bubble_wait_remaining <= game.avatar.SLEEP_BUBBLE_MAX_WAIT,
		"Sleeping should schedule the next bubble after a random wait"
	)
	check(
		(game.avatar.sleep_bubble_sprite.position + game.avatar.SLEEP_BUBBLE_FRAME_ANCHOR + game.avatar.SLEEP_TEXTURE.get_size() * 0.5).is_equal_approx(game.avatar.SLEEP_BUBBLE_NOSE_POSITION),
		"The bubble's pointed end should stay anchored to the cat's nostril"
	)
	check(
		game.avatar.SLEEP_BUBBLE_FRAMES.all(func(frame): return frame.get_size() == Vector2(144, 96)),
		"All sleeping-bubble frames should share one fixed canvas so the nostril anchor cannot jump"
	)
	var bubble_widths: Array[int] = []
	for bubble_frame in game.avatar.SLEEP_BUBBLE_FRAMES:
		bubble_widths.append(bubble_frame.get_image().get_used_rect().size.x)
	check(bubble_widths[6] > bubble_widths[9] and bubble_widths[9] < bubble_widths[13], "One bubble cycle should grow, shrink, and grow again")
	check(bubble_widths[6] == bubble_widths[13] and bubble_widths.max() <= 108, "Both growth peaks should keep the approved maximum bubble size")
	check(is_equal_approx(float(game.avatar.SLEEP_BUBBLE_FRAMES.size()) / game.avatar.SLEEP_BUBBLE_FPS, 2.8), "One complete bubble cycle should take about 2.8 seconds")
	var sleeping_cat_position: Vector2 = game.avatar.cat_sprite.position
	game.avatar.sleep_bubble_wait_remaining = 0.0
	game.avatar._process(0.0)
	check(game.avatar.sleep_bubble_active and game.avatar.sleep_bubble_sprite.visible, "The bubble should appear only when its random wait finishes")
	check(game.avatar.sleep_bubble_sprite.texture == game.avatar.SLEEP_BUBBLE_FRAMES[0], "An occasional bubble should begin at its smallest frame")
	game.avatar._process(1.0 / game.avatar.SLEEP_BUBBLE_FPS + 0.01)
	check(game.avatar.sleep_bubble_sprite.texture == game.avatar.SLEEP_BUBBLE_FRAMES[1], "The sleeping bubble should visibly grow to the next frame")
	check(game.avatar.cat_sprite.position.is_equal_approx(sleeping_cat_position), "Animating the bubble must not make the sleeping cat float")
	game.avatar.sleep_bubble_frame = game.avatar.SLEEP_BUBBLE_FRAMES.size() - 1
	game.avatar.sleep_bubble_frame_elapsed = 0.0
	game.avatar._update_sleep_bubble()
	game.avatar._process(1.0 / game.avatar.SLEEP_BUBBLE_FPS + 0.01)
	check(not game.avatar.sleep_bubble_active and not game.avatar.sleep_bubble_sprite.visible, "A completed bubble cycle should disappear instead of looping continuously")
	for grounded_mood in ["sleep", "idle", "happy", "follow"]:
		game.avatar.set_mood(grounded_mood)
		var grounded_position: Vector2 = game.avatar.cat_sprite.position
		game.avatar._process(0.73)
		check(game.avatar.cat_sprite.position.is_equal_approx(grounded_position), "Home cat mood '%s' should have no floating animation" % grounded_mood)
		var grounded_bounds: Rect2 = game.avatar._get_texture_visual_bounds(game.avatar.cat_sprite.texture)
		var grounded_texture_size: Vector2 = game.avatar.cat_sprite.texture.get_size()
		var grounded_visual_bottom: float = game.avatar.cat_sprite.position.y + (grounded_bounds.end.y - grounded_texture_size.y * 0.5) * game.avatar.cat_sprite.scale.y
		check(is_equal_approx(grounded_visual_bottom, game.avatar.size.y * game.avatar.SHADOW_CENTER_Y_RATIO), "Home cat mood '%s' should rest directly on its shadow" % grounded_mood)
	game.avatar.set_mood("sleep")
	check(not game.avatar.sleep_bubble_sprite.visible and not game.avatar.sleep_bubble_active, "Returning to sleep should schedule an occasional bubble instead of showing one immediately")
	game.update_home_pointer_state(Vector2(320, 360), true)
	check(game.avatar.mood == "idle", "Moving the pointer into the left side of Home should wake the cat")
	check(not game.avatar.sleep_bubble_sprite.visible, "Waking the cat should hide the sleeping bubble immediately")
	var pet_double_click := InputEventMouseButton.new()
	pet_double_click.button_index = MOUSE_BUTTON_LEFT
	pet_double_click.pressed = true
	pet_double_click.double_click = true
	check(game.home_pet_interaction_surface != null, "Home should expose a double-click surface over the cat")
	game._on_home_pet_input(pet_double_click)
	check(game.avatar.is_playing_interaction() and game.avatar.cat_sprite.texture == game.avatar.DESKTOP_BELLY_FRAMES[0], "Double-clicking the Home cat should begin the belly-roll animation")
	game.avatar._process(1.0 / game.avatar.DESKTOP_BELLY_FPS + 0.01)
	check(game.avatar.interaction_frame == 1, "The Home belly-roll interaction should advance through its animation frames")
	for home_roll_step in range(game.avatar.DESKTOP_BELLY_FRAMES.size() + 1):
		game.avatar._process(1.0 / game.avatar.DESKTOP_BELLY_FPS + 0.01)
	check(not game.avatar.is_playing_interaction(), "The Home belly-roll interaction should finish once instead of looping forever")
	game.update_home_pointer_state(Vector2(900, 360), true, 9.9)
	check(game.avatar.mood == "idle", "Leaving the Home wake area should keep the cat awake during the ten-second grace period")
	game.update_home_pointer_state(Vector2(320, 360), true, 0.0)
	check(game.avatar.mood == "idle" and game.home_pointer_outside_elapsed == 0.0, "Returning to the Home wake area should cancel the pending sleep countdown")
	game.update_home_pointer_state(Vector2(900, 360), true, 9.9)
	game.update_home_pointer_state(Vector2(900, 360), true, 0.2)
	check(game.avatar.mood == "sleep", "The Home cat should sleep only after the pointer stays away for ten seconds")
	game.avatar.set_mood("idle")
	var movement_tests := [
		{"vector": Vector2.LEFT, "frames": game.avatar.MOVE_LEFT_FRAMES, "name": "left"},
		{"vector": Vector2.RIGHT, "frames": game.avatar.MOVE_RIGHT_FRAMES, "name": "right"},
	]
	for movement_test in movement_tests:
		game.avatar.move_time_remaining = 0.0
		game.avatar.play_move(movement_test.vector)
		game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
		check(game.avatar.cat_sprite.texture in movement_test.frames, "%s movement should use its directional animation" % movement_test.name.capitalize())
		check(movement_test.frames.size() >= 10, "%s movement should contain at least ten frames" % movement_test.name.capitalize())
		check(movement_test.frames.all(func(frame): return frame.get_size() == Vector2(704, 512)), "%s movement should use one fixed large canvas" % movement_test.name.capitalize())
		for safe_frame in movement_test.frames:
			var safe_rect: Rect2i = safe_frame.get_image().get_used_rect()
			check(
				safe_rect.position.x >= 12
				and safe_rect.position.y >= 12
				and safe_rect.end.x <= 692
				and safe_rect.end.y <= 500,
				"%s movement frames should keep transparent padding around the whole cat" % movement_test.name.capitalize()
			)
	var desktop_pet_size := Vector2(400.0, 300.0)
	var idle_visual_height: float = game.avatar.PET_TEXTURE.get_image().get_used_rect().size.y * minf(
		desktop_pet_size.x / game.avatar.PET_TEXTURE.get_width(),
		desktop_pet_size.y / game.avatar.PET_TEXTURE.get_height()
	) * 0.95
	var movement_visual_height: float = game.avatar.MOVE_RIGHT_FRAMES[0].get_image().get_used_rect().size.y * minf(
		desktop_pet_size.x / game.avatar.MOVE_RIGHT_FRAMES[0].get_width(),
		desktop_pet_size.y / game.avatar.MOVE_RIGHT_FRAMES[0].get_height()
	) * game.avatar.MOVEMENT_SCALE_MULTIPLIER
	check(absf(idle_visual_height - movement_visual_height) < 4.0, "Starting a movement animation should not make the cat visibly smaller")
	game.avatar.move_direction = "left"
	game.avatar.move_time_remaining = 0.0
	game.avatar.play_move(Vector2.UP)
	check(game.avatar.move_direction == "left" and game.avatar._get_move_frames() == game.avatar.MOVE_LEFT_FRAMES, "Vertical movement should keep the latest left-facing run animation")
	game.avatar.move_direction = "right"
	game.avatar.move_time_remaining = 0.0
	game.avatar.play_move(Vector2.DOWN)
	check(game.avatar.move_direction == "right" and game.avatar._get_move_frames() == game.avatar.MOVE_RIGHT_FRAMES, "Vertical movement should keep the latest right-facing run animation")
	game.avatar.move_direction = "right"
	game.avatar.move_frame = game.avatar.MOVE_RIGHT_FRAMES.size() - 1
	game.avatar.move_frame_elapsed = 0.0
	game.avatar.move_time_remaining = 1.0
	game.avatar._process(1.0 / game.avatar.MOVE_FPS + 0.01)
	check(game.avatar.move_frame == game.avatar.MOVE_LOOP_START_FRAME, "Movement loops should skip the sitting and preparation frames after their first pass")
	game.avatar.set_mood("blush")
	var first_shy_texture = game.avatar.cat_sprite.texture
	check(first_shy_texture == game.avatar.SHY_FRAMES[0], "Shy mood should start on the first blush frame")
	game.avatar._process(1.0 / game.avatar.SHY_FPS + 0.01)
	check(game.avatar.cat_sprite.texture in game.avatar.SHY_FRAMES, "Shy mood should use the blush animation frames")
	check(game.avatar.cat_sprite.texture != first_shy_texture, "Shy tail animation should advance to the next frame")

	var xp_before_fishing := int(game.get_progress_stats().experience)
	game.show_fishing()
	await process_frame
	check(
		music_manager.is_fishing_music_active()
		and music_manager.music_player.stream == music_manager.fishing_music,
		"Entering Fishing should switch the Music bus player to Cats Fishing Day"
	)
	check(game.fishing_game != null, "Fishing should be implemented by its own component")
	check(game.fishing_game.get_script().resource_path == "res://src/fishing_game.gd", "Fishing should live in the new readable script")
	check(
		game.fishing_game.failure_sound_player != null
		and game.fishing_game.failure_sound_player.bus == &"SFX"
		and game.fishing_game.failure_sound_player.stream == game.fishing_game.FISHING_FAILURE_SOUND
		and game.fishing_game.FISHING_FAILURE_SOUND.loop_mode == AudioStreamWAV.LOOP_DISABLED,
		"Fishing failures should use the trimmed one-shot sound through the SFX bus"
	)
	check(
		game.fishing_game.success_sound_player != null
		and game.fishing_game.success_sound_player.bus == &"SFX"
		and game.fishing_game.success_sound_player.stream == game.fishing_game.FISHING_SUCCESS_SOUND
		and game.fishing_game.FISHING_SUCCESS_SOUND.loop_mode == AudioStreamWAV.LOOP_DISABLED,
		"Successful catches should use the trimmed Tiny Splash one-shot through the SFX bus"
	)
	var failure_sound_probe = load("res://src/fishing_game.gd").new()
	failure_sound_probe.configure(
		{"id": "default_orange_cat", "name": "Maple", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(failure_sound_probe)
	await process_frame
	var empty_catch_for_sound_test: Array[Dictionary] = []
	failure_sound_probe._finish_attempt(empty_catch_for_sound_test)
	check(
		failure_sound_probe.failure_sound_player.playing
		and not failure_sound_probe.success_sound_player.playing,
		"An empty net should play only Cozy Cat Fishing Failure when the failure result appears"
	)
	failure_sound_probe.queue_free()
	await process_frame
	check(game.fishing_game.FISH_TYPES.size() == 52, "Fishing should define all fifty-two fish species")
	check(FishCatalogScript.RARITY_LEVEL_FISH_IDS.map(func(fish_ids): return fish_ids.size()) == [3, 4, 4, 3, 3, 2, 2, 3, 4, 4, 4, 4, 3, 3, 3, 3], "Fish rarity levels should follow the approved Level 0-15 distribution")
	for balanced_fish in FishCatalogScript.FISH_TYPES:
		var balanced_fish_id := str(balanced_fish.id)
		var balanced_rarity_level := int(balanced_fish.rarity_level)
		var expected_base_goal_count := int(
			FishCatalogScript.BASE_GOAL_COUNT_OVERRIDES.get(
				balanced_fish_id,
				FishCatalogScript.BASE_GOAL_COUNTS_BY_RARITY_LEVEL[balanced_rarity_level]
			)
		)
		check(
			int(balanced_fish.base_goal_count) == expected_base_goal_count,
			"Every fish should use the approved rarity-based base goal count"
		)
	var glass_knifefish := FishCatalogScript.definition("glass_knifefish")
	check(
		glass_knifefish.swim_size == Vector2(195, 72)
		and is_equal_approx(float(glass_knifefish.speed_multiplier), 0.90),
		"Glass Knifefish should swim at 1.5 times its former size and use its slower movement speed"
	)
	var electric_eel := FishCatalogScript.definition("electric_eel")
	check(
		electric_eel.swim_size == Vector2(171.6, 72.8),
		"Electric Eel should swim at 1.3 times its former gameplay size"
	)
	check(FishCatalogScript.STARTER_FISH_IDS.is_empty(), "A new player should not have any fish discovered by default")
	check(FishingLevelCatalogScript.newly_introduced_fish_ids(1) == ["green"], "Green Fish should be introduced as a new discovery on level one")
	check(FishingLevelCatalogScript.newly_introduced_fish_ids(2) == ["coral"], "Coral Angelfish should be introduced on level two")
	check(FishingLevelCatalogScript.newly_introduced_fish_ids(3) == ["golden"], "Golden Ribbonfish should be introduced on level three")
	check(game.fishing_game.FISH_TYPES.all(func(fish): return not fish.has("xp")), "Fish definitions should no longer grant per-species XP")
	check(game.fishing_game.FISH_TYPES.all(func(fish): return not str(fish.get("description", "")).is_empty()), "Every fish species should have an encyclopedia description")
	var fishing_levels := FishingLevelCatalogScript.all_levels()
	check(fishing_levels.size() == 450, "Fishing should provide exactly four hundred and fifty campaign levels")
	check(
		fishing_levels.all(func(level): return level.spawn_fish_ids.size() <= 15),
		"Each campaign level should allow at most fifteen spawning species"
	)
	check(
		fishing_levels.all(func(level): return level.goals.all(func(goal): return level.spawn_fish_ids.has(str(goal.fish_id)))),
		"Capping the spawn pool must retain every target species"
	)
	check(
		is_equal_approx(
			1.0 - float(FishingLevelCatalogScript.level_config(1).catch_success_chance),
			0.02
		)
		and is_equal_approx(
			1.0 - float(FishingLevelCatalogScript.level_config(450).catch_success_chance),
			0.15
		),
		"Base fish escape chance should rise from two percent on level one to fifteen percent on level 450"
	)
	var escape_chance_increases_smoothly := true
	for level_index in range(1, fishing_levels.size()):
		var previous_escape := 1.0 - float(fishing_levels[level_index - 1].catch_success_chance)
		var current_escape := 1.0 - float(fishing_levels[level_index].catch_success_chance)
		if current_escape + 0.000001 < previous_escape:
			escape_chance_increases_smoothly = false
			break
	check(escape_chance_increases_smoothly, "Base fish escape chance should never decrease as campaign levels advance")
	check(fishing_levels.all(func(level): return int(level.time_limit_seconds) >= 30 and int(level.time_limit_seconds) <= 90), "Every fishing level should last between thirty and ninety seconds")
	check(
		FishingLevelCatalogScript.base_time_for_pass_rate(0.95) == 86
		and FishingLevelCatalogScript.base_time_for_pass_rate(0.90) == 78
		and FishingLevelCatalogScript.base_time_for_pass_rate(0.85) == 70
		and FishingLevelCatalogScript.base_time_for_pass_rate(0.80) == 66
		and FishingLevelCatalogScript.base_time_for_pass_rate(0.75) == 53,
		"Fishing pass-rate bands should use the approved 86/78/70/66/53-second base times"
	)
	check(fishing_levels.all(func(level): return level.goals.size() >= 1 and level.goals.size() <= 3), "Every fishing level should request one to three fish species")
	check(
		fishing_levels.all(func(level): return level.goals.all(func(goal): return int(goal.count) >= 1 and int(goal.count) <= FishingLevelCatalogScript.MAX_GOAL_COUNT)),
		"Every generated fishing goal should respect the expanded one-to-twelve count range"
	)
	check(
		is_equal_approx(FishingLevelCatalogScript.target_pass_rate(1), 0.95)
		and is_equal_approx(FishingLevelCatalogScript.target_pass_rate(21), 0.90)
		and is_equal_approx(FishingLevelCatalogScript.target_pass_rate(61), 0.85)
		and is_equal_approx(FishingLevelCatalogScript.target_pass_rate(121), 0.80)
		and is_equal_approx(FishingLevelCatalogScript.target_pass_rate(171), 0.75)
		and is_equal_approx(FishingLevelCatalogScript.target_pass_rate(200), 0.75)
		and is_equal_approx(FishingLevelCatalogScript.target_pass_rate(201), 0.75)
		and is_equal_approx(FishingLevelCatalogScript.target_pass_rate(450), 0.75),
		"The five campaign bands should use the approved 95/90/85/80/75 percent target pass rates"
	)
	check(
		is_equal_approx(FishingLevelCatalogScript.spawn_total_multiplier(0.95), 10.0)
		and is_equal_approx(FishingLevelCatalogScript.spawn_total_multiplier(0.90), 9.0)
		and is_equal_approx(FishingLevelCatalogScript.spawn_total_multiplier(0.85), 8.0)
		and is_equal_approx(FishingLevelCatalogScript.spawn_total_multiplier(0.80), 7.5)
		and is_equal_approx(FishingLevelCatalogScript.spawn_total_multiplier(0.75), 7.5),
		"Fishing pass-rate bands should map to the current finite spawn multipliers"
	)
	var extended_levels_keep_pass_rate := true
	for level_number in range(201, 451):
		if not is_equal_approx(float(fishing_levels[level_number - 1].target_pass_rate), 0.75):
			extended_levels_keep_pass_rate = false
			break
	check(extended_levels_keep_pass_rate, "Every fishing level from 201 through 450 should keep level 200's 75 percent target pass rate")
	var has_time_recovery_level := false
	for level_index in range(1, fishing_levels.size()):
		if int(fishing_levels[level_index].time_limit_seconds) > int(fishing_levels[level_index - 1].time_limit_seconds):
			has_time_recovery_level = true
			break
	check(has_time_recovery_level, "Fishing time limits should include recovery levels instead of decreasing mechanically every round")
	var campaign_goal_fish_ids := {}
	for level_config in fishing_levels:
		for goal in level_config.goals:
			campaign_goal_fish_ids[str(goal.fish_id)] = true
	check(campaign_goal_fish_ids.size() == FishCatalogScript.FISH_TYPES.size(), "All fish species should be introduced as campaign goals by level 450")
	check(FishingLevelCatalogScript.DISCOVERY_LEVEL_BY_FISH_ID.size() == FishCatalogScript.FISH_TYPES.size(), "Every fish species should have an explicit discovery level")
	for fish_index in range(FishCatalogScript.FISH_TYPES.size()):
		var fish: Dictionary = FishCatalogScript.FISH_TYPES[fish_index]
		var fish_id := str(fish.id)
		var discovery_level := FishingLevelCatalogScript.discovery_level(fish_id)
		if fish_index < 22:
			check(discovery_level <= 200, "The original twenty-two fish should remain within the original campaign")
		else:
			check(discovery_level >= 201 and discovery_level <= 450, "The thirty new fish should be introduced across levels 201-450")
		if FishCatalogScript.STARTER_FISH_IDS.has(fish_id):
			continue
		check(FishingLevelCatalogScript.level_config(discovery_level).goals.any(func(goal): return str(goal.fish_id) == fish_id), "Each species should be guaranteed on its configured discovery level")
	check(float(FishingLevelCatalogScript.level_config(18).difficulty_multiplier) > float(FishingLevelCatalogScript.level_config(17).difficulty_multiplier), "Completing rarity level one should add a small campaign difficulty bump")
	check(float(FishingLevelCatalogScript.level_config(214).difficulty_multiplier) > float(FishingLevelCatalogScript.level_config(213).difficulty_multiplier), "Seeing every Level 7 fish should add the next small campaign difficulty bump")
	var level_450_config := FishingLevelCatalogScript.level_config(450)
	var endless_goal_sets := {}
	for endless_level_number in range(451, 471):
		var endless_config := FishingLevelCatalogScript.level_config(endless_level_number)
		check(int(endless_config.level) == endless_level_number, "Endless fishing should preserve level numbers above 450")
		check(endless_config.goals.size() >= 2 and endless_config.goals.size() <= 3, "Every endless fishing level should choose two or three target species")
		check(endless_config.new_fish_ids.is_empty(), "Endless fishing should not introduce new species")
		check(endless_config.spawn_fish_ids.size() == 15, "Endless levels should also cap the spawn pool at fifteen species")
		check(endless_config.goals.all(func(goal): return endless_config.spawn_fish_ids.has(str(goal.fish_id))), "Every endless target species should remain in the capped spawn pool")
		check(int(endless_config.time_limit_seconds) == int(level_450_config.time_limit_seconds), "Endless fishing should keep level 450's time limit")
		check(is_equal_approx(float(endless_config.target_pass_rate), float(level_450_config.target_pass_rate)), "Endless fishing should keep level 450's target pass rate")
		check(is_equal_approx(float(endless_config.difficulty_multiplier), float(level_450_config.difficulty_multiplier)), "Endless fishing should keep level 450's difficulty multiplier")
		check(is_equal_approx(float(endless_config.catch_success_chance), float(level_450_config.catch_success_chance)), "Endless fishing should keep level 450's catch success chance")
		check(is_equal_approx(float(endless_config.spawn_total_multiplier), float(level_450_config.spawn_total_multiplier)), "Endless fishing should keep level 450's spawn multiplier")
		check(int(endless_config.xp_reward) >= 200 and int(endless_config.xp_reward) <= 230, "Endless fishing should reward between 200 and 230 XP")
		check(endless_config == FishingLevelCatalogScript.level_config(endless_level_number), "An unfinished endless level should keep the same random configuration after reloading")
		endless_goal_sets[JSON.stringify(endless_config.goals)] = true
	check(endless_goal_sets.size() > 1, "Successive endless fishing levels should not all choose the same targets")
	check(game.fishing_game.MAIN_SCREEN_TEXTURE.resource_path.ends_with("fishing_environment_background.png"), "Fishing should use the selected clean horizontal-riverbank background with no baked UI, cat, net, or fish")
	check(game.fishing_game.GREEN_FISH_TEXTURE.resource_path.ends_with("green_fish_v2.png"), "Fishing should use the remodeled green fish")
	check(game.fishing_game.CORAL_ANGELFISH_TEXTURE.resource_path.ends_with("coral_angelfish_v2.png"), "Fishing should use the generated coral angelfish")
	check(game.fishing_game.GOLDEN_RIBBONFISH_TEXTURE.resource_path.ends_with("golden_ribbonfish_v2.png"), "Fishing should use the generated golden ribbonfish")
	check(game.fishing_game.GOAL_POPUP_TEXTURE.resource_path.ends_with("fishing_goal_popup_base_v2.png"), "The pre-round popup should use the approved V2 background-only artwork")
	check(game.fishing_game.CATCH_POPUP_TEXTURE.resource_path.ends_with("fishing_catch_popup_background_v1.png"), "Successful catches should use the approved background-only catch popup artwork")
	check(game.fishing_game.round_goals.size() <= game.fishing_game.MAX_ROUND_GOAL_TYPES, "A fishing round should request at most three fish species")
	check(game.fishing_game.state == game.fishing_game.GameState.SHOWING_GOALS, "Fishing should open on the pre-round goal popup")
	check(game.fishing_game.goal_popup_overlay != null and game.fishing_game.catch_hotspot.disabled, "The goal popup should block Catch until the player starts the round")
	check(game.fishing_game.goal_popup_panel.position == game.fishing_game.GOAL_POPUP_PANEL_POSITION and game.fishing_game.goal_popup_panel.size == game.fishing_game.GOAL_POPUP_PANEL_SIZE, "The complete goal popup should use the editable panel position and size constants")
	var goal_popup_background = game.fishing_game.goal_popup_panel.find_child("FishingGoalPopupBackground", true, false)
	check(goal_popup_background is TextureRect and goal_popup_background.texture == game.fishing_game.GOAL_POPUP_TEXTURE, "The goal popup background should remain separate from its live text and fish nodes")
	var goal_popup_title = game.fishing_game.goal_popup_panel.find_child("FishingGoalPopupTitle", true, false)
	check(goal_popup_title.position == game.fishing_game.GOAL_POPUP_TITLE_POSITION and goal_popup_title.size == game.fishing_game.GOAL_POPUP_TITLE_SIZE and goal_popup_title.get_theme_font_size("font_size") == game.fishing_game.GOAL_POPUP_TITLE_FONT_SIZE, "The goal title should use editable position, size, and font-size constants")
	check(game.fishing_game.goal_popup_fish_views.size() == game.fishing_game.round_goals.size() and game.fishing_game.goal_popup_count_labels.size() == game.fishing_game.round_goals.size(), "The goal popup should render every configured fish row")
	for goal_index in range(game.fishing_game.goal_popup_fish_views.size()):
		var goal_fish_view: TextureRect = game.fishing_game.goal_popup_fish_views[goal_index]
		var goal_count_label: Label = game.fishing_game.goal_popup_count_labels[goal_index]
		check(goal_fish_view.position == game.fishing_game.GOAL_POPUP_FISH_POSITIONS[goal_index] and goal_fish_view.size == game.fishing_game.GOAL_POPUP_FISH_SIZES[goal_index], "Each goal fish should use its editable position and size constants")
		check(goal_count_label.position == game.fishing_game.GOAL_POPUP_COUNT_POSITIONS[goal_index] and goal_count_label.size == game.fishing_game.GOAL_POPUP_COUNT_SIZE and goal_count_label.get_theme_font_size("font_size") == game.fishing_game.GOAL_POPUP_COUNT_FONT_SIZE, "Each goal count should use editable position, size, and font-size constants")
	check(game.fishing_game.goal_popup_time_label.text == "01:30" and game.fishing_game.goal_popup_time_label.position == game.fishing_game.GOAL_POPUP_TIMER_POSITION and game.fishing_game.goal_popup_time_label.get_theme_font_size("font_size") == game.fishing_game.GOAL_POPUP_TIMER_FONT_SIZE, "The pre-round timer should show the configured time with editable layout and font size")
	var goal_popup_time_title = game.fishing_game.goal_popup_panel.find_child("FishingGoalPopupTimeTitle", true, false)
	var goal_popup_footer = game.fishing_game.goal_popup_panel.find_child("FishingGoalPopupFooter", true, false)
	check(goal_popup_time_title.position == game.fishing_game.GOAL_POPUP_TIME_TITLE_POSITION and goal_popup_time_title.get_theme_font_size("font_size") == game.fishing_game.GOAL_POPUP_TIME_TITLE_FONT_SIZE, "The time-limit title should use editable layout constants")
	check(goal_popup_footer.position == game.fishing_game.GOAL_POPUP_FOOTER_POSITION and goal_popup_footer.get_theme_font_size("font_size") == game.fishing_game.GOAL_POPUP_FOOTER_FONT_SIZE, "The start prompt should use editable layout constants")
	check(game.fishing_game.stats_labels[0].text == "LEVEL: 1\nTIME: 01:30", "The upper-left panel should replace cumulative fish and XP with level and round time")
	check(game.fishing_game.goal_progress_labels.size() == game.fishing_game.round_goals.size(), "The upper-right panel should mirror every fish type from the pre-round popup")
	for goal_index in range(game.fishing_game.goal_progress_labels.size()):
		var tracker_label: RichTextLabel = game.fishing_game.goal_progress_labels[goal_index]
		var required_count := int(game.fishing_game.round_goals[goal_index].count)
		check(tracker_label.position == game.fishing_game.GOAL_TRACKER_PROGRESS_POSITIONS[goal_index] and tracker_label.get_theme_font_size("normal_font_size") == game.fishing_game.GOAL_TRACKER_PROGRESS_FONT_SIZE, "Each live goal counter should use the editable tracker layout constants")
		check(tracker_label.text.contains(game.fishing_game.GOAL_PROGRESS_UNMET_COLOR_HEX) and tracker_label.text.contains("0[/color]") and tracker_label.text.contains("/%d" % required_count), "An unmet goal should show a red zero and its required total in white")
	game.fishing_game._start_round_from_goal_popup()
	check(game.fishing_game.goal_popup_overlay == null and game.fishing_game.state == game.fishing_game.GameState.WAITING_FOR_FISH, "Clicking the goal popup should dismiss it and enter the waiting state")
	check(not game.fishing_game.spawn_timer.is_stopped(), "Starting the round should schedule the first individual fish")
	game.fishing_game.spawn_timer.stop()
	game.fishing_game._process(1.2)
	check(is_equal_approx(game.fishing_game.round_time_remaining, 88.8) and game.fishing_game.stats_labels[0].text == "LEVEL: 1\nTIME: 01:29", "The round timer should count down only after the player closes the goal popup")
	check(game.fishing_game.pause_click_area != null and game.fishing_game.pause_click_area.get_index() < game.fishing_game.catch_hotspot.get_index(), "Fishing should place its full-screen pause click area behind the Catch button")
	var time_before_manual_pause: float = game.fishing_game.round_time_remaining
	game.fishing_game.pause_click_area.emit_signal("pressed")
	check(game.fishing_game.state == game.fishing_game.GameState.PAUSED and game.fishing_game.pause_overlay != null, "Clicking outside Catch should pause an active fishing round")
	check(game.fishing_game.pause_overlay.find_child("PauseCircle", true, false) != null and game.fishing_game.pause_overlay.find_child("PauseBarLeft", true, false) != null and game.fishing_game.pause_overlay.find_child("PauseBarRight", true, false) != null, "Fishing should show the central pause-circle icon")
	var fishing_pause_dimmer = game.fishing_game.pause_overlay.find_child("PauseDimmer", true, false)
	check(fishing_pause_dimmer is ColorRect and fishing_pause_dimmer.color == game.fishing_game.PAUSE_DIMMER_COLOR, "Fishing should use the configured soft pause dimmer")
	game.fishing_game._process(5.0)
	check(is_equal_approx(game.fishing_game.round_time_remaining, time_before_manual_pause), "The fishing countdown must remain frozen while manually paused")
	game.fishing_game.pause_overlay.emit_signal("pressed")
	check(game.fishing_game.state == game.fishing_game.GameState.WAITING_FOR_FISH and game.fishing_game.pause_overlay == null, "Clicking anywhere on the pause overlay should resume the same fishing state")
	check(game.fishing_game.FRAME_DURATIONS.size() == 6, "Fishing should keep a six-frame cooperative lift")
	check(game.fishing_game.NET_FRAME_POSITIONS.size() == 6 and game.fishing_game.PET_FRAME_POSITIONS.size() == 6, "Net and replaceable pet layers should each define six aligned poses")
	check(game.fishing_game.DEFAULT_FISHING_PET_FRAMES.size() == 6, "The default cat should provide six genuinely different lifting poses")
	check(game.fishing_game.net_view.texture == game.fishing_game.NET_HANDS_TEXTURE, "Fishing should use the reusable cat-free net-and-human-hands layer")
	check(game.fishing_game.pet_view.texture == game.fishing_game.DEFAULT_FISHING_PET_FRAMES[0], "Fishing should begin with the paws-at-feet pet frame")
	check(game.fishing_game.net_view.visible, "The dynamic cat and net should be visible on the idle frame")
	check(game.fishing_game.animation_frame_index == 0, "Fishing should begin on cooperative animation frame one")
	check(game.fishing_game.NET_FRAME_POSITIONS[0].y > game.fishing_game.NET_FRAME_POSITIONS[5].y, "Frame one should start at the pet's feet and lift toward frame six")
	check(game.fishing_game.PET_FRAME_POSITIONS.all(func(position): return position.y == game.fishing_game.PET_FRAME_POSITIONS[0].y), "The seated pet should remain anchored on the riverbank while its paws change pose")
	check(game.fishing_game.pet_view.get_index() < game.fishing_game.net_view.get_index(), "The pet body should render behind the net")
	check(game.fishing_game.fish_layer.get_index() > game.fishing_game.net_view.get_index(), "Swimming fish should render above the net artwork")
	var mochi_fishing = load("res://src/fishing_game.gd").new()
	mochi_fishing.configure(
		{"id": "mochi", "name": "Mochi", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(mochi_fishing)
	await process_frame
	check(
		mochi_fishing.pet_id == "mochi"
		and mochi_fishing.pet_view.texture == mochi_fishing.MOCHI_FISHING_DEFAULT_TEXTURE,
		"Mochi should use her approved front-facing seated pose throughout idle fishing"
	)
	check(
		mochi_fishing.MOCHI_FISHING_CRY_FRAMES.size() == 8
		and mochi_fishing.MOCHI_FISHING_SUCCESS_FRAMES.size() == 8
		and mochi_fishing.MOCHI_FISHING_CRY_FRAMES[0] == mochi_fishing.MOCHI_FISHING_DEFAULT_TEXTURE
		and mochi_fishing.MOCHI_FISHING_SUCCESS_FRAMES[0] == mochi_fishing.MOCHI_FISHING_DEFAULT_TEXTURE
		and mochi_fishing.MOCHI_FISHING_SUCCESS_FRAMES[-1] == mochi_fishing.MOCHI_FISHING_DEFAULT_TEXTURE,
		"Mochi's empty-net cry and successful head-tilt smile should transition cleanly from the approved fishing pose"
	)
	check(
		mochi_fishing.MOCHI_FISHING_CRY_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(627, 627)
		)
		and mochi_fishing.MOCHI_FISHING_SUCCESS_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(627, 627)
		),
		"Every Mochi fishing reaction frame should share one fixed canvas so she cannot jump or change size"
	)
	mochi_fishing._start_round_from_goal_popup()
	mochi_fishing.spawn_timer.stop()
	mochi_fishing.state = mochi_fishing.GameState.LIFTING_NET
	var no_caught_fish_views: Array[TextureRect] = []
	await mochi_fishing._play_lift_animation(no_caught_fish_views, false)
	check(
		mochi_fishing.pet_view.texture == mochi_fishing.MOCHI_FISHING_CRY_FRAMES[-1],
		"An empty Mochi net should finish on her tearful expression before the result popup"
	)
	await mochi_fishing._play_lift_animation(no_caught_fish_views, true)
	check(
		mochi_fishing.pet_view.texture == mochi_fishing.MOCHI_FISHING_SUCCESS_FRAMES[-1],
		"A successful Mochi net should finish her head-tilt smile and return to the approved seated pose"
	)
	check(
		mochi_fishing._failure_cat_texture() == mochi_fishing.MOCHI_FISHING_CRY_FRAMES[-1],
		"Mochi's failed-catch popup should continue with her own final crying expression"
	)
	mochi_fishing.queue_free()
	await process_frame
	var biscuit_fishing = load("res://src/fishing_game.gd").new()
	biscuit_fishing.configure(
		{"id": "biscuit", "name": "Biscuit", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(biscuit_fishing)
	await process_frame
	check(
		biscuit_fishing.pet_view.texture == biscuit_fishing.BISCUIT_FISHING_DEFAULT_TEXTURE,
		"Biscuit should sit front-facing behind the net while fishing"
	)
	check(
		biscuit_fishing.BISCUIT_FISHING_WINK_FRAMES.size() == 8
		and biscuit_fishing.BISCUIT_FISHING_WINK_FRAMES[0] == biscuit_fishing.BISCUIT_FISHING_DEFAULT_TEXTURE
		and biscuit_fishing.BISCUIT_FISHING_WINK_FRAMES[-1] == biscuit_fishing.BISCUIT_FISHING_DEFAULT_TEXTURE
		and biscuit_fishing.BISCUIT_FISHING_WINK_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(512, 512)
		),
		"Biscuit's successful catch should have a fixed-size wink sequence that returns to her approved fishing pose"
	)
	check(
		biscuit_fishing._failure_cat_texture() == biscuit_fishing.BISCUIT_FISHING_FAILURE_TEXTURE
		and biscuit_fishing._round_failure_cat_texture() == biscuit_fishing.BISCUIT_FISHING_FAILURE_TEXTURE,
		"Both failed catches and failed rounds should use Biscuit's own disappointed static art"
	)
	biscuit_fishing._apply_animation_frame(5)
	check(
		biscuit_fishing.pet_view.texture == biscuit_fishing.BISCUIT_FISHING_DEFAULT_TEXTURE,
		"Lifting the net should never swap Biscuit to Maple's animation frames"
	)
	biscuit_fishing._start_round_from_goal_popup()
	biscuit_fishing.spawn_timer.stop()
	biscuit_fishing.state = biscuit_fishing.GameState.LIFTING_NET
	await biscuit_fishing._play_lift_animation(no_caught_fish_views, true)
	check(
		biscuit_fishing.pet_view.texture == biscuit_fishing.BISCUIT_FISHING_WINK_FRAMES[-1],
		"Catching at least one fish as Biscuit should play her wink and return to the default fishing pose"
	)
	biscuit_fishing.queue_free()
	await process_frame
	var luna_fishing = load("res://src/fishing_game.gd").new()
	luna_fishing.configure(
		{"id": "luna", "name": "Luna", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(luna_fishing)
	await process_frame
	check(
		luna_fishing.pet_view.texture == luna_fishing.LUNA_FISHING_DEFAULT_TEXTURE,
		"Luna should use her own front-sitting Russian Blue art behind the fishing net"
	)
	check(
		not _texture_lower_half_has_green_chroma(luna_fishing.LUNA_FISHING_DEFAULT_TEXTURE),
		"Luna's front-sitting paws should not retain green-screen pixels"
	)
	check(
		luna_fishing.LUNA_FISHING_SUCCESS_FRAMES.size() == 8
		and luna_fishing.LUNA_FISHING_SUCCESS_FRAMES[0] == luna_fishing.LUNA_FISHING_DEFAULT_TEXTURE
		and luna_fishing.LUNA_FISHING_SUCCESS_FRAMES[-1] == luna_fishing.LUNA_FISHING_DEFAULT_TEXTURE
		and luna_fishing.LUNA_FISHING_SUCCESS_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(512, 512)
		),
		"Luna's successful catch should use an eight-frame fixed-canvas reaction that returns to her fishing pose"
	)
	check(
		luna_fishing.LUNA_FISHING_SUCCESS_FRAMES.all(
			func(frame): return frame.get_image().get_pixel(0, 0).a == 0.0
		),
		"Every Luna success frame should have a transparent keyed background"
	)
	check(
		luna_fishing._failure_cat_texture() == luna_fishing.LUNA_FISHING_FAILURE_TEXTURE
		and luna_fishing._round_failure_cat_texture() == luna_fishing.LUNA_FISHING_FAILURE_TEXTURE,
		"Luna's failed catch and failed round should both use her own sighing static art"
	)
	luna_fishing._apply_animation_frame(5)
	check(
		luna_fishing.pet_view.texture == luna_fishing.LUNA_FISHING_DEFAULT_TEXTURE,
		"Lifting the net should keep Luna's own static pose before her catch reaction"
	)
	luna_fishing._start_round_from_goal_popup()
	luna_fishing.spawn_timer.stop()
	luna_fishing.state = luna_fishing.GameState.LIFTING_NET
	await luna_fishing._play_lift_animation(no_caught_fish_views, true)
	check(
		luna_fishing.pet_view.texture == luna_fishing.LUNA_FISHING_SUCCESS_FRAMES[-1],
		"Catching at least one fish as Luna should play her custom success animation and return to the default pose"
	)
	luna_fishing.queue_free()
	await process_frame
	var poppy_fishing = load("res://src/fishing_game.gd").new()
	poppy_fishing.configure(
		{"id": "poppy", "name": "Poppy", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(poppy_fishing)
	await process_frame
	check(
		poppy_fishing.pet_view.texture == poppy_fishing.POPPY_FISHING_DEFAULT_TEXTURE,
		"Poppy should use her own front-sitting pose behind the fishing net"
	)
	check(
		poppy_fishing.POPPY_FISHING_SUCCESS_FRAMES.size() == 8
		and poppy_fishing.POPPY_FISHING_SUCCESS_FRAMES.all(
			func(frame): return frame.get_size() == Vector2(512, 512)
		),
		"Poppy's successful catch should use the approved eight-frame head-tilt animation"
	)
	check(
		poppy_fishing._failure_cat_texture() == poppy_fishing.POPPY_FISHING_FAILURE_TEXTURE
		and poppy_fishing._round_failure_cat_texture() == poppy_fishing.POPPY_FISHING_FAILURE_TEXTURE,
		"Poppy's failed catch and failed round should use her own static disappointed pose"
	)
	poppy_fishing.queue_free()
	await process_frame
	var black_cat_fishing = load("res://src/fishing_game.gd").new()
	black_cat_fishing.configure(
		{"id": "black_cat", "name": "", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(black_cat_fishing)
	await process_frame
	check(
		black_cat_fishing.pet_view.texture
		== black_cat_fishing.BLACK_CAT_FISHING_DEFAULT_TEXTURE,
		"The black cat should use her front-facing half-lidded pose behind the fishing net"
	)
	check(
		black_cat_fishing.BLACK_CAT_FISHING_SUCCESS_FRAMES.size() == 8
		and black_cat_fishing.BLACK_CAT_FISHING_SUCCESS_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(512, 512)
				and frame.get_image().get_pixel(0, 0).a == 0.0
			)
		),
		"The black cat's successful catch should use eight transparent fixed-canvas paw-lick frames"
	)
	check(
		black_cat_fishing._failure_cat_texture()
		== black_cat_fishing.BLACK_CAT_FISHING_FAILURE_TEXTURE
		and black_cat_fishing._round_failure_cat_texture()
		== black_cat_fishing.BLACK_CAT_FISHING_FAILURE_TEXTURE,
		"The black cat's failed catch and failed round should use her disdainful sigh"
	)
	black_cat_fishing._start_round_from_goal_popup()
	black_cat_fishing.spawn_timer.stop()
	black_cat_fishing.state = black_cat_fishing.GameState.LIFTING_NET
	await black_cat_fishing._play_lift_animation(no_caught_fish_views, true)
	check(
		black_cat_fishing.pet_view.texture
		== black_cat_fishing.BLACK_CAT_FISHING_SUCCESS_FRAMES[-1],
		"Catching a fish as the black cat should finish her proud paw-lick animation"
	)
	black_cat_fishing.queue_free()
	await process_frame
	var maine_coon_fishing = load("res://src/fishing_game.gd").new()
	maine_coon_fishing.configure(
		{"id": "maine_coon", "name": "Cedar", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(maine_coon_fishing)
	await process_frame
	check(
		maine_coon_fishing.pet_view.texture
		== maine_coon_fishing.MAINE_COON_FISHING_DEFAULT_TEXTURE
		and maine_coon_fishing.MAINE_COON_FISHING_DEFAULT_TEXTURE.get_image().get_used_rect().size.x <= 300
		and maine_coon_fishing.MAINE_COON_FISHING_DEFAULT_TEXTURE.get_image().get_used_rect().end.y == 500,
		"The Maine Coon should always use her grounded, shadow-free front-sitting pose behind the fishing net"
	)
	check(
		maine_coon_fishing.MAINE_COON_FISHING_SUCCESS_FRAMES.size() == 8
		and maine_coon_fishing.MAINE_COON_FISHING_SUCCESS_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(512, 512)
				and frame.get_image().get_pixel(0, 0).a == 0.0
			)
		),
		"The Maine Coon's successful catch should use eight transparent fixed-canvas victory-wave frames"
	)
	check(
		maine_coon_fishing._failure_cat_texture()
		== maine_coon_fishing.MAINE_COON_FISHING_FAILURE_TEXTURE
		and maine_coon_fishing._round_failure_cat_texture()
		== maine_coon_fishing.MAINE_COON_FISHING_FAILURE_TEXTURE,
		"The Maine Coon's failed catch and failed round should use her closed-eyes face-paw pose"
	)
	maine_coon_fishing._start_round_from_goal_popup()
	maine_coon_fishing.spawn_timer.stop()
	maine_coon_fishing.state = maine_coon_fishing.GameState.LIFTING_NET
	await maine_coon_fishing._play_lift_animation(no_caught_fish_views, true)
	check(
		maine_coon_fishing.pet_view.texture
		== maine_coon_fishing.MAINE_COON_FISHING_SUCCESS_FRAMES[-1],
		"Catching a fish as the Maine Coon should finish her proud paw-wave animation"
	)
	maine_coon_fishing.queue_free()
	await process_frame
	var golden_munchkin_fishing = load("res://src/fishing_game.gd").new()
	golden_munchkin_fishing.configure(
		{"id": "golden_munchkin", "name": "Honey", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(golden_munchkin_fishing)
	await process_frame
	check(
		golden_munchkin_fishing.pet_view.texture
		== golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_DEFAULT_TEXTURE
		and not _walk_has_unsupported_floor_shadow(
			golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_DEFAULT_TEXTURE
		),
		"The Golden Munchkin should use her shadow-free front-sitting pose behind the fishing net"
	)
	check(
		golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_SUCCESS_FRAMES.size() == 8
		and golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_SUCCESS_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(512, 512)
				and frame.get_image().get_pixel(0, 0).a == 0.0
				and not _walk_has_unsupported_floor_shadow(frame)
			)
		),
		"The Golden Munchkin's successful catch should use eight shadow-free transparent fixed-canvas fish-hug frames"
	)
	check(
		golden_munchkin_fishing._failure_cat_texture()
		== golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_FAILURE_TEXTURE
		and golden_munchkin_fishing._round_failure_cat_texture()
		== golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_FAILURE_TEXTURE
		and not _walk_has_unsupported_floor_shadow(
			golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_FAILURE_TEXTURE
		),
		"The Golden Munchkin's failed catch and failed round should use her shadow-free teary static pose"
	)
	golden_munchkin_fishing._start_round_from_goal_popup()
	golden_munchkin_fishing.spawn_timer.stop()
	golden_munchkin_fishing.state = golden_munchkin_fishing.GameState.LIFTING_NET
	await golden_munchkin_fishing._play_lift_animation(no_caught_fish_views, true)
	check(
		golden_munchkin_fishing.pet_view.texture
		== golden_munchkin_fishing.GOLDEN_MUNCHKIN_FISHING_SUCCESS_FRAMES[-1],
		"Catching a fish as the Golden Munchkin should finish her fish-hug animation"
	)
	golden_munchkin_fishing.queue_free()
	await process_frame
	var siamese_fishing = load("res://src/fishing_game.gd").new()
	siamese_fishing.configure(
		{"id": "siamese", "name": "Pearl", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"]}
	)
	root.add_child(siamese_fishing)
	await process_frame
	check(
		siamese_fishing.pet_view.texture
		== siamese_fishing.SIAMESE_FISHING_DEFAULT_TEXTURE,
		"The Siamese should use her approved front-facing pose behind the fishing net"
	)
	check(
		siamese_fishing.SIAMESE_FISHING_SUCCESS_FRAMES.size() == 8
		and siamese_fishing.SIAMESE_FISHING_SUCCESS_FRAMES.all(
			func(frame): return (
				frame.get_size() == Vector2(512, 512)
				and frame.get_image().get_pixel(0, 0).a == 0.0
			)
		),
		"The Siamese successful catch should use eight transparent fixed-canvas tail-wag frames"
	)
	check(
		siamese_fishing._failure_cat_texture()
		== siamese_fishing.SIAMESE_FISHING_FAILURE_TEXTURE
		and siamese_fishing._round_failure_cat_texture()
		== siamese_fishing.SIAMESE_FISHING_FAILURE_TEXTURE,
		"The Siamese failed catch and failed round should use her approved static disappointed pose"
	)
	siamese_fishing._start_round_from_goal_popup()
	siamese_fishing.spawn_timer.stop()
	siamese_fishing.state = siamese_fishing.GameState.LIFTING_NET
	await siamese_fishing._play_lift_animation(no_caught_fish_views, true)
	check(
		siamese_fishing.pet_view.texture
		== siamese_fishing.SIAMESE_FISHING_SUCCESS_FRAMES[-1],
		"Catching a fish as the Siamese should finish her tail-wag and pleased head tilt"
	)
	siamese_fishing.queue_free()
	await process_frame
	check(not game.fishing_game.stats_panel is PanelContainer and game.fishing_game.stats_panel.size == game.fishing_game.STATS_PANEL_SIZE, "Fishing statistics should use an independently movable textured panel group")
	check(game.fishing_game.stats_panel.position == game.fishing_game.STATS_PANEL_POSITION and game.fishing_game.stats_panel.find_child("StatsPanelFrame", true, false).texture == game.fishing_game.STATS_PANEL_TEXTURE, "The statistics frame and its text should share the editable Stats panel position")
	check(game.fishing_game.fish_guide_panel.position == game.fishing_game.FISH_TYPES_PANEL_POSITION and game.fishing_game.fish_guide_panel.find_child("FishTypesPanelFrame", true, false).texture == game.fishing_game.FISH_TYPES_PANEL_TEXTURE, "The goal-tracker frame, fish icons, and live counts should move as one group")
	check(game.fishing_game.heart_panel.position == game.fishing_game.HEART_PANEL_POSITION and game.fishing_game.heart_panel.find_child("HeartPanelFrame", true, false).texture == game.fishing_game.HEART_PANEL_TEXTURE, "The heart frame, hearts, and countdown should move as one group")
	check(game.fishing_game.heart_views.filter(func(heart): return heart.visible).size() == 5 and game.fishing_game.heart_timer_label.text == "", "Fishing should show five hearts in the upper-right frame")
	check(game.fishing_game.heart_views.all(func(heart): return heart.size == Vector2(34, 34) and heart.position.y >= 18.0 and heart.position.y + heart.size.y <= game.fishing_game.HEART_PANEL_SIZE.y), "Fishing hearts should fit inside the independently movable heart frame")
	check(
		game.fishing_game.catch_hotspot.text == "CATCH!"
		and game.fishing_game.catch_hotspot.get_theme_font("font") == GameFontStylesScript.BUTTON_FONT,
		"The fishing action should replace the baked mixed-case word with an editable uppercase original-font button"
	)
	game.fishing_game.catch_hotspot.disabled = true
	var disabled_catch_style = game.fishing_game.catch_hotspot.get_theme_stylebox("disabled")
	check(
		disabled_catch_style is StyleBoxFlat
		and disabled_catch_style.bg_color.a == 1.0
		and disabled_catch_style.corner_radius_top_left == 31,
		"The disabled Catch button should stay opaque and fully cover the legacy baked label"
	)
	game.fishing_game.catch_hotspot.disabled = false
	var planned_spawn_ids: Array[String] = game.fishing_game.round_spawn_sequence.duplicate()
	check(
		planned_spawn_ids.size() == game.fishing_game.round_total_spawn_count
		and game.fishing_game.round_total_spawn_count == ceili(
			float(game.fishing_game.round_required_fish_total)
			* game.fishing_game.round_spawn_total_multiplier
		),
		"Each fishing round should apply one multiplier to its complete finite fish total"
	)
	check(
		planned_spawn_ids.all(func(fish_id): return game.fishing_game.round_spawn_fish_ids.has(fish_id)),
		"The finite spawn plan should only use species available on the current campaign level"
	)
	for planned_goal in game.fishing_game.round_goals:
		var planned_goal_id := str(planned_goal.fish_id)
		check(
			int(game.fishing_game.round_planned_spawn_counts.get(planned_goal_id, 0))
			>= FishingLevelCatalogScript.guaranteed_target_spawn_count(int(planned_goal.count)),
			"Every target species should receive a rounded-up 1.2-times guaranteed quota"
		)
	check(
		game.fishing_game.round_spawn_times.size() == game.fishing_game.round_spawn_sequence.size()
		and game.fishing_game.round_spawn_times.front() >= game.fishing_game.FIRST_FISH_SPAWN_TIME_SECONDS
		and game.fishing_game.round_spawn_times.back() <= float(game.fishing_game.round_time_limit_seconds),
		"Every fish in the finite total should have its own in-round gameplay timestamp"
	)
	if not game.fishing_game.round_spawn_times.is_empty():
		var final_spawn_time := minf(
			float(game.fishing_game.round_time_limit_seconds)
				* game.fishing_game.FINAL_FISH_SPAWN_TIME_FRACTION,
			float(game.fishing_game.round_time_limit_seconds)
				- game.fishing_game.FINAL_FISH_SPAWN_MIN_REMAINING_SECONDS
		)
		var spawn_window: float = final_spawn_time - game.fishing_game.FIRST_FISH_SPAWN_TIME_SECONDS
		var slot_duration: float = spawn_window / float(game.fishing_game.round_spawn_times.size())
		for spawn_time_index in range(game.fishing_game.round_spawn_times.size()):
			var slot_start: float = (
				game.fishing_game.FIRST_FISH_SPAWN_TIME_SECONDS
				+ slot_duration * float(spawn_time_index)
			)
			var planned_time: float = game.fishing_game.round_spawn_times[spawn_time_index]
			check(
				planned_time >= slot_start + slot_duration * game.fishing_game.SPAWN_SLOT_RANDOM_MIN
				and planned_time <= slot_start + slot_duration * game.fishing_game.SPAWN_SLOT_RANDOM_MAX,
				"Each fish should receive a randomized time inside its own evenly distributed slot"
			)
			if spawn_time_index > 0:
				check(
					planned_time > game.fishing_game.round_spawn_times[spawn_time_index - 1],
					"Individual fish spawn times should stay strictly ordered without synchronous groups"
				)
	var spawn_plan_probe = load("res://src/fishing_game.gd").new()
	var representative_plan_has_non_goal_fish := false
	for representative_level in [1, 60, 120, 200, 300, 450, 451]:
		spawn_plan_probe.rng.seed = representative_level
		spawn_plan_probe.current_level = representative_level
		spawn_plan_probe._load_round_configuration()
		var probe_count_total := 0
		for species_count in spawn_plan_probe.round_planned_spawn_counts.values():
			probe_count_total += int(species_count)
		check(
			spawn_plan_probe.round_spawn_sequence.size() == spawn_plan_probe.round_total_spawn_count
			and spawn_plan_probe.round_spawn_times.size() == spawn_plan_probe.round_total_spawn_count
			and probe_count_total == spawn_plan_probe.round_total_spawn_count,
			"Level %d should preserve its exact precomputed fish total after removing waves" % representative_level
		)
		var probe_goal_ids: Array[String] = []
		for probe_goal in spawn_plan_probe.round_goals:
			var probe_goal_id := str(probe_goal.fish_id)
			probe_goal_ids.append(probe_goal_id)
			check(
				int(spawn_plan_probe.round_planned_spawn_counts.get(probe_goal_id, 0))
					>= FishingLevelCatalogScript.guaranteed_target_spawn_count(int(probe_goal.count)),
				"Level %d should reserve the rounded-up 1.2-times quota for every target species" % representative_level
			)
		var expected_probe_total := ceili(
			float(spawn_plan_probe.round_required_fish_total)
			* spawn_plan_probe.round_spawn_total_multiplier
		)
		check(
			spawn_plan_probe.round_total_spawn_count == expected_probe_total
			and spawn_plan_probe.round_spawn_sequence.all(
				func(fish_id): return spawn_plan_probe.round_spawn_fish_ids.has(fish_id)
			),
			"Level %d should use one total multiplier and draw only from its available fish pool" % representative_level
		)
		if spawn_plan_probe.round_spawn_sequence.any(
			func(fish_id): return not probe_goal_ids.has(fish_id)
		):
			representative_plan_has_non_goal_fish = true
		for probe_time_index in range(1, spawn_plan_probe.round_spawn_times.size()):
			check(
				spawn_plan_probe.round_spawn_times[probe_time_index]
					> spawn_plan_probe.round_spawn_times[probe_time_index - 1],
					"Level %d should use a strictly ordered individual-fish schedule" % representative_level
				)
	check(
		representative_plan_has_non_goal_fish,
		"Expanded round totals should keep non-goal fish in the shared available-fish pool"
	)
	spawn_plan_probe.free()
	var fishing_buttons: Array[Node] = game.fishing_game.find_children("*", "Button", true, false)
	var home_button = fishing_buttons.filter(func(button): return button.text == "← HOME").front()
	check(home_button.position.y >= game.fishing_game.STATS_PANEL_POSITION.y + 125.0, "The Home button should sit below the visible upper-left statistics frame")
	check(game.fishing_game.NET_FRAME_POSITIONS[0].x + game.fishing_game.NET_FRAME_SIZES[0].x < game.fishing_game.catch_hotspot.position.x, "The fishing animation should stop before the Catch button")
	var next_spawn_index_before_manual_spawn: int = game.fishing_game.next_spawn_index
	game.fishing_game._spawn_fish()
	check(
		game.fishing_game.active_fish.size() == 1
		and game.fishing_game.next_spawn_index == next_spawn_index_before_manual_spawn + 1,
		"Each spawn event should add exactly one fish instead of a synchronized group"
	)
	game.fishing_game._spawn_fish()
	check(
		game.fishing_game.active_fish.size() == 2,
		"The next scheduled fish may enter while an earlier fish is still swimming"
	)
	check(game.fishing_game.active_fish.all(func(entry): return entry.view.scale.x < 0.0), "Every fish moving left-to-right should be flipped to face right")
	check(game.fishing_game.active_fish.all(func(entry): return entry.view.position.y >= game.fishing_game.RIVER_SWIM_MIN_Y and entry.view.position.y <= game.fishing_game.RIVER_SWIM_MAX_Y), "Every fish should stay inside the river lane")
	var fish_position_before_pause: Vector2 = game.fishing_game.active_fish[0].view.position
	game.fishing_game._pause_game()
	await create_timer(0.08).timeout
	check(game.fishing_game.active_fish[0].view.position.is_equal_approx(fish_position_before_pause), "Swimming fish should remain completely still while fishing is paused")
	game.fishing_game.pause_overlay.emit_signal("pressed")
	check(game.fishing_game._swimming_fish_size(game.fishing_game.FISH_TYPES[0]) == Vector2(47.5, 30) and game.fishing_game._swimming_fish_size(game.fishing_game.FISH_TYPES[1]) == Vector2(62, 56) and game.fishing_game._swimming_fish_size(game.fishing_game.FISH_TYPES[2]) == Vector2(138, 65), "Green Fish should swim at half size and Coral Angelfish at two-thirds size without changing Golden Ribbonfish")
	var mint_catfish: Dictionary = FishCatalogScript.definition("mint_catfish")
	var mint_catfish_visual = game.fishing_game._make_fish_visual(
		mint_catfish,
		game.fishing_game._swimming_fish_size(mint_catfish)
	)
	check(
		game.fishing_game._swimming_fish_size(mint_catfish) == Vector2(102.9, 50.89)
		and mint_catfish_visual.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		and mint_catfish_visual.material is ShaderMaterial,
		"Mint Catfish should preserve the selected long-body art and render through the solid-opacity material"
	)
	check(
		mint_catfish.texture.resource_path.ends_with("mint_catfish_v2.png")
		and mint_catfish.texture_region == Rect2(57, 139, 1438, 711),
		"Mint Catfish should use the exact user-selected transparent sprite and its trimmed fish bounds"
	)
	mint_catfish_visual.free()
	var pink_salmon: Dictionary = FishCatalogScript.definition("pink_salmon")
	var pink_salmon_used_rect: Rect2i = pink_salmon.texture.get_image().get_used_rect()
	var pink_salmon_goal_visual = game.fishing_game._make_fish_visual(
		pink_salmon,
		game.fishing_game.GOAL_TRACKER_FISH_SIZES[0],
		"goal_texture_region"
	)
	check(
		game.fishing_game._swimming_fish_size(pink_salmon) == Vector2(204.75, 120.9)
		and pink_salmon.texture.resource_path.ends_with("pink_salmon_v2.png")
		and float(pink_salmon_used_rect.size.x) / pink_salmon_used_rect.size.y > 2.4,
		"Pink Salmon should use the longer salmon silhouette and swim at 1.5 times its previous tuned size"
	)
	check(
		pink_salmon_goal_visual.texture is AtlasTexture
		and pink_salmon_goal_visual.texture.get_size() == Vector2(1152, 460),
		"Pink Salmon goal icons should trim the square canvas so the fish fills its goal box"
	)
	pink_salmon_goal_visual.free()
	var red_white_koi: Dictionary = FishCatalogScript.definition("red_white_koi")
	var red_white_koi_used_rect: Rect2i = red_white_koi.texture.get_image().get_used_rect()
	check(
		game.fishing_game._swimming_fish_size(red_white_koi) == Vector2(136.5, 81.9)
		and red_white_koi.texture.resource_path.ends_with("red_white_koi_v2.png")
		and float(red_white_koi_used_rect.size.y) / red_white_koi_used_rect.size.x > 0.6,
		"Red White Koi should use the plumper silhouette and swim at exactly 1.3 times its former size"
	)
	check(not game.fishing_game.is_fish_in_catch_zone(), "A fish entering from the left should begin outside the net")
	var first_fish_entry: Dictionary = game.fishing_game.active_fish[0]
	var first_fish_view: TextureRect = first_fish_entry.view
	first_fish_view.position = game.fishing_game.NET_CATCH_ZONE.get_center() - first_fish_view.size * 0.5
	check(game.fishing_game.is_fish_in_catch_zone(first_fish_entry), "Any fish centered inside the net should be catchable")
	check(is_equal_approx(game.fishing_game.round_catch_success_chance, 0.98), "Level one should begin with a two-percent escape chance")
	check(game.fishing_game.catch_succeeds(true, game.fishing_game.round_catch_success_chance - 0.01), "A fish inside the net should succeed below the current level's tuned catch threshold")
	check(not game.fishing_game.catch_succeeds(true, game.fishing_game.round_catch_success_chance), "A fish inside the net should fail at the current level's tuned catch threshold")
	check(not game.fishing_game.catch_succeeds(false, 0.0), "A fish outside the net should always fail")
	game.fishing_game.resolve_catch_for_test(true, 0)
	check(
		game.fishing_game.success_sound_player.playing
		and not game.fishing_game.failure_sound_player.playing,
		"A successful catch should play only Tiny Splash and never the fishing failure sound"
	)
	check(game.fishing_game.fish_caught == 1, "Casting should catch one fish")
	check(int(game.fishing_game.round_goal_counts.get("green", 0)) == 1, "Catching Green Fish should update the level-one Green Fish target")
	check(int(game.get_progress_stats().experience) == xp_before_fishing and game.fishing_game.xp_earned == 0, "Catching an individual fish should not award XP")
	check(game.fishing_game.result_overlay != null and game.fishing_game.result_overlay.name == "FishingCatchPopupOverlay", "A previously discovered Green Fish should go directly to the catch summary without another unlock popup")
	check(game.get_progress_stats().unlocked_fish_ids == ["green"], "An existing save should retain its discovered Green Fish")
	var catch_popup_background = game.fishing_game.result_overlay.find_child("FishingCatchPopupBackground", true, false)
	var catch_popup_title = game.fishing_game.result_overlay.find_child("FishingCatchPopupTitle", true, false)
	var catch_popup_footer = game.fishing_game.result_overlay.find_child("FishingCatchPopupFooter", true, false)
	check(catch_popup_background is TextureRect and catch_popup_background.texture == game.fishing_game.CATCH_POPUP_TEXTURE, "The live catch popup should keep its background separate from fish and text")
	check(catch_popup_title.text == "YOU CAUGHT:" and catch_popup_footer.text == "CLICK ANYWHERE TO CONTINUE", "The live catch popup should show the approved title and continue prompt")
	check(game.fishing_game.catch_popup_fish_views.size() == 1 and game.fishing_game.catch_popup_count_labels.size() == 1 and game.fishing_game.catch_popup_count_labels[0].text == "X 1", "A single caught fish type should create exactly one catch row")
	var green_popup_size: Vector2 = game.fishing_game._catch_popup_fish_size(
		FishCatalogScript.definition("green")
	)
	var yellow_popup_size: Vector2 = game.fishing_game._catch_popup_fish_size(
		FishCatalogScript.definition("yellow_striped")
	)
	check(
		green_popup_size == yellow_popup_size * 0.5
		and game.fishing_game.catch_popup_fish_views[0].size == green_popup_size
		and game.fishing_game.catch_popup_fish_views[0].position
			== game.fishing_game.CATCH_POPUP_FISH_POSITIONS[0]
			+ (game.fishing_game.CATCH_POPUP_FISH_SIZE - green_popup_size) * 0.5,
		"The tightly cropped Green Fish should be half-scale and centered so its visible catch-popup size matches Yellow Striped Fish"
	)
	game.fishing_game._pause_game()
	check(game.fishing_game.state == game.fishing_game.GameState.SHOWING_RESULT and game.fishing_game.pause_overlay == null, "Fishing should ignore pause requests while a result popup is already open")
	check(game.fishing_game.stats_panel.visible, "Fishing totals should remain embedded in the background while a popup is open")
	var fishing_scene_view: Control = game.fishing_game.get_node("FishingView")
	check(
		fishing_scene_view.is_ancestor_of(game.fishing_game.stats_panel)
		and not game.fishing_game.result_overlay.is_ancestor_of(game.fishing_game.stats_panel),
		"The statistics panel must remain in the scene-backed HUD, not become part of the popup"
	)
	check(
		game.fishing_game.result_overlay.get_parent() == game.fishing_game
		and game.fishing_game.result_overlay.get_index() > fishing_scene_view.get_index(),
		"The popup must render above the scene-backed fishing view"
	)
	check(game.fishing_game.main_background_view.texture == game.fishing_game.MAIN_SCREEN_TEXTURE, "Opening a popup must keep the normal fishing background")
	var popup_stat_labels: Array[Node] = game.fishing_game.result_overlay.find_children("*", "Label", true, false).filter(func(label): return label.text.begins_with("LEVEL:"))
	check(popup_stat_labels.is_empty(), "Result popups should not create a second statistics box")
	var time_before_paused_popup: float = game.fishing_game.round_time_remaining
	game.fishing_game._process(5.0)
	check(is_equal_approx(game.fishing_game.round_time_remaining, time_before_paused_popup), "The round countdown should pause while a catch-result popup is open")
	game.fishing_game._dismiss_result()
	check(game.fishing_game.stats_panel.visible, "Fishing totals should still be visible after closing the popup")
	check(game.fishing_game.net_view.visible and game.fishing_game.animation_frame_index == 0, "Returning from a result should restore cooperative animation frame one")
	var xp_before_batch := int(game.get_progress_stats().experience)
	game.fishing_game.resolve_catch_batch_for_test([0, 1, 2])
	check(game.fishing_game.fish_caught == 4 and game.fishing_game.xp_earned == 0, "One net should catch multiple fish without granting per-fish XP")
	check(int(game.fishing_game.round_goal_counts.get("green", 0)) == 2 and not game.fishing_game.round_goal_counts.has("coral") and not game.fishing_game.round_goal_counts.has("golden"), "Only the Green Fish target count should update on level one")
	check(game.fishing_game.result_overlay.name == "FishingNewFishPopupOverlay" and game.fishing_game.pending_new_fish_unlocks.size() == 1, "The first caught Coral and Golden fish should each queue a new-fish popup")
	check(game.get_progress_stats().unlocked_fish_ids.size() == 3, "First catches should immediately persist Coral and Golden as discovered fish")
	game.fishing_game.result_overlay.emit_signal("pressed")
	check(game.fishing_game.result_overlay.name == "FishingNewFishPopupOverlay" and game.fishing_game.pending_new_fish_unlocks.is_empty(), "The second newly discovered level-one fish should receive its own popup")
	game.fishing_game.result_overlay.emit_signal("pressed")
	check(game.fishing_game.result_overlay.name == "FishingCatchPopupOverlay", "New-fish popups should lead into the normal catch summary")
	check(game.fishing_game.catch_popup_fish_views.size() == 3 and game.fishing_game.catch_popup_count_labels.all(func(label): return label.text == "X 1"), "A catch containing three species should show three vertical live rows")
	check(game.get_progress_stats().unlocked_fish_ids.size() == 3, "The discovered fish collection should remain duplicate-free after repeated catches")
	var repeated_catch_fishes: Array[Dictionary] = [
		game.fishing_game.FISH_TYPES[0].duplicate(true),
		game.fishing_game.FISH_TYPES[0].duplicate(true),
		game.fishing_game.FISH_TYPES[1].duplicate(true)
	]
	var aggregated_catch_rows: Array[Dictionary] = game.fishing_game._aggregate_caught_fishes(
		repeated_catch_fishes
	)
	check(aggregated_catch_rows.size() == 2 and int(aggregated_catch_rows[0].count) == 2 and int(aggregated_catch_rows[1].count) == 1, "Repeated fish of the same species should combine into one X N catch row")
	check(int(game.get_progress_stats().experience) == xp_before_batch, "A multi-fish catch should leave shared XP unchanged until the level is completed")
	var first_goal_fish_id := str(game.fishing_game.round_goals[0].fish_id)
	var first_goal_fish: Dictionary = FishCatalogScript.definition(first_goal_fish_id)
	var extra_first_goal_fish: Array[Dictionary] = []
	for extra_index in range(20):
		extra_first_goal_fish.append(first_goal_fish.duplicate(true))
	game.fishing_game._record_round_goal_catches(extra_first_goal_fish)
	var first_goal_required_count := int(game.fishing_game.round_goals[0].count)
	check(int(game.fishing_game.round_goal_counts[first_goal_fish_id]) == first_goal_required_count, "A completed goal numerator should stop at its required total")
	check(game.fishing_game.goal_progress_labels[0].text.contains(game.fishing_game.GOAL_PROGRESS_COMPLETE_COLOR_HEX) and game.fishing_game.goal_progress_labels[0].text.contains("%d/%d" % [first_goal_required_count, first_goal_required_count]) and not game.fishing_game.goal_progress_labels[0].text.contains(game.fishing_game.GOAL_PROGRESS_UNMET_COLOR_HEX), "A completed goal should render the full capped fraction in green")
	game.fishing_game.round_goal_counts[first_goal_fish_id] = 0
	game.fishing_game._update_goal_tracker()
	game.fishing_game._dismiss_result()
	var future_fish := {"id": "future_lionfish", "name": "Lionfish"}
	var future_fishes: Array[Dictionary] = [future_fish]
	game.fishing_game.pending_new_fish_unlocks = game.fishing_game._register_new_fish_unlocks(future_fishes)
	game.fishing_game.pending_catch_result_fishes.append(game.fishing_game.FISH_TYPES[0].duplicate(true))
	game.fishing_game._emit_shared_stats_changed()
	game.fishing_game.state = game.fishing_game.GameState.SHOWING_RESULT
	game.fishing_game._show_next_catch_popup()
	var new_fish_popup_background = game.fishing_game.result_overlay.find_child("FishingNewFishPopupBackground", true, false)
	var new_fish_popup_title = game.fishing_game.result_overlay.find_child("FishingNewFishPopupTitle", true, false)
	var new_fish_popup_subtitle = game.fishing_game.result_overlay.find_child("FishingNewFishPopupSubtitle", true, false)
	var new_fish_popup_footer = game.fishing_game.result_overlay.find_child("FishingNewFishPopupFooter", true, false)
	check(new_fish_popup_background is TextureRect and new_fish_popup_background.texture == game.fishing_game.SUCCESS_POPUP_TEXTURE, "A genuinely new future fish should use the separate ray-and-confetti unlock background")
	check(new_fish_popup_title.text == "CONGRATULATIONS!" and new_fish_popup_subtitle.text == "YOU UNLOCKED:" and new_fish_popup_footer.text == "CLICK ANYWHERE TO CONTINUE", "The future new-fish popup should show the approved live text")
	check(new_fish_popup_title.get_theme_constant("shadow_offset_y") > 0 and new_fish_popup_subtitle.get_theme_constant("shadow_offset_y") == 0 and new_fish_popup_footer.get_theme_constant("shadow_offset_y") == 0, "Only the new-fish Congratulations title should keep a text shadow")
	check(game.get_progress_stats().unlocked_fish_ids.has("future_lionfish"), "A genuinely new future fish should be persisted after discovery")
	game.fishing_game.result_overlay.emit_signal("pressed")
	check(game.fishing_game.result_overlay.name == "FishingCatchPopupOverlay", "A genuinely new fish popup should still lead into the catch summary")
	game.fishing_game._dismiss_result()
	game.fishing_game._spawn_fish()
	var animated_entry: Dictionary = game.fishing_game.active_fish[0]
	var animated_view: TextureRect = animated_entry.view
	animated_view.position = game.fishing_game.NET_CATCH_ZONE.get_center() - animated_view.size * 0.5
	game.fishing_game.request_catch()
	await create_timer(0.05).timeout
	var lift_frame_before_pause: int = game.fishing_game.animation_frame_index
	var lift_time_before_pause: float = game.fishing_game.round_time_remaining
	game.fishing_game._pause_game()
	check(game.fishing_game.state == game.fishing_game.GameState.PAUSED and game.fishing_game.state_before_pause == game.fishing_game.GameState.LIFTING_NET, "Clicking outside Catch during the lift should pause and remember the lifting state")
	await create_timer(0.18).timeout
	check(game.fishing_game.animation_frame_index == lift_frame_before_pause and is_equal_approx(game.fishing_game.round_time_remaining, lift_time_before_pause), "The net animation and countdown should both freeze during a mid-lift pause")
	game.fishing_game.pause_overlay.emit_signal("pressed")
	await create_timer(1.15).timeout
	check(game.fishing_game.state == game.fishing_game.GameState.SHOWING_RESULT, "The real Catch flow should finish on a result screen")
	check(game.fishing_game.animation_frame_index == 5, "The lift animation should finish on frame six")
	check(game.fishing_game.pet_view.texture == game.fishing_game.DEFAULT_FISHING_PET_FRAMES[5], "Frame six should use the opposite tilted, closed-eye happy pet pose")
	check(game.fishing_game.result_overlay != null, "The animated Catch flow should show success or failure")
	var time_during_animated_popup: float = game.fishing_game.round_time_remaining
	game.fishing_game._process(3.0)
	check(is_equal_approx(game.fishing_game.round_time_remaining, time_during_animated_popup), "Every fishing result popup should pause the countdown until the player returns")
	game.fishing_game._dismiss_result()
	for unfinished_goal in game.fishing_game.round_goals:
		game.fishing_game.round_goal_counts[str(unfinished_goal.fish_id)] = 0
	game.fishing_game._update_goal_tracker()
	game.fishing_game.round_time_remaining = 0.1
	game.fishing_game.state = game.fishing_game.GameState.WAITING_FOR_FISH
	game.fishing_game._process(0.2)
	check(game.fishing_game.state == game.fishing_game.GameState.ROUND_ENDED and game.fishing_game.catch_hotspot.disabled and game.fishing_game.stats_labels[0].text == "LEVEL: 1\nTIME: 00:00", "Time reaching zero should end the round and disable Catch")
	check(not game.fishing_game._round_goals_completed() and game.fishing_game.result_is_round_end, "An expired round with missing target fish should fail its final goal check")
	var failed_round_background = game.fishing_game.result_overlay.find_child("FishingResultPopupBackground", true, false)
	var failed_round_home_button: Button = game.fishing_game.result_overlay.find_child(
		"FishingRoundFailureHomeButton",
		true,
		false
	)
	var failed_round_retry_button: Button = game.fishing_game.result_overlay.find_child(
		"FishingRoundFailureRetryButton",
		true,
		false
	)
	check(
		failed_round_background.texture == game.fishing_game.FAILURE_POPUP_TEXTURE
		and game.fishing_game.result_overlay.find_child("FishingRoundFailureCat", true, false) != null
		and failed_round_home_button != null
		and failed_round_home_button.text == "GO HOME"
		and failed_round_retry_button != null
		and failed_round_retry_button.text == "TRY AGAIN",
		"A failed final goal check should show the crying cat with Go Home and Try Again actions"
	)
	check(
		game.fishing_game.hearts == 4
		and game.fishing_game.round_failure_retry_pending
		and game.fishing_game.current_level_retry_count == 1
		and is_equal_approx(game.fishing_game.round_catch_success_chance, 1.0)
		and int(game.get_progress_stats().fishing_retry_level) == 1
		and int(game.get_progress_stats().fishing_retry_count) == 1,
		"Failing level one should consume one heart, persist one retry, and reduce its two-percent escape chance to zero"
	)
	game.fishing_game._spawn_fish()
	check(game.fishing_game.active_fish.is_empty(), "No new fish should spawn after the round timer reaches zero")
	failed_round_retry_button.emit_signal("pressed")
	check(
		game.fishing_game.state == game.fishing_game.GameState.SHOWING_GOALS
		and game.fishing_game.goal_popup_overlay != null
		and game.fishing_game.current_level == 1
		and game.fishing_game.round_goal_counts.values().all(func(count): return int(count) == 0),
		"Clicking a failed level with hearts remaining should reset that same level and reopen its goal popup"
	)

	var no_hearts_fishing = load("res://src/fishing_game.gd").new()
	no_hearts_fishing.configure(
		{"id": "mochi", "name": "Mochi", "type": "Cat"},
		{"experience": 0, "unlocked_fish_ids": ["green"], "hearts": 1}
	)
	root.add_child(no_hearts_fishing)
	await process_frame
	no_hearts_fishing._start_round_from_goal_popup()
	no_hearts_fishing.spawn_timer.stop()
	for no_heart_goal in no_hearts_fishing.round_goals:
		no_hearts_fishing.round_goal_counts[str(no_heart_goal.fish_id)] = 0
	no_hearts_fishing._end_round()
	var mochi_failed_cat: TextureRect = no_hearts_fishing.result_overlay.find_child(
		"FishingRoundFailureCat",
		true,
		false
	)
	check(
		no_hearts_fishing.hearts == 0
		and mochi_failed_cat.texture == no_hearts_fishing.MOCHI_FISHING_FAILURE_STATIC_TEXTURE
		and no_hearts_fishing.MOCHI_FISHING_FAILURE_STATIC_TEXTURE.get_image().get_used_rect().position.x > 0,
		"Mochi's level-failure popup should use the complete-tail static crying illustration and consume the last heart"
	)
	var no_hearts_retry_button: Button = no_hearts_fishing.result_overlay.find_child(
		"FishingRoundFailureRetryButton",
		true,
		false
	)
	no_hearts_retry_button.emit_signal("pressed")
	check(
		no_hearts_fishing.result_overlay.name == "FishingNoHeartsPopupOverlay"
		and no_hearts_fishing.no_hearts_countdown_label.text.begins_with("PLEASE TRY AGAIN IN "),
		"Trying again without a heart should open the live heart-restoration countdown popup"
	)
	no_hearts_fishing.queue_free()
	await process_frame

	var retry_assist_fishing = load("res://src/fishing_game.gd").new()
	retry_assist_fishing.configure(
		{},
		{
			"fishing_level": 450,
			"fishing_retry_level": 450,
			"fishing_retry_count": 2,
			"unlocked_fish_ids": ["green"]
		}
	)
	root.add_child(retry_assist_fishing)
	await process_frame
	check(
		retry_assist_fishing.current_level_retry_count == 2
		and is_equal_approx(retry_assist_fishing.round_catch_success_chance, 0.91)
		and retry_assist_fishing.round_retry_target_spawn_bonus_per_goal == 0,
		"Two persisted retries on level 450 should reduce escape chance from fifteen to nine percent"
	)
	retry_assist_fishing.queue_free()
	await process_frame

	var retry_spawn_assist_fishing = load("res://src/fishing_game.gd").new()
	retry_spawn_assist_fishing.configure(
		{},
		{
			"fishing_level": 450,
			"fishing_retry_level": 450,
			"fishing_retry_count": 6,
			"unlocked_fish_ids": ["green"]
		}
	)
	root.add_child(retry_spawn_assist_fishing)
	await process_frame
	var retry_spawn_base_total := ceili(
		float(retry_spawn_assist_fishing.round_required_fish_total)
		* retry_spawn_assist_fishing.round_spawn_total_multiplier
	)
	var all_retry_targets_receive_bonus := true
	for retry_goal in retry_spawn_assist_fishing.round_goals:
		var retry_goal_spawn_count := int(
			retry_spawn_assist_fishing.round_planned_spawn_counts.get(
				str(retry_goal.fish_id),
				0
			)
		)
		if retry_goal_spawn_count < (
			FishingLevelCatalogScript.guaranteed_target_spawn_count(int(retry_goal.count))
			+ 1
		):
			all_retry_targets_receive_bonus = false
	check(
		is_equal_approx(retry_spawn_assist_fishing.round_catch_success_chance, 1.0)
		and retry_spawn_assist_fishing.round_retry_target_spawn_bonus_per_goal == 1
		and retry_spawn_assist_fishing.round_total_spawn_count
			== retry_spawn_base_total + retry_spawn_assist_fishing.round_goals.size()
		and all_retry_targets_receive_bonus,
		"Failing level 450 after reaching guaranteed catches should add one of every target fish to the next attempt"
	)
	retry_spawn_assist_fishing.current_level_retry_count = 7
	retry_spawn_assist_fishing._update_round_catch_success_chance()
	retry_spawn_assist_fishing._build_round_spawn_plan()
	check(
		retry_spawn_assist_fishing.round_retry_target_spawn_bonus_per_goal == 2
		and retry_spawn_assist_fishing.round_total_spawn_count
			== retry_spawn_base_total + retry_spawn_assist_fishing.round_goals.size() * 2,
		"Every additional failure at guaranteed catch chance should add another copy of every target fish"
	)
	retry_spawn_assist_fishing.queue_free()
	await process_frame

	var completed_fishing = load("res://src/fishing_game.gd").new()
	completed_fishing.configure({}, {
		"experience": 0,
		"fishing_level": 1,
		"fishing_retry_level": 1,
		"fishing_retry_count": 2,
		"unlocked_fish_ids": ["green", "coral", "golden"]
	})
	root.add_child(completed_fishing)
	await process_frame
	check(
		completed_fishing.round_retry_target_spawn_bonus_per_goal == 1,
		"A level-one attempt after failing once at one-hundred-percent catch chance should receive one extra target fish"
	)
	completed_fishing._start_round_from_goal_popup()
	completed_fishing.spawn_timer.stop()
	var completed_xp_before := int(completed_fishing.shared_stats.get("experience", 0))
	for completed_goal_index in range(completed_fishing.round_goals.size()):
		var completed_goal: Dictionary = completed_fishing.round_goals[completed_goal_index]
		var completed_goal_count := int(completed_goal.count)
		completed_fishing.round_goal_counts[str(completed_goal.fish_id)] = (
			completed_goal_count - 1
			if completed_goal_index == completed_fishing.round_goals.size() - 1
			else completed_goal_count
		)
	completed_fishing._update_goal_tracker()
	var early_completion_time: float = float(completed_fishing.round_time_remaining)
	var final_goal: Dictionary = completed_fishing.round_goals.back()
	var final_goal_catch: Array[Dictionary] = [
		FishCatalogScript.definition(str(final_goal.fish_id)).duplicate(true)
	]
	completed_fishing._finish_attempt(final_goal_catch)
	check(completed_fishing.round_completion_pending and completed_fishing.result_overlay.name == "FishingCatchPopupOverlay", "Catching the final required fish should mark an early completion while still showing the catch summary")
	completed_fishing.result_overlay.emit_signal("pressed")
	var completed_round_background = completed_fishing.result_overlay.find_child("FishingLevelCompletePopupBackground", true, false)
	check(completed_fishing._round_goals_completed() and completed_fishing.result_is_round_end, "A round should end successfully as soon as every required count is caught")
	check(
		completed_fishing.current_level_retry_count == 0
		and not completed_fishing.shared_stats.has("fishing_retry_level")
		and not completed_fishing.shared_stats.has("fishing_retry_count"),
		"Completing a level should clear its persisted retry assistance"
	)
	check(completed_fishing.round_time_remaining == early_completion_time and completed_fishing.round_time_remaining > 0.0, "Early completion should stop the round without waiting for or zeroing the remaining countdown")
	check(completed_round_background.texture == completed_fishing.SUCCESS_POPUP_TEXTURE, "A successful final goal check should show the existing congratulations popup")
	var completed_title = completed_fishing.result_overlay.find_child("FishingLevelCompletePopupTitle", true, false)
	var completed_message = completed_fishing.result_overlay.find_child("FishingLevelCompletePopupMessage", true, false)
	var completed_xp_label = completed_fishing.result_overlay.find_child("FishingLevelCompleteXPReward", true, false)
	var next_level_button = completed_fishing.result_overlay.find_child("FishingNextLevelButton", true, false)
	var completed_home_button = completed_fishing.result_overlay.find_child("FishingLevelCompleteHomeButton", true, false)
	check(completed_title.text == "CONGRATULATIONS!" and completed_message.text == "YOU'VE COMPLETED THIS LEVEL!", "The level-complete popup should use the approved live wording")
	check(completed_xp_label.text == "XP EARNED: %d" % completed_fishing.round_xp_reward, "The level-complete popup should show the configured one-time XP reward")
	check(int(completed_fishing.shared_stats.experience) == completed_xp_before + completed_fishing.round_xp_reward and completed_fishing.xp_earned == completed_fishing.round_xp_reward, "Completing a fishing level should award its XP exactly once")
	var completed_xp_after_award := int(completed_fishing.shared_stats.experience)
	completed_fishing._award_round_completion_xp()
	check(int(completed_fishing.shared_stats.experience) == completed_xp_after_award, "Reopening or re-entering the success flow must not award the same level XP twice")
	check(completed_title.get_theme_constant("shadow_offset_y") > 0 and completed_message.get_theme_constant("shadow_offset_y") == 0, "Only the level-complete Congratulations title should have a text shadow")
	check(next_level_button is Button and next_level_button.text == "NEXT LEVEL" and completed_home_button is Button and completed_home_button.text == "GO HOME", "The successful-level popup should offer both approved actions")
	check(next_level_button.get_theme_stylebox("normal").bg_color == Color("#e87942") and completed_home_button.get_theme_stylebox("normal").bg_color == Color("#fff7e9"), "The level-complete actions should reuse Home's simple orange and cream button styles")
	check(next_level_button.get_theme_constant("shadow_offset_y") == 0 and completed_home_button.get_theme_constant("shadow_offset_y") == 0, "The level-complete button text should not have shadows")
	next_level_button.emit_signal("pressed")
	check(
		completed_fishing.current_level == 2
		and completed_fishing.state == completed_fishing.GameState.SHOWING_GOALS
		and completed_fishing.goal_popup_overlay != null
		and completed_fishing.round_retry_target_spawn_bonus_per_goal == 0
		and is_equal_approx(
			completed_fishing.round_catch_success_chance,
			float(FishingLevelCatalogScript.level_config(2).catch_success_chance)
		),
		"After a retry-assisted level is passed, the next level should use its regular unassisted escape rate"
	)
	completed_fishing.queue_free()
	await process_frame


	game.show_reverse_fetch()
	await process_frame
	var xp_before_fetch := int(game.get_progress_stats().experience)
	game.retrieve_ball()
	check(game.fetch_count == 1, "Clicking the ball should count one retrieval")
	check(int(game.get_progress_stats().experience) == xp_before_fetch, "Reverse fetch should stay an interaction and not award progression XP")

	var station_ids: Array[String] = PetCatalogScript.catalog_ids()
	var station_colors := {}
	var station_motifs := {}
	for station_id in station_ids:
		var station_theme: Dictionary = desktop.get_desktop_station_theme(str(station_id))
		station_colors[str(station_theme.primary)] = true
		station_motifs[str(station_theme.motif)] = true
	check(station_ids.size() == 9 and station_colors.size() == 9 and station_motifs.size() == 9, "Every catalog cat should have a distinct desktop Station theme")
	check(desktop.get_desktop_station_theme("unknown").id == "maple", "Unknown legacy cats should safely use Maple's Station")
	game.show_home()
	check(music_manager.is_home_music_active(), "Desktop music regression should start from a HOME screen with music playing")
	game.enter_desktop_mode()
	check(
		not music_manager.music_player.playing and music_manager.fade_tween == null,
		"Entering Desktop Companion should immediately stop all background music and pending fades"
	)
	await process_frame
	check(game.current_screen == "widget" and desktop.desktop_station != null, "Desktop companion should build a dedicated Station")
	check(desktop.normal_window_unresizable == false, "Normal game windows should remain resizable outside Desktop mode")
	check(desktop.desktop_station.get_meta("station_id") == "maple", "Maple should receive Maple's unique Station")
	check(desktop.station_drag_handle != null and desktop.pet_drag_surface != null, "Both the Station and the pet should expose drag surfaces")
	check(desktop.follow_button.text == "FOLLOW ME", "The Station should start with a compact Follow Me button")
	var station_top = desktop.desktop_station.find_child("StationTopArt", true, false)
	var station_controls = desktop.desktop_station.find_child("StationControlsPanel", true, false)
	var station_buttons: Array[Node] = desktop.desktop_station.find_children("*", "Button", true, false)
	var station_labels: Array[Node] = desktop.desktop_station.find_children("*", "Label", true, false)
	check(
		is_instance_valid(desktop.pet_station_top_art)
		and not station_top.visible
		and desktop.pet_station_top_art.visible
		and desktop.pet_station_top_art.get_index() < game.avatar.get_index(),
		"A seated cat and its mat should share the pet canvas with the mat permanently below the cat"
	)
	check(
		desktop.pet_station_top_art.position == Vector2(20.0, 193.0),
		"The pet-window copy of the Station art should line up exactly with the original Station"
	)
	check(
		_station_art_is_standardized(
			station_top,
			pet_texture("maple", "station"),
			desktop.STATION_TOP_ART_POSITION,
			desktop.STATION_TOP_ART_SIZE
		),
		"Maple's Station top should use the new side-view flower grass artwork"
	)
	check(
		station_controls is Panel
		and station_controls.position.y == desktop.STATION_CONTROLS_Y
		and station_top.position.y + station_top.size.y == station_controls.position.y,
		"Every cat-specific Station top should use one shared frame touching the controls panel"
	)
	check(station_buttons.size() == 3, "The default Station should contain exactly three buttons")
	check(station_buttons.any(func(button): return button.text == "GO HOME") and station_buttons.any(func(button): return button.text == "FOLLOW ME") and station_buttons.any(func(button): return button.text == "QUIT"), "The three Station buttons should be Go Home, Follow Me, and Quit")
	check(station_buttons.all(func(button): return button.size == Vector2(104, 50) and button.position.y == 13.0), "Station buttons should be compact and aligned in one horizontal row")
	check(
		station_buttons.all(func(button): return button.get_theme_font("font") == GameFontStylesScript.REGULAR_FONT and button.get_theme_font("font").get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x <= button.size.x - 8.0),
		"The enlarged original Station labels should fit inside all three compact buttons"
	)
	check(station_buttons.all(func(button): return button.get_theme_stylebox("normal") is StyleBoxFlat and button.get_theme_stylebox("normal").corner_radius_top_left >= 20), "Every Station button should use a strongly rounded style")
	check(station_labels.is_empty(), "The Station should not contain the removed title, XP, motif, or drag-helper text")
	check(desktop.station_drag_handle == desktop.desktop_station and desktop.station_drag_handle.size == Vector2(desktop.STATION_LOGICAL_SIZE), "The full Station background should be draggable while its buttons remain interactive")
	check(station_controls.mouse_filter == Control.MOUSE_FILTER_PASS and station_buttons.all(func(button): return button.mouse_filter == Control.MOUSE_FILTER_STOP), "Station background drag events should pass upward while buttons keep their clicks")
	check(is_equal_approx(desktop.DESKTOP_WIDGET_SCALE, 0.90) and is_equal_approx(desktop.widget_screen_scale, 0.90), "The desktop cat and Station should share the requested ten-percent size reduction")
	check(desktop.get_station_pixel_size() == Vector2(324, 149), "Fractional 90-percent Station dimensions should round to whole pixels instead of creating edge letterboxing")
	check(desktop.PET_WIDGET_LOGICAL_SIZE == Vector2i(400, 300), "The desktop pet should use a wider transparent window so same-size run poses are never squeezed")
	check(desktop.STATION_PET_FOOT_Y == 107.0, "The resting desktop pet should sit five pixels higher on its Station")
	var desktop_rect: Rect2 = desktop.get_current_desktop_screen_rect()
	var expected_station_position: Vector2 = desktop.get_initial_station_position(desktop_rect)
	check(desktop.widget_station_position.is_equal_approx(expected_station_position), "The Station should initially be fixed to the lower-right corner")
	check(
		desktop.widget_pet_at_station and desktop.widget_pet_position.is_equal_approx(desktop.get_station_pet_anchor()),
		"The pet should begin on its Station (actual %s, anchor %s)" % [desktop.widget_pet_position, desktop.get_station_pet_anchor()]
	)
	check(desktop.widget_pet_position.y + desktop.get_pet_widget_pixel_size().y > desktop.widget_station_position.y + desktop.STATION_CONTROLS_Y * desktop.widget_screen_scale, "The enlarged pet should visually meet the grass instead of floating above it")
	desktop._on_pet_drag_input(pet_double_click)
	check(game.avatar.is_playing_interaction() and not desktop.widget_pet_dragging, "Double-clicking the cat on its Station should roll without starting a drag")
	for station_roll_step in range(game.avatar.DESKTOP_BELLY_FRAMES.size() + 1):
		game.avatar._process(1.0 / game.avatar.DESKTOP_BELLY_FPS + 0.01)
	check(not game.avatar.is_playing_interaction(), "The Station belly-roll interaction should complete and return to the seated state")
	check(game.avatar.DESKTOP_WINK_FRAMES.size() == 9 and game.avatar.DESKTOP_BELLY_FRAMES.size() == 21, "Desktop idle gestures should use a smooth chronological timeline with the inserted kneading cycle")
	check(
		game.avatar.DESKTOP_WINK_FRAMES.all(func(frame): return frame.get_size() == Vector2(418, 418))
		and game.avatar.DESKTOP_BELLY_FRAMES.all(func(frame): return frame.get_size() == Vector2(418, 418)),
		"Every Desktop idle frame should keep one fixed canvas"
	)
	for safe_frame in game.avatar.DESKTOP_WINK_FRAMES + game.avatar.DESKTOP_BELLY_FRAMES:
		var safe_rect: Rect2i = safe_frame.get_image().get_used_rect()
		check(
			safe_rect.position.x >= 5
			and safe_rect.position.y >= 5
			and safe_rect.end.x <= 413
			and safe_rect.end.y <= 413,
			"Every Desktop idle frame should retain transparent padding so tails cannot wrap across cell boundaries"
		)
	check(
		game.avatar.DESKTOP_BELLY_FRAMES[5] == game.avatar.DESKTOP_BELLY_FRAMES[15]
		and game.avatar.DESKTOP_BELLY_FRAMES[4] == game.avatar.DESKTOP_BELLY_FRAMES[16]
		and game.avatar.DESKTOP_BELLY_FRAMES[3] == game.avatar.DESKTOP_BELLY_FRAMES[17]
		and game.avatar.DESKTOP_BELLY_FRAMES[2] == game.avatar.DESKTOP_BELLY_FRAMES[18]
		and game.avatar.DESKTOP_BELLY_FRAMES[1] == game.avatar.DESKTOP_BELLY_FRAMES[19]
		and game.avatar.DESKTOP_BELLY_FRAMES[0] == game.avatar.DESKTOP_BELLY_FRAMES[20],
		"The belly reveal should return along the exact same poses instead of jumping to unrelated recovery art"
	)
	check(
		game.avatar.DESKTOP_BELLY_FRAMES[6].resource_path.contains("desktop_biscuit")
		and game.avatar.DESKTOP_BELLY_FRAMES[14].resource_path.contains("desktop_biscuit"),
		"The side-lying peak should contain the inserted right-paw making-biscuits frames"
	)
	for biscuit_pair in [[7, 8], [10, 11], [13, 14]]:
		var complete_ear_rect: Rect2i = game.avatar.DESKTOP_BELLY_FRAMES[biscuit_pair[0]].get_image().get_used_rect()
		var repaired_ear_rect: Rect2i = game.avatar.DESKTOP_BELLY_FRAMES[biscuit_pair[1]].get_image().get_used_rect()
		check(
			repaired_ear_rect.end.x >= complete_ear_rect.end.x - 2,
			"Every right-column biscuit frame should retain the complete screen-right ear"
		)
	check(game.avatar.desktop_idle_enabled, "A seated awake pet on its Station should enable occasional Desktop idle gestures")
	check(
		game.avatar.desktop_idle_wait_remaining > 0.0
		and game.avatar.desktop_idle_wait_remaining <= game.avatar.DESKTOP_IDLE_MAX_WAIT,
		"Desktop idle gestures should wait a random interval instead of playing continuously"
	)
	game.avatar._start_desktop_idle_animation("wink")
	check(game.avatar.desktop_idle_animation == "wink" and game.avatar.cat_sprite.texture == game.avatar.DESKTOP_WINK_FRAMES[0], "The synchronized wink gesture should start from its seated frame")
	for wink_frame_index in range(game.avatar.DESKTOP_WINK_FRAMES.size()):
		game.avatar.desktop_idle_frame = wink_frame_index
		game.avatar._apply_current_texture()
		game.avatar._update_layout()
		var wink_bounds: Rect2 = game.avatar._get_texture_visual_bounds(game.avatar.cat_sprite.texture)
		var wink_texture_size: Vector2 = game.avatar.cat_sprite.texture.get_size()
		var wink_visual_bottom: float = game.avatar.cat_sprite.position.y + (wink_bounds.end.y - wink_texture_size.y * 0.5) * game.avatar.cat_sprite.scale.y
		check(is_equal_approx(wink_visual_bottom, game.avatar.size.y * game.avatar.SHADOW_CENTER_Y_RATIO), "Every wink frame should stay planted on the Station shadow")
	game.avatar._start_desktop_idle_animation("belly")
	check(game.avatar.desktop_idle_animation == "belly" and game.avatar.cat_sprite.texture == game.avatar.DESKTOP_BELLY_FRAMES[0], "The belly reveal should start from its seated frame")
	for roll_frame_index in range(game.avatar.DESKTOP_BELLY_FRAMES.size()):
		game.avatar.desktop_idle_frame = roll_frame_index
		game.avatar._apply_current_texture()
		game.avatar._update_layout()
		var roll_bounds: Rect2 = game.avatar._get_texture_visual_bounds(game.avatar.cat_sprite.texture)
		var roll_texture_size: Vector2 = game.avatar.cat_sprite.texture.get_size()
		var roll_visual_bottom: float = game.avatar.cat_sprite.position.y + (roll_bounds.end.y - roll_texture_size.y * 0.5) * game.avatar.cat_sprite.scale.y
		check(is_equal_approx(roll_visual_bottom, game.avatar.size.y * game.avatar.SHADOW_CENTER_Y_RATIO), "Every belly-reveal frame should remain supported by the Station ground plane")
	game.avatar._stop_desktop_idle_animation()
	game.avatar._schedule_next_desktop_idle()
	game.avatar._apply_current_texture()
	check(desktop.get_station_wake_rect().size.x == desktop.get_station_wake_rect().size.y, "The Station wake area should be a square directly above it")
	var simulated_screens: Array[Rect2] = [
		Rect2(-1440.0, 0.0, 1440.0, 900.0),
		Rect2(0.0, 0.0, 1280.0, 720.0),
		Rect2(1280.0, -180.0, 1920.0, 1080.0)
	]
	var right_screen_position: Vector2 = desktop.clamp_desktop_item_position_to_screens(
		Vector2(1750.0, 100.0),
		desktop.get_station_pixel_size(),
		simulated_screens
	)
	var left_screen_position: Vector2 = desktop.clamp_desktop_item_position_to_screens(
		Vector2(-1200.0, 100.0),
		desktop.get_station_pixel_size(),
		simulated_screens
	)
	check(right_screen_position.x >= 1280.0 and left_screen_position.x < 0.0, "Station clamping should allow placement on monitors on either side of the MacBook display")
	var cross_screen_step := Vector2(1300.0, 120.0)
	var pet_position_before_cross_screen_test: Vector2 = desktop.widget_pet_position
	desktop.set_widget_pet_position(cross_screen_step, false)
	check(desktop.widget_pet_position.is_equal_approx(cross_screen_step), "Follow movement should cross a display seam instead of being pinned to the current screen edge")
	desktop.set_widget_pet_position(pet_position_before_cross_screen_test, false)
	var return_target_across_screen_seam: Vector2 = desktop.get_station_pet_anchor()
	var return_start_across_screen_seam := return_target_across_screen_seam + Vector2(2600.0, -120.0)
	desktop.widget_pet_at_station = false
	desktop.widget_returning_to_station = true
	desktop.set_widget_pet_position(return_start_across_screen_seam, false)
	var expected_cross_screen_return_step := return_start_across_screen_seam.move_toward(
		return_target_across_screen_seam,
		0.02 * desktop.PET_FOLLOW_RUN_SPEED * desktop.widget_screen_scale
	)
	desktop.update(0.02, Vector2(-100000.0, -100000.0))
	check(
		desktop.widget_pet_position.is_equal_approx(expected_cross_screen_return_step),
		"Returning after Unfollow should cross a display seam instead of being pinned to the display edge"
	)
	desktop.widget_returning_to_station = false
	desktop.widget_pet_at_station = true
	desktop.set_widget_pet_position(return_target_across_screen_seam)

	var original_station_position: Vector2 = desktop.widget_station_position
	desktop.set_widget_station_position(original_station_position - Vector2(90, 45))
	check(not desktop.widget_station_position.is_equal_approx(original_station_position), "Dragging logic should be able to move the Station from its initial position")
	check(desktop.widget_pet_position.is_equal_approx(desktop.get_station_pet_anchor()), "A pet resting on the Station should move with the Station")

	desktop.widget_pet_at_station = false
	desktop.set_widget_pet_position(desktop.widget_pet_position - Vector2(260, 120))
	desktop.widget_seconds_since_pet_drag = desktop.PET_RETURN_SECONDS - 0.1
	var far_pointer: Vector2 = Vector2(desktop.widget_station_position) - Vector2(600, 600)
	desktop.update(0.2, far_pointer)
	check(desktop.widget_returning_to_station or desktop.widget_pet_at_station, "A pet left away from the Station for fifteen seconds should begin returning")
	for return_step in range(30):
		desktop.update(0.1, far_pointer)
	check(
		desktop.widget_pet_at_station
		and desktop.widget_pet_position.distance_to(desktop.get_station_pet_anchor()) < 2.0
		and game.avatar.move_time_remaining == 0.0,
		"The returning pet should settle at the Station and leave its walking pose"
	)

	desktop.widget_seconds_outside_station = desktop.STATION_WAKE_SECONDS - 0.1
	desktop.update(0.2, far_pointer)
	check(game.avatar.mood == "sleep", "Thirty seconds without the pointer in the Station space should put the pet to sleep")
	desktop.update(0.1, desktop.get_pet_screen_rect().get_center())
	check(game.avatar.mood == "idle", "Moving the pointer onto the sleeping pet should wake it")

	var before_follow_position: Vector2 = desktop.widget_pet_position
	var follow_pointer: Vector2 = Vector2(desktop.widget_station_position) - Vector2(300, 220)
	game.avatar.mood_badge.text = "STALE COMING!"
	game.avatar.mood_badge.visible = true
	desktop.set_widget_following(true)
	desktop.update(0.0, desktop.widget_follow_last_pointer)
	check(desktop.widget_follow_has_target and desktop.widget_pet_position.is_equal_approx(before_follow_position), "Clicking Follow Me should immediately capture the current pointer without teleporting the pet")
	desktop.update(0.0, follow_pointer)
	check(desktop.widget_following and desktop.follow_button.text == "UNFOLLOW", "Follow Me should stay enabled and change the button to Unfollow")
	check(
		game.avatar.mood_badge.text == "" and not game.avatar.mood_badge.visible,
		"Follow Me should never show a Coming badge above the cat"
	)
	check(desktop.widget_follow_has_target and desktop.widget_follow_chasing and desktop.widget_follow_reaction_remaining >= 0.3 and desktop.widget_follow_reaction_remaining <= 0.6, "Starting a chase should give the pet one short reaction delay")
	check(desktop.widget_pet_position.is_equal_approx(before_follow_position) and game.avatar.mood == "follow", "The following pet should stay seated during its reaction time")
	desktop.update(0.1, follow_pointer)
	check(desktop.widget_pet_position.is_equal_approx(before_follow_position), "The pet should not start running before its reaction timer finishes")
	desktop.widget_follow_reaction_remaining = 0.0
	desktop.update(0.1, follow_pointer)
	var slow_follow_distance: float = desktop.widget_pet_position.distance_to(before_follow_position)
	check(slow_follow_distance > 0.0 and slow_follow_distance <= desktop.PET_FOLLOW_RUN_SPEED * desktop.widget_screen_scale * 0.1 + 0.1, "The following pet should run at the new slower fixed speed")
	check(station_top.visible and not desktop.pet_station_top_art.visible, "The Station should restore its own mat after the cat walks away")
	check(game.avatar.cat_sprite.texture in game.avatar.MOVE_LEFT_FRAMES + game.avatar.MOVE_RIGHT_FRAMES, "Follow Me should use only the left or right running animation")
	var position_before_new_reaction: Vector2 = desktop.widget_pet_position
	var second_follow_pointer := follow_pointer + Vector2(120.0, 0.0)
	desktop.update(0.0, second_follow_pointer)
	check(desktop.widget_pet_position.is_equal_approx(position_before_new_reaction) and desktop.widget_follow_chasing and is_zero_approx(desktop.widget_follow_reaction_remaining) and game.avatar.move_time_remaining > 0.0, "Moving the pointer again must update the target without pausing the cat or restarting its reaction")
	desktop._on_pet_drag_input(pet_double_click)
	desktop.update(0.4, second_follow_pointer)
	check(game.avatar.is_playing_interaction() and desktop.widget_pet_position.is_equal_approx(position_before_new_reaction), "Double-clicking during Follow Me should pause movement while the cat rolls")
	for follow_roll_step in range(game.avatar.DESKTOP_BELLY_FRAMES.size() + 1):
		game.avatar._process(1.0 / game.avatar.DESKTOP_BELLY_FPS + 0.01)
	check(not game.avatar.is_playing_interaction() and desktop.widget_following, "Follow Me should remain enabled after the double-click roll finishes")
	check(not game.avatar.desktop_idle_enabled and game.avatar.desktop_idle_animation == "", "Following the pointer should cancel seated Desktop idle gestures")
	desktop.set_widget_following(false)
	check(not desktop.widget_following and desktop.follow_button.text == "FOLLOW ME", "Unfollow should stop permanent following and restore the button")
	check(desktop.widget_returning_to_station or desktop.widget_pet_at_station, "Unfollow should immediately send the pet back toward its Station")
	for unfollow_return_step in range(30):
		desktop.update(0.1, far_pointer)
	check(desktop.widget_pet_at_station, "The unfollowed pet should finish walking back to its Station")
	check(not station_top.visible and desktop.pet_station_top_art.visible, "The returning cat should finish above the mat on the shared pet canvas")

	var go_home_buttons := station_buttons.filter(func(button): return button.text == "GO HOME")
	check(go_home_buttons.size() == 1, "Desktop Station should expose exactly one Go Home action")
	go_home_buttons[0].emit_signal("pressed")
	await process_frame
	await process_frame
	check(not game.desktop_mode and game.current_screen == "home", "Clicking Go Home should leave Desktop mode and open Home")
	check(desktop.desktop_station == null and desktop.pet_drag_surface == null, "Go Home should close both native Desktop companion surfaces")
	check(music_manager.is_home_music_active(), "Go Home from Desktop Companion should restore HOME background music")

	if failures.is_empty():
		print("SMOKE TEST PASS: direct home -> aquarium -> store -> pool -> fishing -> reverse fetch -> desktop rules -> Go Home")
		quit(0)
	else:
		print("SMOKE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)
