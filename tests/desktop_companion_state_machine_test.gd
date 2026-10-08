extends SceneTree

const StateMachineScript = preload(
	"res://src/desktop/desktop_companion_state_machine.gd"
)

var failures: Array[String] = []


func _initialize() -> void:
	_run()


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures.append(message)
	push_error(message)


func _run() -> void:
	_test_return_lifecycle()
	_test_follow_hysteresis_and_reaction()
	_test_drag_resume_policy()
	_test_rest_state()
	if failures.is_empty():
		print("DESKTOP STATE MACHINE TEST PASS: explicit motion transitions, follow hysteresis, drag resume, return timing, and rest state")
		quit(0)
	else:
		print("DESKTOP STATE MACHINE TEST FAIL: %d failure(s)" % failures.size())
		quit(1)


func _test_return_lifecycle() -> void:
	var machine := StateMachineScript.new()
	_check(machine.motion_state == machine.MotionState.DOCKED, "Reset state should be DOCKED")
	machine.force_docked(false)
	_check(machine.motion_state == machine.MotionState.AWAY_IDLE, "Leaving the Station should enter AWAY_IDLE")
	machine.advance_away_timer(machine.PET_RETURN_SECONDS - 0.1)
	_check(machine.motion_state == machine.MotionState.AWAY_IDLE, "The pet must wait the full return timeout")
	machine.advance_away_timer(0.2)
	_check(machine.motion_state == machine.MotionState.RETURNING, "The return timeout should enter RETURNING")
	var start := Vector2(1000.0, 0.0)
	var target := Vector2.ZERO
	var next := machine.update_return_position(start, target, 0.1, 1.0)
	_check(is_equal_approx(next.distance_to(start), 15.0), "Return movement should use the fixed 150 px/s speed")
	next = machine.update_return_position(next, target, 10.0, 1.0)
	_check(next == target and machine.motion_state == machine.MotionState.DOCKED, "Reaching the target should atomically enter DOCKED")


func _test_follow_hysteresis_and_reaction() -> void:
	var machine := StateMachineScript.new()
	var pet_position := Vector2.ZERO
	machine.update_follow_target(Vector2(500.0, 0.0), Vector2(500.0, 0.0))
	machine.enable_follow(pet_position, 1.0)
	_check(machine.motion_state == machine.MotionState.FOLLOW_REACTION, "A distant Follow target should begin with one reaction state")
	_check(machine.follow_reaction_remaining >= 0.3 and machine.follow_reaction_remaining <= 0.6, "The reaction delay must remain between 0.3 and 0.6 seconds")
	var reaction := machine.follow_reaction_remaining
	var waiting_position := machine.update_follow_position(pet_position, reaction * 0.5, 1.0)
	_check(waiting_position == pet_position, "FOLLOW_REACTION must not move before its timer ends")
	machine.follow_reaction_remaining = 0.0
	pet_position = machine.update_follow_position(pet_position, 0.1, 1.0)
	_check(is_equal_approx(pet_position.x, 15.0), "Follow movement should consume delta at 150 px/s")
	pet_position = machine.update_follow_position(pet_position, 10.0, 1.0)
	_check(machine.motion_state == machine.MotionState.FOLLOW_SETTLED, "Reaching the 60 px radius should enter FOLLOW_SETTLED")
	_check(is_equal_approx(pet_position.distance_to(machine.follow_target), 60.0), "Follow should stop at the near radius")
	machine.update_follow_target(pet_position + Vector2(90.0, 0.0), Vector2.ZERO)
	var settled_position := machine.update_follow_position(pet_position, 1.0, 1.0)
	_check(settled_position == pet_position and machine.motion_state == machine.MotionState.FOLLOW_SETTLED, "Movement inside the 100 px resume radius must stay settled")
	machine.update_follow_target(pet_position + Vector2(110.0, 0.0), Vector2.ZERO)
	machine.update_follow_position(pet_position, 0.0, 1.0)
	_check(machine.motion_state == machine.MotionState.FOLLOW_REACTION, "Crossing the resume radius should start one new reaction")
	machine.disable_follow(false)
	_check(machine.motion_state == machine.MotionState.RETURNING and not machine.follow_has_target, "Unfollow away from the Station should clear the target and return")


func _test_drag_resume_policy() -> void:
	var machine := StateMachineScript.new()
	machine.update_follow_target(Vector2(500.0, 0.0), Vector2.ZERO)
	machine.enable_follow(Vector2.ZERO, 1.0)
	machine.follow_reaction_remaining = 0.0
	machine.update_follow_position(Vector2.ZERO, 0.1, 1.0)
	_check(machine.motion_state == machine.MotionState.FOLLOWING, "The fixture should enter FOLLOWING")
	machine.begin_drag()
	_check(machine.motion_state == machine.MotionState.DRAGGING_FOLLOW, "Dragging during Follow should use the explicit DRAGGING_FOLLOW state")
	machine.end_drag()
	_check(machine.motion_state == machine.MotionState.FOLLOWING, "Releasing a Follow drag should resume its previous state without another delay")
	machine.disable_follow(true)
	machine.begin_drag()
	_check(machine.motion_state == machine.MotionState.DRAGGING_FREE, "Dragging a docked pet should use DRAGGING_FREE")
	machine.end_drag()
	_check(machine.motion_state == machine.MotionState.AWAY_IDLE, "A free drag should wait away from the Station after release")


func _test_rest_state() -> void:
	var machine := StateMachineScript.new()
	machine.update_rest(machine.STATION_WAKE_SECONDS - 0.1, false, false)
	_check(machine.rest_state == machine.RestState.AWAKE, "Rest should remain AWAKE before the timeout")
	machine.update_rest(0.2, false, false)
	_check(machine.rest_state == machine.RestState.SLEEPING, "Rest should enter SLEEPING after the timeout")
	machine.update_rest(0.1, true, true)
	_check(machine.rest_state == machine.RestState.AWAKE and machine.seconds_outside_station == 0.0, "Pointer contact should wake the pet and reset the sleep timer")
