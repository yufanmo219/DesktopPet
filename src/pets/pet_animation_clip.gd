class_name PetAnimationClip
extends Resource

## Data-only description of one pet animation.
##
## A clip owns resource paths and playback/layout metadata, while PetAvatar and
## feature presenters own runtime state. Keeping those concerns separate makes
## a new pet a catalog addition instead of a renderer change.

var clip_id := ""
var frame_paths: Array[String] = []
var frame_durations: Array[float] = []
var fps := 0.0
var loop_start_frame := 0
var wait_min := 0.0
var wait_max := 0.0
var layout_scale := 0.82
var layout_size_reference := "current"
var visual_bounds_reference := "current"
var fixed_visual_bounds := Rect2()
var uses_fixed_visual_bounds := false
var position_offset := Vector2.ZERO


func load_frames(pet_id: String) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	for path in frame_paths:
		var resource := ResourceLoader.load(path, "Texture2D")
		if not resource is Texture2D:
			push_error("Pet '%s' could not load animation '%s' frame %s." % [
				pet_id,
				clip_id,
				path
			])
			continue
		frames.append(resource)
	return frames


func frame_duration(frame_index: int, fallback_fps := 1.0) -> float:
	if frame_index >= 0 and frame_index < frame_durations.size():
		return maxf(frame_durations[frame_index], 0.0001)
	var safe_fps := fps if fps > 0.0 else fallback_fps
	return 1.0 / maxf(safe_fps, 0.0001)


func validation_errors() -> Array[String]:
	var errors: Array[String] = []
	if clip_id.is_empty():
		errors.append("clip_id is required")
	if frame_paths.is_empty():
		errors.append("frames are required")
	if not frame_durations.is_empty() and frame_durations.size() != frame_paths.size():
		errors.append("frame duration count must match frame count")
	if loop_start_frame < 0 or loop_start_frame >= maxi(frame_paths.size(), 1):
		errors.append("loop_start_frame is outside the clip")
	if wait_min < 0.0 or wait_max < wait_min:
		errors.append("wait range is invalid")
	if layout_scale <= 0.0:
		errors.append("layout_scale must be positive")
	for path in frame_paths:
		if not ResourceLoader.exists(path, "Texture2D"):
			errors.append("asset does not exist: %s" % path)
	return errors
