class_name HeartService
extends RefCounted

## Time-based heart policy independent from scenes and UI.
##
## Callers supply `now_unix`, which keeps offline recovery deterministic and
## makes the policy testable without changing the operating-system clock.

const MAX_HEARTS := 5
const DEFAULT_RESTORE_SECONDS := 15

var _store
var _restore_seconds := DEFAULT_RESTORE_SECONDS


func _init(configured_store = null, restore_seconds := DEFAULT_RESTORE_SECONDS) -> void:
	_store = configured_store
	_restore_seconds = maxi(1, restore_seconds)


func configure(configured_store, restore_seconds := DEFAULT_RESTORE_SECONDS) -> void:
	_store = configured_store
	_restore_seconds = maxi(1, restore_seconds)


func heart_count() -> int:
	return 0 if _store == null else int(_store.progress.hearts)


func next_restore_unix() -> int:
	return 0 if _store == null else int(_store.progress.next_heart_restore_unix)


func is_full() -> bool:
	return heart_count() >= MAX_HEARTS


func can_spend() -> bool:
	return heart_count() > 0


func spend(now_unix: int) -> bool:
	if _store == null:
		return false
	restore_at(now_unix)
	var current_hearts := heart_count()
	if current_hearts <= 0:
		return false
	var next_deadline := next_restore_unix()
	var remaining_hearts := current_hearts - 1
	if remaining_hearts < MAX_HEARTS and next_deadline <= 0:
		next_deadline = now_unix + _restore_seconds
	_store.set_hearts(remaining_hearts, next_deadline)
	return true


func restore_at(now_unix: int) -> bool:
	if _store == null:
		return false
	var current_hearts := heart_count()
	var current_deadline := next_restore_unix()
	if current_hearts >= MAX_HEARTS:
		if current_hearts != MAX_HEARTS or current_deadline != 0:
			_store.set_hearts(MAX_HEARTS, 0)
			return true
		return false

	if current_deadline <= 0:
		_store.set_hearts(current_hearts, now_unix + _restore_seconds)
		return true

	# A clock rollback or corrupt far-future deadline must not lock recovery for
	# longer than one normal interval from the newly observed time.
	var latest_valid_deadline := now_unix + _restore_seconds
	if current_deadline > latest_valid_deadline:
		_store.set_hearts(current_hearts, latest_valid_deadline)
		return true

	if now_unix < current_deadline:
		return false

	var restored_count := 1 + int(
		(now_unix - current_deadline) / _restore_seconds
	)
	var restored_hearts := mini(MAX_HEARTS, current_hearts + restored_count)
	var next_deadline := (
		0
		if restored_hearts >= MAX_HEARTS
		else current_deadline + restored_count * _restore_seconds
	)
	_store.set_hearts(restored_hearts, next_deadline)
	return true


func seconds_until_next(now_unix: int) -> int:
	if is_full() or next_restore_unix() <= 0:
		return 0
	return maxi(0, next_restore_unix() - now_unix)
