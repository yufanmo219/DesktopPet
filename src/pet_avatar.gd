class_name PetAvatar
extends Control

const PET_TEXTURE: Texture2D = preload("res://assets/pets/current/orange_cat.png")
const SLEEP_TEXTURE: Texture2D = preload("res://assets/pets/current/sprites/orange_cat_sleep.png")
const MOCHI_HOME_TAIL_BLINK_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/mochi/home_tail_blink/frame_01.png"),
	preload("res://assets/pets/mochi/home_tail_blink/frame_02.png"),
	preload("res://assets/pets/mochi/home_tail_blink/frame_03.png"),
	preload("res://assets/pets/mochi/home_tail_blink/frame_04.png"),
	preload("res://assets/pets/mochi/home_tail_blink/frame_05.png"),
	preload("res://assets/pets/mochi/home_tail_blink/frame_06.png"),
	preload("res://assets/pets/mochi/home_tail_blink/frame_07.png"),
	preload("res://assets/pets/mochi/home_tail_blink/frame_08.png")
]
const MOCHI_SLEEP_TEXTURE: Texture2D = preload("res://assets/pets/mochi/sleep/mochi_sleep.png")
const MOCHI_SLEEP_EAR_TWITCH_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_01.png"),
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_02.png"),
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_03.png"),
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_04.png"),
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_05.png"),
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_06.png"),
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_07.png"),
	preload("res://assets/pets/mochi/sleep/ear_twitch/frame_08.png")
]
const MOCHI_LICK_PAW_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_01.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_02.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_03.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_04.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_05.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_06.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_07.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_08.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_09.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_10.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_11.png"),
	preload("res://assets/pets/mochi/side_lick_paw_v3/frame_12.png")
]
const MOCHI_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/mochi/walk_left/frame_01.png"),
	preload("res://assets/pets/mochi/walk_left/frame_02.png"),
	preload("res://assets/pets/mochi/walk_left/frame_03.png"),
	preload("res://assets/pets/mochi/walk_left/frame_04.png"),
	preload("res://assets/pets/mochi/walk_left/frame_05.png"),
	preload("res://assets/pets/mochi/walk_left/frame_06.png"),
	preload("res://assets/pets/mochi/walk_left/frame_07.png"),
	preload("res://assets/pets/mochi/walk_left/frame_08.png"),
	preload("res://assets/pets/mochi/walk_left/frame_09.png"),
	preload("res://assets/pets/mochi/walk_left/frame_10.png"),
	preload("res://assets/pets/mochi/walk_left/frame_11.png"),
	preload("res://assets/pets/mochi/walk_left/frame_12.png")
]
const MOCHI_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/mochi/walk_right/frame_01.png"),
	preload("res://assets/pets/mochi/walk_right/frame_02.png"),
	preload("res://assets/pets/mochi/walk_right/frame_03.png"),
	preload("res://assets/pets/mochi/walk_right/frame_04.png"),
	preload("res://assets/pets/mochi/walk_right/frame_05.png"),
	preload("res://assets/pets/mochi/walk_right/frame_06.png"),
	preload("res://assets/pets/mochi/walk_right/frame_07.png"),
	preload("res://assets/pets/mochi/walk_right/frame_08.png"),
	preload("res://assets/pets/mochi/walk_right/frame_09.png"),
	preload("res://assets/pets/mochi/walk_right/frame_10.png"),
	preload("res://assets/pets/mochi/walk_right/frame_11.png"),
	preload("res://assets/pets/mochi/walk_right/frame_12.png")
]
const BISCUIT_IDLE_TEXTURE: Texture2D = preload(
	"res://assets/pets/biscuit/home/biscuit_side_sitting.png"
)
const BISCUIT_SLEEP_TEXTURE: Texture2D = preload(
	"res://assets/pets/biscuit/sleep/biscuit_sleep.png"
)
const BISCUIT_BUTTERFLY_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_01.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_02.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_03.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_04.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_05.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_06.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_07.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_08.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_09.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_10.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_11.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_12.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_13.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_14.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_15.png"),
	preload("res://assets/pets/biscuit/desktop/butterfly/frame_16.png")
]
const BISCUIT_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/biscuit/walk_left/frame_01.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_02.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_03.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_04.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_05.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_06.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_07.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_08.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_09.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_10.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_11.png"),
	preload("res://assets/pets/biscuit/walk_left/frame_12.png")
]
const BISCUIT_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/biscuit/walk_right/frame_01.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_02.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_03.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_04.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_05.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_06.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_07.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_08.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_09.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_10.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_11.png"),
	preload("res://assets/pets/biscuit/walk_right/frame_12.png")
]
const LUNA_IDLE_TEXTURE: Texture2D = preload(
	"res://assets/pets/russian_blue/home/luna_side_sitting.png"
)
const LUNA_SLEEP_TEXTURE: Texture2D = preload(
	"res://assets/pets/russian_blue/sleep/luna_sleep_v2.png"
)
const LUNA_SLEEP_IDLE_FRAMES: Array[Texture2D] = [
	LUNA_SLEEP_TEXTURE,
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_02.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_03.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_04.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_05.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_06.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_07.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_08.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_09.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_10.png"),
	preload("res://assets/pets/russian_blue/sleep/face_wash_v2/frame_11.png"),
	LUNA_SLEEP_TEXTURE
]
const LUNA_STRETCH_YAWN_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_01.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_02.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_03.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_04.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_05.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_06.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_07.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_08.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_09.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_10.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_11.png"),
	preload("res://assets/pets/russian_blue/desktop/stretch_yawn/frame_12.png")
]
const LUNA_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_01.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_02.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_03.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_04.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_05.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_06.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_07.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_08.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_09.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_10.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_11.png"),
	preload("res://assets/pets/russian_blue/walk_left_v3/frame_12.png")
]
const LUNA_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_01.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_02.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_03.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_04.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_05.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_06.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_07.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_08.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_09.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_10.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_11.png"),
	preload("res://assets/pets/russian_blue/walk_right_v3/frame_12.png")
]
const POPPY_IDLE_TEXTURE: Texture2D = preload("res://assets/pets/blue_british/home/poppy_side_sitting.png")
const POPPY_SLEEP_TEXTURE: Texture2D = preload("res://assets/pets/blue_british/sleep/poppy_sleep.png")
const POPPY_SLEEP_FACE_RUB_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_01.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_02.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_03.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_04.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_05.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_06.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_07.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_08.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_09.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_10.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_11.png"),
	preload("res://assets/pets/blue_british/sleep/face_rub/frame_12.png")
]
const POPPY_TEASER_PLAY_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_01.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_02.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_03.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_04.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_05.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_06.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_07.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_08.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_09.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_10.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_11.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_12.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_13.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_14.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_15.png"),
	preload("res://assets/pets/blue_british/desktop/teaser_play/frame_16.png")
]
const POPPY_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/blue_british/walk_left/frame_01.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_02.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_03.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_04.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_05.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_06.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_07.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_08.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_09.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_10.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_11.png"),
	preload("res://assets/pets/blue_british/walk_left/frame_12.png")
]
const POPPY_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/blue_british/walk_right/frame_01.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_02.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_03.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_04.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_05.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_06.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_07.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_08.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_09.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_10.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_11.png"),
	preload("res://assets/pets/blue_british/walk_right/frame_12.png")
]
const BLACK_CAT_IDLE_TEXTURE: Texture2D = preload(
	"res://assets/pets/black_cat/home/black_cat_side_sitting.png"
)
const BLACK_CAT_SLEEP_TEXTURE: Texture2D = preload(
	"res://assets/pets/black_cat/sleep/black_cat_sleep.png"
)
const BLACK_CAT_FALL_ASLEEP_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_01.png"),
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_02.png"),
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_03.png"),
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_04.png"),
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_05.png"),
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_06.png"),
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_07.png"),
	preload("res://assets/pets/black_cat/sleep/fall_asleep/frame_08.png")
]
const BLACK_CAT_LICK_PAW_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/black_cat/fishing/success/frame_01.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_02.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_03.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_04.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_05.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_06.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_07.png"),
	preload("res://assets/pets/black_cat/fishing/success/frame_08.png")
]
const BLACK_CAT_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/black_cat/walk_left_v3/frame_01.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_02.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_03.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_04.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_05.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_06.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_07.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_08.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_09.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_10.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_11.png"),
	preload("res://assets/pets/black_cat/walk_left_v3/frame_12.png")
]
const BLACK_CAT_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/black_cat/walk_right_v3/frame_01.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_02.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_03.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_04.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_05.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_06.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_07.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_08.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_09.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_10.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_11.png"),
	preload("res://assets/pets/black_cat/walk_right_v3/frame_12.png")
]
const MAINE_COON_IDLE_TEXTURE: Texture2D = preload(
	"res://assets/pets/maine_coon/home/maine_coon_side_sitting.png"
)
const MAINE_COON_SLEEP_TEXTURE: Texture2D = preload(
	"res://assets/pets/maine_coon/sleep/maine_coon_sleep.png"
)
const MAINE_COON_SLEEP_PAW_LICK_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_01.png"),
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_02.png"),
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_03.png"),
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_04.png"),
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_05.png"),
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_06.png"),
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_07.png"),
	preload("res://assets/pets/maine_coon/sleep/paw_lick/frame_08.png")
]
const MAINE_COON_NUZZLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_01.png"),
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_02.png"),
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_03.png"),
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_04.png"),
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_05.png"),
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_06.png"),
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_07.png"),
	preload("res://assets/pets/maine_coon/desktop/nuzzle/frame_08.png")
]
const MAINE_COON_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/maine_coon/walk_left/frame_01.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_02.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_03.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_04.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_05.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_06.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_07.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_08.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_09.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_10.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_11.png"),
	preload("res://assets/pets/maine_coon/walk_left/frame_12.png")
]
const MAINE_COON_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/maine_coon/walk_right/frame_01.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_02.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_03.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_04.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_05.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_06.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_07.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_08.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_09.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_10.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_11.png"),
	preload("res://assets/pets/maine_coon/walk_right/frame_12.png")
]
const GOLDEN_MUNCHKIN_IDLE_TEXTURE: Texture2D = preload(
	"res://assets/pets/golden_munchkin/home/golden_munchkin_side_sitting.png"
)
const GOLDEN_MUNCHKIN_SLEEP_TEXTURE: Texture2D = preload(
	"res://assets/pets/golden_munchkin/sleep/golden_munchkin_sleep.png"
)
const GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_01.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_02.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_03.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_04.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_05.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_06.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_07.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_08.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_09.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_10.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_11.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_12.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_13.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_14.png"),
	preload("res://assets/pets/golden_munchkin/sleep/tail_sweep/frame_15.png")
]
const GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_01.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_02.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_03.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_04.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_05.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_06.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_07.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_08.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_09.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_10.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_11.png"),
	preload("res://assets/pets/golden_munchkin/desktop/failed_roll/frame_12.png")
]
const GOLDEN_MUNCHKIN_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/golden_munchkin/move_left/frame_01.png"),
	preload("res://assets/pets/golden_munchkin/move_left/frame_02.png"),
	preload("res://assets/pets/golden_munchkin/move_left/frame_03.png"),
	preload("res://assets/pets/golden_munchkin/move_left/frame_04.png"),
	preload("res://assets/pets/golden_munchkin/move_left/frame_05.png"),
	preload("res://assets/pets/golden_munchkin/move_left/frame_06.png"),
	preload("res://assets/pets/golden_munchkin/move_left/frame_07.png"),
	preload("res://assets/pets/golden_munchkin/move_left/frame_08.png")
]
const GOLDEN_MUNCHKIN_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/golden_munchkin/move_right/frame_01.png"),
	preload("res://assets/pets/golden_munchkin/move_right/frame_02.png"),
	preload("res://assets/pets/golden_munchkin/move_right/frame_03.png"),
	preload("res://assets/pets/golden_munchkin/move_right/frame_04.png"),
	preload("res://assets/pets/golden_munchkin/move_right/frame_05.png"),
	preload("res://assets/pets/golden_munchkin/move_right/frame_06.png"),
	preload("res://assets/pets/golden_munchkin/move_right/frame_07.png"),
	preload("res://assets/pets/golden_munchkin/move_right/frame_08.png")
]
const SIAMESE_IDLE_TEXTURE: Texture2D = preload(
	"res://assets/pets/siamese/home/siamese_side_sitting.png"
)
const SIAMESE_SLEEP_TEXTURE: Texture2D = preload(
	"res://assets/pets/siamese/sleep/siamese_sleep.png"
)
const SIAMESE_TREAT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/siamese/desktop/treat/frame_01.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_02.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_03.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_04.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_05.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_06.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_07.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_08.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_09.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_10.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_11.png"),
	preload("res://assets/pets/siamese/desktop/treat/frame_12.png")
]
const SIAMESE_MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/siamese/walk_left/frame_01.png"),
	preload("res://assets/pets/siamese/walk_left/frame_02.png"),
	preload("res://assets/pets/siamese/walk_left/frame_03.png"),
	preload("res://assets/pets/siamese/walk_left/frame_04.png")
]
const SIAMESE_MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/siamese/walk_right/frame_01.png"),
	preload("res://assets/pets/siamese/walk_right/frame_02.png"),
	preload("res://assets/pets/siamese/walk_right/frame_03.png"),
	preload("res://assets/pets/siamese/walk_right/frame_04.png")
]
const SLEEP_BUBBLE_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_01.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_02.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_03.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_04.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_05.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_06.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_07.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_08.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_09.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_10.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_11.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_12.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_13.png"),
	preload("res://assets/pets/current/sprites/sleep_bubble/frames/frame_14.png")
]
const MOVE_LEFT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/current/sprites/move_left/frame_01.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_02.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_03.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_04.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_05.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_06.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_07.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_08.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_09.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_10.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_11.png"),
	preload("res://assets/pets/current/sprites/move_left/frame_12.png")
]
const MOVE_RIGHT_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/current/sprites/move_right/frame_01.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_02.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_03.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_04.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_05.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_06.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_07.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_08.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_09.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_10.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_11.png"),
	preload("res://assets/pets/current/sprites/move_right/frame_12.png")
]
const SHY_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/current/sprites/shy/frame_01.png"),
	preload("res://assets/pets/current/sprites/shy/frame_02.png"),
	preload("res://assets/pets/current/sprites/shy/frame_03.png"),
	preload("res://assets/pets/current/sprites/shy/frame_04.png"),
	preload("res://assets/pets/current/sprites/shy/frame_05.png"),
	preload("res://assets/pets/current/sprites/shy/frame_06.png")
]
const DESKTOP_WINK_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/current/sprites/desktop_wink/frame_01.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_02.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_03.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_04.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_05.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_06.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_07.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_08.png"),
	preload("res://assets/pets/current/sprites/desktop_wink/frame_09.png")
]
const DESKTOP_BELLY_FRAMES: Array[Texture2D] = [
	preload("res://assets/pets/current/sprites/desktop_roll/frame_01.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_02.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_03.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_04.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_05.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_06.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_01.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_02.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_03.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_04.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_05.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_06.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_07.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_08.png"),
	preload("res://assets/pets/current/sprites/desktop_biscuit/frame_09.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_06.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_05.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_04.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_03.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_02.png"),
	preload("res://assets/pets/current/sprites/desktop_roll/frame_01.png")
]
const MOVE_FPS := 7.0
const LUNA_MOVE_FPS := 12.0
const BLACK_CAT_MOVE_FPS := 10.0
# Fixed canvas/foot line for the freshly authored mirrored Luna walk cycle.
const LUNA_MOVE_LAYOUT_BOUNDS := Rect2(0.0, 0.0, 704.0, 500.0)
# Sable's new side-profile cycle shares one canvas and planted-paw baseline.
const BLACK_CAT_MOVE_LAYOUT_BOUNDS := Rect2(0.0, 0.0, 704.0, 500.0)
const MOVE_LOOP_START_FRAME := 3
const MOVEMENT_SCALE_MULTIPLIER := 0.98
const BLACK_CAT_SLEEP_SCALE_MULTIPLIER := 0.76
const SHY_FPS := 6.0
const DESKTOP_WINK_FPS := 6.0
const DESKTOP_BELLY_FPS := 4.5
const DESKTOP_IDLE_MIN_WAIT := 7.0
const DESKTOP_IDLE_MAX_WAIT := 15.0
const SLEEP_BUBBLE_FPS := 5.0
const SLEEP_BUBBLE_MIN_WAIT := 3.0
const SLEEP_BUBBLE_MAX_WAIT := 8.0
const SLEEP_BUBBLE_NOSE_POSITION := Vector2(374.0, 338.0)
const BISCUIT_SLEEP_BUBBLE_NOSE_POSITION := Vector2(218.0, 398.0)
const SLEEP_BUBBLE_FRAME_ANCHOR := Vector2(10.0, 70.0)
const SHADOW_CENTER_Y_RATIO := 0.91
const MOCHI_HOME_IDLE_MIN_WAIT := 4.0
const MOCHI_HOME_IDLE_MAX_WAIT := 8.0
const MOCHI_HOME_IDLE_FRAME_DURATIONS := [0.30, 0.10, 0.10, 0.15, 0.15, 0.10, 0.10, 0.40]
const MOCHI_SLEEP_EAR_TWITCH_MIN_WAIT := 3.5
const MOCHI_SLEEP_EAR_TWITCH_MAX_WAIT := 9.0
const MOCHI_SLEEP_EAR_TWITCH_FRAME_DURATIONS: Array[float] = [0.40, 0.10, 0.10, 0.12, 0.12, 0.10, 0.10, 0.45]
const MOCHI_LICK_PAW_FRAME_DURATIONS: Array[float] = [0.45, 0.10, 0.10, 0.11, 0.14, 0.10, 0.14, 0.11, 0.10, 0.10, 0.11, 0.60]
const BISCUIT_BUTTERFLY_FRAME_DURATIONS: Array[float] = [
	0.35, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14,
	0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.55
]
const BISCUIT_DOUBLE_CLICK_OFFSET := Vector2(0.0, -8.0)
const LUNA_STRETCH_YAWN_FRAME_DURATIONS: Array[float] = [
	0.40, 0.14, 0.14, 0.16, 0.18, 0.22,
	0.24, 0.18, 0.16, 0.16, 0.20, 0.55
]
const LUNA_SLEEP_IDLE_FRAME_DURATIONS: Array[float] = [
	0.30, 0.18, 0.16, 0.18, 0.22, 0.35,
	0.30, 0.22, 0.18, 0.16, 0.18, 0.40
]
const LUNA_SLEEP_IDLE_MIN_WAIT := 4.0
const LUNA_SLEEP_IDLE_MAX_WAIT := 10.0
const POPPY_SLEEP_FACE_RUB_FRAME_DURATIONS: Array[float] = [
	0.22, 0.14, 0.14, 0.17, 0.16, 0.16, 0.18, 0.16, 0.16, 0.17, 0.18, 0.30
]
const POPPY_TEASER_PLAY_FRAME_DURATIONS: Array[float] = [
	0.75, 0.50, 0.36, 0.60,
	0.44, 0.52, 0.42, 0.42,
	0.32, 0.27, 0.27, 0.32,
	0.45, 0.50, 0.65, 0.90
]
const BLACK_CAT_FALL_ASLEEP_FRAME_DURATIONS: Array[float] = [
	0.48, 0.18, 0.22, 0.30, 0.34, 0.44, 0.50, 0.70
]
const BLACK_CAT_LICK_PAW_FRAME_DURATIONS: Array[float] = [
	0.34, 0.18, 0.22, 0.26, 0.24, 0.24, 0.30, 0.58
]
const MAINE_COON_SLEEP_PAW_LICK_FRAME_DURATIONS: Array[float] = [
	0.70, 0.28, 0.32, 0.40, 0.32, 0.26, 0.30, 0.95
]
const MAINE_COON_NUZZLE_FRAME_DURATIONS: Array[float] = [
	0.42, 0.18, 0.22, 0.25, 0.24, 0.35, 0.22, 0.68
]
const GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAME_DURATIONS: Array[float] = [
	0.26, 0.17, 0.17, 0.17, 0.52,
	0.17, 0.17, 0.17, 0.24, 0.17,
	0.17, 0.55, 0.18, 0.18, 0.30
]
const GOLDEN_MUNCHKIN_FAILED_ROLL_FRAME_DURATIONS: Array[float] = [
	0.60, 0.24, 0.22, 0.24, 0.22, 0.15,
	0.20, 0.52, 0.26, 0.24, 0.24, 0.75
]
const SIAMESE_TREAT_FRAME_DURATIONS: Array[float] = [
	0.36, 0.22, 0.27, 0.10, 0.125, 0.09,
	0.125, 0.09, 0.125, 0.13, 0.25, 0.65
]
const POPPY_SLEEP_FACE_RUB_MIN_WAIT := 4.0
const POPPY_SLEEP_FACE_RUB_MAX_WAIT := 10.0
const GameFontStylesScript = preload("res://src/game_font_styles.gd")

