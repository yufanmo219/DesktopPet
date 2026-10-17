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
const GREEN_FISH_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/fish/processed/green_fish_v2.png"
)
const CORAL_ANGELFISH_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/fish/processed/coral_angelfish_v2.png"
)
const GOLDEN_RIBBONFISH_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/fish/processed/golden_ribbonfish_v2.png"
)
const HEART_TEXTURE: Texture2D = preload(
	"res://assets/ui/fishing/hearts/heart_sprite_256.png"
)
const GameFontStylesScript = preload("res://src/game_font_styles.gd")
const FishCatalogScript = preload("res://src/fish_catalog.gd")
const FishingLevelCatalogScript = preload("res://src/fishing_level_catalog.gd")
const FishingSessionScript = preload("res://src/fishing/fishing_session.gd")
const PetCatalogScript = preload("res://src/pets/pet_catalog.gd")
const FishingPetPresentationScript = preload(
	"res://src/fishing/fishing_pet_presentation.gd"
)
const GameStateStoreScript = preload("res://src/progression/game_state_store.gd")
const HeartServiceScript = preload("res://src/progression/heart_service.gd")
const FishingViewScene = preload("res://src/fishing/ui/fishing_view.tscn")
const GoalPopupScene = preload("res://src/fishing/ui/popups/goal_popup.tscn")
const CatchPopupScene = preload("res://src/fishing/ui/popups/catch_popup.tscn")
const HomeConfirmationPopupScene = preload(
	"res://src/fishing/ui/popups/home_confirmation_popup.tscn"
)
const NewFishPopupScene = preload("res://src/fishing/ui/popups/new_fish_popup.tscn")
const LevelCompletePopupScene = preload(
	"res://src/fishing/ui/popups/level_complete_popup.tscn"
)
const RoundFailurePopupScene = preload(
	"res://src/fishing/ui/popups/round_failure_popup.tscn"
)
const NoHeartsPopupScene = preload("res://src/fishing/ui/popups/no_hearts_popup.tscn")
const CatchFailurePopupScene = preload(
	"res://src/fishing/ui/popups/catch_failure_popup.tscn"
)
const PauseOverlayScene = preload("res://src/fishing/ui/popups/pause_overlay.tscn")

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

const CATCH_SUCCESS_CHANCE := FishingSessionScript.DEFAULT_CATCH_SUCCESS_CHANCE
const RETRY_ESCAPE_REDUCTION := FishingSessionScript.RETRY_ESCAPE_REDUCTION
const FIRST_FISH_SPAWN_TIME_SECONDS := FishingSessionScript.FIRST_FISH_SPAWN_TIME_SECONDS
const FINAL_FISH_SPAWN_TIME_FRACTION := FishingSessionScript.FINAL_FISH_SPAWN_TIME_FRACTION
const FINAL_FISH_SPAWN_MIN_REMAINING_SECONDS := (
	FishingSessionScript.FINAL_FISH_SPAWN_MIN_REMAINING_SECONDS
)
# One fish is assigned to each equal time slot. Picking a point inside the
# middle 70% of every slot keeps the stream random without allowing clumps.
const SPAWN_SLOT_RANDOM_MIN := FishingSessionScript.SPAWN_SLOT_RANDOM_MIN
const SPAWN_SLOT_RANDOM_MAX := FishingSessionScript.SPAWN_SLOT_RANDOM_MAX
const MAX_HEARTS := HeartServiceScript.MAX_HEARTS
const HEART_RESTORE_SECONDS := HeartServiceScript.DEFAULT_RESTORE_SECONDS
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
var pet_presentation: FishingPetPresentation
var fishing_session = FishingSessionScript.new()
var current_level: int:
	get:
		return fishing_session.current_level
	set(value):
		fishing_session.current_level = value
var fish_caught: int:
	get:
		return fishing_session.fish_caught
	set(value):
		fishing_session.fish_caught = value
var xp_earned: int:
	get:
		return fishing_session.xp_earned
	set(value):
		fishing_session.xp_earned = value
var round_config: Dictionary:
	get:
		return fishing_session.round_config
	set(value):
		fishing_session.round_config = value
var round_goals: Array[Dictionary]:
	get:
		return fishing_session.round_goals
	set(value):
		fishing_session.round_goals = value
var round_spawn_fish_ids: Array[String]:
	get:
		return fishing_session.round_spawn_fish_ids
	set(value):
		fishing_session.round_spawn_fish_ids = value
