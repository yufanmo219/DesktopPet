class_name FishingGame
extends Control

## Cooperative fishing minigame.
##
## The three generated 1672x941 UI images are the visual source of truth.
## This script adds interaction on top: live counters, swimming generated fish,
## the layered six-frame net animation, rewards, and click-anywhere result screens.

signal catch_completed(succeeded: bool, fish_caught: int, xp_earned: int)
signal shared_stats_changed(stats: Dictionary)
signal back_requested


const MAIN_SCREEN_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/concepts/fishing_environment_background.png"
)
const STATS_PANEL_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/panels/processed/stats_panel_frame.png"
)
const HEART_PANEL_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/panels/processed/heart_panel_frame.png"
)
const FISH_TYPES_PANEL_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/panels/processed/fish_types_panel_frame.png"
)
const SUCCESS_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/popups/processed/fishing_success_popup_base.png"
)
const FAILURE_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/popups/processed/fishing_failure_popup_base.png"
)
const NO_HEARTS_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/popups/processed/fishing_no_hearts_popup_base.png"
)
const GOAL_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/popups/processed/fishing_goal_popup_base_v2.png"
)
const CATCH_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/popups/processed/fishing_catch_popup_background_v1.png"
)
const HOME_RETURN_POPUP_TEXTURE: Texture2D = preload(
	"res://assets/ui/store/popups/purchase_confirmation_frame_v3.png"
)
const FISHING_FAILURE_SOUND: AudioStreamWAV = preload(
	"res://assets/audio/sfx/fishing/cozy_cat_fishing_failure.wav"
)
const FISHING_SUCCESS_SOUND: AudioStreamWAV = preload(
	"res://assets/audio/sfx/fishing/tiny_splash_success.wav"
)
const NET_HANDS_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/animations/cooperative_v3/processed/net_hands.png"
)
const DEFAULT_FISHING_PET_FRAMES: Array[Texture2D] = [
	preload("res://assets/ui/fishing/animations/cooperative_v4/pet_frames/frame_01.png"),
	preload("res://assets/ui/fishing/animations/cooperative_v4/pet_frames/frame_02.png"),
	preload("res://assets/ui/fishing/animations/cooperative_v4/pet_frames/frame_03.png"),
	preload("res://assets/ui/fishing/animations/cooperative_v4/pet_frames/frame_04.png"),
	preload("res://assets/ui/fishing/animations/cooperative_v4/pet_frames/frame_05.png"),
	preload("res://assets/ui/fishing/animations/cooperative_v4/pet_frames/frame_06.png")
]
const MOCHI_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/mochi/fishing/default/mochi_fishing_default.png"
)
const MOCHI_FISHING_CRY_FRAMES: Array[Texture2D] = [
	MOCHI_FISHING_DEFAULT_TEXTURE,
	preload("res://assets/pets/mochi/fishing/cry_v2/frame_02.png"),
	preload("res://assets/pets/mochi/fishing/cry_v2/frame_03.png"),
	preload("res://assets/pets/mochi/fishing/cry_v2/frame_04.png"),
	preload("res://assets/pets/mochi/fishing/cry_v2/frame_05.png"),
	preload("res://assets/pets/mochi/fishing/cry_v2/frame_06.png"),
	preload("res://assets/pets/mochi/fishing/cry_v2/frame_07.png"),
	preload("res://assets/pets/mochi/fishing/cry_v2/frame_08.png")
]
const MOCHI_FISHING_SUCCESS_FRAMES: Array[Texture2D] = [
	MOCHI_FISHING_DEFAULT_TEXTURE,
	preload("res://assets/pets/mochi/fishing/success/frame_02.png"),
	preload("res://assets/pets/mochi/fishing/success/frame_03.png"),
	preload("res://assets/pets/mochi/fishing/success/frame_04.png"),
	preload("res://assets/pets/mochi/fishing/success/frame_05.png"),
	preload("res://assets/pets/mochi/fishing/success/frame_06.png"),
	preload("res://assets/pets/mochi/fishing/success/frame_07.png"),
	MOCHI_FISHING_DEFAULT_TEXTURE
]
const MOCHI_FISHING_FAILURE_STATIC_TEXTURE: Texture2D = preload(
	"res://assets/pets/mochi/fishing/failure/mochi_fishing_failure_static.png"
)
const BISCUIT_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/biscuit/fishing/default/biscuit_fishing_default.png"
)
const BISCUIT_FISHING_WINK_FRAMES: Array[Texture2D] = [
	BISCUIT_FISHING_DEFAULT_TEXTURE,
	preload("res://assets/pets/biscuit/fishing/success_wink_v3/frame_02.png"),
	preload("res://assets/pets/biscuit/fishing/success_wink_v3/frame_03.png"),
	preload("res://assets/pets/biscuit/fishing/success_wink_v3/frame_04.png"),
	preload("res://assets/pets/biscuit/fishing/success_wink_v3/frame_05.png"),
	preload("res://assets/pets/biscuit/fishing/success_wink_v3/frame_06.png"),
	preload("res://assets/pets/biscuit/fishing/success_wink_v3/frame_07.png"),
	BISCUIT_FISHING_DEFAULT_TEXTURE
]
const BISCUIT_FISHING_FAILURE_TEXTURE: Texture2D = preload(
	"res://assets/pets/biscuit/fishing/failure/biscuit_fishing_failure.png"
)
const LUNA_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/russian_blue/fishing/default/luna_fishing_default.png"
)
const LUNA_FISHING_SUCCESS_FRAMES: Array[Texture2D] = [
	LUNA_FISHING_DEFAULT_TEXTURE,
	preload("res://assets/pets/russian_blue/fishing/success/frame_02.png"),
	preload("res://assets/pets/russian_blue/fishing/success/frame_03.png"),
	preload("res://assets/pets/russian_blue/fishing/success/frame_04.png"),
	preload("res://assets/pets/russian_blue/fishing/success/frame_05.png"),
	preload("res://assets/pets/russian_blue/fishing/success/frame_06.png"),
	preload("res://assets/pets/russian_blue/fishing/success/frame_07.png"),
	LUNA_FISHING_DEFAULT_TEXTURE
]
const LUNA_FISHING_FAILURE_TEXTURE: Texture2D = preload(
	"res://assets/pets/russian_blue/fishing/failure/luna_fishing_failure.png"
)
const POPPY_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/blue_british/fishing/default/poppy_fishing_default.png"
)
const POPPY_FISHING_SUCCESS_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/blue_british/fishing/success/frame_01.png"),
	preload("res://assets/pets/blue_british/fishing/success/frame_02.png"),
	preload("res://assets/pets/blue_british/fishing/success/frame_03.png"),
	preload("res://assets/pets/blue_british/fishing/success/frame_04.png"),
	preload("res://assets/pets/blue_british/fishing/success/frame_05.png"),
	preload("res://assets/pets/blue_british/fishing/success/frame_06.png"),
	preload("res://assets/pets/blue_british/fishing/success/frame_07.png"),
	preload("res://assets/pets/blue_british/fishing/success/frame_08.png")
]
const POPPY_FISHING_FAILURE_TEXTURE: Texture2D = preload(
	"res://assets/pets/blue_british/fishing/failure/poppy_fishing_failure.png"
)
const BLACK_CAT_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/black_cat/fishing/default/black_cat_fishing_default.png"
)
const BLACK_CAT_FISHING_SUCCESS_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/black_cat/fishing/success/frame_01.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_02.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_03.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_04.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_05.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_06.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_07.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_08.png")
]
const BLACK_CAT_FISHING_FAILURE_TEXTURE: Texture2D = preload(
	"res://assets/pets/black_cat/fishing/failure/black_cat_fishing_failure.png"
)
const MAINE_COON_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/maine_coon/fishing/default/maine_coon_fishing_default.png"
)
const MAINE_COON_FISHING_SUCCESS_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/maine_coon/fishing/success/frame_01.png"),
	preload("res://assets/pets/maine_coon/fishing/success/frame_02.png"),
	preload("res://assets/pets/maine_coon/fishing/success/frame_03.png"),
	preload("res://assets/pets/maine_coon/fishing/success/frame_04.png"),
	preload("res://assets/pets/maine_coon/fishing/success/frame_05.png"),
	preload("res://assets/pets/maine_coon/fishing/success/frame_06.png"),
	preload("res://assets/pets/maine_coon/fishing/success/frame_07.png"),
	preload("res://assets/pets/maine_coon/fishing/success/frame_08.png")
]
const MAINE_COON_FISHING_FAILURE_TEXTURE: Texture2D = preload(
	"res://assets/pets/maine_coon/fishing/failure/maine_coon_fishing_failure.png"
)
const GOLDEN_MUNCHKIN_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/golden_munchkin/fishing/default/golden_munchkin_fishing_default.png"
)
const GOLDEN_MUNCHKIN_FISHING_SUCCESS_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_01.png"),
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_02.png"),
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_03.png"),
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_04.png"),
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_05.png"),
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_06.png"),
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_07.png"),
	preload("res://assets/pets/golden_munchkin/fishing/success/frame_08.png")
]
const GOLDEN_MUNCHKIN_FISHING_FAILURE_TEXTURE: Texture2D = preload(
	"res://assets/pets/golden_munchkin/fishing/failure/golden_munchkin_fishing_failure.png"
)
const SIAMESE_FISHING_DEFAULT_TEXTURE: Texture2D = preload(
	"res://assets/pets/siamese/fishing/default/siamese_fishing_default.png"
)
const SIAMESE_FISHING_SUCCESS_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/siamese/fishing/success/frame_01.png"),
	preload("res://assets/pets/siamese/fishing/success/frame_02.png"),
	preload("res://assets/pets/siamese/fishing/success/frame_03.png"),
	preload("res://assets/pets/siamese/fishing/success/frame_04.png"),
	preload("res://assets/pets/siamese/fishing/success/frame_05.png"),
	preload("res://assets/pets/siamese/fishing/success/frame_06.png"),
	preload("res://assets/pets/siamese/fishing/success/frame_07.png"),
	preload("res://assets/pets/siamese/fishing/success/frame_08.png")
]
const SIAMESE_FISHING_FAILURE_TEXTURE: Texture2D = preload(
	"res://assets/pets/siamese/fishing/failure/siamese_fishing_failure.png"
)

const GREEN_FISH_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/fish/processed/green_fish_v2.png"
)
const CORAL_ANGELFISH_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/fish/processed/coral_angelfish_v2.png"
)
const GOLDEN_RIBBONFISH_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/fish/processed/golden_ribbonfish_v2.png"
)
const CRYING_CAT_TEXTURE: Texture2D = preload(
	"res://assets/pets/current/sprites/orange_cat_cry.png"
)
const HEART_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/hearts/heart_sprite_256.png"
)
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const FishingLevelCatalogScript = preload("res://src/fishing_level_catalog.gd")

static var FISH_TYPES: Array[Dictionary] = FishCatalogScript.FISH_TYPES
const STARTER_FISH_IDS: Array[String] = FishCatalogScript.STARTER_FISH_IDS
const TOTAL_FISHING_LEVELS := FishingLevelCatalogScript.TOTAL_LEVELS

# Every playable level loads one to three goals from FishingLevelCatalog.
const MAX_ROUND_GOAL_TYPES := 3
const FISHING_LEVEL := 1
const DEFAULT_ROUND_TIME_LIMIT_SECONDS := FishingLevelCatalogScript.MAX_TIME_LIMIT_SECONDS

# Fishing goal popup layout. Every text/image position, size, and font size is
# kept here so the popup can be adjusted without searching through UI code.
const GOAL_POPUP_PANEL_POSITION := Vector2(315, 35)
const GOAL_POPUP_PANEL_SIZE := Vector2(650, 650)
const GOAL_POPUP_TITLE_POSITION := Vector2(100, 50)
const GOAL_POPUP_TITLE_SIZE := Vector2(450, 60)
const GOAL_POPUP_TITLE_FONT_SIZE := 45
const GOAL_POPUP_FISH_POSITIONS: Array[Vector2] = [
	Vector2(200, 120),
	Vector2(200, 220),
	Vector2(200, 320)
]
const GOAL_POPUP_FISH_SIZES: Array[Vector2] = [
	Vector2(172, 96),
	Vector2(172, 96),
	Vector2(172, 96)
]
const GOAL_POPUP_COUNT_POSITIONS: Array[Vector2] = [
	Vector2(382, 135),
	Vector2(382, 235),
	Vector2(382, 335)
]
const GOAL_POPUP_COUNT_SIZE := Vector2(145, 58)
const GOAL_POPUP_COUNT_FONT_SIZE := 42
const GOAL_POPUP_TIME_TITLE_POSITION := Vector2(185, 415)
const GOAL_POPUP_TIME_TITLE_SIZE := Vector2(280, 42)
const GOAL_POPUP_TIME_TITLE_FONT_SIZE := 29
const GOAL_POPUP_TIMER_POSITION := Vector2(205, 463)
const GOAL_POPUP_TIMER_SIZE := Vector2(240, 55)
const GOAL_POPUP_TIMER_FONT_SIZE := 45
const GOAL_POPUP_FOOTER_POSITION := Vector2(115, 555)
const GOAL_POPUP_FOOTER_SIZE := Vector2(420, 48)
const GOAL_POPUP_FOOTER_FONT_SIZE := 22
const GOAL_POPUP_TEXT_COLOR := Color("#58352b")
const GOAL_POPUP_DIMMER_COLOR := Color(0.09, 0.07, 0.06, 0.28)