var mood := "idle"
var pet_id := "default_orange_cat"
var home_idle_enabled := false
var home_idle_playing := false
var home_idle_frame := 0
var home_idle_frame_elapsed := 0.0
var home_idle_wait_remaining := 0.0
var cat_sprite: Sprite2D
var sleep_bubble_sprite: Sprite2D
var mood_badge: Label
var move_direction := "right"
var move_frame := 0
var move_frame_elapsed := 0.0
var move_time_remaining := 0.0
var interaction_animation_active := false
var interaction_frames: Array[Texture2D] = []
var interaction_frame_durations: Array[float] = []
var interaction_frame := 0
var interaction_frame_elapsed := 0.0
var shy_frame := 0
var shy_frame_elapsed := 0.0
var desktop_idle_enabled := false
var desktop_idle_animation := ""
var desktop_idle_frames: Array[Texture2D] = []
var desktop_idle_frame := 0
var desktop_idle_frame_elapsed := 0.0
var desktop_idle_wait_remaining := 0.0
var sleep_bubble_frame := 0
var sleep_bubble_frame_elapsed := 0.0
var sleep_bubble_active := false
var sleep_bubble_wait_remaining := 0.0
var mochi_sleep_ear_twitch_playing := false
var mochi_sleep_ear_twitch_frame := 0
var mochi_sleep_ear_twitch_frame_elapsed := 0.0
var mochi_sleep_ear_twitch_wait_remaining := 0.0
var luna_sleep_idle_playing := false
var luna_sleep_idle_frame := 0
var luna_sleep_idle_frame_elapsed := 0.0
var luna_sleep_idle_wait_remaining := 0.0
var poppy_sleep_face_rub_playing := false
var poppy_sleep_face_rub_frame := 0
var poppy_sleep_face_rub_frame_elapsed := 0.0
var poppy_sleep_face_rub_wait_remaining := 0.0
var black_cat_fall_asleep_playing := false
var black_cat_fall_asleep_frame := 0
var black_cat_fall_asleep_frame_elapsed := 0.0
var maine_coon_sleep_paw_lick_playing := false
var maine_coon_sleep_paw_lick_frame := 0
var maine_coon_sleep_paw_lick_frame_elapsed := 0.0
var golden_munchkin_sleep_tail_playing := false
var golden_munchkin_sleep_tail_frame := 0
var golden_munchkin_sleep_tail_frame_elapsed := 0.0
static var texture_visual_bounds_cache: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	cat_sprite = Sprite2D.new()
	cat_sprite.texture = PET_TEXTURE
	cat_sprite.centered = true
	add_child(cat_sprite)

	sleep_bubble_sprite = Sprite2D.new()
	sleep_bubble_sprite.name = "SleepBubble"
	sleep_bubble_sprite.centered = false
	sleep_bubble_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sleep_bubble_sprite.position = (
		SLEEP_BUBBLE_NOSE_POSITION
		- SLEEP_TEXTURE.get_size() * 0.5
		- SLEEP_BUBBLE_FRAME_ANCHOR
	)
	sleep_bubble_sprite.z_index = 1
	cat_sprite.add_child(sleep_bubble_sprite)

	mood_badge = Label.new()
	GameFontStylesScript.apply_regular(mood_badge)
	mood_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mood_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mood_badge.add_theme_font_size_override("font_size", 24)
	mood_badge.add_theme_color_override("font_color", Color("#5c3546"))
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(1.0, 0.96, 0.87, 0.92)
	badge_style.set_corner_radius_all(14)
	badge_style.content_margin_left = 12
	badge_style.content_margin_right = 12
	mood_badge.add_theme_stylebox_override("normal", badge_style)
	add_child(mood_badge)
	_update_visuals()