var round_time_limit_seconds: int:
	get:
		return fishing_session.round_time_limit_seconds
	set(value):
		fishing_session.round_time_limit_seconds = value
var round_difficulty_multiplier: float:
	get:
		return fishing_session.round_difficulty_multiplier
	set(value):
		fishing_session.round_difficulty_multiplier = value
var round_target_pass_rate: float:
	get:
		return fishing_session.round_target_pass_rate
	set(value):
		fishing_session.round_target_pass_rate = value
var round_catch_success_chance: float:
	get:
		return fishing_session.round_catch_success_chance
	set(value):
		fishing_session.round_catch_success_chance = value
var current_level_retry_count: int:
	get:
		return fishing_session.current_level_retry_count
	set(value):
		fishing_session.current_level_retry_count = value
var round_spawn_total_multiplier: float:
	get:
		return fishing_session.round_spawn_total_multiplier
	set(value):
		fishing_session.round_spawn_total_multiplier = value
var round_xp_reward: int:
	get:
		return fishing_session.round_xp_reward
	set(value):
		fishing_session.round_xp_reward = value
var round_completion_xp_awarded: bool:
	get:
		return fishing_session.round_completion_xp_awarded
	set(value):
		fishing_session.round_completion_xp_awarded = value
var round_completion_pending: bool:
	get:
		return fishing_session.round_completion_pending
	set(value):
		fishing_session.round_completion_pending = value
var round_time_remaining: float:
	get:
		return fishing_session.round_time_remaining
	set(value):
		fishing_session.round_time_remaining = value
var round_started: bool:
	get:
		return fishing_session.round_started
	set(value):
		fishing_session.round_started = value
var round_goal_counts: Dictionary:
	get:
		return fishing_session.round_goal_counts
	set(value):
		fishing_session.round_goal_counts = value
var active_fish: Array[Dictionary] = []
var progress_store = GameStateStoreScript.new()
var heart_service = HeartServiceScript.new(progress_store, HEART_RESTORE_SECONDS)
var hearts: int:
	get:
		return heart_service.heart_count()
var next_heart_restore_unix: int:
	get:
		return heart_service.next_restore_unix()
var shared_stats: Dictionary = {}

var rng: RandomNumberGenerator:
	get:
		return fishing_session.rng
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
var round_spawn_sequence: Array[String]:
	get:
		return fishing_session.round_spawn_sequence
	set(value):
		fishing_session.round_spawn_sequence = value
var round_spawn_times: Array[float]:
	get:
		return fishing_session.round_spawn_times
	set(value):
		fishing_session.round_spawn_times = value
var round_planned_spawn_counts: Dictionary:
	get:
		return fishing_session.round_planned_spawn_counts
	set(value):
		fishing_session.round_planned_spawn_counts = value
var round_required_fish_total: int:
	get:
		return fishing_session.round_required_fish_total
	set(value):
		fishing_session.round_required_fish_total = value
var round_total_spawn_count: int:
	get:
		return fishing_session.round_total_spawn_count
	set(value):
		fishing_session.round_total_spawn_count = value
var round_retry_target_spawn_bonus_per_goal: int:
	get:
		return fishing_session.round_retry_target_spawn_bonus_per_goal
	set(value):
		fishing_session.round_retry_target_spawn_bonus_per_goal = value
var next_spawn_index: int:
	get:
		return fishing_session.next_spawn_index
	set(value):
		fishing_session.next_spawn_index = value
var animation_frame_index := 0
var result_is_round_end := false
var round_failure_retry_pending := false
var no_hearts_popup_pending := false


