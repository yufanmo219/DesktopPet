class_name GameFontStyles
extends RefCounted

const REGULAR_FONT: Font = preload(
	"res://assets/fonts/original_handwriting/yufan_original_handwriting.ttf"
)
const ACCENT_FONT: Font = preload(
	"res://assets/fonts/original_handwriting/yufan_original_handwriting.ttf"
)
const BUTTON_FONT: Font = preload(
	"res://assets/fonts/original_handwriting/yufan_original_handwriting.ttf"
)


static func display_text(value: Variant) -> String:
	return str(value).replace("—", "-").replace("“", "'").replace("”", "'").replace("•", "-").to_upper()


static func apply_regular(control: Control) -> void:
	control.add_theme_font_override("font", REGULAR_FONT)
	control.add_theme_constant_override("outline_size", 0)
	control.add_theme_constant_override("shadow_offset_x", 0)
	control.add_theme_constant_override("shadow_offset_y", 0)
	control.add_theme_constant_override("shadow_outline_size", 0)


static func apply_accent(control: Control) -> void:
	control.add_theme_font_override("font", ACCENT_FONT)
	control.add_theme_color_override("font_color", Color("#e98555"))
	control.add_theme_color_override("font_outline_color", Color("#684230"))
	control.add_theme_color_override("font_shadow_color", Color(0.24, 0.15, 0.12, 0.28))
	control.add_theme_constant_override("outline_size", 2)
	control.add_theme_constant_override("shadow_offset_x", 1)
	control.add_theme_constant_override("shadow_offset_y", 2)
	control.add_theme_constant_override("shadow_outline_size", 0)


static func apply_button(control: Control) -> void:
	control.add_theme_font_override("font", BUTTON_FONT)
	control.add_theme_color_override("font_color", Color.WHITE)
	control.add_theme_color_override("font_hover_color", Color.WHITE)
	control.add_theme_color_override("font_pressed_color", Color.WHITE)
	control.add_theme_color_override("font_focus_color", Color.WHITE)
	control.add_theme_color_override("font_outline_color", Color("#684230"))
	control.add_theme_color_override("font_shadow_color", Color(0.24, 0.15, 0.12, 0.32))
	control.add_theme_constant_override("outline_size", 2)
	control.add_theme_constant_override("shadow_offset_x", 1)
	control.add_theme_constant_override("shadow_offset_y", 2)
	control.add_theme_constant_override("shadow_outline_size", 0)


static func make_game_theme() -> Theme:
	var game_theme := Theme.new()
	game_theme.default_font = REGULAR_FONT
	return game_theme