func set_pet(data: Dictionary) -> void:
	pet_id = str(data.get("id", "default_orange_cat")).to_lower()
	# A PetAvatar can be reused while switching cats or rebuilding the Desktop
	# companion. Never let the previous cat's walking state leak into the new
	# cat's stationary pose.
	move_time_remaining = 0.0
	move_frame = 0
	move_frame_elapsed = 0.0
	_stop_home_idle_animation()
	_stop_desktop_idle_animation()
	_stop_mochi_sleep_ear_twitch()
	_stop_luna_sleep_idle()
	_stop_poppy_sleep_face_rub()
	_stop_black_cat_fall_asleep()
	_stop_maine_coon_sleep_paw_lick()
	_stop_golden_munchkin_sleep_tail()
	interaction_animation_active = false
	interaction_frames = []
	interaction_frame_durations = []
	if home_idle_enabled:
		_schedule_next_home_idle()
	if mood == "sleep":
		_schedule_next_sleep_effect()
	_update_visuals()


func set_home_idle_enabled(enabled: bool) -> void:
	home_idle_enabled = enabled
	_stop_home_idle_animation()
	if enabled:
		_schedule_next_home_idle()
	_apply_current_texture()


func set_mood(value: String) -> void:
	var mood_changed := mood != value
	mood = value
	if mood != "idle":
		_stop_desktop_idle_animation()
	if mood == "sleep":
		move_time_remaining = 0.0
		if mood_changed:
			_schedule_next_sleep_effect()
	elif mood_changed:
		sleep_bubble_active = false
		sleep_bubble_wait_remaining = 0.0
		_stop_mochi_sleep_ear_twitch()
		_stop_luna_sleep_idle()
		_stop_poppy_sleep_face_rub()
		_stop_black_cat_fall_asleep()
		_stop_maine_coon_sleep_paw_lick()
		_stop_golden_munchkin_sleep_tail()
	if mood == "blush" and mood_changed:
		shy_frame = 0
		shy_frame_elapsed = 0.0
	_update_visuals()


func play_move(movement: Vector2) -> void:
	if mood == "sleep" or movement.length_squared() < 0.01:
		return
	_stop_desktop_idle_animation()
	var next_direction := move_direction
	if movement.x < -0.01:
		next_direction = "left"
	elif movement.x > 0.01:
		next_direction = "right"
	if move_time_remaining <= 0.0 or move_direction != next_direction:
		move_frame = 0
		move_frame_elapsed = 0.0
	move_direction = next_direction
	move_time_remaining = 1.15
	_apply_current_texture()


