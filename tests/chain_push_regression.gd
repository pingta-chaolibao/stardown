extends SceneTree
## Whole-line pushing: atomic validation, stable identities, one undo per input.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const Steps = preload("res://scripts/input/step_input.gd")
const LENGTHS := [2, 3, 4, 8, 60]
const DIRECTIONS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]

var checks: int = 0
var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases: Array[Callable] = [_test_lengths_and_directions, _test_wall_blockers,
		_test_boundaries, _test_gap_and_side_neighbor, _test_undo_restart,
		_test_repeated_input]
	for test in cases:
		var previous := failures
		test.call()
		print("%s %s" % ["PASS" if previous == failures else "FAIL", test.get_method()])
	print("CHAIN PUSH RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_lengths_and_directions() -> void:
	for count in LENGTHS:
		for direction in DIRECTIONS:
			var game := _game(_data(count, direction))
			var start := game.player
			_check(game.try_move(direction) == &"pushed", "%d-crystal line pushes toward %s" % [count, str(direction)])
			_check(game.player == start + direction, "hero advances exactly one cell")
			_check(game.crates().size() == count, "line keeps every crystal")
			for identity in count:
				_check(game.crate_id(start + direction * (identity + 2)) == identity, "crystal advances one cell without identity overwrite")
			_check(game.moves == 1 and game.pushes == 1 and game.history_size() == 1, "whole line is one move, one push action, one undo")


func _test_wall_blockers() -> void:
	for count in LENGTHS:
		for direction in DIRECTIONS:
			var game := _game(_data(count, direction, "wall"))
			var initial := game.snapshot()
			_check(game.try_move(direction) == &"crate_blocked", "wall after %d-crystal line blocks" % count)
			_check(game.snapshot() == initial and game.history_size() == 0, "wall blocks entire line atomically")
			_check(not game.undo(), "blocked line creates no undo step")


func _test_boundaries() -> void:
	for count in LENGTHS:
		for direction in DIRECTIONS:
			var game := _game(_data(count, direction, "boundary"))
			var initial := game.snapshot()
			_check(game.try_move(direction) == &"crate_blocked", "boundary after %d-crystal line blocks" % count)
			_check(game.snapshot() == initial and game.history_size() == 0, "boundary leaves every identity, counter and hero unchanged")


func _test_gap_and_side_neighbor() -> void:
	var data := _data(2, Vector2i.RIGHT)
	data["terrain"] = ["........", "........", "........"]
	data["crates"] = [[2, 1], [3, 1], [5, 1], [3, 0]]
	var game := _game(data)
	game.try_move(Vector2i.RIGHT)
	_check(game.crate_id(Vector2i(3, 1)) == 0 and game.crate_id(Vector2i(4, 1)) == 1, "adjacent pair advances")
	_check(game.crate_id(Vector2i(5, 1)) == 2, "gap stops scan before distant crystal")
	_check(game.crate_id(Vector2i(3, 0)) == 3, "off-axis neighbor never moves with line")
	_check(game.try_move(Vector2i.RIGHT) == &"pushed", "newly adjacent third crystal joins next push")
	_check(game.crate_id(Vector2i(4, 1)) == 0 and game.crate_id(Vector2i(5, 1)) == 1 and game.crate_id(Vector2i(6, 1)) == 2, "new three-crystal line moves once")
	_check(game.crate_id(Vector2i(3, 0)) == 3, "off-axis neighbor still unchanged")


func _test_undo_restart() -> void:
	for count in LENGTHS:
		var game := _game(_data(count, Vector2i.RIGHT))
		var initial := game.snapshot()
		game.try_move(Vector2i.RIGHT)
		var after_one := game.snapshot()
		game.try_move(Vector2i.RIGHT)
		var before_blocked := game.snapshot()
		_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked" and game.snapshot() == before_blocked, "line ending at boundary blocks after accepted pushes")
		_check(game.history_size() == 2, "two pushes create exactly two history entries")
		_check(game.undo() and game.snapshot() == after_one, "one undo restores the entire line's preceding state")
		_check(game.undo() and game.snapshot() == initial and not game.undo(), "second undo restores initial identities and counters")
		game.try_move(Vector2i.RIGHT)
		game.try_move(Vector2i.LEFT)
		_check(game.crate_id(Vector2i(3, 1)) == 0, "walking away does not pull the line")
		game.restart()
		_check(game.snapshot() == initial and game.history_size() == 0 and not game.undo(), "restart restores all crystals and clears line history")


func _test_repeated_input() -> void:
	var game := _game(_data(4, Vector2i.RIGHT))
	var input := Steps.new()
	game.try_move(input.command_for_event(_key()).get("direction"))
	var after_one := game.snapshot()
	for i in 20:
		_check(input.command_for_event(_key(true, true)).is_empty(), "OS echo cannot push line repeatedly")
		_check(input.command_for_event(_key()).is_empty(), "duplicate held press cannot push line repeatedly")
	_check(game.snapshot() == after_one, "held key leaves entire line at one-cell displacement")
	input.command_for_event(_key(false))
	game.try_move(input.command_for_event(_key()).get("direction"))
	_check(game.moves == 2 and game.pushes == 2, "released and re-pressed key advances whole line one more cell")
	_check(game.undo() and game.snapshot() == after_one, "one undo reverses one repeated-input line push")


func _data(count: int, direction: Vector2i, blocker: String = "") -> Dictionary:
	var length := count + (2 if blocker == "boundary" else 4)
	var width := length if direction.x != 0 else 3
	var height := length if direction.y != 0 else 3
	var start := Vector2i(1, 1)
	if direction.x < 0:
		start.x = width - 2
	if direction.y < 0:
		start.y = height - 2
	var terminal := start + direction * (count + 1)
	var rows: Array = []
	for y in height:
		var row := ""
		for x in width:
			row += "#" if blocker == "wall" and Vector2i(x, y) == terminal else "."
		rows.append(row)
	var crystals: Array = []
	for i in count:
		var cell := start + direction * (i + 1)
		crystals.append([cell.x, cell.y])
	return {"schema_version": 1, "id": "chain_fixture", "title": "Chain regression fixture",
		"is_temporary": true, "source_note": "Automated rule tests, not a playable level",
		"terrain": rows, "player": [start.x, start.y], "crates": crystals,
		"targets": [], "objective": "none"}


func _game(data: Dictionary) -> State:
	var level := Level.from_dictionary(data)
	_check(level.error.is_empty(), "line fixture validates: " + level.error)
	var game := State.new()
	_check(game.load_level(level), "line fixture loads")
	return game


func _key(pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_D
	event.physical_keycode = KEY_D
	event.pressed = pressed
	event.echo = echo
	return event


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