func configure(
	pet: Dictionary,
	saved_stats: Dictionary = {},
	configured_progress_store = null
) -> void:
	pet_id = str(pet.get("id", "default_orange_cat")).to_lower()
	pet_name = str(pet.get("name", "Companion"))
	pet_presentation = FishingPetPresentationScript.new(
		PetCatalogScript.definition_or_default(pet_id)
	)
	if progress_store.progress_changed.is_connected(_on_progress_store_changed):
		progress_store.progress_changed.disconnect(_on_progress_store_changed)
	if configured_progress_store == null:
		progress_store = GameStateStoreScript.new()
		progress_store.replace(saved_stats, false)
	else:
		progress_store = configured_progress_store
	progress_store.progress_changed.connect(_on_progress_store_changed)
	heart_service = HeartServiceScript.new(progress_store, HEART_RESTORE_SECONDS)
	shared_stats = progress_store.snapshot()
	current_level = maxi(
		int(shared_stats.get("fishing_level", FISHING_LEVEL)),
		FISHING_LEVEL
	)
	current_level_retry_count = (
		maxi(0, int(shared_stats.get("fishing_retry_count", 0)))
		if int(shared_stats.get("fishing_retry_level", 0)) == current_level
		else 0
	)
	unlocked_fish_ids.clear()
	for starter_fish_id in STARTER_FISH_IDS:
		unlocked_fish_ids.append(starter_fish_id)
	var saved_unlocked_fish_ids: Variant = shared_stats.get("unlocked_fish_ids", [])
	if saved_unlocked_fish_ids is Array:
		for fish_id_value in saved_unlocked_fish_ids:
			var fish_id := str(fish_id_value)
			if fish_id != "" and not unlocked_fish_ids.has(fish_id):
				unlocked_fish_ids.append(fish_id)
	_restore_hearts_at(int(Time.get_unix_time_from_system()), false)


func _on_progress_store_changed(snapshot: Dictionary) -> void:
	shared_stats = snapshot.duplicate(true)
	shared_stats_changed.emit(shared_stats.duplicate(true))


func _ready() -> void:
	if pet_presentation == null:
		pet_presentation = FishingPetPresentationScript.new(
			PetCatalogScript.definition_or_default(pet_id)
		)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rng.randomize()
	_load_round_configuration()
	_reset_round_goal_progress()
	_build_interface()
	_build_audio_players()
	_update_stats()
	_update_heart_display()
	_emit_shared_stats_changed()
	if hearts > 0:
		_show_goal_popup()
	else:
		_show_no_hearts_popup()


func _build_audio_players() -> void:
	failure_sound_player = get_node("FishingView/FishingFailureSoundPlayer")
	success_sound_player = get_node("FishingView/FishingSuccessSoundPlayer")


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
	fishing_session.load_level(current_level, current_level_retry_count)


func _build_interface() -> void:
	var fishing_view := get_node_or_null("FishingView") as Control
	if fishing_view == null:
		fishing_view = FishingViewScene.instantiate()
		add_child(fishing_view)

	main_background_view = fishing_view.get_node("FishingBackground")
	pause_click_area = fishing_view.get_node("FishingPauseClickArea")
	pet_view = fishing_view.get_node("FishingPetView")
	net_view = fishing_view.get_node("FishingNetView")
	fish_layer = fishing_view.get_node("FishingFishLayer")
	var hud: Control = fishing_view.get_node("FishingHUD")
	stats_panel = hud.get_node("FishingStatsPanel")
	stats_labels.clear()
	stats_labels.append(stats_panel.get_node("FishingLevelTimeLabel"))
	heart_panel = hud.get_node("FishingHeartPanel")
	heart_timer_label = heart_panel.get_node("HeartTimerLabel")
	heart_views.clear()
	for index in range(MAX_HEARTS):
		heart_views.append(heart_panel.get_node("FishingHeart%d" % (index + 1)))
	catch_hotspot = hud.get_node("FishingCatchButton")
	var home_button: Button = hud.get_node("FishingHomeButton")
	spawn_timer = fishing_view.get_node("FishingSpawnTimer")

	if not pause_click_area.pressed.is_connected(_pause_game):
		pause_click_area.pressed.connect(_pause_game)
	if not home_button.pressed.is_connected(_request_return_home):
		home_button.pressed.connect(_request_return_home)
	if not catch_hotspot.pressed.is_connected(request_catch):
		catch_hotspot.pressed.connect(request_catch)
	if not spawn_timer.timeout.is_connected(_spawn_fish):
		spawn_timer.timeout.connect(_spawn_fish)
	_style_home_button(home_button)
	_style_catch_button(catch_hotspot)
	_apply_animation_frame(0)
	_build_fish_guide()


func _style_home_button(button: Button) -> void:
	GameFontStylesScript.apply_regular(button)
	var normal := _panel_style(Color(1.0, 0.93, 0.75, 0.92), 16)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#fff0c9")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)


