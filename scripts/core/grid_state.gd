class_name GridState
extends RefCounted
## Pure grid rules: no scene, renderer, timers, physics, or input dependencies.

const Level = preload("res://scripts/core/level_data.gd")
const Energy = preload("res://scripts/core/energy_rules.gd")
const Heroes = preload("res://scripts/core/hero_rules.gd")

var level: Level
var player: Vector2i = Vector2i.ZERO
var moves: int = 0
var pushes: int = 0
var pulls: int = 0
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
		"moves": 0, "pushes": 0, "pulls": 0, "alive": true,
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
		if level.bush_at(next) != null:
			return &"bush_blocked"
		return &"energy_blocked" if barrier_is_active(next) else &"wall"
	if _crates.has(next) and not Heroes.can_push(level.hero_kind):
		return &"cannot_push"
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
	var pulled := false
	if not chain.is_empty():
		# Move the far end first so no crystal overwrites the next one's identity.
		for index in range(chain.size() - 1, -1, -1):
			var cell := chain[index]
			var identity: int = candidate[cell]
			candidate.erase(cell)
			candidate[cell + direction] = identity
	if Heroes.can_pull(level.hero_kind):
		var behind := player - direction
		if candidate.has(behind):
			# Only the nearest rear crystal enters the hero's old cell.
			# Further crystals and side neighbours keep their positions.
			var identity: int = candidate[behind]
			candidate.erase(behind)
			candidate[player] = identity
			pulled = true
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
	pulls += 1 if pulled else 0
	alive = settled["alive"]
	_pressure = settled["pressure"]
	_barriers = settled["barriers"]
	if not alive:
		return &"died"
	if pulled:
		return &"pulled"
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
	if level == null or not level.is_floor(cell) or barrier_is_active(cell):
		return false
	var bush := level.bush_at(cell)
	return bush == null or not bush.BLOCKS_MOVEMENT


func barrier_is_active(cell: Vector2i) -> bool:
	return _barriers.get(cell, false)


func pressure_is_active(id: String) -> bool:
	return _pressure.get(id, false)


func pressure_cell_is_active(id: String, cell: Vector2i) -> bool:
	if level == null:
		return false
	for link in level.energy_links:
		if link["id"] == id and cell in link["plates"]:
			return Energy.pressure_matches(cell, link["pressure_sources"], player, _crates)
	return false


func pressure_progress(id: String) -> Vector2i:
	var count := Vector2i.ZERO
	if level != null:
		for link in level.energy_links:
			if link["id"] == id:
				count.y = link["plates"].size()
				for cell: Vector2i in link["plates"]:
					count.x += 1 if pressure_cell_is_active(id, cell) else 0
	return count


func pressure_states() -> Dictionary:
	return _pressure.duplicate()


func barrier_states() -> Dictionary:
	return _barriers.duplicate()


func blocks_sight(cell: Vector2i) -> bool:
	# Terrain query only: movable sight targets are a caller-level concern.
	if level == null or not level.is_floor(cell) or barrier_is_active(cell):
		return true
	var bush := level.bush_at(cell)
	return bush != null and bush.BLOCKS_SIGHT


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
	pulls = state["pulls"]
	alive = state["alive"]
	_pressure = state["pressure"].duplicate()
	_barriers = state["barriers"].duplicate()
	last_mechanism_error = ""


func snapshot() -> Dictionary:
	# Copies prevent external callers and later moves from altering undo history.
	return {"player": player, "crates": _crates.duplicate(), "moves": moves, "pushes": pushes, "pulls": pulls,
		"alive": alive, "pressure": _pressure.duplicate(), "barriers": _barriers.duplicate()}
