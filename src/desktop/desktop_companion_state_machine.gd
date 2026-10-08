class_name DesktopCompanionStateMachine
extends RefCounted

## Pure desktop-pet behavior model.
##
## This class has no Node, Window, DisplayServer, or texture dependency. The
## controller translates input into transitions and renders the resulting
## position/rest state through DesktopWindowHost and PetAvatar.

enum MotionState {
	DOCKED,
	AWAY_IDLE,
	DRAGGING_FREE,
	DRAGGING_FOLLOW,
	FOLLOW_REACTION,
	FOLLOWING,
	FOLLOW_SETTLED,
	RETURNING
}

enum RestState {
	AWAKE,
	SLEEPING
}

const STATION_WAKE_SECONDS := 30.0
const PET_RETURN_SECONDS := 15.0
const PET_FOLLOW_RUN_SPEED := 150.0
const PET_FOLLOW_REACTION_MIN := 0.3
const PET_FOLLOW_REACTION_MAX := 0.6
const PET_FOLLOW_ARRIVAL_DISTANCE := 60.0
const PET_FOLLOW_RESUME_DISTANCE := 100.0

var motion_state := MotionState.DOCKED
var rest_state := RestState.AWAKE
var seconds_outside_station := 0.0
var seconds_since_pet_drag := 0.0
var follow_last_pointer := Vector2.ZERO
var follow_target := Vector2.ZERO
var follow_reaction_remaining := 0.0
var follow_has_target := false

var _follow_state_before_drag := MotionState.FOLLOW_SETTLED


func reset() -> void:
	motion_state = MotionState.DOCKED
	rest_state = RestState.AWAKE
	seconds_outside_station = 0.0
	seconds_since_pet_drag = 0.0
	follow_last_pointer = Vector2.ZERO
	follow_target = Vector2.ZERO
	follow_reaction_remaining = 0.0
	follow_has_target = false
	_follow_state_before_drag = MotionState.FOLLOW_SETTLED


func is_follow_mode() -> bool:
	return motion_state in [
		MotionState.DRAGGING_FOLLOW,
		MotionState.FOLLOW_REACTION,
		MotionState.FOLLOWING,
		MotionState.FOLLOW_SETTLED
	]


func is_follow_chasing() -> bool:
	return motion_state in [MotionState.FOLLOW_REACTION, MotionState.FOLLOWING]


func is_dragging() -> bool:
	return motion_state in [MotionState.DRAGGING_FREE, MotionState.DRAGGING_FOLLOW]


func is_docked() -> bool:
	return motion_state == MotionState.DOCKED


func is_returning() -> bool:
	return motion_state == MotionState.RETURNING


func motion_state_name() -> String:
	return MotionState.keys()[motion_state]


func rest_state_name() -> String:
	return RestState.keys()[rest_state]


func begin_drag() -> void:
	if is_follow_mode():
		_follow_state_before_drag = motion_state
		motion_state = MotionState.DRAGGING_FOLLOW
	else:
		motion_state = MotionState.DRAGGING_FREE
	seconds_since_pet_drag = 0.0
	rest_state = RestState.AWAKE


func end_drag() -> void:
	if motion_state == MotionState.DRAGGING_FOLLOW:
		motion_state = _follow_state_before_drag
	elif motion_state == MotionState.DRAGGING_FREE:
		motion_state = MotionState.AWAY_IDLE
	seconds_since_pet_drag = 0.0


func enable_follow(pet_position: Vector2, screen_scale: float) -> void:
	seconds_since_pet_drag = 0.0
	rest_state = RestState.AWAKE
	follow_reaction_remaining = 0.0
	follow_has_target = true
	if (
		follow_target.distance_to(pet_position)
		> PET_FOLLOW_RESUME_DISTANCE * screen_scale
	):
		_start_follow_reaction()
	else:
		motion_state = MotionState.FOLLOW_SETTLED


func disable_follow(pet_is_at_station: bool) -> void:
	follow_reaction_remaining = 0.0
	follow_has_target = false
	motion_state = (
		MotionState.DOCKED if pet_is_at_station else MotionState.RETURNING
	)
	rest_state = RestState.AWAKE
	seconds_since_pet_drag = 0.0