func _style_catch_button(button: Button) -> void:
	GameFontStylesScript.apply_button(button)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#e97852")
	normal.border_color = Color("#a94f39")
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(31)
	normal.shadow_color = Color(0.20, 0.08, 0.05, 0.27)
	normal.shadow_size = 7
	normal.shadow_offset = Vector2(0, 4)
	button.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#f1855d")
	button.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color("#ca5e43")
	pressed.shadow_size = 2
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color("#d96d4d")
	disabled.border_color = Color("#984936")
	disabled.shadow_size = 4
	disabled.shadow_color = Color(0.20, 0.08, 0.05, 0.20)
	button.add_theme_stylebox_override("disabled", disabled)


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
	home_return_overlay = HomeConfirmationPopupScene.instantiate()
	add_child(home_return_overlay)
	var panel: Control = home_return_overlay.get_node("FishingHomeReturnPanel")
	_style_popup_label(panel.get_node("Title"), true)
	_style_popup_label(panel.get_node("FishingHomeReturnWarning"), false)
	var cancel_button: Button = panel.get_node("FishingHomeReturnCancelButton")
	var confirm_button: Button = panel.get_node("FishingHomeReturnConfirmButton")
	_style_home_popup_button(cancel_button, false, 26)
	_style_home_popup_button(confirm_button, true, 26)
	cancel_button.pressed.connect(_cancel_return_home)
	confirm_button.pressed.connect(_confirm_return_home)


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
	fishing_session.abandon_round()
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
	if not is_instance_valid(fish_guide_panel):
		fish_guide_panel = get_node("FishingView/FishingHUD/FishingFishTypesPanel")
	var dynamic_goals: Control = fish_guide_panel.get_node("DynamicGoals")
	for child in dynamic_goals.get_children():
		dynamic_goals.remove_child(child)
		child.queue_free()
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
		dynamic_goals.add_child(icon)

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
		dynamic_goals.add_child(progress)
		goal_progress_labels.append(progress)
	_update_goal_tracker()


func _rebuild_fish_guide() -> void:
	_build_fish_guide()


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

	pause_overlay = PauseOverlayScene.instantiate()
	pause_overlay.pressed.connect(_resume_from_pause)
	add_child(pause_overlay)


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

	goal_popup_overlay = GoalPopupScene.instantiate()
	goal_popup_overlay.pressed.connect(_start_round_from_goal_popup)
	add_child(goal_popup_overlay)
	goal_popup_panel = goal_popup_overlay.get_node("FishingGoalPopupPanel")
	_style_popup_label(goal_popup_panel.get_node("FishingGoalPopupTitle"), true)
	_style_popup_label(goal_popup_panel.get_node("FishingGoalPopupTimeTitle"), false)
	_style_popup_label(goal_popup_panel.get_node("FishingGoalPopupTimer"), true)
	_style_popup_label(goal_popup_panel.get_node("FishingGoalPopupFooter"), false)

	goal_popup_fish_views.clear()
	goal_popup_count_labels.clear()
	var visible_goal_count := mini(round_goals.size(), MAX_ROUND_GOAL_TYPES)
	for index in range(MAX_ROUND_GOAL_TYPES):
		var fish_view: TextureRect = goal_popup_panel.get_node(
			"FishingGoalPopupFish%d" % (index + 1)
		)
		var count_label: Label = goal_popup_panel.get_node(
			"FishingGoalPopupCount%d" % (index + 1)
		)
		var is_visible := index < visible_goal_count
		fish_view.visible = is_visible
		count_label.visible = is_visible
		if not is_visible:
			continue
		var goal: Dictionary = round_goals[index]
		var fish := _fish_definition(str(goal.get("fish_id", "green")))
		_configure_fish_visual(fish_view, fish, GOAL_POPUP_FISH_SIZES[index], "goal_texture_region")
		count_label.text = "X %d" % int(goal.get("count", 0))
		_style_popup_label(count_label, false)
		goal_popup_fish_views.append(fish_view)
		goal_popup_count_labels.append(count_label)
	goal_popup_time_label = goal_popup_panel.get_node("FishingGoalPopupTimer")
	goal_popup_time_label.text = _format_countdown(round_time_limit_seconds)


func _style_popup_label(
	label: Label,
	accent := false,
	regular_color := GOAL_POPUP_TEXT_COLOR
) -> void:
	if accent:
		GameFontStylesScript.apply_accent(label)
	else:
		GameFontStylesScript.apply_regular(label)
		label.add_theme_color_override("font_color", regular_color)


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
	fishing_session.start_round()
	state = GameState.WAITING_FOR_FISH
	catch_hotspot.disabled = true
	_update_stats()
	_schedule_next_planned_spawn()


