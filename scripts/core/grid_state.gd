class_name GridState
extends RefCounted
## Pure grid rules: no scene, renderer, timers, physics, or input dependencies.

const Level = preload("res://scripts/core/level_data.gd")
const Energy = preload("res://scripts/core/energy_rules.gd")

var level: Level
var player: Vector2i = Vector2i.ZERO
var moves: int = 0
var pushes: int = 0
var alive: bool = true
var last_mechanism_error: String = ""
var _crates: Dictionary = {}
var _history: Array[Dictionary] = []
var _pressure: Dictionary = {}
var _barriers: Dictionary = {}
var _initial_state: Dictionary = {}


func load_level(definition: Level) -> bool:
	# Invalid data must not replace a running session.
	if not alive or definition == null or not definition.error.is_empty():
		return false
	var initial_crystals: Dictionary = {}
	for i in definition.initial_crates.size():
		initial_crystals[definition.initial_crates[i]] = i
	var settled := Energy.settle(definition.energy_links, definition.start, initial_crystals, {})
	last_mechanism_error = settled["error"]
	if not last_mechanism_error.is_empty():
		return false
	if not settled["alive"]:
		last_mechanism_error = "英雄不能从已激活的能量格内开始。"
		return false
	level = definition
	_initial_state = {"player": definition.start, "crates": initial_crystals,
		"moves": 0, "pushes": 0, "alive": true,
		"pressure": settled["pressure"], "barriers": settled["barriers"]}
	_restore(_initial_state)
	_history.clear()
	return true


func try_move(direction: Vector2i) -> StringName:
	if level == null:
		return &"no_level"
	if not alive:
		return &"dead"
	last_mechanism_error = ""
	if absi(direction.x) + absi(direction.y) != 1:
		return &"invalid_direction"
	if is_complete():
		return &"complete"
	var next := player + direction
	if not is_walkable(next):
		return &"energy_blocked" if barrier_is_active(next) else &"wall"
	var chain: Array[Vector2i] = []
	var destination := next
	while _crates.has(destination):
		chain.append(destination)
		destination += direction
	# Validate the entire contiguous line before recording or mutating anything.
	# Its length is determined by occupancy, with no fixed push-count limit.
	if not chain.is_empty() and not is_walkable(destination):
		return &"crate_blocked"
	var candidate := _crates.duplicate()
	if not chain.is_empty():
		# Move the far end first so no crystal overwrites the next one's identity.
		for index in range(chain.size() - 1, -1, -1):
			var cell := chain[index]
			var identity: int = candidate[cell]
			candidate.erase(cell)
			candidate[cell + direction] = identity
	var settled := Energy.settle(level.energy_links, next, candidate, _barriers)
	last_mechanism_error = settled["error"]
	if not last_mechanism_error.is_empty():
		return &"rule_unresolved"
	# Commit movement, pressure, barriers and death as one undoable action.
	_history.append(snapshot())
	_crates = candidate
	player = next
	moves += 1
	pushes += 0 if chain.is_empty() else 1
	alive = settled["alive"]
	_pressure = settled["pressure"]
	_barriers = settled["barriers"]
	if not alive:
		return &"died"
	return &"pushed" if not chain.is_empty() else &"moved"


func undo() -> bool:
	if _history.is_empty():
		return false
	var previous: Dictionary = _history.pop_back()
	_restore(previous)
	return true


func restart() -> bool:
	if not alive:
		return false
	_history.clear()
	if level == null:
		return true
	_restore(_initial_state)
	return true


func is_complete() -> bool:
	if level == null or not alive:
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


func is_walkable(cell: Vector2i) -> bool:
	return level != null and level.is_floor(cell) and not barrier_is_active(cell)


func barrier_is_active(cell: Vector2i) -> bool:
	return _barriers.get(cell, false)


func pressure_is_active(id: String) -> bool:
	return _pressure.get(id, false)


func pressure_states() -> Dictionary:
	return _pressure.duplicate()


func barrier_states() -> Dictionary:
	return _barriers.duplicate()


func blocks_sight(cell: Vector2i) -> bool:
	# Terrain query only: movable sight targets are a caller-level concern.
	return not is_walkable(cell)


func sight_path_is_clear(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if blocks_sight(cell):
			return false
	return true


func _restore(state: Dictionary) -> void:
	player = state["player"]
	_crates = state["crates"].duplicate()
	moves = state["moves"]
	pushes = state["pushes"]
	alive = state["alive"]
	_pressure = state["pressure"].duplicate()
	_barriers = state["barriers"].duplicate()
	last_mechanism_error = ""


func snapshot() -> Dictionary:
	# Copies prevent external callers and later moves from altering undo history.
	return {"player": player, "crates": _crates.duplicate(), "moves": moves, "pushes": pushes,
		"alive": alive, "pressure": _pressure.duplicate(), "barriers": _barriers.duplicate()}
