class_name GridState
extends RefCounted
## Pure grid rules: no scene, renderer, timers, physics, or input dependencies.

const Level = preload("res://scripts/core/level_data.gd")

var level: Level
var player: Vector2i = Vector2i.ZERO
var moves: int = 0
var pushes: int = 0
var _crates: Dictionary = {}
var _history: Array[Dictionary] = []


func load_level(definition: Level) -> bool:
	# Invalid data must not replace a running session.
	if definition == null or not definition.error.is_empty():
		return false
	level = definition
	restart()
	return true


func try_move(direction: Vector2i) -> StringName:
	if level == null:
		return &"no_level"
	if absi(direction.x) + absi(direction.y) != 1:
		return &"invalid_direction"
	if is_complete():
		return &"complete"
	var next := player + direction
	if not level.is_floor(next):
		return &"wall"
	var pushing := _crates.has(next)
	var destination := next + direction
	if pushing and (not level.is_floor(destination) or _crates.has(destination)):
		# A second crate always blocks the push; never move a chain of crates.
		return &"crate_blocked"
	_history.append(snapshot())
	if pushing:
		var identity: int = _crates[next]
		_crates.erase(next)
		_crates[destination] = identity
		pushes += 1
	player = next
	moves += 1
	return &"pushed" if pushing else &"moved"


func undo() -> bool:
	if _history.is_empty():
		return false
	var previous: Dictionary = _history.pop_back()
	player = previous["player"]
	_crates = previous["crates"].duplicate()
	moves = previous["moves"]
	pushes = previous["pushes"]
	return true


func restart() -> void:
	_history.clear()
	_crates.clear()
	moves = 0
	pushes = 0
	if level == null:
		player = Vector2i.ZERO
		return
	player = level.start
	for i in level.initial_crates.size():
		_crates[level.initial_crates[i]] = i


func is_complete() -> bool:
	if level == null:
		return false
	if level.objective == "player_on_exit":
		return player == level.exit_cell
	if level.objective != "all_crates_on_targets":
		return false
	for target in level.targets:
		if not _crates.has(target):
			return false
	return true


func crates() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _crates:
		cells.append(cell)
	return cells


func crate_id(cell: Vector2i) -> int:
	# Identity remains stable across movement, undo, and restart.
	return _crates.get(cell, -1)


func occupied_targets() -> int:
	var count := 0
	if level != null:
		for target in level.targets:
			if _crates.has(target):
				count += 1
	return count


func history_size() -> int:
	return _history.size()


func snapshot() -> Dictionary:
	# Copies prevent external callers and later moves from altering undo history.
	return {"player": player, "crates": _crates.duplicate(), "moves": moves, "pushes": pushes}