func _reset_round_goal_progress() -> void:
	fishing_session.reset_goal_progress()
	_update_goal_tracker()


func _record_round_goal_catches(caught_fishes: Array[Dictionary]) -> void:
	# The compatibility wrapper records goal progress only. Total caught fish is
	# owned by FishingSession and incremented by _finish_attempt().
	var previous_total := fish_caught
	var previous_completion_pending := round_completion_pending
	fishing_session.record_catches(caught_fishes)
	fish_caught = previous_total
	round_completion_pending = previous_completion_pending
	_update_goal_tracker()


func _required_goal_count(fish_id: String) -> int:
	return fishing_session.required_goal_count(fish_id)


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
	var expired := fishing_session.advance_time(delta)
	if ceili(round_time_remaining) != previous_second:
		_update_stats()
	if expired and state != GameState.LIFTING_NET:
		_end_round()


func _end_round(preserve_time_remaining := false) -> void:
	if result_is_round_end and is_instance_valid(result_overlay):
		return
	spawn_timer.stop()
	_remove_swimming_fishes()
	state = GameState.ROUND_ENDED
	catch_hotspot.disabled = true
	_apply_animation_frame(0)
	_update_stats()
	result_is_round_end = true
	if fishing_session.finish_round(preserve_time_remaining):
		round_failure_retry_pending = false
		_show_round_success()
	else:
		_consume_heart_for_failed_round()
		round_failure_retry_pending = true
		_show_round_failure()


func _round_goals_completed() -> bool:
	return fishing_session.goals_completed()


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
	return fishing_session.catch_succeeds(fish_is_inside_net, roll)


func _update_round_catch_success_chance() -> void:
	fishing_session.update_catch_success_chance()


func _record_failed_level_attempt() -> void:
	fishing_session.record_failed_attempt()


func _retry_target_spawn_bonus_per_goal() -> int:
	return fishing_session.retry_target_spawn_bonus_per_goal()


func _play_lift_animation(
	caught_fish_visuals: Array[TextureRect] = [],
	caught_any_fish := false
) -> void:
	var fish_start_positions: Array[Vector2] = []
	for view in caught_fish_visuals:
		fish_start_positions.append(view.position if is_instance_valid(view) else Vector2.ZERO)
	var pet_reaction_frames: Array[Texture2D] = pet_presentation.reaction_frames(
		caught_any_fish
	)
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
		fishing_session.record_catches(caught_fishes)
		_update_goal_tracker()
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
	progress_store.replace_unlocked_fish_ids(unlocked_fish_ids)
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
	var overlay: Button = NewFishPopupScene.instantiate()
	overlay.pressed.connect(_dismiss_new_fish_unlock)
	result_overlay = overlay
	add_child(overlay)
	var panel: Control = overlay.get_node("FishingNewFishPopupPanel")
	_style_popup_label(panel.get_node("FishingNewFishPopupTitle"), true)
	for label_name in [
		"FishingNewFishPopupSubtitle",
		"FishingNewFishPopupInfoLineOne",
		"FishingNewFishPopupInfoLineTwo",
		"FishingNewFishPopupFooter"
	]:
		_style_popup_label(
			panel.get_node(label_name),
			false,
			CELEBRATION_REGULAR_TEXT_COLOR
		)
	new_fish_popup_view = panel.get_node("FishingNewFishPopupFish")
	_configure_fish_visual(new_fish_popup_view, fish, NEW_FISH_ICON_SIZE)


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
	var overlay: Button = CatchPopupScene.instantiate()
	overlay.pressed.connect(_advance_catch_result_page.bind(caught_rows, page_index))
	result_overlay = overlay
	add_child(overlay)
	var panel: Control = overlay.get_node("FishingCatchPopupPanel")
	_style_popup_label(panel.get_node("FishingCatchPopupTitle"), true)

	catch_popup_fish_views.clear()
	catch_popup_count_labels.clear()
	for slot_index in range(MAX_CATCH_POPUP_FISH_TYPES):
		panel.get_node("FishingCatchPopupFish%d" % (slot_index + 1)).visible = false
		panel.get_node("FishingCatchPopupCount%d" % (slot_index + 1)).visible = false
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
		var fish_view: TextureRect = panel.get_node(
			"FishingCatchPopupFish%d" % (index + 1)
		)
		fish_view.visible = true
		_configure_fish_visual(fish_view, fish, fish_size)
		fish_view.set_meta("fish_id", str(fish.get("id", "green")))
		fish_view.position = (
			fish_slot_position + (fish_slot_size - fish_size) * 0.5
		)
		catch_popup_fish_views.append(fish_view)

		var count_label: Label = panel.get_node(
			"FishingCatchPopupCount%d" % (index + 1)
		)
		count_label.visible = true
		count_label.text = "X %d" % int(row.get("count", 0))
		count_label.position = count_position
		count_label.size = count_size
		count_label.add_theme_font_size_override("font_size", count_font_size)
		_style_popup_label(count_label, false, CATCH_POPUP_TEXT_COLOR)
		catch_popup_count_labels.append(count_label)

	var footer: Label = panel.get_node("FishingCatchPopupFooter")
	footer.text = (
		"CLICK ANYWHERE TO SEE MORE"
		if last_row_index < caught_rows.size()
		else "CLICK ANYWHERE TO CONTINUE"
	)
	_style_popup_label(footer, false, CATCH_POPUP_TEXT_COLOR)


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
	var overlay: Button = CatchFailurePopupScene.instantiate()
	overlay.pressed.connect(_dismiss_result)
	result_overlay = overlay
	add_child(overlay)
	var content: VBoxContainer = overlay.get_node("Panel/Content")
	var cat: TextureRect = content.get_node("Cat")
	cat.texture = _failure_cat_texture()
	_style_popup_label(content.get_node("Title"), true)
	_style_popup_label(content.get_node("Footer"), false, Color("#786359"))


