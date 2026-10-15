class_name ScreenId
extends RefCounted

const NONE := &""
const HOME := &"home"
const PET_POOL := &"pool"
const STORE := &"store"
const FISH_BOOK := &"fish_book"
const FISHING := &"fishing"
const AQUARIUM_LOADING := &"aquarium_loading"
const AQUARIUM := &"aquarium"
const REVERSE_FETCH := &"fetch"
const DESKTOP_WIDGET := &"widget"


static func is_aquarium(screen_id: StringName) -> bool:
	return screen_id in [AQUARIUM_LOADING, AQUARIUM]


static func should_cache(screen_id: StringName) -> bool:
	return screen_id == AQUARIUM