# Per-catch popup layout. The background remains a separate texture; fish and
# text are live nodes: up to three species use one column, four to six use
# two columns, and larger catches continue on another page without truncation.
const CATCH_POPUP_ROWS_PER_COLUMN := 3
const MAX_CATCH_POPUP_FISH_TYPES := CATCH_POPUP_ROWS_PER_COLUMN * 2
const CATCH_POPUP_PANEL_POSITION := Vector2(315, 35)
const CATCH_POPUP_PANEL_SIZE := Vector2(650, 650)
const CATCH_POPUP_TITLE_POSITION := Vector2(105, 42)
const CATCH_POPUP_TITLE_SIZE := Vector2(440, 60)
const CATCH_POPUP_TITLE_FONT_SIZE := 42
const CATCH_POPUP_FISH_POSITIONS: Array[Vector2] = [
	Vector2(160, 120),
	Vector2(160, 230),
	Vector2(160, 340)
]
const CATCH_POPUP_FISH_SIZE := Vector2(200, 105)
const CATCH_POPUP_COUNT_POSITIONS: Array[Vector2] = [
	Vector2(350, 124),
	Vector2(350, 234),
	Vector2(350, 344)
]
const CATCH_POPUP_COUNT_SIZE := Vector2(150, 58)
const CATCH_POPUP_COUNT_FONT_SIZE := 38
const CATCH_POPUP_TWO_COLUMN_FISH_ORIGIN := Vector2(65, 125)
const CATCH_POPUP_TWO_COLUMN_COUNT_ORIGIN := Vector2(235, 146)
const CATCH_POPUP_TWO_COLUMN_STEP := Vector2(280, 110)
const CATCH_POPUP_TWO_COLUMN_FISH_SIZE := Vector2(155, 100)
const CATCH_POPUP_TWO_COLUMN_COUNT_SIZE := Vector2(85, 58)
const CATCH_POPUP_TWO_COLUMN_COUNT_FONT_SIZE := 32
const CATCH_POPUP_FOOTER_POSITION := Vector2(110, 556)
const CATCH_POPUP_FOOTER_SIZE := Vector2(430, 48)
const CATCH_POPUP_FOOTER_FONT_SIZE := 21
const CATCH_POPUP_TEXT_COLOR := Color("#58352b")
const CATCH_POPUP_DIMMER_COLOR := Color(0.09, 0.07, 0.06, 0.28)

# Celebration popup layout. Both popups reuse SUCCESS_POPUP_TEXTURE as the
# background while every label, fish icon, and button remains a live node.
const CELEBRATION_POPUP_PANEL_POSITION := Vector2(260, 34)
const CELEBRATION_POPUP_PANEL_SIZE := Vector2(760, 652)
const CELEBRATION_POPUP_DIMMER_COLOR := Color(0.09, 0.07, 0.06, 0.28)
const CELEBRATION_TITLE_POSITION := Vector2(105, 65)
const CELEBRATION_TITLE_SIZE := Vector2(550, 82)
const CELEBRATION_TITLE_FONT_SIZE := 60

const LEVEL_COMPLETE_MESSAGE_POSITION := Vector2(105, 170)
const LEVEL_COMPLETE_MESSAGE_SIZE := Vector2(550, 62)
const LEVEL_COMPLETE_MESSAGE_FONT_SIZE := 32
const LEVEL_COMPLETE_XP_POSITION := Vector2(180, 230)
const LEVEL_COMPLETE_XP_SIZE := Vector2(400, 52)
const LEVEL_COMPLETE_XP_FONT_SIZE := 40
const LEVEL_COMPLETE_NEXT_BUTTON_POSITION := Vector2(192, 301)
const LEVEL_COMPLETE_HOME_BUTTON_POSITION := Vector2(192, 399)
const LEVEL_COMPLETE_BUTTON_SIZE := Vector2(376, 66)
const LEVEL_COMPLETE_BUTTON_FONT_SIZE := 38
const ROUND_FAILURE_BUTTON_SIZE := Vector2(240, 62)
const ROUND_FAILURE_BUTTON_FONT_SIZE := 30
const ROUND_FAILURE_BUTTON_SEPARATION := 24

const NEW_FISH_SUBTITLE_POSITION := Vector2(170, 128)
const NEW_FISH_SUBTITLE_SIZE := Vector2(420, 58)
const NEW_FISH_SUBTITLE_FONT_SIZE := 32
const NEW_FISH_ICON_POSITION := Vector2(265, 190)
const NEW_FISH_ICON_SIZE := Vector2(230, 195)
const NEW_FISH_INFO_LINE_ONE_POSITION := Vector2(110, 404)
const NEW_FISH_INFO_LINE_TWO_POSITION := Vector2(205, 438)
const NEW_FISH_INFO_LINE_ONE_SIZE := Vector2(540, 38)
const NEW_FISH_INFO_LINE_TWO_SIZE := Vector2(350, 38)
const NEW_FISH_INFO_FONT_SIZE := 25
const NEW_FISH_FOOTER_POSITION := Vector2(135, 525)
const NEW_FISH_FOOTER_SIZE := Vector2(490, 42)
const NEW_FISH_FOOTER_FONT_SIZE := 19
const CELEBRATION_REGULAR_TEXT_COLOR := Color("#58352b")

const CATCH_SUCCESS_CHANCE := 0.98
const RETRY_ESCAPE_REDUCTION := 0.03
const FIRST_FISH_SPAWN_TIME_SECONDS := 0.25
const FINAL_FISH_SPAWN_TIME_FRACTION := 0.90
const FINAL_FISH_SPAWN_MIN_REMAINING_SECONDS := 3.0
# One fish is assigned to each equal time slot. Picking a point inside the
# middle 70% of every slot keeps the stream random without allowing clumps.
const SPAWN_SLOT_RANDOM_MIN := 0.15
const SPAWN_SLOT_RANDOM_MAX := 0.85
const MAX_HEARTS := 5
const HEART_RESTORE_SECONDS := 15
const FRAME_DURATIONS: Array[float] = [0.13, 0.12, 0.12, 0.13, 0.18, 0.30]
const CUSTOM_FINAL_REACTION_FRAME_DURATIONS: Array[float] = [0.10, 0.10, 0.10]
const CAUGHT_FISH_LIFT_OFFSETS: Array[float] = [0.0, -40.0, -70.0, -90.0, -90.0, -90.0]
const NET_FRAME_POSITIONS: Array[Vector2] = [
	Vector2(190, 78),
	Vector2(190, 38),
	Vector2(190, 0),
	Vector2(190, -20),
	Vector2(190, -20),
	Vector2(190, -20)
]
const NET_FRAME_SIZES: Array[Vector2] = [
	Vector2(760, 760),
	Vector2(760, 760),
	Vector2(760, 760),
	Vector2(760, 760),
	Vector2(760, 760),
	Vector2(760, 760)
]
const PET_FRAME_POSITIONS: Array[Vector2] = [
	Vector2(400, 10),
	Vector2(400, 10),
	Vector2(400, 10),
	Vector2(400, 10),
	Vector2(400, 10),
	Vector2(400, 10)
]
const PET_FRAME_SIZES: Array[Vector2] = [
	Vector2(340, 340),
	Vector2(340, 340),
	Vector2(340, 340),
	Vector2(340, 340),
	Vector2(340, 340),
	Vector2(340, 340)
]
const RIVER_SWIM_MIN_Y := 310.0
const RIVER_SWIM_MAX_Y := 420.0
const NET_CATCH_ZONE := Rect2(320, 300, 450, 260)

# Move these constants to reposition each complete UI group. The frame and all
# of its labels/icons/hearts are children of the same group and move together.
const STATS_PANEL_POSITION := Vector2(50, 130)
const STATS_PANEL_SIZE := Vector2(298, 136)
const STATS_LABEL_POSITION := Vector2(45, 26)
const STATS_LABEL_SIZE := Vector2(246, 84)
const STATS_LABEL_FONT_SIZE := 27
const HEART_PANEL_POSITION := Vector2(50, 50)
const HEART_PANEL_SIZE := Vector2(314, 83)
const FISH_TYPES_PANEL_POSITION := Vector2(892, 50)
const FISH_TYPES_PANEL_SIZE := Vector2(327, 250)
const GOAL_TRACKER_TITLE_POSITION := Vector2(22, 17)
const GOAL_TRACKER_TITLE_SIZE := Vector2(278, 38)
const GOAL_TRACKER_TITLE_FONT_SIZE := 32
const GOAL_TRACKER_FISH_POSITIONS: Array[Vector2] = [
	Vector2(40, 55),
	Vector2(40, 111),
	Vector2(40, 165)
]
const GOAL_TRACKER_FISH_SIZES: Array[Vector2] = [
	Vector2(68, 44),
	Vector2(68, 44),
	Vector2(68, 44)
]
const GOAL_TRACKER_PROGRESS_POSITIONS: Array[Vector2] = [
	Vector2(150, 55),
	Vector2(150, 110),
	Vector2(150, 165)
]
const GOAL_TRACKER_PROGRESS_SIZE := Vector2(210, 48)
const GOAL_TRACKER_PROGRESS_FONT_SIZE := 27
const GOAL_PROGRESS_UNMET_COLOR_HEX := "#d94f45"
const GOAL_PROGRESS_REQUIRED_COLOR_HEX := "#fffaf0"
const GOAL_PROGRESS_COMPLETE_COLOR_HEX := "#4f9b45"
const GOAL_PROGRESS_OUTLINE_COLOR := Color("#694237")
const CATCH_BUTTON_POSITION := Vector2(966, 562)
const HOME_BUTTON_POSITION := Vector2(30, 620)
const HOME_RETURN_PANEL_POSITION := Vector2(330, 205)
const HOME_RETURN_PANEL_SIZE := Vector2(620, 310)
const HOME_RETURN_BUTTON_SIZE := Vector2(225, 58)

# Pause icon geometry is shared across the fishing pause overlays.
const PAUSE_DIMMER_COLOR := Color(0.12, 0.09, 0.08, 0.13)
const PAUSE_CIRCLE_POSITION := Vector2(520, 240)
const PAUSE_CIRCLE_SIZE := Vector2(240, 240)
const PAUSE_BAR_SIZE := Vector2(34, 108)
const PAUSE_BAR_LEFT_POSITION := Vector2(68, 61)
const PAUSE_BAR_RIGHT_POSITION := Vector2(138, 61)

enum GameState {
	WAITING_FOR_FISH,
	READY_TO_CATCH,
	LIFTING_NET,
	SHOWING_RESULT,
	SHOWING_GOALS,
	ROUND_ENDED,
	PAUSED
}


var state := GameState.WAITING_FOR_FISH
var pet_id := "default_orange_cat"
var pet_name := "Companion"
var current_level := FISHING_LEVEL
var fish_caught := 0
var xp_earned := 0
var round_config: Dictionary = {}
var round_goals: Array[Dictionary] = []
var round_spawn_fish_ids: Array[String] = []
var round_time_limit_seconds := DEFAULT_ROUND_TIME_LIMIT_SECONDS
var round_difficulty_multiplier := 1.0
var round_target_pass_rate := 0.95
var round_catch_success_chance := CATCH_SUCCESS_CHANCE
var current_level_retry_count := 0
var round_spawn_total_multiplier := FishingLevelCatalogScript.spawn_total_multiplier(0.95)
var round_xp_reward := 0
var round_completion_xp_awarded := false
var round_completion_pending := false
var round_time_remaining := float(DEFAULT_ROUND_TIME_LIMIT_SECONDS)
var round_started := false
var round_goal_counts: Dictionary = {}
var active_fish: Array[Dictionary] = []
var hearts := MAX_HEARTS
var next_heart_restore_unix := 0
var shared_stats: Dictionary = {}