func _show_round_success() -> void:
	_award_round_completion_xp()
	current_level_retry_count = 0
	progress_store.advance_fishing_level(maxi(
		maxi(
			current_level + 1,
			int(shared_stats.get("fishing_level", FISHING_LEVEL))
		),
		FISHING_LEVEL
	))
	progress_store.clear_retry()
	_emit_shared_stats_changed()

	result_overlay = LevelCompletePopupScene.instantiate()
	add_child(result_overlay)
	var panel: Control = result_overlay.get_node("FishingLevelCompletePopupPanel")
	_style_popup_label(panel.get_node("FishingLevelCompletePopupTitle"), true)
	_style_popup_label(
		panel.get_node("FishingLevelCompletePopupMessage"),
		false,
		CELEBRATION_REGULAR_TEXT_COLOR
	)
	var xp_reward_label: Label = panel.get_node("FishingLevelCompleteXPReward")
	xp_reward_label.text = "XP EARNED: %d" % round_xp_reward
	_style_popup_label(xp_reward_label, false, CELEBRATION_REGULAR_TEXT_COLOR)
	var next_button: Button = panel.get_node("FishingNextLevelButton")
	var home_button: Button = panel.get_node("FishingLevelCompleteHomeButton")
	_style_home_popup_button(next_button, true)
	_style_home_popup_button(home_button, false)
	next_button.pressed.connect(_start_next_level_from_success)
	home_button.pressed.connect(_return_home_from_round_success)


func _award_round_completion_xp() -> void:
	if round_completion_xp_awarded:
		return
	var awarded_xp := fishing_session.claim_completion_xp()
	progress_store.add_experience(awarded_xp)
	catch_completed.emit(true, fish_caught, xp_earned)


func _style_home_popup_button(
	button: Button,
	accent: bool,
	font_size := LEVEL_COMPLETE_BUTTON_FONT_SIZE
) -> void:
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


func _start_next_level_from_success() -> void:
	fishing_session.advance_to_next_level(
		int(shared_stats.get("fishing_level", current_level + 1))
	)
	_clear_result_overlay()
	result_is_round_end = false
	_rebuild_fish_guide()
	_update_stats()
	_show_goal_popup()


func _return_home_from_round_success() -> void:
	_clear_result_overlay()
	result_is_round_end = false
	back_requested.emit()


func _consume_heart_for_failed_round(now_unix := -1) -> void:
	var now := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	if heart_service.spend(now):
		_update_heart_display()
		_emit_shared_stats_changed()


func _prepare_current_level_retry() -> void:
	fishing_session.prepare_retry()
	_rebuild_fish_guide()
	_update_stats()
	_show_goal_popup()


