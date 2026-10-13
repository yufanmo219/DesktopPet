class_name AquariumLoadingScreen
extends Control

## Full-screen loading veil shown while aquarium fish animations are prepared.

const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const AquariumLoadingViewScene = preload(
	"res://src/aquarium/aquarium_loading_view.tscn"
)
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
	_ensure_view()
	_bind_view()
	_style_view()


func _process(delta: float) -> void:
	if not is_instance_valid(hourglass):
		return
	hourglass.rotation = fmod(
		hourglass.rotation + TAU / ROTATION_SECONDS * delta,
		TAU
	)


func _ensure_view() -> void:
	if get_node_or_null("AquariumLoadingView") == null:
		add_child(AquariumLoadingViewScene.instantiate())


func _bind_view() -> void:
	background = get_node("AquariumLoadingView/AquariumLoadingBackground")
	hourglass = get_node("AquariumLoadingView/AquariumLoadingHourglass")
	message_label = get_node("AquariumLoadingView/AquariumLoadingMessage")


func _style_view() -> void:
	background.color = BACKGROUND_COLOR
	message_label.text = GameFontStylesScript.display_text(LOADING_MESSAGE)
	GameFontStylesScript.apply_regular(message_label)
	message_label.add_theme_font_size_override("font_size", MESSAGE_FONT_SIZE)
	message_label.add_theme_color_override("font_color", TEXT_COLOR)