var rng := RandomNumberGenerator.new()
var stats_labels: Array[Label] = []
var stats_panel: Control
var fish_guide_panel: Control
var goal_progress_labels: Array[RichTextLabel] = []
var heart_panel: Control
var main_background_view: TextureRect
var pause_click_area: Button
var pause_overlay: Button
var state_before_pause := GameState.WAITING_FOR_FISH
var home_return_overlay: Control
var state_before_home_return := GameState.WAITING_FOR_FISH
var spawn_timer_paused_before_home_return := false
var returning_home := false
var pet_view: TextureRect
var net_view: TextureRect
var catch_hotspot: Button
var fish_layer: Control
var heart_views: Array[TextureRect] = []
var heart_timer_label: Label
var result_overlay: Control
var no_hearts_countdown_label: Label
var goal_popup_overlay: Button
var goal_popup_panel: Control
var goal_popup_fish_views: Array[TextureRect] = []
var goal_popup_count_labels: Array[Label] = []
var goal_popup_time_label: Label
var catch_popup_fish_views: Array[TextureRect] = []
var catch_popup_count_labels: Array[Label] = []
var unlocked_fish_ids: Array[String] = STARTER_FISH_IDS.duplicate()
var pending_new_fish_unlocks: Array[Dictionary] = []
var pending_catch_result_fishes: Array[Dictionary] = []
var new_fish_popup_view: TextureRect
var spawn_timer: Timer
var failure_sound_player: AudioStreamPlayer
var success_sound_player: AudioStreamPlayer
var round_spawn_sequence: Array[String] = []
var round_spawn_times: Array[float] = []
var round_planned_spawn_counts: Dictionary = {}
var round_required_fish_total := 0
var round_total_spawn_count := 0
var round_retry_target_spawn_bonus_per_goal := 0
var next_spawn_index := 0
var animation_frame_index := 0
var result_is_round_end := false
var round_failure_retry_pending := false
var no_hearts_popup_pending := false


func configure(pet: Dictionary, saved_stats: Dictionary = {}) -> void:
	pet_id = str(pet.get("id", "default_orange_cat")).to_lower()
	pet_name = str(pet.get("name", "Companion"))
	shared_stats = saved_stats.duplicate(true)
	current_level = maxi(
		int(saved_stats.get("fishing_level", FISHING_LEVEL)),
		FISHING_LEVEL
	)
	current_level_retry_count = (
		maxi(0, int(saved_stats.get("fishing_retry_count", 0)))
		if int(saved_stats.get("fishing_retry_level", 0)) == current_level
		else 0
	)
	unlocked_fish_ids.clear()
	for starter_fish_id in STARTER_FISH_IDS:
		unlocked_fish_ids.append(starter_fish_id)
	var saved_unlocked_fish_ids: Variant = saved_stats.get("unlocked_fish_ids", [])
	if saved_unlocked_fish_ids is Array:
		for fish_id_value in saved_unlocked_fish_ids:
			var fish_id := str(fish_id_value)
			if fish_id != "" and not unlocked_fish_ids.has(fish_id):
				unlocked_fish_ids.append(fish_id)
	hearts = clampi(int(saved_stats.get("hearts", MAX_HEARTS)), 0, MAX_HEARTS)
	next_heart_restore_unix = maxi(0, int(saved_stats.get("next_heart_restore_unix", 0)))
	_restore_hearts_at(int(Time.get_unix_time_from_system()), false)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.randomize()
	_build_audio_players()
	_load_round_configuration()
	_reset_round_goal_progress()
	_build_interface()
	_update_stats()
	_update_heart_display()
	_emit_shared_stats_changed()
	if hearts > 0:
		_show_goal_popup()
	else:
		_show_no_hearts_popup()


func _build_audio_players() -> void:
	failure_sound_player = AudioStreamPlayer.new()
	failure_sound_player.name = "FishingFailureSoundPlayer"
	failure_sound_player.stream = FISHING_FAILURE_SOUND
	failure_sound_player.bus = &"SFX"
	failure_sound_player.volume_db = -4.0
	failure_sound_player.max_polyphony = 1
	add_child(failure_sound_player)
	success_sound_player = AudioStreamPlayer.new()
	success_sound_player.name = "FishingSuccessSoundPlayer"
	success_sound_player.stream = FISHING_SUCCESS_SOUND
	success_sound_player.bus = &"SFX"
	success_sound_player.volume_db = -4.0
	success_sound_player.max_polyphony = 1
	add_child(success_sound_player)


func _play_failure_sound() -> void:
	if not is_instance_valid(failure_sound_player):
		return
	failure_sound_player.stop()
	failure_sound_player.play()


func _play_success_sound() -> void:
	if not is_instance_valid(success_sound_player):
		return
	success_sound_player.stop()
	success_sound_player.play()


func _process(delta: float) -> void:
	if _restore_hearts_at(int(Time.get_unix_time_from_system())):
		_update_heart_display()
	elif hearts <= 0:
		_update_heart_display()
	_update_no_hearts_countdown()
	_advance_round_timer(delta)


func _load_round_configuration() -> void:
	round_config = FishingLevelCatalogScript.level_config(current_level)
	round_goals.clear()
	for goal in round_config.get("goals", []):
		round_goals.append(Dictionary(goal).duplicate(true))
	round_spawn_fish_ids.clear()
	for fish_id in round_config.get("spawn_fish_ids", []):
		round_spawn_fish_ids.append(str(fish_id))
	round_time_limit_seconds = clampi(
		int(round_config.get("time_limit_seconds", DEFAULT_ROUND_TIME_LIMIT_SECONDS)),
		FishingLevelCatalogScript.MIN_TIME_LIMIT_SECONDS,
		FishingLevelCatalogScript.MAX_TIME_LIMIT_SECONDS
	)
	round_difficulty_multiplier = maxf(
		0.75,
		float(round_config.get("difficulty_multiplier", 1.0))
	)
	round_target_pass_rate = clampf(float(round_config.get("target_pass_rate", 0.75)), 0.0, 1.0)
	_update_round_catch_success_chance()
	round_spawn_total_multiplier = maxf(
		1.0,
		float(round_config.get(
			"spawn_total_multiplier",
			FishingLevelCatalogScript.spawn_total_multiplier(round_target_pass_rate)
		))
	)
	round_xp_reward = maxi(0, int(round_config.get("xp_reward", 0)))
	round_completion_xp_awarded = false
	round_completion_pending = false
	round_time_remaining = float(round_time_limit_seconds)
	_build_round_spawn_plan()


func _build_interface() -> void:
	main_background_view = _full_screen_texture(MAIN_SCREEN_TEXTURE)
	add_child(main_background_view)
	_build_pause_click_area()

	# The pet is a replaceable layer behind the shared net-and-human-hands art.
	# Maple uses six lifting poses. Mochi reacts with her own animation, while
	# Biscuit keeps the approved front-facing pose behind the shared net.
	pet_view = TextureRect.new()
	pet_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pet_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pet_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pet_view)

	net_view = TextureRect.new()
	net_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	net_view.stretch_mode = TextureRect.STRETCH_SCALE
	net_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	net_view.texture = NET_HANDS_TEXTURE
	net_view.visible = true
	add_child(net_view)
	_apply_animation_frame(0)

	# Swimming fish are intentionally drawn after the net. When they cross the
	# catch zone they sit visibly over the net mesh, creating the "fish in net"
	# effect instead of disappearing behind the animation artwork.
	fish_layer = Control.new()
	fish_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fish_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fish_layer)

	stats_panel = _build_stats_panel()
	add_child(stats_panel)
	_build_fish_guide()
	_build_heart_display()
	_build_back_button()
	_build_catch_hotspot()

	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_fish)
	add_child(spawn_timer)


func _build_pause_click_area() -> void:
	pause_click_area = Button.new()
	pause_click_area.name = "FishingPauseClickArea"
	pause_click_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_click_area.flat = true
	pause_click_area.focus_mode = Control.FOCUS_NONE
	pause_click_area.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_click_area.pressed.connect(_pause_game)
	add_child(pause_click_area)


func _build_stats_panel() -> Control:
	var panel := Control.new()
	panel.name = "FishingStatsPanel"
	panel.position = STATS_PANEL_POSITION
	panel.size = STATS_PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_make_panel_frame("StatsPanelFrame", STATS_PANEL_TEXTURE))
	var label := Label.new()
	label.name = "FishingLevelTimeLabel"
	GameFontStylesScript.apply_regular(label)
	label.position = STATS_LABEL_POSITION
	label.size = STATS_LABEL_SIZE
	label.add_theme_font_size_override("font_size", STATS_LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", Color("#54362b"))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	stats_labels.append(label)
	return panel


func _build_back_button() -> void:
	var button := Button.new()
	button.name = "FishingHomeButton"
	button.text = "← HOME"
	GameFontStylesScript.apply_regular(button)
	button.position = HOME_BUTTON_POSITION
	button.size = Vector2(154, 44)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", Color("#5a3b31"))
	button.add_theme_color_override("font_hover_color", Color("#5a3b31"))
	var normal := _panel_style(Color(1.0, 0.93, 0.75, 0.92), 16)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#fff0c9")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(_request_return_home)
	add_child(button)


func _request_return_home() -> void:
	if returning_home or is_instance_valid(home_return_overlay):
		return
	if not round_started or state == GameState.ROUND_ENDED or result_is_round_end:
		returning_home = true
		back_requested.emit()
		return
	# Result popups already block Home, including the final catch awaiting its
	# completion reward. Do not let another caller bypass their result flow.
	if is_instance_valid(result_overlay):
		return
	state_before_home_return = state
	spawn_timer_paused_before_home_return = spawn_timer.paused
	state = GameState.PAUSED
	spawn_timer.paused = true
	_set_active_fish_tweens_paused(true)
	_show_home_return_confirmation()


func _show_home_return_confirmation() -> void:
	home_return_overlay = Control.new()
	home_return_overlay.name = "FishingHomeReturnConfirmation"
	home_return_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	home_return_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(home_return_overlay)

	var dimmer := ColorRect.new()
	dimmer.color = CATCH_POPUP_DIMMER_COLOR
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_return_overlay.add_child(dimmer)

	var panel := Control.new()
	panel.name = "FishingHomeReturnPanel"
	panel.position = HOME_RETURN_PANEL_POSITION
	panel.size = HOME_RETURN_PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	home_return_overlay.add_child(panel)

	var background := TextureRect.new()
	background.texture = HOME_RETURN_POPUP_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)

	var title := _make_popup_label(
		"GO HOME?", Vector2(60, 30), Vector2(500, 65), 36, true
	)
	panel.add_child(title)
	var warning := _make_popup_label(
		"YOU WILL LOSE 1 HEART IF YOU LEAVE NOW.",
		Vector2(40, 96), Vector2(540, 86), 27, false
	)
	warning.name = "FishingHomeReturnWarning"
	panel.add_child(warning)

	var cancel_button := _make_home_style_popup_button(
		"KEEP PLAYING", _cancel_return_home, false, 26
	)
	cancel_button.name = "FishingHomeReturnCancelButton"
	cancel_button.position = Vector2(60, 210)
	cancel_button.size = HOME_RETURN_BUTTON_SIZE
	panel.add_child(cancel_button)

	var confirm_button := _make_home_style_popup_button(
		"GO HOME", _confirm_return_home, true, 26
	)
	confirm_button.name = "FishingHomeReturnConfirmButton"
	confirm_button.position = Vector2(335, 210)
	confirm_button.size = HOME_RETURN_BUTTON_SIZE
	panel.add_child(confirm_button)


func _cancel_return_home() -> void:
	if not is_instance_valid(home_return_overlay):
		return
	_clear_home_return_confirmation()
	state = state_before_home_return
	spawn_timer.paused = spawn_timer_paused_before_home_return
	if state != GameState.PAUSED:
		_set_active_fish_tweens_paused(false)


func _confirm_return_home() -> void:
	if returning_home or not is_instance_valid(home_return_overlay):
		return
	# Mark the exit before emitting stats or navigation signals so duplicate
	# clicks and an in-flight lift cannot charge again or finish the round.
	returning_home = true
	_clear_home_return_confirmation()
	round_started = false
	state = GameState.ROUND_ENDED
	catch_hotspot.disabled = true
	spawn_timer.stop()
	_remove_swimming_fishes()
	_consume_heart_for_failed_round()
	back_requested.emit()


func _clear_home_return_confirmation() -> void:
	if not is_instance_valid(home_return_overlay):
		return
	var overlay := home_return_overlay
	home_return_overlay = null
	remove_child(overlay)
	overlay.queue_free()


func _build_fish_guide() -> void:
	fish_guide_panel = Control.new()
	fish_guide_panel.name = "FishingFishTypesPanel"
	fish_guide_panel.position = FISH_TYPES_PANEL_POSITION
	fish_guide_panel.size = FISH_TYPES_PANEL_SIZE
	fish_guide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_guide_panel.add_child(_make_panel_frame("FishTypesPanelFrame", FISH_TYPES_PANEL_TEXTURE))
	add_child(fish_guide_panel)

	var title := Label.new()
	title.name = "FishingGoalTrackerTitle"
	title.text = "GOALS"
	GameFontStylesScript.apply_accent(title)
	title.position = GOAL_TRACKER_TITLE_POSITION
	title.size = GOAL_TRACKER_TITLE_SIZE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", GOAL_TRACKER_TITLE_FONT_SIZE)
	title.add_theme_color_override("font_color", Color("#52352c"))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fish_guide_panel.add_child(title)

	goal_progress_labels.clear()
	var visible_goal_count := mini(round_goals.size(), MAX_ROUND_GOAL_TYPES)
	for index in range(visible_goal_count):
		var goal: Dictionary = round_goals[index]
		var fish := _fish_definition(str(goal.get("fish_id", "green")))
		var icon := _make_fish_visual(
			fish,
			GOAL_TRACKER_FISH_SIZES[index],
			"goal_texture_region"
		)
		icon.name = "FishingGoalTrackerFish%d" % (index + 1)
		icon.position = GOAL_TRACKER_FISH_POSITIONS[index]
		fish_guide_panel.add_child(icon)

		var progress := RichTextLabel.new()
		progress.name = "FishingGoalTrackerProgress%d" % (index + 1)
		progress.bbcode_enabled = true
		progress.scroll_active = false
		progress.fit_content = false
		progress.autowrap_mode = TextServer.AUTOWRAP_OFF
		progress.position = GOAL_TRACKER_PROGRESS_POSITIONS[index]
		progress.size = GOAL_TRACKER_PROGRESS_SIZE
		progress.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		progress.add_theme_font_override("normal_font", GameFontStylesScript.REGULAR_FONT)
		progress.add_theme_font_size_override(
			"normal_font_size",
			GOAL_TRACKER_PROGRESS_FONT_SIZE
		)
		progress.add_theme_color_override("font_outline_color", GOAL_PROGRESS_OUTLINE_COLOR)
		progress.add_theme_constant_override("outline_size", 1)
		progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fish_guide_panel.add_child(progress)
		goal_progress_labels.append(progress)
	_update_goal_tracker()