func stop_move() -> void:
	move_time_remaining = 0.0
	move_frame_elapsed = 0.0
	_apply_current_texture()


func play_belly_roll() -> void:
	stop_move()
	_stop_desktop_idle_animation()
	interaction_animation_active = true
	interaction_frames = (
		MOCHI_LICK_PAW_FRAMES
		if _uses_mochi_home_art()
		else BISCUIT_BUTTERFLY_FRAMES if _uses_biscuit_home_art()
		else LUNA_STRETCH_YAWN_FRAMES if _uses_luna_home_art()
		else POPPY_TEASER_PLAY_FRAMES if _uses_poppy_home_art()
		else BLACK_CAT_LICK_PAW_FRAMES if _uses_black_cat_home_art()
		else MAINE_COON_NUZZLE_FRAMES if _uses_maine_coon_home_art()
		else GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES if _uses_golden_munchkin_home_art()
		else SIAMESE_TREAT_FRAMES if _uses_siamese_home_art()
		else DESKTOP_BELLY_FRAMES
	)
	interaction_frame_durations.clear()
	if _uses_mochi_home_art():
		interaction_frame_durations.assign(MOCHI_LICK_PAW_FRAME_DURATIONS)
	elif _uses_biscuit_home_art():
		interaction_frame_durations.assign(BISCUIT_BUTTERFLY_FRAME_DURATIONS)
	elif _uses_luna_home_art():
		interaction_frame_durations.assign(LUNA_STRETCH_YAWN_FRAME_DURATIONS)
	elif _uses_poppy_home_art():
		interaction_frame_durations.assign(POPPY_TEASER_PLAY_FRAME_DURATIONS)
	elif _uses_black_cat_home_art():
		interaction_frame_durations.assign(BLACK_CAT_LICK_PAW_FRAME_DURATIONS)
	elif _uses_maine_coon_home_art():
		interaction_frame_durations.assign(MAINE_COON_NUZZLE_FRAME_DURATIONS)
	elif _uses_golden_munchkin_home_art():
		interaction_frame_durations.assign(GOLDEN_MUNCHKIN_FAILED_ROLL_FRAME_DURATIONS)
	elif _uses_siamese_home_art():
		interaction_frame_durations.assign(SIAMESE_TREAT_FRAME_DURATIONS)
	interaction_frame = 0
	interaction_frame_elapsed = 0.0
	_apply_current_texture()
	_update_visuals()


func is_playing_interaction() -> bool:
	return interaction_animation_active


func _process(delta: float) -> void:
	if interaction_animation_active:
		_process_interaction_animation(delta)
	elif mood == "sleep":
		if _uses_golden_munchkin_home_art() or _uses_siamese_home_art():
			pass
		elif _uses_maine_coon_home_art():
			_process_maine_coon_sleep_paw_lick(delta)
		elif _uses_black_cat_home_art():
			_process_black_cat_fall_asleep(delta)
		elif _uses_luna_home_art():
			_process_luna_sleep_idle(delta)
		elif _uses_poppy_home_art():
			_process_poppy_sleep_face_rub(delta)
		elif _uses_mochi_home_art():
			_process_mochi_sleep_ear_twitch(delta)
		else:
			_process_sleep_bubble(delta)
	elif mood == "blush":
		shy_frame_elapsed += delta
		if shy_frame_elapsed >= 1.0 / SHY_FPS:
			shy_frame_elapsed = fmod(shy_frame_elapsed, 1.0 / SHY_FPS)
			shy_frame = (shy_frame + 1) % SHY_FRAMES.size()
			_apply_current_texture()
	elif move_time_remaining > 0.0 and mood != "sleep":
		move_time_remaining = maxf(0.0, move_time_remaining - delta)
		move_frame_elapsed += delta
		var move_fps := (
			LUNA_MOVE_FPS
			if _uses_luna_home_art()
			else BLACK_CAT_MOVE_FPS if _uses_black_cat_home_art()
			else MOVE_FPS
		)
		var move_frame_duration := 1.0 / move_fps
		while move_frame_elapsed >= move_frame_duration:
			move_frame_elapsed -= move_frame_duration
			move_frame += 1
			if move_frame >= _get_move_frames().size():
				move_frame = _get_move_loop_start_frame()
		_apply_current_texture()
	elif desktop_idle_enabled and mood == "idle":
		_process_desktop_idle(delta)
	elif home_idle_enabled and mood == "idle" and _uses_mochi_home_art():
		_process_home_idle(delta)
	elif cat_sprite.texture != _get_idle_texture() and mood != "sleep":
		_apply_current_texture()
	_update_layout()
	queue_redraw()


func _update_visuals() -> void:
	if not is_instance_valid(cat_sprite):
		return
	cat_sprite.modulate = Color.WHITE
	cat_sprite.rotation = 0.0
	match mood:
		"sleep":
			mood_badge.text = ""
		"blush":
			mood_badge.text = "FEELING SHY..."
		"roll_eyes":
			mood_badge.text = "...REALLY?"
		"blink":
			mood_badge.text = "BLINK!"
		"follow":
			mood_badge.text = ""
		"happy":
			mood_badge.text = "HAPPY!"
		_:
			mood_badge.text = ""
	mood_badge.visible = (
		mood != "follow"
		and mood_badge.text != ""
		and not interaction_animation_active
	)
	_apply_current_texture()
	_update_layout()


func _apply_current_texture() -> void:
	if not is_instance_valid(cat_sprite):
		return
	if interaction_animation_active:
		cat_sprite.texture = interaction_frames[interaction_frame]
	elif mood == "sleep":
		if _uses_siamese_home_art():
			cat_sprite.texture = SIAMESE_SLEEP_TEXTURE
		elif _uses_golden_munchkin_home_art():
			cat_sprite.texture = GOLDEN_MUNCHKIN_SLEEP_TEXTURE
		elif _uses_maine_coon_home_art():
			cat_sprite.texture = (
				MAINE_COON_SLEEP_PAW_LICK_FRAMES[maine_coon_sleep_paw_lick_frame]
				if maine_coon_sleep_paw_lick_playing
				else MAINE_COON_SLEEP_TEXTURE
			)
		elif _uses_black_cat_home_art():
			cat_sprite.texture = (
				BLACK_CAT_FALL_ASLEEP_FRAMES[black_cat_fall_asleep_frame]
				if black_cat_fall_asleep_playing
				else BLACK_CAT_SLEEP_TEXTURE
			)
		elif _uses_luna_home_art():
			cat_sprite.texture = (
				LUNA_SLEEP_IDLE_FRAMES[luna_sleep_idle_frame]
				if luna_sleep_idle_playing
				else LUNA_SLEEP_TEXTURE
			)
		elif _uses_poppy_home_art():
			cat_sprite.texture = (
				POPPY_SLEEP_FACE_RUB_FRAMES[poppy_sleep_face_rub_frame]
				if poppy_sleep_face_rub_playing
				else POPPY_SLEEP_TEXTURE
			)
		elif _uses_mochi_home_art():
			cat_sprite.texture = (
				MOCHI_SLEEP_EAR_TWITCH_FRAMES[mochi_sleep_ear_twitch_frame]
				if mochi_sleep_ear_twitch_playing
				else MOCHI_SLEEP_TEXTURE
			)
		elif _uses_biscuit_home_art():
			cat_sprite.texture = BISCUIT_SLEEP_TEXTURE
		else:
			cat_sprite.texture = SLEEP_TEXTURE
	elif mood == "blush":
		cat_sprite.texture = _get_idle_texture() if _uses_custom_home_art() else SHY_FRAMES[shy_frame]
	elif move_time_remaining > 0.0:
		cat_sprite.texture = _get_move_frames()[move_frame]
	elif desktop_idle_animation != "" and not desktop_idle_frames.is_empty():
		cat_sprite.texture = desktop_idle_frames[desktop_idle_frame]
	elif home_idle_playing and _uses_mochi_home_art():
		cat_sprite.texture = MOCHI_HOME_TAIL_BLINK_FRAMES[home_idle_frame]
	else:
		cat_sprite.texture = _get_idle_texture()
	cat_sprite.texture_filter = (
		CanvasItem.TEXTURE_FILTER_LINEAR
		if (
			cat_sprite.texture == BLACK_CAT_IDLE_TEXTURE
			or cat_sprite.texture == BLACK_CAT_SLEEP_TEXTURE
			or cat_sprite.texture in BLACK_CAT_FALL_ASLEEP_FRAMES
			or cat_sprite.texture in BLACK_CAT_MOVE_LEFT_FRAMES
			or cat_sprite.texture in BLACK_CAT_MOVE_RIGHT_FRAMES
		)
		else CanvasItem.TEXTURE_FILTER_PARENT_NODE
	)
	_update_sleep_bubble()


func _uses_mochi_home_art() -> bool:
	return pet_id == "mochi"


func _uses_biscuit_home_art() -> bool:
	return pet_id == "biscuit"


func _uses_luna_home_art() -> bool:
	return pet_id == "luna"


func _uses_poppy_home_art() -> bool:
	return pet_id == "poppy"