func update_follow_target(target: Vector2, pointer_position: Vector2) -> void:
	follow_last_pointer = pointer_position
	follow_target = target
	follow_has_target = true


func update_follow_position(
	pet_position: Vector2,
	delta: float,
	screen_scale: float
) -> Vector2:
	if not is_follow_mode() or is_dragging():
		return pet_position
	var displacement := follow_target - pet_position
	var arrival_distance := PET_FOLLOW_ARRIVAL_DISTANCE * screen_scale
	var resume_distance := PET_FOLLOW_RESUME_DISTANCE * screen_scale
	if displacement.length() <= arrival_distance:
		_settle_follow()
		return pet_position
	if motion_state == MotionState.FOLLOW_SETTLED:
		if displacement.length() <= resume_distance:
			return pet_position
		_start_follow_reaction()
	var movement_delta := maxf(0.0, delta)
	if motion_state == MotionState.FOLLOW_REACTION:
		var reaction_delta := minf(movement_delta, follow_reaction_remaining)
		follow_reaction_remaining -= reaction_delta
		movement_delta -= reaction_delta
		if follow_reaction_remaining <= 0.0:
			follow_reaction_remaining = 0.0
			motion_state = MotionState.FOLLOWING
	if movement_delta <= 0.0:
		return pet_position
	var follow_distance := minf(
		PET_FOLLOW_RUN_SPEED * screen_scale * movement_delta,
		displacement.length() - arrival_distance
	)
	var next_position := pet_position.move_toward(follow_target, follow_distance)
	motion_state = MotionState.FOLLOWING
	if next_position.distance_to(follow_target) <= arrival_distance + 0.001:
		_settle_follow()
	return next_position


func advance_away_timer(delta: float) -> void:
	if motion_state != MotionState.AWAY_IDLE:
		return
	seconds_since_pet_drag += maxf(0.0, delta)
	if seconds_since_pet_drag >= PET_RETURN_SECONDS:
		motion_state = MotionState.RETURNING


func update_return_position(
	pet_position: Vector2,
	station_target: Vector2,
	delta: float,
	screen_scale: float
) -> Vector2:
	if motion_state != MotionState.RETURNING:
		return pet_position
	rest_state = RestState.AWAKE
	seconds_outside_station = 0.0
	var return_distance := (
		PET_FOLLOW_RUN_SPEED * screen_scale * maxf(0.0, delta)
	)
	var next_position := pet_position.move_toward(station_target, return_distance)
	if next_position == station_target:
		arrive_at_station()
	return next_position


func arrive_at_station() -> void:
	motion_state = MotionState.DOCKED
	rest_state = RestState.AWAKE
	seconds_since_pet_drag = 0.0
	seconds_outside_station = 0.0


func update_rest(
	delta: float,
	reset_timer: bool,
	pointer_on_pet: bool
) -> void:
	if reset_timer:
		seconds_outside_station = 0.0
	else:
		seconds_outside_station += maxf(0.0, delta)
	if pointer_on_pet:
		rest_state = RestState.AWAKE
	elif seconds_outside_station >= STATION_WAKE_SECONDS and not is_dragging():
		rest_state = RestState.SLEEPING


func force_docked(value: bool) -> void:
	if value:
		motion_state = MotionState.DOCKED
	elif motion_state == MotionState.DOCKED:
		motion_state = MotionState.AWAY_IDLE


func force_returning(value: bool) -> void:
	if value:
		motion_state = MotionState.RETURNING
	elif motion_state == MotionState.RETURNING:
		motion_state = MotionState.AWAY_IDLE


func force_dragging(value: bool) -> void:
	if value and not is_dragging():
		begin_drag()
	elif not value and is_dragging():
		end_drag()


func force_follow_chasing(value: bool) -> void:
	if not is_follow_mode():
		return
	if value:
		motion_state = MotionState.FOLLOWING
	else:
		_settle_follow()


func _start_follow_reaction() -> void:
	motion_state = MotionState.FOLLOW_REACTION
	follow_reaction_remaining = randf_range(
		PET_FOLLOW_REACTION_MIN,
		PET_FOLLOW_REACTION_MAX
	)


func _settle_follow() -> void:
	motion_state = MotionState.FOLLOW_SETTLED
	follow_reaction_remaining = 0.0