func _rebuild_fish_guide() -> void:
	if is_instance_valid(fish_guide_panel):
		var previous_panel := fish_guide_panel
		fish_guide_panel = null
		if previous_panel.get_parent() != null:
			previous_panel.get_parent().remove_child(previous_panel)
		previous_panel.queue_free()
	goal_progress_labels.clear()
	_build_fish_guide()


func _build_heart_display() -> void:
	heart_panel = Control.new()
	heart_panel.name = "FishingHeartPanel"
	heart_panel.position = HEART_PANEL_POSITION
	heart_panel.size = HEART_PANEL_SIZE
	heart_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_panel.add_child(_make_panel_frame("HeartPanelFrame", HEART_PANEL_TEXTURE))
	add_child(heart_panel)

	heart_views.clear()
	for index in range(MAX_HEARTS):
		var heart := TextureRect.new()
		heart.name = "FishingHeart%d" % (index + 1)
		heart.texture = HEART_TEXTURE
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.size = Vector2(34, 34)
		heart.mouse_filter = Control.MOUSE_FILTER_IGNORE
		heart_panel.add_child(heart)
		heart_views.append(heart)
	heart_timer_label = Label.new()
	GameFontStylesScript.apply_regular(heart_timer_label)
	heart_timer_label.position = Vector2(14, 18)
	heart_timer_label.size = Vector2(282, 44)
	heart_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heart_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heart_timer_label.add_theme_font_size_override("font_size", 24)
	heart_timer_label.add_theme_color_override("font_color", Color("#543a32"))
	heart_timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	heart_panel.add_child(heart_timer_label)


func _build_catch_hotspot() -> void:
	# The background no longer contains a baked button, so this is a fully movable
	# independent control.
	catch_hotspot = Button.new()
	catch_hotspot.position = CATCH_BUTTON_POSITION
	catch_hotspot.size = Vector2(272, 118)
	catch_hotspot.text = "CATCH!"
	catch_hotspot.focus_mode = Control.FOCUS_NONE
	catch_hotspot.add_theme_font_size_override("font_size", 50)
	catch_hotspot.add_theme_color_override("font_color", Color.WHITE)
	catch_hotspot.add_theme_color_override("font_hover_color", Color.WHITE)
	catch_hotspot.add_theme_color_override("font_disabled_color", Color("#fff4e6"))
	GameFontStylesScript.apply_button(catch_hotspot)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#e97852")
	normal.border_color = Color("#a94f39")
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(31)
	normal.shadow_color = Color(0.20, 0.08, 0.05, 0.27)
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 4)
	catch_hotspot.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#f1855d")
	catch_hotspot.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("#ca5e43")
	pressed.shadow_size = 2
	catch_hotspot.add_theme_stylebox_override("pressed", pressed)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color("#d96d4d")
	disabled.border_color = Color("#984936")
	disabled.shadow_size = 4
	disabled.shadow_color = Color(0.20, 0.08, 0.05, 0.20)
	catch_hotspot.add_theme_stylebox_override("disabled", disabled)
	catch_hotspot.pressed.connect(request_catch)
	add_child(catch_hotspot)


func _pause_game() -> void:
	if (
		not round_started
		or round_time_remaining <= 0.0
		or is_instance_valid(goal_popup_overlay)
		or is_instance_valid(result_overlay)
		or state not in [
			GameState.WAITING_FOR_FISH,
			GameState.READY_TO_CATCH,
			GameState.LIFTING_NET
		]
	):
		return
	state_before_pause = state
	state = GameState.PAUSED
	spawn_timer.paused = true
	_set_active_fish_tweens_paused(true)

	pause_overlay = Button.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.flat = true
	pause_overlay.focus_mode = Control.FOCUS_NONE
	pause_overlay.pressed.connect(_resume_from_pause)
	add_child(pause_overlay)

	var soft_dimmer := ColorRect.new()
	soft_dimmer.name = "PauseDimmer"
	soft_dimmer.color = PAUSE_DIMMER_COLOR
	soft_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	soft_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_overlay.add_child(soft_dimmer)

	var pause_circle := Panel.new()
	pause_circle.name = "PauseCircle"
	pause_circle.position = PAUSE_CIRCLE_POSITION
	pause_circle.size = PAUSE_CIRCLE_SIZE
	pause_circle.modulate = Color(1.0, 1.0, 1.0, 0.72)
	pause_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var circle_style := StyleBoxFlat.new()
	circle_style.bg_color = Color("#e97857")
	circle_style.border_color = Color("#8f493b")
	circle_style.set_border_width_all(5)
	circle_style.set_corner_radius_all(120)
	circle_style.shadow_color = Color(0.33, 0.16, 0.12, 0.22)
	circle_style.shadow_size = 9
	circle_style.shadow_offset = Vector2(0, 5)
	pause_circle.add_theme_stylebox_override("panel", circle_style)
	pause_overlay.add_child(pause_circle)

	pause_circle.add_child(_make_pause_bar(
		"PauseBarLeft",
		PAUSE_BAR_LEFT_POSITION
	))
	pause_circle.add_child(_make_pause_bar(
		"PauseBarRight",
		PAUSE_BAR_RIGHT_POSITION
	))


func _make_pause_bar(node_name: String, position_value: Vector2) -> Panel:
	var bar := Panel.new()
	bar.name = node_name
	bar.position = position_value
	bar.size = PAUSE_BAR_SIZE
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff0c8")
	style.border_color = Color("#7d4036")
	style.set_border_width_all(4)
	style.set_corner_radius_all(10)
	bar.add_theme_stylebox_override("panel", style)
	return bar


func _resume_from_pause() -> void:
	if state != GameState.PAUSED or is_instance_valid(home_return_overlay):
		return
	if is_instance_valid(pause_overlay):
		pause_overlay.queue_free()
	pause_overlay = null
	state = state_before_pause
	spawn_timer.paused = false
	_set_active_fish_tweens_paused(false)


func _set_active_fish_tweens_paused(should_pause: bool) -> void:
	for entry in active_fish:
		var tween = entry.get("tween")
		if tween == null or not tween.is_valid():
			continue
		if should_pause:
			tween.pause()
		else:
			tween.play()


func _show_goal_popup() -> void:
	if is_instance_valid(goal_popup_overlay):
		return
	state = GameState.SHOWING_GOALS
	catch_hotspot.disabled = true
	spawn_timer.stop()

	goal_popup_overlay = Button.new()
	goal_popup_overlay.name = "FishingGoalPopupOverlay"
	goal_popup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	goal_popup_overlay.flat = true
	goal_popup_overlay.focus_mode = Control.FOCUS_NONE
	goal_popup_overlay.pressed.connect(_start_round_from_goal_popup)
	add_child(goal_popup_overlay)

	var dimmer := ColorRect.new()
	dimmer.name = "FishingGoalPopupDimmer"
	dimmer.color = GOAL_POPUP_DIMMER_COLOR
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_popup_overlay.add_child(dimmer)

	goal_popup_panel = Control.new()
	goal_popup_panel.name = "FishingGoalPopupPanel"
	goal_popup_panel.position = GOAL_POPUP_PANEL_POSITION
	goal_popup_panel.size = GOAL_POPUP_PANEL_SIZE
	goal_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_popup_overlay.add_child(goal_popup_panel)

	var background := TextureRect.new()
	background.name = "FishingGoalPopupBackground"
	background.texture = GOAL_POPUP_TEXTURE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_popup_panel.add_child(background)

	var title := _make_popup_label(
		"YOU NEED TO CATCH!",
		GOAL_POPUP_TITLE_POSITION,
		GOAL_POPUP_TITLE_SIZE,
		GOAL_POPUP_TITLE_FONT_SIZE,
		true
	)
	title.name = "FishingGoalPopupTitle"
	goal_popup_panel.add_child(title)

	goal_popup_fish_views.clear()
	goal_popup_count_labels.clear()
	var visible_goal_count := mini(round_goals.size(), MAX_ROUND_GOAL_TYPES)
	for index in range(visible_goal_count):
		var goal: Dictionary = round_goals[index]
		var fish := _fish_definition(str(goal.get("fish_id", "green")))
		var fish_view := _make_fish_visual(
			fish,
			GOAL_POPUP_FISH_SIZES[index],
			"goal_texture_region"
		)
		fish_view.name = "FishingGoalPopupFish%d" % (index + 1)
		fish_view.position = GOAL_POPUP_FISH_POSITIONS[index]
		goal_popup_panel.add_child(fish_view)
		goal_popup_fish_views.append(fish_view)

		var count_label := _make_popup_label(
			"X %d" % int(goal.get("count", 0)),
			GOAL_POPUP_COUNT_POSITIONS[index],
			GOAL_POPUP_COUNT_SIZE,
			GOAL_POPUP_COUNT_FONT_SIZE
		)
		count_label.name = "FishingGoalPopupCount%d" % (index + 1)
		goal_popup_panel.add_child(count_label)
		goal_popup_count_labels.append(count_label)

	var time_title := _make_popup_label(
		"TIME LIMIT",
		GOAL_POPUP_TIME_TITLE_POSITION,
		GOAL_POPUP_TIME_TITLE_SIZE,
		GOAL_POPUP_TIME_TITLE_FONT_SIZE
	)
	time_title.name = "FishingGoalPopupTimeTitle"
	goal_popup_panel.add_child(time_title)

	goal_popup_time_label = _make_popup_label(
		_format_countdown(round_time_limit_seconds),
		GOAL_POPUP_TIMER_POSITION,
		GOAL_POPUP_TIMER_SIZE,
		GOAL_POPUP_TIMER_FONT_SIZE,
		true
	)
	goal_popup_time_label.name = "FishingGoalPopupTimer"
	goal_popup_panel.add_child(goal_popup_time_label)

	var footer := _make_popup_label(
		"CLICK ANYWHERE TO START",
		GOAL_POPUP_FOOTER_POSITION,
		GOAL_POPUP_FOOTER_SIZE,
		GOAL_POPUP_FOOTER_FONT_SIZE
	)
	footer.name = "FishingGoalPopupFooter"
	goal_popup_panel.add_child(footer)


