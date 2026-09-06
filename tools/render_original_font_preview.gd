extends SceneTree

const OUTPUT := "res://dev_only/outputs/previews/fonts/godot_font_preview.png"
const FONT_PATH := "res://assets/fonts/original_handwriting/yufan_original_handwriting.ttf"
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const SAMPLE_LINES := [
	"WELCOME HOME!!",
	"CURRENT XP: 2,400",
	"UNLOCK WITH 500 XP",
]
const REQUIRED_CHARACTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!?.,:'+ -/%←()"


func _initialize() -> void:
	call_deferred("_render")


func _render() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.get_base_dir()))
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var canvas := Control.new()
	canvas.size = Vector2(1280, 720)
	root.add_child(canvas)

	var background := ColorRect.new()
	background.color = Color("#352a25")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)

	for index in range(SAMPLE_LINES.size()):
		var font: Font = load(FONT_PATH)
		if font == null:
			push_error("Could not load custom font: %s" % FONT_PATH)
			quit(1)
			return
		for character in REQUIRED_CHARACTERS:
			if character != " " and not font.has_char(character.unicode_at(0)):
				push_error("Font %s is missing %s" % [FONT_PATH, character])
				quit(1)
				return

		var panel := Panel.new()
		panel.position = Vector2(70, 55 + index * 215)
		panel.size = Vector2(1140, 170)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("#42342e")
		panel_style.border_color = Color("#99694d")
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(24)
		panel.add_theme_stylebox_override("panel", panel_style)
		canvas.add_child(panel)

		var label := Label.new()
		label.text = SAMPLE_LINES[index]
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 88)
		label.add_theme_color_override("font_color", Color.WHITE)
		match index:
			1:
				GameFontStylesScript.apply_accent(label)
			2:
				GameFontStylesScript.apply_button(label)
			_:
				GameFontStylesScript.apply_regular(label)
				label.add_theme_color_override("font_color", Color.WHITE)
		panel.add_child(label)

	await process_frame
	await process_frame
	var error := root.get_texture().get_image().save_png(OUTPUT)
	if error != OK:
		push_error("Could not save original handwriting font preview: %s" % error_string(error))
		quit(1)
		return
	print("ORIGINAL HANDWRITING FONT PASS: %s" % OUTPUT)
	quit(0)