func _uses_black_cat_home_art() -> bool:
	return pet_id == "black_cat"


func _uses_maine_coon_home_art() -> bool:
	return pet_id == "maine_coon"


func _uses_golden_munchkin_home_art() -> bool:
	return pet_id == "golden_munchkin"


func _uses_siamese_home_art() -> bool:
	return pet_id == "siamese"


func _uses_custom_home_art() -> bool:
	return (
		_uses_mochi_home_art()
		or _uses_biscuit_home_art()
		or _uses_luna_home_art()
		or _uses_poppy_home_art()
		or _uses_black_cat_home_art()
		or _uses_maine_coon_home_art()
		or _uses_golden_munchkin_home_art()
		or _uses_siamese_home_art()
	)


func _get_idle_texture() -> Texture2D:
	if _uses_mochi_home_art():
		return MOCHI_HOME_TAIL_BLINK_FRAMES[0]
	if _uses_biscuit_home_art():
		return BISCUIT_IDLE_TEXTURE
	if _uses_luna_home_art():
		return LUNA_IDLE_TEXTURE
	if _uses_poppy_home_art():
		return POPPY_IDLE_TEXTURE
	if _uses_black_cat_home_art():
		return BLACK_CAT_IDLE_TEXTURE
	if _uses_maine_coon_home_art():
		return MAINE_COON_IDLE_TEXTURE
	if _uses_golden_munchkin_home_art():
		return GOLDEN_MUNCHKIN_IDLE_TEXTURE
	if _uses_siamese_home_art():
		return SIAMESE_IDLE_TEXTURE
	return PET_TEXTURE


func _process_home_idle(delta: float) -> void:
	if not home_idle_playing:
		home_idle_wait_remaining = maxf(0.0, home_idle_wait_remaining - delta)
		if home_idle_wait_remaining <= 0.0:
			home_idle_playing = true
			home_idle_frame = 0
			home_idle_frame_elapsed = 0.0
			_apply_current_texture()
		return
	home_idle_frame_elapsed += delta
	while home_idle_frame_elapsed >= float(MOCHI_HOME_IDLE_FRAME_DURATIONS[home_idle_frame]):
		home_idle_frame_elapsed -= float(MOCHI_HOME_IDLE_FRAME_DURATIONS[home_idle_frame])
		if home_idle_frame >= MOCHI_HOME_TAIL_BLINK_FRAMES.size() - 1:
			_stop_home_idle_animation()
			_schedule_next_home_idle()
			_apply_current_texture()
			return
		home_idle_frame += 1
		_apply_current_texture()


func _stop_home_idle_animation() -> void:
	home_idle_playing = false
	home_idle_frame = 0
	home_idle_frame_elapsed = 0.0


func _schedule_next_home_idle() -> void:
	home_idle_wait_remaining = randf_range(MOCHI_HOME_IDLE_MIN_WAIT, MOCHI_HOME_IDLE_MAX_WAIT)


func _process_interaction_animation(delta: float) -> void:
	interaction_frame_elapsed += delta
	var frame_duration := _get_interaction_frame_duration()
	while interaction_frame_elapsed >= frame_duration:
		interaction_frame_elapsed -= frame_duration
		if interaction_frame >= interaction_frames.size() - 1:
			interaction_animation_active = false
			interaction_frames = []
			interaction_frame_durations = []
			interaction_frame = 0
			interaction_frame_elapsed = 0.0
			if desktop_idle_enabled and mood == "idle":
				_schedule_next_desktop_idle()
			_update_visuals()
			return
		interaction_frame += 1
		frame_duration = _get_interaction_frame_duration()
	_apply_current_texture()


func _get_interaction_frame_duration() -> float:
	if interaction_frame < interaction_frame_durations.size():
		return interaction_frame_durations[interaction_frame]
	return 1.0 / DESKTOP_BELLY_FPS


func _get_move_frames() -> Array[Texture2D]:
	if _uses_mochi_home_art():
		return MOCHI_MOVE_LEFT_FRAMES if move_direction == "left" else MOCHI_MOVE_RIGHT_FRAMES
	if _uses_biscuit_home_art():
		return BISCUIT_MOVE_LEFT_FRAMES if move_direction == "left" else BISCUIT_MOVE_RIGHT_FRAMES
	if _uses_luna_home_art():
		return LUNA_MOVE_LEFT_FRAMES if move_direction == "left" else LUNA_MOVE_RIGHT_FRAMES
	if _uses_poppy_home_art():
		return POPPY_MOVE_LEFT_FRAMES if move_direction == "left" else POPPY_MOVE_RIGHT_FRAMES
	if _uses_black_cat_home_art():
		return BLACK_CAT_MOVE_LEFT_FRAMES if move_direction == "left" else BLACK_CAT_MOVE_RIGHT_FRAMES
	if _uses_maine_coon_home_art():
		return MAINE_COON_MOVE_LEFT_FRAMES if move_direction == "left" else MAINE_COON_MOVE_RIGHT_FRAMES
	if _uses_golden_munchkin_home_art():
		return GOLDEN_MUNCHKIN_MOVE_LEFT_FRAMES if move_direction == "left" else GOLDEN_MUNCHKIN_MOVE_RIGHT_FRAMES
	if _uses_siamese_home_art():
		return SIAMESE_MOVE_LEFT_FRAMES if move_direction == "left" else SIAMESE_MOVE_RIGHT_FRAMES
	return MOVE_LEFT_FRAMES if move_direction == "left" else MOVE_RIGHT_FRAMES


func _get_move_loop_start_frame() -> int:
	return 0 if _uses_custom_home_art() else MOVE_LOOP_START_FRAME


func set_desktop_idle_enabled(enabled: bool) -> void:
	if desktop_idle_enabled == enabled:
		return
	desktop_idle_enabled = enabled
	if enabled:
		_schedule_next_desktop_idle()
	else:
		_stop_desktop_idle_animation()
		desktop_idle_wait_remaining = 0.0
	_apply_current_texture()


func _process_desktop_idle(delta: float) -> void:
	if desktop_idle_animation == "":
		desktop_idle_wait_remaining = maxf(0.0, desktop_idle_wait_remaining - delta)
		if desktop_idle_wait_remaining <= 0.0:
			if _uses_golden_munchkin_home_art() or _uses_siamese_home_art():
				_schedule_next_desktop_idle()
				return
			_start_desktop_idle_animation(
				"mochi_tail_blink"
				if _uses_mochi_home_art()
				else "biscuit_butterfly" if _uses_biscuit_home_art()
				else "luna_stretch_yawn" if _uses_luna_home_art()
				else "poppy_face_rub" if _uses_poppy_home_art()
				else "black_cat_lick_paw" if _uses_black_cat_home_art()
				else "maine_coon_nuzzle" if _uses_maine_coon_home_art()
				else "wink" if randf() < 0.68
				else "belly"
			)
		return

	desktop_idle_frame_elapsed += delta
	var frame_duration := _get_desktop_idle_frame_duration()
	while desktop_idle_frame_elapsed >= frame_duration:
		desktop_idle_frame_elapsed -= frame_duration
		if desktop_idle_frame >= desktop_idle_frames.size() - 1:
			_stop_desktop_idle_animation()
			_schedule_next_desktop_idle()
			_apply_current_texture()
			return
		desktop_idle_frame += 1
		frame_duration = _get_desktop_idle_frame_duration()
	_apply_current_texture()


func _start_desktop_idle_animation(animation_name: String) -> void:
	desktop_idle_animation = animation_name
	if animation_name == "mochi_tail_blink":
		desktop_idle_frames = MOCHI_HOME_TAIL_BLINK_FRAMES
	elif animation_name == "biscuit_butterfly":
		desktop_idle_frames = BISCUIT_BUTTERFLY_FRAMES
	elif animation_name == "luna_stretch_yawn":
		desktop_idle_frames = LUNA_STRETCH_YAWN_FRAMES
	elif animation_name == "poppy_face_rub":
		desktop_idle_frames = POPPY_SLEEP_FACE_RUB_FRAMES
	elif animation_name == "black_cat_lick_paw":
		desktop_idle_frames = BLACK_CAT_LICK_PAW_FRAMES
	elif animation_name == "maine_coon_nuzzle":
		desktop_idle_frames = MAINE_COON_NUZZLE_FRAMES
	else:
		desktop_idle_frames = DESKTOP_WINK_FRAMES if animation_name == "wink" else DESKTOP_BELLY_FRAMES
	desktop_idle_frame = 0
	desktop_idle_frame_elapsed = 0.0
	_apply_current_texture()