func _make_popup_label(
	text: String,
	label_position: Vector2,
	label_size: Vector2,
	font_size: int,
	accent := false,
	regular_color := GOAL_POPUP_TEXT_COLOR
) -> Label:
	var label := Label.new()
	label.text = GameFontStylesScript.display_text(text)
	if accent:
		GameFontStylesScript.apply_accent(label)
	else:
		GameFontStylesScript.apply_regular(label)
	label.position = label_position
	label.size = label_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	if not accent:
		label.add_theme_color_override("font_color", regular_color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _fish_definition(fish_id: String) -> Dictionary:
	return FishCatalogScript.definition(fish_id)


func _start_round_from_goal_popup() -> void:
	if state != GameState.SHOWING_GOALS:
		return
	if is_instance_valid(goal_popup_overlay):
		goal_popup_overlay.queue_free()
	goal_popup_overlay = null
	goal_popup_panel = null
	goal_popup_fish_views.clear()
	goal_popup_count_labels.clear()
	goal_popup_time_label = null
	round_time_remaining = float(round_time_limit_seconds)
	round_started = true
	next_spawn_index = 0
	state = GameState.WAITING_FOR_FISH
	catch_hotspot.disabled = true
	_update_stats()
	_schedule_next_planned_spawn()


func _reset_round_goal_progress() -> void:
	round_goal_counts.clear()
	var visible_goal_count := mini(round_goals.size(), MAX_ROUND_GOAL_TYPES)
	for index in range(visible_goal_count):
		var fish_id := str(round_goals[index].get("fish_id", "green"))
		round_goal_counts[fish_id] = 0
	_update_goal_tracker()


func _record_round_goal_catches(caught_fishes: Array[Dictionary]) -> void:
	for fish in caught_fishes:
		var fish_id := str(fish.get("id", ""))
		if not round_goal_counts.has(fish_id):
			continue
		var required_count := _required_goal_count(fish_id)
		var current_count := int(round_goal_counts.get(fish_id, 0))
		round_goal_counts[fish_id] = mini(required_count, current_count + 1)
	_update_goal_tracker()


func _required_goal_count(fish_id: String) -> int:
	for goal in round_goals:
		if str(goal.get("fish_id", "")) == fish_id:
			return maxi(0, int(goal.get("count", 0)))
	return 0


func _update_goal_tracker() -> void:
	var visible_goal_count := mini(
		round_goals.size(),
		mini(MAX_ROUND_GOAL_TYPES, goal_progress_labels.size())
	)
	for index in range(visible_goal_count):
		var goal: Dictionary = round_goals[index]
		var fish_id := str(goal.get("fish_id", "green"))
		var required_count := maxi(0, int(goal.get("count", 0)))
		var current_count := mini(
			required_count,
			maxi(0, int(round_goal_counts.get(fish_id, 0)))
		)
		goal_progress_labels[index].text = _goal_progress_markup(
			current_count,
			required_count
		)


func _goal_progress_markup(current_count: int, required_count: int) -> String:
	if current_count >= required_count:
		return (
			"[color=%s]: [/color][color=%s]%d/%d[/color]"
			% [
				GOAL_PROGRESS_REQUIRED_COLOR_HEX,
				GOAL_PROGRESS_COMPLETE_COLOR_HEX,
				required_count,
				required_count
			]
		)
	return (
		"[color=%s]: [/color][color=%s]%d[/color][color=%s]/%d[/color]"
		% [
			GOAL_PROGRESS_REQUIRED_COLOR_HEX,
			GOAL_PROGRESS_UNMET_COLOR_HEX,
			current_count,
			GOAL_PROGRESS_REQUIRED_COLOR_HEX,
			required_count
		]
	)


func _round_timer_is_running() -> bool:
	return (
		round_started
		and round_time_remaining > 0.0
		and state in [
			GameState.WAITING_FOR_FISH,
			GameState.READY_TO_CATCH
		]
	)


func _advance_round_timer(delta: float) -> void:
	if not _round_timer_is_running():
		return
	var previous_second := ceili(round_time_remaining)
	round_time_remaining = maxf(0.0, round_time_remaining - maxf(0.0, delta))
	if ceili(round_time_remaining) != previous_second:
		_update_stats()
	if round_time_remaining <= 0.0 and state != GameState.LIFTING_NET:
		_end_round()


func _end_round(preserve_time_remaining := false) -> void:
	if result_is_round_end and is_instance_valid(result_overlay):
		return
	if not preserve_time_remaining:
		round_time_remaining = 0.0
	round_completion_pending = false
	spawn_timer.stop()
	_remove_swimming_fishes()
	state = GameState.ROUND_ENDED
	catch_hotspot.disabled = true
	_apply_animation_frame(0)
	_update_stats()
	result_is_round_end = true
	if _round_goals_completed():
		round_failure_retry_pending = false
		_show_round_success()
	else:
		_record_failed_level_attempt()
		_consume_heart_for_failed_round()
		round_failure_retry_pending = true
		_show_round_failure()


func _round_goals_completed() -> bool:
	var visible_goal_count := mini(round_goals.size(), MAX_ROUND_GOAL_TYPES)
	for index in range(visible_goal_count):
		var goal: Dictionary = round_goals[index]
		var fish_id := str(goal.get("fish_id", "green"))
		var required_count := maxi(0, int(goal.get("count", 0)))
		if int(round_goal_counts.get(fish_id, 0)) < required_count:
			return false
	return true


func _spawn_fish() -> void:
	if (
		not round_started
		or round_time_remaining <= 0.0
		or next_spawn_index >= round_spawn_sequence.size()
		or state in [
			GameState.LIFTING_NET,
			GameState.SHOWING_RESULT,
			GameState.SHOWING_GOALS,
			GameState.ROUND_ENDED,
			GameState.PAUSED
		]
	):
		return
	spawn_timer.stop()
	state = GameState.READY_TO_CATCH
	catch_hotspot.disabled = false
	var fish_id := round_spawn_sequence[next_spawn_index]
	next_spawn_index += 1
	_spawn_single_fish(0, fish_id)
	_schedule_next_planned_spawn()


func _spawn_single_fish(index: int, fish_id: String) -> void:
	var fish := _fish_definition(fish_id)
	var view := _make_fish_visual(fish, _swimming_fish_size(fish))
	view.position = Vector2(
		-view.size.x - 35.0 - float(index) * rng.randf_range(75.0, 135.0),
		_pick_swim_y()
	)
	# The river current moves left-to-right, so every swimming fish faces right.
	view.pivot_offset = view.size * 0.5
	view.scale.x = -1.0
	fish_layer.add_child(view)
	var tween := create_tween()
	var species_speed := maxf(0.55, float(fish.get("speed_multiplier", 1.0)))
	var effective_speed := species_speed * round_difficulty_multiplier
	var travel_time := (
		(rng.randf_range(5.2, 7.4) + float(index) * 0.28)
		/ effective_speed
	)
	tween.tween_property(view, "position:x", 1310.0 + view.size.x, travel_time)
	var entry := {"fish": fish, "view": view, "tween": tween}
	active_fish.append(entry)
	tween.finished.connect(_on_fish_swim_finished.bind(view))


func _pick_swim_y() -> float:
	for attempt in range(12):
		var candidate := rng.randf_range(RIVER_SWIM_MIN_Y, RIVER_SWIM_MAX_Y)
		var overlaps := active_fish.any(func(entry):
			var existing_view: TextureRect = entry.get("view")
			return is_instance_valid(existing_view) and absf(existing_view.position.y - candidate) < 48.0
		)
		if not overlaps or attempt == 11:
			return candidate
	return RIVER_SWIM_MIN_Y


func _on_fish_swim_finished(view: TextureRect) -> void:
	for index in range(active_fish.size() - 1, -1, -1):
		if active_fish[index].get("view") == view:
			active_fish.remove_at(index)
			break
	if is_instance_valid(view):
		view.queue_free()
	if active_fish.is_empty() and state == GameState.READY_TO_CATCH:
		state = GameState.WAITING_FOR_FISH
		catch_hotspot.disabled = true


func request_catch() -> void:
	if (
		not round_started
		or round_time_remaining <= 0.0
		or state in [
			GameState.LIFTING_NET,
			GameState.SHOWING_RESULT,
			GameState.SHOWING_GOALS,
			GameState.ROUND_ENDED,
			GameState.PAUSED
		]
	):
		return
	spawn_timer.stop()
	state = GameState.LIFTING_NET
	catch_hotspot.disabled = true
	_stop_fish_motion()
	var caught_fishes: Array[Dictionary] = []
	var caught_visuals: Array[TextureRect] = []
	for entry in active_fish:
		var view: TextureRect = entry.get("view")
		if _fish_entry_is_in_catch_zone(entry) and catch_succeeds(true, rng.randf()):
			var fish: Dictionary = entry.get("fish", {})
			caught_fishes.append(fish.duplicate(true))
			if is_instance_valid(view):
				caught_visuals.append(view)
		elif is_instance_valid(view):
			view.queue_free()
	await _play_lift_animation(caught_visuals, not caught_fishes.is_empty())
	if not is_inside_tree() or returning_home:
		return
	_remove_swimming_fishes()
	_finish_attempt(caught_fishes)


func is_fish_in_catch_zone(entry: Dictionary = {}) -> bool:
	if state != GameState.READY_TO_CATCH or active_fish.is_empty():
		return false
	if not entry.is_empty():
		return _fish_entry_is_in_catch_zone(entry)
	return active_fish.any(func(item): return _fish_entry_is_in_catch_zone(item))


func _fish_entry_is_in_catch_zone(entry: Dictionary) -> bool:
	var view: TextureRect = entry.get("view")
	if not is_instance_valid(view):
		return false
	var fish_center := view.position + view.size * 0.5
	return NET_CATCH_ZONE.has_point(fish_center)


func catch_succeeds(fish_is_inside_net: bool, roll: float) -> bool:
	return fish_is_inside_net and roll < round_catch_success_chance


func _update_round_catch_success_chance() -> void:
	var base_catch_chance := clampf(
		float(round_config.get("catch_success_chance", CATCH_SUCCESS_CHANCE)),
		0.0,
		1.0
	)
	var base_escape_chance := 1.0 - base_catch_chance
	var assisted_escape_chance := maxf(
		0.0,
		base_escape_chance - float(current_level_retry_count) * RETRY_ESCAPE_REDUCTION
	)
	round_catch_success_chance = 1.0 - assisted_escape_chance


func _record_failed_level_attempt() -> void:
	current_level_retry_count += 1
	_update_round_catch_success_chance()


func _retry_target_spawn_bonus_per_goal() -> int:
	var base_catch_chance := clampf(
		float(round_config.get("catch_success_chance", CATCH_SUCCESS_CHANCE)),
		0.0,
		1.0
	)
	var base_escape_chance := 1.0 - base_catch_chance
	# The epsilon prevents exact three-percent steps such as fifteen percent
	# from rounding up to one extra retry because of floating-point noise.
	var retries_until_guaranteed := ceili(
		maxf(0.0, base_escape_chance - 0.000001) / RETRY_ESCAPE_REDUCTION
	)
	return maxi(0, current_level_retry_count - retries_until_guaranteed)


func _play_lift_animation(
	caught_fish_visuals: Array[TextureRect] = [],
	caught_any_fish := false
) -> void:
	var fish_start_positions: Array[Vector2] = []
	for view in caught_fish_visuals:
		fish_start_positions.append(view.position if is_instance_valid(view) else Vector2.ZERO)
	var pet_reaction_frames: Array[Texture2D] = []
	if _uses_mochi_fishing_art():
		pet_reaction_frames = (
			MOCHI_FISHING_SUCCESS_FRAMES
			if caught_any_fish
			else MOCHI_FISHING_CRY_FRAMES
		)
	elif _uses_biscuit_fishing_art() and caught_any_fish:
		pet_reaction_frames = BISCUIT_FISHING_WINK_FRAMES
	elif _uses_luna_fishing_art() and caught_any_fish:
		pet_reaction_frames = LUNA_FISHING_SUCCESS_FRAMES
	elif _uses_poppy_fishing_art() and caught_any_fish:
		pet_reaction_frames = POPPY_FISHING_SUCCESS_FRAMES
	elif _uses_black_cat_fishing_art() and caught_any_fish:
		pet_reaction_frames = BLACK_CAT_FISHING_SUCCESS_FRAMES
	elif _uses_maine_coon_fishing_art() and caught_any_fish:
		pet_reaction_frames = MAINE_COON_FISHING_SUCCESS_FRAMES
	elif _uses_golden_munchkin_fishing_art() and caught_any_fish:
		pet_reaction_frames = GOLDEN_MUNCHKIN_FISHING_SUCCESS_FRAMES
	elif _uses_siamese_fishing_art() and caught_any_fish:
		pet_reaction_frames = SIAMESE_FISHING_SUCCESS_FRAMES
	for index in range(FRAME_DURATIONS.size()):
		if not is_inside_tree() or returning_home:
			return
		_apply_animation_frame(index)
		for fish_index in range(caught_fish_visuals.size()):
			var view := caught_fish_visuals[fish_index]
			if is_instance_valid(view):
				view.position = fish_start_positions[fish_index] + Vector2(
					0.0,
					CAUGHT_FISH_LIFT_OFFSETS[index]
				)
		if pet_reaction_frames.is_empty():
			await _wait_for_unpaused_gameplay_time(FRAME_DURATIONS[index])
		elif index < FRAME_DURATIONS.size() - 1:
			pet_view.texture = pet_reaction_frames[index]
			await _wait_for_unpaused_gameplay_time(FRAME_DURATIONS[index])
		else:
			# Custom pet reactions have eight frames while the net has six. Play
			# the final three inside the net's existing 0.30-second hold so
			# the catch interaction stays just as responsive as Maple's.
			for final_offset in range(CUSTOM_FINAL_REACTION_FRAME_DURATIONS.size()):
				if not is_inside_tree() or returning_home:
					return
				pet_view.texture = pet_reaction_frames[index + final_offset]
				await _wait_for_unpaused_gameplay_time(
					CUSTOM_FINAL_REACTION_FRAME_DURATIONS[final_offset]
				)


func _wait_for_unpaused_gameplay_time(duration: float) -> void:
	var remaining := maxf(0.0, duration)
	while remaining > 0.0 and is_inside_tree() and not returning_home:
		await get_tree().process_frame
		if state != GameState.PAUSED:
			remaining -= get_process_delta_time()


func _finish_attempt(caught_fishes: Array[Dictionary]) -> void:
	spawn_timer.stop()
	state = GameState.SHOWING_RESULT
	result_is_round_end = false
	pending_new_fish_unlocks.clear()
	pending_catch_result_fishes.clear()
	if not caught_fishes.is_empty():
		_play_success_sound()
		fish_caught += caught_fishes.size()
		_record_round_goal_catches(caught_fishes)
		round_completion_pending = _round_goals_completed()
		if round_completion_pending:
			spawn_timer.stop()
			catch_hotspot.disabled = true
		pending_new_fish_unlocks = _register_new_fish_unlocks(caught_fishes)
		for fish in caught_fishes:
			pending_catch_result_fishes.append(fish.duplicate(true))
		_emit_shared_stats_changed()
		catch_completed.emit(true, fish_caught, xp_earned)
		_show_next_catch_popup()
	else:
		catch_completed.emit(false, fish_caught, xp_earned)
		_show_failure()
	_update_stats()


func _register_new_fish_unlocks(caught_fishes: Array[Dictionary]) -> Array[Dictionary]:
	var newly_unlocked: Array[Dictionary] = []
	for fish in caught_fishes:
		var fish_id := str(fish.get("id", ""))
		if fish_id == "" or unlocked_fish_ids.has(fish_id):
			continue
		unlocked_fish_ids.append(fish_id)
		newly_unlocked.append(fish.duplicate(true))
	shared_stats["unlocked_fish_ids"] = unlocked_fish_ids.duplicate()
	return newly_unlocked


func _show_next_catch_popup() -> void:
	if not pending_new_fish_unlocks.is_empty():
		var newly_unlocked_fish: Dictionary = pending_new_fish_unlocks.pop_front()
		_show_new_fish_unlock(newly_unlocked_fish)
		return
	var caught_fishes: Array[Dictionary] = []
	for fish in pending_catch_result_fishes:
		caught_fishes.append(fish.duplicate(true))
	pending_catch_result_fishes.clear()
	_show_catch_result(caught_fishes)


## Deterministic entry point for smoke tests and future debug tooling.
## Gameplay uses request_catch(), which plays the animation and rolls normally.
func resolve_catch_for_test(succeeded := true, fish_index := 0) -> void:
	var safe_index := clampi(fish_index, 0, FISH_TYPES.size() - 1)
	var caught_fishes: Array[Dictionary] = []
	if succeeded:
		caught_fishes.append(FISH_TYPES[safe_index].duplicate(true))
	_remove_swimming_fishes()
	_finish_attempt(caught_fishes)


func resolve_catch_batch_for_test(fish_indices: Array) -> void:
	var caught_fishes: Array[Dictionary] = []
	for fish_index in fish_indices:
		var safe_index := clampi(fish_index, 0, FISH_TYPES.size() - 1)
		caught_fishes.append(FISH_TYPES[safe_index].duplicate(true))
	_remove_swimming_fishes()
	_finish_attempt(caught_fishes)


func _show_new_fish_unlock(fish: Dictionary) -> void:
	var overlay := Button.new()
	overlay.name = "FishingNewFishPopupOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.flat = true
	overlay.focus_mode = Control.FOCUS_NONE
	overlay.pressed.connect(_dismiss_new_fish_unlock)
	result_overlay = overlay
	add_child(overlay)

	var panel := _build_celebration_panel(
		result_overlay,
		"FishingNewFishPopupPanel",
		"FishingNewFishPopupBackground"
	)

	var title := _make_popup_label(
		"CONGRATULATIONS!",
		CELEBRATION_TITLE_POSITION,
		CELEBRATION_TITLE_SIZE,
		CELEBRATION_TITLE_FONT_SIZE,
		true
	)
	title.name = "FishingNewFishPopupTitle"
	panel.add_child(title)

	var subtitle := _make_popup_label(
		"YOU UNLOCKED:",
		NEW_FISH_SUBTITLE_POSITION,
		NEW_FISH_SUBTITLE_SIZE,
		NEW_FISH_SUBTITLE_FONT_SIZE,
		false,
		CELEBRATION_REGULAR_TEXT_COLOR
	)
	subtitle.name = "FishingNewFishPopupSubtitle"
	panel.add_child(subtitle)

	new_fish_popup_view = _make_fish_visual(fish, NEW_FISH_ICON_SIZE)
	new_fish_popup_view.name = "FishingNewFishPopupFish"
	new_fish_popup_view.position = NEW_FISH_ICON_POSITION
	panel.add_child(new_fish_popup_view)

	var info_line_one := _make_popup_label(
		"FIND OUT MORE IN THE FISH",
		NEW_FISH_INFO_LINE_ONE_POSITION,
		NEW_FISH_INFO_LINE_ONE_SIZE,
		NEW_FISH_INFO_FONT_SIZE,
		false,
		CELEBRATION_REGULAR_TEXT_COLOR
	)
	info_line_one.name = "FishingNewFishPopupInfoLineOne"
	panel.add_child(info_line_one)

	var info_line_two := _make_popup_label(
		"ENCYCLOPEDIA",
		NEW_FISH_INFO_LINE_TWO_POSITION,
		NEW_FISH_INFO_LINE_TWO_SIZE,
		NEW_FISH_INFO_FONT_SIZE,
		false,
		CELEBRATION_REGULAR_TEXT_COLOR
	)
	info_line_two.name = "FishingNewFishPopupInfoLineTwo"
	panel.add_child(info_line_two)

	var footer := _make_popup_label(
		"CLICK ANYWHERE TO CONTINUE",
		NEW_FISH_FOOTER_POSITION,
		NEW_FISH_FOOTER_SIZE,
		NEW_FISH_FOOTER_FONT_SIZE,
		false,
		CELEBRATION_REGULAR_TEXT_COLOR
	)
	footer.name = "FishingNewFishPopupFooter"
	panel.add_child(footer)


func _dismiss_new_fish_unlock() -> void:
	_clear_result_overlay()
	new_fish_popup_view = null
	_show_next_catch_popup()


func _show_catch_result(caught_fishes: Array[Dictionary]) -> void:
	_show_catch_result_page(_aggregate_caught_fishes(caught_fishes), 0)


func _show_catch_result_page(caught_rows: Array[Dictionary], page_index: int) -> void:
	var first_row_index := page_index * MAX_CATCH_POPUP_FISH_TYPES
	var last_row_index := mini(first_row_index + MAX_CATCH_POPUP_FISH_TYPES, caught_rows.size())
	var page_rows := caught_rows.slice(first_row_index, last_row_index)
	var use_two_columns := page_rows.size() > CATCH_POPUP_ROWS_PER_COLUMN
	var overlay := Button.new()
	overlay.name = "FishingCatchPopupOverlay"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.flat = true
	overlay.focus_mode = Control.FOCUS_NONE
	overlay.pressed.connect(_advance_catch_result_page.bind(caught_rows, page_index))
	result_overlay = overlay
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.name = "FishingCatchPopupDimmer"
	dimmer.color = CATCH_POPUP_DIMMER_COLOR
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_overlay.add_child(dimmer)

	var panel := Control.new()
	panel.name = "FishingCatchPopupPanel"
	panel.position = CATCH_POPUP_PANEL_POSITION
	panel.size = CATCH_POPUP_PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_overlay.add_child(panel)

	var background := TextureRect.new()
	background.name = "FishingCatchPopupBackground"
	background.texture = CATCH_POPUP_TEXTURE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)

	var title := _make_popup_label(
		"YOU CAUGHT:",
		CATCH_POPUP_TITLE_POSITION,
		CATCH_POPUP_TITLE_SIZE,
		CATCH_POPUP_TITLE_FONT_SIZE,
		true
	)
	title.name = "FishingCatchPopupTitle"
	panel.add_child(title)

	catch_popup_fish_views.clear()
	catch_popup_count_labels.clear()
	for index in range(page_rows.size()):
		var row: Dictionary = page_rows[index]
		var fish: Dictionary = row.get("fish", {})
		var row_index := floori(float(index) / 2.0) if use_two_columns else index
		var fish_slot_position := CATCH_POPUP_FISH_POSITIONS[row_index]
		var fish_slot_size := CATCH_POPUP_FISH_SIZE
		var count_position := CATCH_POPUP_COUNT_POSITIONS[row_index]
		var count_size := CATCH_POPUP_COUNT_SIZE
		var count_font_size := CATCH_POPUP_COUNT_FONT_SIZE
		if use_two_columns:
			var cell_offset := Vector2(index % 2, row_index) * CATCH_POPUP_TWO_COLUMN_STEP
			fish_slot_position = CATCH_POPUP_TWO_COLUMN_FISH_ORIGIN + cell_offset
			fish_slot_size = CATCH_POPUP_TWO_COLUMN_FISH_SIZE
			count_position = CATCH_POPUP_TWO_COLUMN_COUNT_ORIGIN + cell_offset
			count_size = CATCH_POPUP_TWO_COLUMN_COUNT_SIZE
			count_font_size = CATCH_POPUP_TWO_COLUMN_COUNT_FONT_SIZE
		var fish_size := _catch_popup_fish_size(fish, fish_slot_size)
		var fish_view := _make_fish_visual(fish, fish_size)
		fish_view.name = "FishingCatchPopupFish%d" % (index + 1)
		fish_view.set_meta("fish_id", str(fish.get("id", "green")))
		fish_view.position = (
			fish_slot_position + (fish_slot_size - fish_size) * 0.5
		)
		panel.add_child(fish_view)
		catch_popup_fish_views.append(fish_view)

		var count_label := _make_popup_label(
			"X %d" % int(row.get("count", 0)),
			count_position,
			count_size,
			count_font_size,
			false,
			CATCH_POPUP_TEXT_COLOR
		)
		count_label.name = "FishingCatchPopupCount%d" % (index + 1)
		panel.add_child(count_label)
		catch_popup_count_labels.append(count_label)

	var footer := _make_popup_label(
		"CLICK ANYWHERE TO SEE MORE"
			if last_row_index < caught_rows.size()
			else "CLICK ANYWHERE TO CONTINUE",
		CATCH_POPUP_FOOTER_POSITION,
		CATCH_POPUP_FOOTER_SIZE,
		CATCH_POPUP_FOOTER_FONT_SIZE,
		false,
		CATCH_POPUP_TEXT_COLOR
	)
	footer.name = "FishingCatchPopupFooter"
	panel.add_child(footer)