func _show_round_failure() -> void:
	_play_failure_sound()
	result_overlay = RoundFailurePopupScene.instantiate()
	add_child(result_overlay)
	var content: VBoxContainer = result_overlay.get_node("Panel/Content")
	var cat: TextureRect = content.get_node("FishingRoundFailureCat")
	cat.texture = _round_failure_cat_texture()
	_style_popup_label(content.get_node("Title"), true)
	var actions: HBoxContainer = content.get_node("FishingRoundFailureActions")
	var home_button: Button = actions.get_node("FishingRoundFailureHomeButton")
	var retry_button: Button = actions.get_node("FishingRoundFailureRetryButton")
	_style_home_popup_button(home_button, false, ROUND_FAILURE_BUTTON_FONT_SIZE)
	_style_home_popup_button(retry_button, true, ROUND_FAILURE_BUTTON_FONT_SIZE)
	home_button.pressed.connect(_return_home_from_round_failure)
	retry_button.pressed.connect(_retry_current_level_from_round_failure)


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
	var overlay: Button = NoHeartsPopupScene.instantiate()
	overlay.pressed.connect(_dismiss_result)
	result_overlay = overlay
	add_child(result_overlay)
	var content: VBoxContainer = overlay.get_node("Panel/Content")
	var cat: TextureRect = content.get_node("FishingNoHeartsCat")
	cat.texture = _round_failure_cat_texture()
	_style_popup_label(content.get_node("Title"), true)
	no_hearts_countdown_label = content.get_node("FishingNoHeartsCountdown")
	_style_popup_label(no_hearts_countdown_label, false, Color("#58352b"))
	_style_popup_label(content.get_node("Footer"), false, Color("#786359"))
	_update_no_hearts_countdown()


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
	fishing_session.build_spawn_plan()


func _weighted_random_fish_id(candidate_ids: Array[String]) -> String:
	return fishing_session.weighted_random_fish_id(candidate_ids)


func _shuffle_fish_ids(fish_ids: Array) -> void:
	fishing_session.shuffle_fish_ids(fish_ids)


func _build_round_spawn_times(spawn_count: int) -> void:
	fishing_session.build_spawn_times(spawn_count)


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
	pet_view.texture = pet_presentation.default_frame(animation_frame_index)


func _failure_cat_texture() -> Texture2D:
	return pet_presentation.catch_failure_texture


func _round_failure_cat_texture() -> Texture2D:
	return pet_presentation.round_failure_texture


func _make_fish_visual(
	fish: Dictionary,
	target_size: Vector2,
	texture_region_key := "texture_region"
) -> TextureRect:
	var texture_view := TextureRect.new()
	_configure_fish_visual(texture_view, fish, target_size, texture_region_key)
	return texture_view


func _configure_fish_visual(
	texture_view: TextureRect,
	fish: Dictionary,
	target_size: Vector2,
	texture_region_key := "texture_region"
) -> void:
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


func _restore_hearts_at(now_unix: int, _emit_change := true) -> bool:
	return heart_service.restore_at(now_unix)


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
	var now := now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	return heart_service.seconds_until_next(now)


func _format_countdown(total_seconds: int) -> String:
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _emit_shared_stats_changed() -> void:
	var progress_patch := {
		"hearts": hearts,
		"next_heart_restore_unix": next_heart_restore_unix,
		"fishing_level": maxi(
			maxi(
				current_level,
				int(shared_stats.get("fishing_level", current_level))
			),
			FISHING_LEVEL
		),
		"unlocked_fish_ids": unlocked_fish_ids.duplicate()
	}
	if current_level_retry_count > 0:
		progress_patch["fishing_retry_level"] = current_level
		progress_patch["fishing_retry_count"] = current_level_retry_count
	else:
		progress_patch["fishing_retry_level"] = 0
		progress_patch["fishing_retry_count"] = 0
	var changed: bool = progress_store.merge(progress_patch)
	shared_stats = progress_store.snapshot()
	if not changed:
		shared_stats_changed.emit(shared_stats.duplicate(true))


func _update_stats() -> void:
	for label in stats_labels:
		if is_instance_valid(label):
			label.text = "LEVEL: %d\nTIME: %s" % [
				current_level,
				_format_countdown(ceili(round_time_remaining))
			]


func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = Color("#b98560")
	style.shadow_color = Color(0.18, 0.09, 0.06, 0.16)
	style.shadow_size = 6
	return style