func _get_desktop_idle_frame_duration() -> float:
	if desktop_idle_animation == "mochi_tail_blink":
		return float(MOCHI_HOME_IDLE_FRAME_DURATIONS[desktop_idle_frame])
	if desktop_idle_animation == "biscuit_butterfly":
		return float(BISCUIT_BUTTERFLY_FRAME_DURATIONS[desktop_idle_frame])
	if desktop_idle_animation == "luna_stretch_yawn":
		return float(LUNA_STRETCH_YAWN_FRAME_DURATIONS[desktop_idle_frame])
	if desktop_idle_animation == "poppy_face_rub":
		return float(POPPY_SLEEP_FACE_RUB_FRAME_DURATIONS[desktop_idle_frame])
	if desktop_idle_animation == "black_cat_lick_paw":
		return float(BLACK_CAT_LICK_PAW_FRAME_DURATIONS[desktop_idle_frame])
	if desktop_idle_animation == "maine_coon_nuzzle":
		return float(MAINE_COON_NUZZLE_FRAME_DURATIONS[desktop_idle_frame])
	var fps := DESKTOP_WINK_FPS if desktop_idle_animation == "wink" else DESKTOP_BELLY_FPS
	return 1.0 / fps


func _stop_desktop_idle_animation() -> void:
	desktop_idle_animation = ""
	desktop_idle_frames = []
	desktop_idle_frame = 0
	desktop_idle_frame_elapsed = 0.0


func _schedule_next_desktop_idle() -> void:
	desktop_idle_wait_remaining = randf_range(DESKTOP_IDLE_MIN_WAIT, DESKTOP_IDLE_MAX_WAIT)


func _update_sleep_bubble() -> void:
	if not is_instance_valid(sleep_bubble_sprite):
		return
	var sleeping_texture := (
		SIAMESE_SLEEP_TEXTURE
		if _uses_siamese_home_art()
		else GOLDEN_MUNCHKIN_SLEEP_TEXTURE if _uses_golden_munchkin_home_art()
		else MAINE_COON_SLEEP_TEXTURE if _uses_maine_coon_home_art()
		else BLACK_CAT_SLEEP_TEXTURE if _uses_black_cat_home_art()
		else LUNA_SLEEP_TEXTURE if _uses_luna_home_art()
		else POPPY_SLEEP_TEXTURE if _uses_poppy_home_art()
		else BISCUIT_SLEEP_TEXTURE if _uses_biscuit_home_art()
		else SLEEP_TEXTURE
	)
	var nose_position := (
		BISCUIT_SLEEP_BUBBLE_NOSE_POSITION
		if _uses_biscuit_home_art()
		else SLEEP_BUBBLE_NOSE_POSITION
	)
	sleep_bubble_sprite.position = (
		nose_position
		- sleeping_texture.get_size() * 0.5
		- SLEEP_BUBBLE_FRAME_ANCHOR
	)
	sleep_bubble_sprite.visible = (
		mood == "sleep"
		and sleep_bubble_active
		and not interaction_animation_active
		and not _uses_mochi_home_art()
		and not _uses_luna_home_art()
		and not _uses_poppy_home_art()
		and not _uses_black_cat_home_art()
		and not _uses_maine_coon_home_art()
		and not _uses_golden_munchkin_home_art()
		and not _uses_siamese_home_art()
	)
	sleep_bubble_sprite.texture = SLEEP_BUBBLE_FRAMES[sleep_bubble_frame]


func _process_sleep_bubble(delta: float) -> void:
	if not sleep_bubble_active:
		sleep_bubble_wait_remaining = maxf(0.0, sleep_bubble_wait_remaining - delta)
		if sleep_bubble_wait_remaining <= 0.0:
			sleep_bubble_active = true
			sleep_bubble_frame = 0
			sleep_bubble_frame_elapsed = 0.0
			_update_sleep_bubble()
		return

	sleep_bubble_frame_elapsed += delta
	var frame_duration := 1.0 / SLEEP_BUBBLE_FPS
	while sleep_bubble_frame_elapsed >= frame_duration:
		sleep_bubble_frame_elapsed -= frame_duration
		if sleep_bubble_frame >= SLEEP_BUBBLE_FRAMES.size() - 1:
			_schedule_next_sleep_bubble()
			return
		sleep_bubble_frame += 1
	_update_sleep_bubble()


func _schedule_next_sleep_bubble() -> void:
	sleep_bubble_active = false
	sleep_bubble_frame = 0
	sleep_bubble_frame_elapsed = 0.0
	sleep_bubble_wait_remaining = randf_range(SLEEP_BUBBLE_MIN_WAIT, SLEEP_BUBBLE_MAX_WAIT)
	_update_sleep_bubble()


func _schedule_next_sleep_effect() -> void:
	if _uses_golden_munchkin_home_art() or _uses_siamese_home_art():
		sleep_bubble_active = false
		sleep_bubble_wait_remaining = 0.0
		_stop_mochi_sleep_ear_twitch()
		_stop_luna_sleep_idle()
		_stop_poppy_sleep_face_rub()
		_stop_black_cat_fall_asleep()
		_stop_maine_coon_sleep_paw_lick()
		_stop_golden_munchkin_sleep_tail()
	elif _uses_maine_coon_home_art():
		sleep_bubble_active = false
		sleep_bubble_wait_remaining = 0.0
		_stop_mochi_sleep_ear_twitch()
		_stop_luna_sleep_idle()
		_stop_poppy_sleep_face_rub()
		_stop_black_cat_fall_asleep()
		_start_maine_coon_sleep_paw_lick()
	elif _uses_black_cat_home_art():
		sleep_bubble_active = false
		sleep_bubble_wait_remaining = 0.0
		_stop_mochi_sleep_ear_twitch()
		_stop_luna_sleep_idle()
		_stop_poppy_sleep_face_rub()
		_start_black_cat_fall_asleep()
	elif _uses_poppy_home_art():
		sleep_bubble_active = false
		sleep_bubble_wait_remaining = 0.0
		_stop_mochi_sleep_ear_twitch()
		_stop_luna_sleep_idle()
		_schedule_next_poppy_sleep_face_rub()
	elif _uses_luna_home_art():
		sleep_bubble_active = false
		sleep_bubble_wait_remaining = 0.0
		_stop_mochi_sleep_ear_twitch()
		_stop_poppy_sleep_face_rub()
		_schedule_next_luna_sleep_idle()
	elif _uses_mochi_home_art():
		sleep_bubble_active = false
		sleep_bubble_wait_remaining = 0.0
		_stop_luna_sleep_idle()
		_stop_poppy_sleep_face_rub()
		_schedule_next_mochi_sleep_ear_twitch()
	else:
		_stop_mochi_sleep_ear_twitch()
		_stop_luna_sleep_idle()
		_stop_poppy_sleep_face_rub()
		_stop_black_cat_fall_asleep()
		_stop_maine_coon_sleep_paw_lick()
		_stop_golden_munchkin_sleep_tail()
		_schedule_next_sleep_bubble()


func _process_mochi_sleep_ear_twitch(delta: float) -> void:
	if not mochi_sleep_ear_twitch_playing:
		mochi_sleep_ear_twitch_wait_remaining = maxf(
			0.0,
			mochi_sleep_ear_twitch_wait_remaining - delta
		)
		if mochi_sleep_ear_twitch_wait_remaining <= 0.0:
			mochi_sleep_ear_twitch_playing = true
			mochi_sleep_ear_twitch_frame = 0
			mochi_sleep_ear_twitch_frame_elapsed = 0.0
			_apply_current_texture()
		return
	mochi_sleep_ear_twitch_frame_elapsed += delta
	var frame_duration := float(
		MOCHI_SLEEP_EAR_TWITCH_FRAME_DURATIONS[mochi_sleep_ear_twitch_frame]
	)
	while mochi_sleep_ear_twitch_frame_elapsed >= frame_duration:
		mochi_sleep_ear_twitch_frame_elapsed -= frame_duration
		if mochi_sleep_ear_twitch_frame >= MOCHI_SLEEP_EAR_TWITCH_FRAMES.size() - 1:
			_schedule_next_mochi_sleep_ear_twitch()
			_apply_current_texture()
			return
		mochi_sleep_ear_twitch_frame += 1
		frame_duration = float(
			MOCHI_SLEEP_EAR_TWITCH_FRAME_DURATIONS[mochi_sleep_ear_twitch_frame]
		)
	_apply_current_texture()


func _schedule_next_mochi_sleep_ear_twitch() -> void:
	mochi_sleep_ear_twitch_playing = false
	mochi_sleep_ear_twitch_frame = 0
	mochi_sleep_ear_twitch_frame_elapsed = 0.0
	mochi_sleep_ear_twitch_wait_remaining = randf_range(
		MOCHI_SLEEP_EAR_TWITCH_MIN_WAIT,
		MOCHI_SLEEP_EAR_TWITCH_MAX_WAIT
	)


func _stop_mochi_sleep_ear_twitch() -> void:
	mochi_sleep_ear_twitch_playing = false
	mochi_sleep_ear_twitch_frame = 0
	mochi_sleep_ear_twitch_frame_elapsed = 0.0
	mochi_sleep_ear_twitch_wait_remaining = 0.0