func _advance_catch_result_page(caught_rows: Array[Dictionary], page_index: int) -> void:
	var next_page_index := page_index + 1
	if next_page_index * MAX_CATCH_POPUP_FISH_TYPES < caught_rows.size():
		_clear_result_overlay()
		_show_catch_result_page(caught_rows, next_page_index)
	else:
		_dismiss_result()


func _catch_popup_fish_size(
	fish: Dictionary,
	slot_size := CATCH_POPUP_FISH_SIZE
) -> Vector2:
	var popup_scale := maxf(float(fish.get("catch_popup_scale", 1.0)), 0.01)
	return slot_size * popup_scale


func _build_celebration_panel(
	overlay: Control,
	panel_name: String,
	background_name: String
) -> Control:
	var dimmer := ColorRect.new()
	dimmer.name = "FishingCelebrationPopupDimmer"
	dimmer.color = CELEBRATION_POPUP_DIMMER_COLOR
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dimmer)

	var panel := Control.new()
	panel.name = panel_name
	panel.position = CELEBRATION_POPUP_PANEL_POSITION
	panel.size = CELEBRATION_POPUP_PANEL_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(panel)

	var background := TextureRect.new()
	background.name = background_name
	background.texture = SUCCESS_POPUP_TEXTURE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)
	return panel


func _aggregate_caught_fishes(caught_fishes: Array[Dictionary]) -> Array[Dictionary]:
	var rows_by_fish_id: Dictionary = {}
	var fish_id_order: Array[String] = []
	for fish in caught_fishes:
		var fish_id := str(fish.get("id", "green"))
		if not rows_by_fish_id.has(fish_id):
			rows_by_fish_id[fish_id] = {
				"fish": fish.duplicate(true),
				"count": 0
			}
			fish_id_order.append(fish_id)
		var row: Dictionary = rows_by_fish_id[fish_id]
		row["count"] = int(row.get("count", 0)) + 1
		rows_by_fish_id[fish_id] = row

	var rows: Array[Dictionary] = []
	for fish_id in fish_id_order:
		rows.append(rows_by_fish_id[fish_id])
	return rows


func _show_failure() -> void:
	_play_failure_sound()
	var box := _build_result_overlay(FAILURE_POPUP_TEXTURE)
	var cat := TextureRect.new()
	cat.texture = _failure_cat_texture()
	cat.custom_minimum_size = Vector2(300, 300)
	cat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cat)
	var title := _result_label("Better luck next time!", 34)
	GameFontStylesScript.apply_accent(title)
	box.add_child(title)
	box.add_child(_result_spacer(30.0))
	box.add_child(_result_label("Click anywhere to return", 18, Color("#786359")))


