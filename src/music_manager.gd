extends Node

const HOME_TRACK_KEY := &"home"
const FISHING_TRACK_KEY := &"fishing"
const AQUARIUM_TRACK_KEY := &"aquarium"
const SHOP_TRACK_KEY := &"shop"
const HOME_TARGET_VOLUME_DB := -12.0
const FISHING_TARGET_VOLUME_DB := -12.0
const AQUARIUM_TARGET_VOLUME_DB := -12.0
const SHOP_TARGET_VOLUME_DB := -12.0
const HOME_FADE_IN_SECONDS := 1.5
const FISHING_FADE_IN_SECONDS := 1.0
const AQUARIUM_FADE_IN_SECONDS := 2.0
const AQUARIUM_FADE_OUT_SECONDS := 1.5
const SHOP_FADE_IN_SECONDS := 1.5
const HOME_FADE_OUT_SECONDS := 0.8
const SILENT_VOLUME_DB := -60.0

@export var home_music_source: AudioStreamWAV
@export var fishing_music_source: AudioStreamWAV
@export var aquarium_music_source: AudioStreamWAV
@export var shop_music_source: AudioStreamWAV
@onready var music_player: AudioStreamPlayer = $MusicPlayer

var current_track_key := &""
var fade_tween: Tween
var home_music: AudioStreamWAV
var fishing_music: AudioStreamWAV
var aquarium_music: AudioStreamWAV
var shop_music: AudioStreamWAV


func _ready() -> void:
	home_music = _prepare_loop(home_music_source, "HOME")
	fishing_music = _prepare_loop(fishing_music_source, "Fishing")
	aquarium_music = _prepare_loop(aquarium_music_source, "Aquarium")
	shop_music = _prepare_loop(shop_music_source, "Shop")
	music_player.stream = home_music


func play_home_music() -> void:
	_play_music(
		HOME_TRACK_KEY,
		home_music,
		HOME_TARGET_VOLUME_DB,
		HOME_FADE_IN_SECONDS
	)


func play_fishing_music() -> void:
	_play_music(
		FISHING_TRACK_KEY,
		fishing_music,
		FISHING_TARGET_VOLUME_DB,
		FISHING_FADE_IN_SECONDS
	)


func play_aquarium_music() -> void:
	_play_music(
		AQUARIUM_TRACK_KEY,
		aquarium_music,
		AQUARIUM_TARGET_VOLUME_DB,
		AQUARIUM_FADE_IN_SECONDS
	)


func stop_aquarium_music() -> void:
	stop_music(AQUARIUM_FADE_OUT_SECONDS)


func play_shop_music() -> void:
	_play_music(
		SHOP_TRACK_KEY,
		shop_music,
		SHOP_TARGET_VOLUME_DB,
		SHOP_FADE_IN_SECONDS
	)


func stop_music(fade_seconds := HOME_FADE_OUT_SECONDS) -> void:
	current_track_key = &""
	_cancel_fade()
	if not music_player.playing:
		music_player.volume_db = SILENT_VOLUME_DB
		return
	if fade_seconds <= 0.0:
		_finish_stop()
		return
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(music_player, "volume_db", SILENT_VOLUME_DB, fade_seconds)
	fade_tween.tween_callback(_finish_stop)


func is_home_music_active() -> bool:
	return current_track_key == HOME_TRACK_KEY and music_player.playing


func is_fishing_music_active() -> bool:
	return current_track_key == FISHING_TRACK_KEY and music_player.playing


func is_aquarium_music_active() -> bool:
	return current_track_key == AQUARIUM_TRACK_KEY and music_player.playing


func is_shop_music_active() -> bool:
	return current_track_key == SHOP_TRACK_KEY and music_player.playing


func _play_music(
	track_key: StringName,
	track: AudioStreamWAV,
	target_volume_db: float,
	fade_in_seconds: float
) -> void:
	if track == null:
		return
	_cancel_fade()
	current_track_key = track_key
	if music_player.stream != track:
		music_player.stop()
		music_player.stream = track
		music_player.volume_db = SILENT_VOLUME_DB
	if not music_player.playing:
		music_player.volume_db = SILENT_VOLUME_DB
		music_player.play()
	_fade_player_to(target_volume_db, fade_in_seconds)


func _prepare_loop(source: AudioStreamWAV, track_label: String) -> AudioStreamWAV:
	if source == null:
		push_error("%s music must import as AudioStreamWAV" % track_label)
		return null
	var loop_stream := source.duplicate(true) as AudioStreamWAV
	loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop_stream.loop_begin = 0
	loop_stream.loop_end = roundi(loop_stream.get_length() * loop_stream.mix_rate)
	return loop_stream


func _fade_player_to(target_volume_db: float, duration: float) -> void:
	if duration <= 0.0:
		music_player.volume_db = target_volume_db
		return
	fade_tween = create_tween()
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(music_player, "volume_db", target_volume_db, duration)


func _cancel_fade() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = null


func _finish_stop() -> void:
	if current_track_key != &"":
		return
	music_player.stop()
	music_player.volume_db = SILENT_VOLUME_DB
	fade_tween = null