func _process_luna_sleep_idle(delta: float) -> void:
	if not luna_sleep_idle_playing:
		luna_sleep_idle_wait_remaining = maxf(
			0.0,
			luna_sleep_idle_wait_remaining - delta
		)
		if luna_sleep_idle_wait_remaining <= 0.0:
			luna_sleep_idle_playing = true
			luna_sleep_idle_frame = 0
			luna_sleep_idle_frame_elapsed = 0.0
			_apply_current_texture()
		return
	luna_sleep_idle_frame_elapsed += delta
	var frame_duration := float(
		LUNA_SLEEP_IDLE_FRAME_DURATIONS[luna_sleep_idle_frame]
	)
	while luna_sleep_idle_frame_elapsed >= frame_duration:
		luna_sleep_idle_frame_elapsed -= frame_duration
		if luna_sleep_idle_frame >= LUNA_SLEEP_IDLE_FRAMES.size() - 1:
			_schedule_next_luna_sleep_idle()
			_apply_current_texture()
			return
		luna_sleep_idle_frame += 1
		frame_duration = float(
			LUNA_SLEEP_IDLE_FRAME_DURATIONS[luna_sleep_idle_frame]
		)
	_apply_current_texture()


func _schedule_next_luna_sleep_idle() -> void:
	luna_sleep_idle_playing = false
	luna_sleep_idle_frame = 0
	luna_sleep_idle_frame_elapsed = 0.0
	luna_sleep_idle_wait_remaining = randf_range(
		LUNA_SLEEP_IDLE_MIN_WAIT,
		LUNA_SLEEP_IDLE_MAX_WAIT
	)


func _stop_luna_sleep_idle() -> void:
	luna_sleep_idle_playing = false
	luna_sleep_idle_frame = 0
	luna_sleep_idle_frame_elapsed = 0.0
	luna_sleep_idle_wait_remaining = 0.0


func _process_poppy_sleep_face_rub(delta: float) -> void:
	if not poppy_sleep_face_rub_playing:
		poppy_sleep_face_rub_wait_remaining = maxf(0.0, poppy_sleep_face_rub_wait_remaining - delta)
		if poppy_sleep_face_rub_wait_remaining <= 0.0:
			poppy_sleep_face_rub_playing = true
			poppy_sleep_face_rub_frame = 0
			poppy_sleep_face_rub_frame_elapsed = 0.0
			_apply_current_texture()
		return
	poppy_sleep_face_rub_frame_elapsed += delta
	var frame_duration := float(POPPY_SLEEP_FACE_RUB_FRAME_DURATIONS[poppy_sleep_face_rub_frame])
	while poppy_sleep_face_rub_frame_elapsed >= frame_duration:
		poppy_sleep_face_rub_frame_elapsed -= frame_duration
		if poppy_sleep_face_rub_frame >= POPPY_SLEEP_FACE_RUB_FRAMES.size() - 1:
			_schedule_next_poppy_sleep_face_rub()
			_apply_current_texture()
			return
		poppy_sleep_face_rub_frame += 1
		frame_duration = float(POPPY_SLEEP_FACE_RUB_FRAME_DURATIONS[poppy_sleep_face_rub_frame])
	_apply_current_texture()


func _schedule_next_poppy_sleep_face_rub() -> void:
	poppy_sleep_face_rub_playing = false
	poppy_sleep_face_rub_frame = 0
	poppy_sleep_face_rub_frame_elapsed = 0.0
	poppy_sleep_face_rub_wait_remaining = randf_range(
		POPPY_SLEEP_FACE_RUB_MIN_WAIT,
		POPPY_SLEEP_FACE_RUB_MAX_WAIT
	)


func _stop_poppy_sleep_face_rub() -> void:
	poppy_sleep_face_rub_playing = false
	poppy_sleep_face_rub_frame = 0
	poppy_sleep_face_rub_frame_elapsed = 0.0
	poppy_sleep_face_rub_wait_remaining = 0.0


func _start_black_cat_fall_asleep() -> void:
	black_cat_fall_asleep_playing = true
	black_cat_fall_asleep_frame = 0
	black_cat_fall_asleep_frame_elapsed = 0.0
	_apply_current_texture()


func _process_black_cat_fall_asleep(delta: float) -> void:
	if not black_cat_fall_asleep_playing:
		return
	black_cat_fall_asleep_frame_elapsed += delta
	var frame_duration := float(
		BLACK_CAT_FALL_ASLEEP_FRAME_DURATIONS[black_cat_fall_asleep_frame]
	)
	while black_cat_fall_asleep_frame_elapsed >= frame_duration:
		black_cat_fall_asleep_frame_elapsed -= frame_duration
		if black_cat_fall_asleep_frame >= BLACK_CAT_FALL_ASLEEP_FRAMES.size() - 1:
			black_cat_fall_asleep_playing = false
			black_cat_fall_asleep_frame = BLACK_CAT_FALL_ASLEEP_FRAMES.size() - 1
			black_cat_fall_asleep_frame_elapsed = 0.0
			_apply_current_texture()
			return
		black_cat_fall_asleep_frame += 1
		frame_duration = float(
			BLACK_CAT_FALL_ASLEEP_FRAME_DURATIONS[black_cat_fall_asleep_frame]
		)
	_apply_current_texture()


func _stop_black_cat_fall_asleep() -> void:
	black_cat_fall_asleep_playing = false
	black_cat_fall_asleep_frame = 0
	black_cat_fall_asleep_frame_elapsed = 0.0


func _start_maine_coon_sleep_paw_lick() -> void:
	maine_coon_sleep_paw_lick_playing = true
	maine_coon_sleep_paw_lick_frame = 0
	maine_coon_sleep_paw_lick_frame_elapsed = 0.0
	_apply_current_texture()


func _process_maine_coon_sleep_paw_lick(delta: float) -> void:
	if not maine_coon_sleep_paw_lick_playing:
		return
	maine_coon_sleep_paw_lick_frame_elapsed += delta
	var frame_duration := float(
		MAINE_COON_SLEEP_PAW_LICK_FRAME_DURATIONS[maine_coon_sleep_paw_lick_frame]
	)
	while maine_coon_sleep_paw_lick_frame_elapsed >= frame_duration:
		maine_coon_sleep_paw_lick_frame_elapsed -= frame_duration
		if maine_coon_sleep_paw_lick_frame >= MAINE_COON_SLEEP_PAW_LICK_FRAMES.size() - 1:
			maine_coon_sleep_paw_lick_playing = false
			maine_coon_sleep_paw_lick_frame = MAINE_COON_SLEEP_PAW_LICK_FRAMES.size() - 1
			maine_coon_sleep_paw_lick_frame_elapsed = 0.0
			_apply_current_texture()
			return
		maine_coon_sleep_paw_lick_frame += 1
		frame_duration = float(
			MAINE_COON_SLEEP_PAW_LICK_FRAME_DURATIONS[maine_coon_sleep_paw_lick_frame]
		)
	_apply_current_texture()


func _stop_maine_coon_sleep_paw_lick() -> void:
	maine_coon_sleep_paw_lick_playing = false
	maine_coon_sleep_paw_lick_frame = 0
	maine_coon_sleep_paw_lick_frame_elapsed = 0.0


func _start_golden_munchkin_sleep_tail() -> void:
	golden_munchkin_sleep_tail_playing = true
	golden_munchkin_sleep_tail_frame = 0
	golden_munchkin_sleep_tail_frame_elapsed = 0.0
	_apply_current_texture()


func _process_golden_munchkin_sleep_tail(delta: float) -> void:
	if not golden_munchkin_sleep_tail_playing:
		_start_golden_munchkin_sleep_tail()
		return
	golden_munchkin_sleep_tail_frame_elapsed += delta
	var frame_duration := float(
		GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAME_DURATIONS[golden_munchkin_sleep_tail_frame]
	)
	while golden_munchkin_sleep_tail_frame_elapsed >= frame_duration:
		golden_munchkin_sleep_tail_frame_elapsed -= frame_duration
		golden_munchkin_sleep_tail_frame = (
			golden_munchkin_sleep_tail_frame + 1
		) % GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAMES.size()
		frame_duration = float(
			GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAME_DURATIONS[golden_munchkin_sleep_tail_frame]
		)
	_apply_current_texture()


func _stop_golden_munchkin_sleep_tail() -> void:
	golden_munchkin_sleep_tail_playing = false
	golden_munchkin_sleep_tail_frame = 0
	golden_munchkin_sleep_tail_frame_elapsed = 0.0