func _show_round_success() -> void:
	_award_round_completion_xp()
	current_level_retry_count = 0
	shared_stats["fishing_level"] = maxi(
		maxi(
			current_level + 1,
			int(shared_stats.get("fishing_level", FISHING_LEVEL))
		),
		FISHING_LEVEL
	)
	_emit_shared_stats_changed()

	result_overlay = Control.new()
	result_overlay.name = "FishingLevelCompletePopupOverlay"
	result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(result_overlay)

	var panel := _build_celebration_panel(
		result_overlay,
		"FishingLevelCompletePopupPanel",
		"FishingLevelCompletePopupBackground"
	)

	var title := _make_popup_label(
		"CONGRATULATIONS!",
		CELEBRATION_TITLE_POSITION,
		CELEBRATION_TITLE_SIZE,
		CELEBRATION_TITLE_FONT_SIZE,
		true
	)
	title.name = "FishingLevelCompletePopupTitle"
	panel.add_child(title)

	var message := _make_popup_label(
		"YOU'VE COMPLETED THIS LEVEL!",
		LEVEL_COMPLETE_MESSAGE_POSITION,
		LEVEL_COMPLETE_MESSAGE_SIZE,
		LEVEL_COMPLETE_MESSAGE_FONT_SIZE,
		false,
		CELEBRATION_REGULAR_TEXT_COLOR
	)
	message.name = "FishingLevelCompletePopupMessage"
	panel.add_child(message)

	var xp_reward_label := _make_popup_label(
		"XP EARNED: %d" % round_xp_reward,
		LEVEL_COMPLETE_XP_POSITION,
		LEVEL_COMPLETE_XP_SIZE,
		LEVEL_COMPLETE_XP_FONT_SIZE,
		false,
		CELEBRATION_REGULAR_TEXT_COLOR
	)
	xp_reward_label.name = "FishingLevelCompleteXPReward"
	panel.add_child(xp_reward_label)

	var next_button := _make_home_style_popup_button(
		"NEXT LEVEL",
		_start_next_level_from_success,
		true
	)
	next_button.name = "FishingNextLevelButton"
	next_button.position = LEVEL_COMPLETE_NEXT_BUTTON_POSITION
	next_button.size = LEVEL_COMPLETE_BUTTON_SIZE
	panel.add_child(next_button)

	var home_button := _make_home_style_popup_button(
		"GO HOME",
		_return_home_from_round_success,
		false
	)
	home_button.name = "FishingLevelCompleteHomeButton"
	home_button.position = LEVEL_COMPLETE_HOME_BUTTON_POSITION
	home_button.size = LEVEL_COMPLETE_BUTTON_SIZE
	panel.add_child(home_button)


func _award_round_completion_xp() -> void:
	if round_completion_xp_awarded:
		return
	round_completion_xp_awarded = true
	xp_earned = round_xp_reward
	shared_stats["experience"] = (
		maxi(0, int(shared_stats.get("experience", 0)))
		+ round_xp_reward
	)
	_emit_shared_stats_changed()
	catch_completed.emit(true, fish_caught, xp_earned)


func _make_home_style_popup_button(
	text: String,
	action: Callable,
	accent: bool,
	font_size := LEVEL_COMPLETE_BUTTON_FONT_SIZE
) -> Button:
	var button := Button.new()
	button.text = GameFontStylesScript.display_text(text)
	GameFontStylesScript.apply_regular(button)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	var text_color := Color.WHITE if accent else Color("#513c4d")
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#e87942") if accent else Color("#fff7e9")
	normal.set_corner_radius_all(14)
	normal.set_border_width_all(2)
	normal.border_color = Color("#bd553f") if accent else Color("#ddc7b2")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#bd553f") if accent else Color.WHITE
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = hover.duplicate()
	pressed.bg_color = Color("#a84b3a") if accent else Color("#f1dfc9")
	button.add_theme_stylebox_override("pressed", pressed)
	button.pressed.connect(action)
	return button


func _start_next_level_from_success() -> void:
	current_level = maxi(
		maxi(
			current_level + 1,
			int(shared_stats.get("fishing_level", current_level + 1))
		),
		FISHING_LEVEL
	)
	_clear_result_overlay()
	result_is_round_end = false
	fish_caught = 0
	xp_earned = 0
	_load_round_configuration()
	round_started = false
	_reset_round_goal_progress()
	_rebuild_fish_guide()
	_update_stats()
	_show_goal_popup()


func _return_home_from_round_success() -> void:
	_clear_result_overlay()
	result_is_round_end = false
	back_requested.emit()


func _consume_heart_for_failed_round(now_unix := -1) -> void:
	if hearts <= 0:
		return
	var now := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	hearts = maxi(0, hearts - 1)
	if hearts < MAX_HEARTS and next_heart_restore_unix <= 0:
		next_heart_restore_unix = now + HEART_RESTORE_SECONDS
	_update_heart_display()
	_emit_shared_stats_changed()


func _prepare_current_level_retry() -> void:
	fish_caught = 0
	xp_earned = 0
	round_completion_pending = false
	round_completion_xp_awarded = false
	round_time_remaining = float(round_time_limit_seconds)
	round_started = false
	_build_round_spawn_plan()
	_reset_round_goal_progress()
	_rebuild_fish_guide()
	_update_stats()
	_show_goal_popup()


func _show_round_failure() -> void:
	_play_failure_sound()
	var box := _build_result_overlay(FAILURE_POPUP_TEXTURE, false)
	result_overlay.name = "FishingRoundFailurePopupOverlay"
	var cat := TextureRect.new()
	cat.name = "FishingRoundFailureCat"
	cat.texture = _round_failure_cat_texture()
	cat.custom_minimum_size = Vector2(300, 300)
	cat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cat)
	var title := _result_label("Better luck next time!", 34)
	GameFontStylesScript.apply_accent(title)
	box.add_child(title)
	box.add_child(_result_spacer(30.0))

	var actions := HBoxContainer.new()
	actions.name = "FishingRoundFailureActions"
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.custom_minimum_size = Vector2(580, ROUND_FAILURE_BUTTON_SIZE.y)
	actions.add_theme_constant_override("separation", ROUND_FAILURE_BUTTON_SEPARATION)
	box.add_child(actions)

	var home_button := _make_home_style_popup_button(
		"GO HOME",
		_return_home_from_round_failure,
		false,
		ROUND_FAILURE_BUTTON_FONT_SIZE
	)
	home_button.name = "FishingRoundFailureHomeButton"
	home_button.custom_minimum_size = ROUND_FAILURE_BUTTON_SIZE
	actions.add_child(home_button)

	var retry_button := _make_home_style_popup_button(
		"TRY AGAIN",
		_retry_current_level_from_round_failure,
		true,
		ROUND_FAILURE_BUTTON_FONT_SIZE
	)
	retry_button.name = "FishingRoundFailureRetryButton"
	retry_button.custom_minimum_size = ROUND_FAILURE_BUTTON_SIZE
	actions.add_child(retry_button)


func _return_home_from_round_failure() -> void:
	_clear_result_overlay()
	result_is_round_end = false
	round_failure_retry_pending = false
	back_requested.emit()


func _retry_current_level_from_round_failure() -> void:
	_dismiss_result()


func _show_no_hearts_popup() -> void:
	state = GameState.ROUND_ENDED
	round_started = false
	catch_hotspot.disabled = true
	spawn_timer.stop()
	_remove_swimming_fishes()
	result_is_round_end = false
	round_failure_retry_pending = false
	no_hearts_popup_pending = true
	var box := _build_result_overlay(NO_HEARTS_POPUP_TEXTURE)
	result_overlay.name = "FishingNoHeartsPopupOverlay"
	var cat := TextureRect.new()
	cat.name = "FishingNoHeartsCat"
	cat.texture = _round_failure_cat_texture()
	cat.custom_minimum_size = Vector2(270, 270)
	cat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(cat)
	var title := _result_label("No hearts left", 34)
	GameFontStylesScript.apply_accent(title)
	box.add_child(title)
	no_hearts_countdown_label = _result_label("", 25, Color("#58352b"))
	no_hearts_countdown_label.name = "FishingNoHeartsCountdown"
	box.add_child(no_hearts_countdown_label)
	box.add_child(_result_spacer(18.0))
	box.add_child(_result_label(
		"Click anywhere to return home",
		18,
		Color("#786359")
	))
	_update_no_hearts_countdown()


func _build_result_overlay(
	background_texture: Texture2D,
	dismiss_on_click := true
) -> VBoxContainer:
	var overlay: Control
	if dismiss_on_click:
		var dismiss_button := Button.new()
		dismiss_button.flat = true
		dismiss_button.focus_mode = Control.FOCUS_NONE
		dismiss_button.pressed.connect(_dismiss_result)
		overlay = dismiss_button
	else:
		overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	result_overlay = overlay
	add_child(overlay)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0.09, 0.07, 0.06, 0.18)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result_overlay.add_child(dimmer)

	var panel := Control.new()
	panel.position = Vector2(260, 34)
	panel.size = Vector2(760, 652)
	panel.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
		if dismiss_on_click
		else Control.MOUSE_FILTER_PASS
	)
	result_overlay.add_child(panel)

	var background := TextureRect.new()
	background.name = "FishingResultPopupBackground"
	background.texture = background_texture
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(background)

	var box := VBoxContainer.new()
	box.position = Vector2(90, 60)
	box.size = Vector2(580, 530)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
		if dismiss_on_click
		else Control.MOUSE_FILTER_PASS
	)
	panel.add_child(box)
	return box


func _dismiss_result() -> void:
	var should_return_home := result_is_round_end
	var should_complete_round := round_completion_pending
	var should_retry_failed_round := round_failure_retry_pending
	var should_return_from_no_hearts := no_hearts_popup_pending
	_clear_result_overlay()
	result_is_round_end = false
	round_failure_retry_pending = false
	no_hearts_popup_pending = false
	net_view.visible = true
	pet_view.visible = true
	_apply_animation_frame(0)
	active_fish.clear()
	if should_return_from_no_hearts:
		back_requested.emit()
		return
	if should_retry_failed_round:
		_restore_hearts_at(int(Time.get_unix_time_from_system()))
		_update_heart_display()
		if hearts > 0:
			_prepare_current_level_retry()
		else:
			_show_no_hearts_popup()
		return
	if should_return_home:
		back_requested.emit()
		return
	if should_complete_round:
		round_completion_pending = false
		_end_round(true)
		return
	if round_time_remaining <= 0.0:
		_end_round()
		return
	state = GameState.WAITING_FOR_FISH
	catch_hotspot.disabled = true
	_schedule_next_planned_spawn()


func _clear_result_overlay() -> void:
	if is_instance_valid(result_overlay):
		var overlay := result_overlay
		result_overlay = null
		if overlay.get_parent() != null:
			overlay.get_parent().remove_child(overlay)
		overlay.queue_free()
	else:
		result_overlay = null
	catch_popup_fish_views.clear()
	no_hearts_countdown_label = null
	catch_popup_count_labels.clear()


func _build_round_spawn_plan() -> void:
	round_spawn_sequence.clear()
	round_spawn_times.clear()
	round_planned_spawn_counts.clear()
	round_required_fish_total = 0
	round_total_spawn_count = 0
	round_retry_target_spawn_bonus_per_goal = _retry_target_spawn_bonus_per_goal()
	next_spawn_index = 0

	var target_spawn_quotas: Dictionary = {}
	var reserved_target_total := 0
	for goal in round_goals:
		var fish_id := str(goal.get("fish_id", "green"))
		var required_count := maxi(1, int(goal.get("count", 1)))
		round_required_fish_total += required_count
		var target_spawn_quota := (
			FishingLevelCatalogScript.guaranteed_target_spawn_count(required_count)
			+ round_retry_target_spawn_bonus_per_goal
		)
		target_spawn_quotas[fish_id] = target_spawn_quota
		reserved_target_total += target_spawn_quota

	var retry_target_spawn_bonus_total := (
		round_retry_target_spawn_bonus_per_goal * round_goals.size()
	)
	round_total_spawn_count = maxi(
		reserved_target_total,
		ceili(float(round_required_fish_total) * round_spawn_total_multiplier)
		+ retry_target_spawn_bonus_total
	)
	if round_total_spawn_count <= 0:
		return

	for goal in round_goals:
		var fish_id := str(goal.get("fish_id", "green"))
		var spawn_quota := int(target_spawn_quotas.get(fish_id, 0))
		for copy_index in range(spawn_quota):
			round_spawn_sequence.append(fish_id)

	while round_spawn_sequence.size() < round_total_spawn_count:
		round_spawn_sequence.append(_weighted_random_fish_id(round_spawn_fish_ids))
	_shuffle_fish_ids(round_spawn_sequence)
	for fish_id in round_spawn_sequence:
		round_planned_spawn_counts[fish_id] = int(
			round_planned_spawn_counts.get(fish_id, 0)
		) + 1

	_build_round_spawn_times(round_spawn_sequence.size())


func _weighted_random_fish_id(candidate_ids: Array[String]) -> String:
	if candidate_ids.is_empty():
		return "green"
	var total_weight := 0.0
	for fish_id in candidate_ids:
		total_weight += maxf(0.001, float(_fish_definition(fish_id).get("spawn_weight", 1.0)))
	var roll := rng.randf() * total_weight
	for fish_id in candidate_ids:
		roll -= maxf(0.001, float(_fish_definition(fish_id).get("spawn_weight", 1.0)))
		if roll <= 0.0:
			return fish_id
	return candidate_ids.back()


