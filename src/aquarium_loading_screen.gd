class_name AquariumLoadingScreen
extends Control

## Full-screen loading veil shown while aquarium fish animations are prepared.

const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const HOURGLASS_TEXTURE: Texture2D = preload(
	"res://assets/ui/loading/aquarium_loading_hourglass_icon_v1.png"
)

const BACKGROUND_COLOR := Color("#2d2a29")
const TEXT_COLOR := Color("#fff8eb")
const HOURGLASS_POSITION := Vector2(576, 214)
const HOURGLASS_SIZE := Vector2(128, 128)
const MESSAGE_POSITION := Vector2(0, 492)
const MESSAGE_SIZE := Vector2(1280, 62)
const MESSAGE_FONT_SIZE := 46
const ROTATION_SECONDS := 1.02
const LOADING_MESSAGE := "PREPARING THE AQUARIUM..."

var background: ColorRect
var hourglass: TextureRect
var message_label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_background()
	_build_hourglass()
	_build_message()


func _process(delta: float) -> void:
	if not is_instance_valid(hourglass):
		return
	hourglass.rotation = fmod(
		hourglass.rotation + TAU / ROTATION_SECONDS * delta,
		TAU
	)


func _build_background() -> void:
	background = ColorRect.new()
	background.name = "AquariumLoadingBackground"
	background.color = BACKGROUND_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)


func _build_hourglass() -> void:
	hourglass = TextureRect.new()
	hourglass.name = "AquariumLoadingHourglass"
	hourglass.texture = HOURGLASS_TEXTURE
	hourglass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hourglass.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hourglass.position = HOURGLASS_POSITION
	hourglass.size = HOURGLASS_SIZE
	hourglass.pivot_offset = HOURGLASS_SIZE * 0.5
	hourglass.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hourglass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hourglass)


func _build_message() -> void:
	message_label = Label.new()
	message_label.name = "AquariumLoadingMessage"
	message_label.text = GameFontStylesScript.display_text(LOADING_MESSAGE)
	message_label.position = MESSAGE_POSITION
	message_label.size = MESSAGE_SIZE
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameFontStylesScript.apply_regular(message_label)
	message_label.add_theme_font_size_override("font_size", MESSAGE_FONT_SIZE)
	message_label.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(message_label)
