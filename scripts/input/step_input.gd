class_name StepInput
extends RefCounted
## One command per physical press, independent of the OS repeat rate.

const DIRECTIONS := {
	&"move_up": Vector2i.UP,
	&"move_down": Vector2i.DOWN,
	&"move_left": Vector2i.LEFT,
	&"move_right": Vector2i.RIGHT,
}
var _held_keys: Dictionary = {}


func command_for_event(event: InputEvent) -> Dictionary:
	if not event is InputEventKey:
		return {}
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not event.pressed:
		_held_keys.erase(key)
		return {}
	if event.echo or _held_keys.has(key):
		return {}
	_held_keys[key] = true
	if event.ctrl_pressed or event.alt_pressed or event.meta_pressed:
		return {}
	var mapped_event: InputEventKey = event
	if mapped_event.physical_keycode == 0:
		mapped_event = event.duplicate()
		mapped_event.physical_keycode = event.keycode
	for action: StringName in DIRECTIONS:
		if mapped_event.is_action(action):
			return {"action": &"move", "direction": DIRECTIONS[action]}
	if mapped_event.is_action(&"undo"):
		return {"action": &"undo"}
	if mapped_event.is_action(&"restart"):
		return {"action": &"restart"}
	return {}


func clear() -> void:
	# Clear on lost window focus, where the matching key release can be missed.
	_held_keys.clear()