func _update_layout() -> void:
	if not is_instance_valid(cat_sprite):
		return
	var safe_size := Vector2(maxf(size.x, 1.0), maxf(size.y, 1.0))
	var texture_size := cat_sprite.texture.get_size()
	# Luna's stretch sheet uses a wider fixed canvas than her seated sprite. Base
	# its display scale on the seated canvas so double-clicking does not make her
	# shrink at Home and then pop back to full size when the animation finishes.
	var layout_texture_size := (
		LUNA_IDLE_TEXTURE.get_size()
		if cat_sprite.texture in LUNA_STRETCH_YAWN_FRAMES
		else POPPY_IDLE_TEXTURE.get_size()
		if cat_sprite.texture in POPPY_SLEEP_FACE_RUB_FRAMES or cat_sprite.texture in POPPY_TEASER_PLAY_FRAMES
		else BLACK_CAT_IDLE_TEXTURE.get_size()
		if cat_sprite.texture in BLACK_CAT_LICK_PAW_FRAMES
		else MAINE_COON_IDLE_TEXTURE.get_size()
		if cat_sprite.texture in MAINE_COON_NUZZLE_FRAMES
		else GOLDEN_MUNCHKIN_IDLE_TEXTURE.get_size()
		if cat_sprite.texture in GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES
		else GOLDEN_MUNCHKIN_SLEEP_TEXTURE.get_size()
		if cat_sprite.texture in GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAMES
		else SIAMESE_IDLE_TEXTURE.get_size()
		if cat_sprite.texture in SIAMESE_TREAT_FRAMES
		else texture_size
	)
	var scale_multiplier := 0.82
	if cat_sprite.texture == PET_TEXTURE or cat_sprite.texture in SHY_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in MOCHI_HOME_TAIL_BLINK_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture == BISCUIT_IDLE_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == LUNA_IDLE_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == POPPY_IDLE_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == BLACK_CAT_IDLE_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == MAINE_COON_IDLE_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == GOLDEN_MUNCHKIN_IDLE_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == SIAMESE_IDLE_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == MOCHI_SLEEP_TEXTURE or cat_sprite.texture in MOCHI_SLEEP_EAR_TWITCH_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture == BISCUIT_SLEEP_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == LUNA_SLEEP_TEXTURE or cat_sprite.texture in LUNA_SLEEP_IDLE_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture == POPPY_SLEEP_TEXTURE:
		scale_multiplier = 0.95
	elif cat_sprite.texture == BLACK_CAT_SLEEP_TEXTURE or cat_sprite.texture in BLACK_CAT_FALL_ASLEEP_FRAMES:
		# The authored lying pose fills much more of its wide canvas than the seated
		# pose. Reduce the complete sleep sequence by twenty percent so every frame
		# keeps one consistent, appropriately smaller visual size.
		scale_multiplier = BLACK_CAT_SLEEP_SCALE_MULTIPLIER
	elif cat_sprite.texture == MAINE_COON_SLEEP_TEXTURE or cat_sprite.texture in MAINE_COON_SLEEP_PAW_LICK_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture == GOLDEN_MUNCHKIN_SLEEP_TEXTURE or cat_sprite.texture in GOLDEN_MUNCHKIN_SLEEP_TAIL_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture == SIAMESE_SLEEP_TEXTURE:
		scale_multiplier = 0.95
	elif (
		cat_sprite.texture in MOVE_LEFT_FRAMES
		or cat_sprite.texture in MOVE_RIGHT_FRAMES
		or cat_sprite.texture in MOCHI_MOVE_LEFT_FRAMES
		or cat_sprite.texture in MOCHI_MOVE_RIGHT_FRAMES
		or cat_sprite.texture in BISCUIT_MOVE_LEFT_FRAMES
		or cat_sprite.texture in BISCUIT_MOVE_RIGHT_FRAMES
		or cat_sprite.texture in LUNA_MOVE_LEFT_FRAMES
		or cat_sprite.texture in LUNA_MOVE_RIGHT_FRAMES
		or cat_sprite.texture in POPPY_MOVE_LEFT_FRAMES
		or cat_sprite.texture in POPPY_MOVE_RIGHT_FRAMES
		or cat_sprite.texture in BLACK_CAT_MOVE_LEFT_FRAMES
		or cat_sprite.texture in BLACK_CAT_MOVE_RIGHT_FRAMES
		or cat_sprite.texture in MAINE_COON_MOVE_LEFT_FRAMES
		or cat_sprite.texture in MAINE_COON_MOVE_RIGHT_FRAMES
		or cat_sprite.texture in GOLDEN_MUNCHKIN_MOVE_LEFT_FRAMES
		or cat_sprite.texture in GOLDEN_MUNCHKIN_MOVE_RIGHT_FRAMES
		or cat_sprite.texture in SIAMESE_MOVE_LEFT_FRAMES
		or cat_sprite.texture in SIAMESE_MOVE_RIGHT_FRAMES
	):
		scale_multiplier = MOVEMENT_SCALE_MULTIPLIER
	elif cat_sprite.texture in MOCHI_LICK_PAW_FRAMES:
		# The repaired sequence shares Mochi's seated canvas and silhouette height.
		# Keep its scale identical so double-clicking cannot shrink/sink the cat.
		scale_multiplier = 0.95
	elif cat_sprite.texture in BISCUIT_BUTTERFLY_FRAMES:
		# Biscuit's interaction begins from the same side-sitting pose as her
		# default sprite, so keep both at one visual scale to prevent a size pop.
		scale_multiplier = 0.95
	elif cat_sprite.texture in LUNA_STRETCH_YAWN_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in POPPY_SLEEP_FACE_RUB_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in POPPY_TEASER_PLAY_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in BLACK_CAT_LICK_PAW_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in MAINE_COON_NUZZLE_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in SIAMESE_TREAT_FRAMES:
		scale_multiplier = 0.95
	elif cat_sprite.texture in DESKTOP_WINK_FRAMES or cat_sprite.texture in DESKTOP_BELLY_FRAMES:
		scale_multiplier = 0.87
	var scale_value := minf(
		safe_size.x / layout_texture_size.x,
		safe_size.y / layout_texture_size.y
	) * scale_multiplier
	# These animations share fixed authored canvases. Anchor every frame from its
	# first frame so moving tails or wider poses never recenter the cat's body.
	var visual_bounds := (
		LUNA_MOVE_LAYOUT_BOUNDS
		if cat_sprite.texture in LUNA_MOVE_LEFT_FRAMES or cat_sprite.texture in LUNA_MOVE_RIGHT_FRAMES
		else BLACK_CAT_MOVE_LAYOUT_BOUNDS
		if cat_sprite.texture in BLACK_CAT_MOVE_LEFT_FRAMES or cat_sprite.texture in BLACK_CAT_MOVE_RIGHT_FRAMES
		else _get_texture_visual_bounds(LUNA_SLEEP_TEXTURE)
		if cat_sprite.texture in LUNA_SLEEP_IDLE_FRAMES
		else _get_texture_visual_bounds(MOCHI_LICK_PAW_FRAMES[0])
		if cat_sprite.texture in MOCHI_LICK_PAW_FRAMES
		else _get_texture_visual_bounds(POPPY_TEASER_PLAY_FRAMES[0])
		if cat_sprite.texture in POPPY_TEASER_PLAY_FRAMES
		else _get_texture_visual_bounds(MAINE_COON_NUZZLE_FRAMES[0])
		if cat_sprite.texture in MAINE_COON_NUZZLE_FRAMES
		else _get_texture_visual_bounds(GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES[0])
		if cat_sprite.texture in GOLDEN_MUNCHKIN_FAILED_ROLL_FRAMES
		else _get_texture_visual_bounds(SIAMESE_TREAT_FRAMES[-1])
		if cat_sprite.texture in SIAMESE_TREAT_FRAMES
		else _get_texture_visual_bounds(cat_sprite.texture)
	)
	var texture_center := texture_size * 0.5
	var visual_center_x := visual_bounds.position.x + visual_bounds.size.x * 0.5
	var visual_bottom := visual_bounds.position.y + visual_bounds.size.y
	cat_sprite.scale = Vector2.ONE * scale_value
	cat_sprite.position = Vector2(
		safe_size.x * 0.5 - (visual_center_x - texture_center.x) * scale_value,
		safe_size.y * SHADOW_CENTER_Y_RATIO - (visual_bottom - texture_center.y) * scale_value
	)
	# Translation only: preserve Biscuit's original frames, coat and scale.
	# Leave idle, walking, and the automatic butterfly animation unchanged.
	if interaction_animation_active and cat_sprite.texture in BISCUIT_BUTTERFLY_FRAMES:
		cat_sprite.position += BISCUIT_DOUBLE_CLICK_OFFSET
	var badge_width := minf(184.0, safe_size.x * 0.90)
	mood_badge.position = Vector2(safe_size.x * 0.5 - badge_width * 0.5, 4.0)
	mood_badge.size = Vector2(badge_width, 40.0)


func _get_texture_visual_bounds(texture: Texture2D) -> Rect2:
	var cache_key := texture.resource_path
	if texture_visual_bounds_cache.has(cache_key):
		return texture_visual_bounds_cache[cache_key]
	var image := texture.get_image()
	var used_rect := image.get_used_rect()
	var bounds := Rect2(used_rect)
	if bounds.size == Vector2.ZERO:
		bounds = Rect2(Vector2.ZERO, texture.get_size())
	texture_visual_bounds_cache[cache_key] = bounds
	return bounds


func _draw() -> void:
	if not _should_draw_ground_shadow():
		return
	var shadow_center := Vector2(size.x * 0.5, size.y * SHADOW_CENTER_Y_RATIO)
	var shadow_radius := Vector2(size.x * 0.28, maxf(8.0, size.y * 0.035))
	var points := PackedVector2Array()
	for index in range(36):
		var angle := TAU * float(index) / 36.0
		points.append(shadow_center + Vector2(cos(angle) * shadow_radius.x, sin(angle) * shadow_radius.y))
	draw_colored_polygon(points, Color(0.20, 0.12, 0.16, 0.16))


func _should_draw_ground_shadow() -> bool:
	return not _uses_maine_coon_home_art() and not _uses_golden_munchkin_home_art()