func _shuffle_fish_ids(fish_ids: Array) -> void:
	for index in range(fish_ids.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held_fish_id = fish_ids[index]
		fish_ids[index] = fish_ids[swap_index]
		fish_ids[swap_index] = held_fish_id


func _build_round_spawn_times(spawn_count: int) -> void:
	round_spawn_times.clear()
	if spawn_count <= 0:
		return
	var final_spawn_time := minf(
		float(round_time_limit_seconds) * FINAL_FISH_SPAWN_TIME_FRACTION,
		float(round_time_limit_seconds) - FINAL_FISH_SPAWN_MIN_REMAINING_SECONDS
	)
	final_spawn_time = maxf(FIRST_FISH_SPAWN_TIME_SECONDS, final_spawn_time)
	if spawn_count == 1:
		round_spawn_times.append(rng.randf_range(
			FIRST_FISH_SPAWN_TIME_SECONDS,
			final_spawn_time
		))
		return
	var spawn_window := final_spawn_time - FIRST_FISH_SPAWN_TIME_SECONDS
	var slot_duration := spawn_window / float(spawn_count)
	for spawn_index in range(spawn_count):
		var slot_start := FIRST_FISH_SPAWN_TIME_SECONDS + slot_duration * float(spawn_index)
		round_spawn_times.append(
			slot_start
			+ slot_duration * rng.randf_range(
				SPAWN_SLOT_RANDOM_MIN,
				SPAWN_SLOT_RANDOM_MAX
			)
		)


func _schedule_next_planned_spawn() -> void:
	if not is_instance_valid(spawn_timer):
		return
	spawn_timer.stop()
	if (
		not round_started
		or round_time_remaining <= 0.0
		or round_completion_pending
		or next_spawn_index >= round_spawn_sequence.size()
	):
		return
	var gameplay_elapsed := float(round_time_limit_seconds) - round_time_remaining
	var planned_time := round_spawn_times[next_spawn_index]
	spawn_timer.start(maxf(0.05, planned_time - gameplay_elapsed))


func _apply_animation_frame(index: int) -> void:
	animation_frame_index = clampi(index, 0, FRAME_DURATIONS.size() - 1)
	net_view.position = NET_FRAME_POSITIONS[animation_frame_index]
	net_view.size = NET_FRAME_SIZES[animation_frame_index]
	pet_view.position = PET_FRAME_POSITIONS[animation_frame_index]
	pet_view.size = PET_FRAME_SIZES[animation_frame_index]
	if _uses_mochi_fishing_art():
		pet_view.texture = MOCHI_FISHING_DEFAULT_TEXTURE
	elif _uses_biscuit_fishing_art():
		pet_view.texture = BISCUIT_FISHING_DEFAULT_TEXTURE
	elif _uses_luna_fishing_art():
		pet_view.texture = LUNA_FISHING_DEFAULT_TEXTURE
	elif _uses_poppy_fishing_art():
		pet_view.texture = POPPY_FISHING_DEFAULT_TEXTURE
	elif _uses_black_cat_fishing_art():
		pet_view.texture = BLACK_CAT_FISHING_DEFAULT_TEXTURE
	elif _uses_maine_coon_fishing_art():
		pet_view.texture = MAINE_COON_FISHING_DEFAULT_TEXTURE
	elif _uses_golden_munchkin_fishing_art():
		pet_view.texture = GOLDEN_MUNCHKIN_FISHING_DEFAULT_TEXTURE
	elif _uses_siamese_fishing_art():
		pet_view.texture = SIAMESE_FISHING_DEFAULT_TEXTURE
	else:
		pet_view.texture = DEFAULT_FISHING_PET_FRAMES[animation_frame_index]


func _uses_mochi_fishing_art() -> bool:
	return pet_id == "mochi"


func _uses_biscuit_fishing_art() -> bool:
	return pet_id == "biscuit"


func _uses_luna_fishing_art() -> bool:
	return pet_id == "luna"


func _uses_poppy_fishing_art() -> bool:
	return pet_id == "poppy"


func _uses_black_cat_fishing_art() -> bool:
	return pet_id == "black_cat"


func _uses_maine_coon_fishing_art() -> bool:
	return pet_id == "maine_coon"


func _uses_golden_munchkin_fishing_art() -> bool:
	return pet_id == "golden_munchkin"


func _uses_siamese_fishing_art() -> bool:
	return pet_id == "siamese"


func _failure_cat_texture() -> Texture2D:
	if _uses_mochi_fishing_art():
		return MOCHI_FISHING_CRY_FRAMES.back()
	if _uses_biscuit_fishing_art():
		return BISCUIT_FISHING_FAILURE_TEXTURE
	if _uses_luna_fishing_art():
		return LUNA_FISHING_FAILURE_TEXTURE
	if _uses_poppy_fishing_art():
		return POPPY_FISHING_FAILURE_TEXTURE
	if _uses_black_cat_fishing_art():
		return BLACK_CAT_FISHING_FAILURE_TEXTURE
	if _uses_maine_coon_fishing_art():
		return MAINE_COON_FISHING_FAILURE_TEXTURE
	if _uses_golden_munchkin_fishing_art():
		return GOLDEN_MUNCHKIN_FISHING_FAILURE_TEXTURE
	if _uses_siamese_fishing_art():
		return SIAMESE_FISHING_FAILURE_TEXTURE
	return CRYING_CAT_TEXTURE


func _round_failure_cat_texture() -> Texture2D:
	if _uses_mochi_fishing_art():
		return MOCHI_FISHING_FAILURE_STATIC_TEXTURE
	if _uses_biscuit_fishing_art():
		return BISCUIT_FISHING_FAILURE_TEXTURE
	if _uses_luna_fishing_art():
		return LUNA_FISHING_FAILURE_TEXTURE
	if _uses_poppy_fishing_art():
		return POPPY_FISHING_FAILURE_TEXTURE
	if _uses_black_cat_fishing_art():
		return BLACK_CAT_FISHING_FAILURE_TEXTURE
	if _uses_maine_coon_fishing_art():
		return MAINE_COON_FISHING_FAILURE_TEXTURE
	if _uses_golden_munchkin_fishing_art():
		return GOLDEN_MUNCHKIN_FISHING_FAILURE_TEXTURE
	if _uses_siamese_fishing_art():
		return SIAMESE_FISHING_FAILURE_TEXTURE
	return CRYING_CAT_TEXTURE


func _make_fish_visual(
	fish: Dictionary,
	target_size: Vector2,
	texture_region_key := "texture_region"
) -> TextureRect:
	var texture_view := TextureRect.new()
	texture_view.texture = _fish_texture_with_region(fish, texture_region_key)
	texture_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_view.stretch_mode = (
		TextureRect.STRETCH_SCALE
		if bool(fish.get("stretch_to_target", false))
		else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	texture_view.material = FishCatalogScript.visual_material(fish)
	# Set IGNORE_SIZE before assigning dimensions. Otherwise Godot initially
	# expands the control to the large source PNG and the icon escapes its slot.
	texture_view.custom_minimum_size = target_size
	texture_view.size = target_size
	texture_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_view


func _fish_texture(fish_id: String) -> Texture2D:
	return _fish_definition(fish_id).get("texture", GREEN_FISH_TEXTURE)


func _trimmed_fish_texture(fish_id: String) -> Texture2D:
	var fish := _fish_definition(fish_id)
	return _fish_texture_with_region(fish, "texture_region")


func _fish_texture_with_region(fish: Dictionary, region_key: String) -> Texture2D:
	var texture: Texture2D = fish.get("texture", GREEN_FISH_TEXTURE)
	var texture_region: Rect2 = fish.get(
		region_key,
		fish.get("texture_region", Rect2())
	)
	if texture_region.size.x <= 0.0 or texture_region.size.y <= 0.0:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = texture_region
	return atlas


func _guide_fish_size(fish_id: String) -> Vector2:
	var swim_size: Vector2 = _fish_definition(fish_id).get("swim_size", Vector2(95, 60))
	var scale_factor := minf(68.0 / swim_size.x, 48.0 / swim_size.y)
	return swim_size * scale_factor


func _swimming_fish_size(fish: Dictionary) -> Vector2:
	return fish.get("swim_size", Vector2(95, 60))


func _remove_swimming_fishes() -> void:
	_stop_fish_motion()
	for entry in active_fish:
		var view = entry.get("view")
		if is_instance_valid(view):
			view.queue_free()
	active_fish.clear()


func _stop_fish_motion() -> void:
	for entry in active_fish:
		var tween = entry.get("tween")
		if tween != null and tween.is_valid():
			tween.kill()


func _restore_hearts_at(now_unix: int, emit_change := true) -> bool:
	if hearts >= MAX_HEARTS:
		hearts = MAX_HEARTS
		next_heart_restore_unix = 0
		return false
	if next_heart_restore_unix <= 0:
		next_heart_restore_unix = now_unix + HEART_RESTORE_SECONDS
		if emit_change:
			_emit_shared_stats_changed()
		return true
	var latest_valid_deadline := now_unix + HEART_RESTORE_SECONDS
	if next_heart_restore_unix > latest_valid_deadline:
		next_heart_restore_unix = latest_valid_deadline
		if emit_change:
			_emit_shared_stats_changed()
		return true
	if now_unix < next_heart_restore_unix:
		return false
	var restored := 1 + int((now_unix - next_heart_restore_unix) / HEART_RESTORE_SECONDS)
	hearts = mini(MAX_HEARTS, hearts + restored)
	if hearts >= MAX_HEARTS:
		next_heart_restore_unix = 0
	else:
		next_heart_restore_unix += restored * HEART_RESTORE_SECONDS
	if emit_change:
		_emit_shared_stats_changed()
	return true


func _update_heart_display() -> void:
	const HEART_SIZE := Vector2(34, 34)
	const HEART_GAP := 5.0
	const PANEL_LEFT := 14.0
	const PANEL_WIDTH := 282.0
	var visible_hearts := clampi(hearts, 0, MAX_HEARTS)
	var row_width := (
		float(visible_hearts) * HEART_SIZE.x
		+ float(maxi(0, visible_hearts - 1)) * HEART_GAP
	)
	var start_x := PANEL_LEFT + (PANEL_WIDTH - row_width) * 0.5
	for index in range(heart_views.size()):
		var heart := heart_views[index]
		heart.visible = index < visible_hearts
		if heart.visible:
			heart.position = Vector2(start_x + float(index) * (HEART_SIZE.x + HEART_GAP), 23)
	if is_instance_valid(heart_timer_label):
		heart_timer_label.text = (
			"NEXT HEART IN %s" % _format_countdown(seconds_until_next_heart())
			if hearts <= 0
			else ""
		)


func _update_no_hearts_countdown() -> void:
	if not is_instance_valid(no_hearts_countdown_label):
		return
	if hearts > 0:
		no_hearts_countdown_label.text = "A HEART IS READY!"
	else:
		no_hearts_countdown_label.text = "PLEASE TRY AGAIN IN %s" % _format_countdown(
			seconds_until_next_heart()
		)


func seconds_until_next_heart(now_unix := -1) -> int:
	if hearts >= MAX_HEARTS or next_heart_restore_unix <= 0:
		return 0
	var now := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	return maxi(0, next_heart_restore_unix - now)


func _format_countdown(total_seconds: int) -> String:
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _emit_shared_stats_changed() -> void:
	shared_stats["hearts"] = hearts
	shared_stats["next_heart_restore_unix"] = next_heart_restore_unix
	shared_stats["fishing_level"] = maxi(
		maxi(
			current_level,
			int(shared_stats.get("fishing_level", current_level))
		),
		FISHING_LEVEL
	)
	shared_stats["unlocked_fish_ids"] = unlocked_fish_ids.duplicate()
	if current_level_retry_count > 0:
		shared_stats["fishing_retry_level"] = current_level
		shared_stats["fishing_retry_count"] = current_level_retry_count
	else:
		shared_stats.erase("fishing_retry_level")
		shared_stats.erase("fishing_retry_count")
	shared_stats_changed.emit(shared_stats.duplicate(true))


func _update_stats() -> void:
	for label in stats_labels:
		if is_instance_valid(label):
			label.text = "LEVEL: %d\nTIME: %s" % [
				current_level,
				_format_countdown(ceili(round_time_remaining))
			]


func _result_label(text: String, font_size: int, color := Color("#58352b")) -> Label:
	var label := Label.new()
	label.text = GameFontStylesScript.display_text(text)
	GameFontStylesScript.apply_regular(label)
	label.custom_minimum_size.y = 48
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _result_spacer(height: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = height
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _full_screen_texture(texture: Texture2D) -> TextureRect:
	var view := TextureRect.new()
	view.texture = texture
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return view


func _make_panel_frame(frame_name: String, texture: Texture2D) -> TextureRect:
	var frame := TextureRect.new()
	frame.name = frame_name
	frame.texture = texture
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return frame


func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = Color("#b98560")
	style.shadow_color = Color(0.18, 0.09, 0.06, 0.16)
	style.shadow_size = 6
	return style
