extends SceneTree
## Dependency-free logic and keyboard regression tests, run by the Godot runtime.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const KeySteps = preload("res://scripts/input/step_input.gd")

var checks: int = 0
var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases: Array[Callable] = [
		_test_walls_and_bounds, _test_single_push, _test_blocked_push,
		_test_no_pull, _test_undo, _test_restart, _test_test_objective, _test_player_exit,
		_test_validation, _test_input_repeat, _test_input_mappings,
		_test_random_history, _test_temporary_map_solution,
	]
	for test in cases:
		var previous_failures := failures
		test.call()
		print("%s %s" % ["PASS" if previous_failures == failures else "FAIL", test.get_method()])
	print("LOGIC RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_walls_and_bounds() -> void:
	var data := _fixture()
	data["player"] = [1, 1]
	var game := _game(data)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.LEFT) == &"wall", "left wall blocks")
	_check(game.try_move(Vector2i.UP) == &"wall", "upper wall blocks")
	_check(game.snapshot() == before and game.history_size() == 0, "wall does not create history or counters")
	for direction in [Vector2i.ZERO, Vector2i(1, 1), Vector2i(2, 0)]:
		_check(game.try_move(direction) == &"invalid_direction", "reject non-cardinal or multi-cell movement")
	data["terrain"] = ["..."]
	data["player"] = [0, 0]
	data["crates"] = []
	game = _game(data)
	_check(game.try_move(Vector2i.LEFT) == &"wall", "outside left edge is blocked even without border walls")
	_check(game.try_move(Vector2i.UP) == &"wall", "outside top edge is blocked")
	game.try_move(Vector2i.RIGHT)
	game.try_move(Vector2i.RIGHT)
	_check(game.try_move(Vector2i.RIGHT) == &"wall", "outside right edge is blocked")
	_check(game.try_move(Vector2i.DOWN) == &"wall", "outside bottom edge is blocked")


func _test_single_push() -> void:
	var game := _game(_fixture())
	_check(game.try_move(Vector2i.RIGHT) == &"pushed", "adjacent single crate can be pushed")
	_check(game.player == Vector2i(3, 2), "hero enters crate's former cell")
	_check(game.crates() == [Vector2i(4, 2)], "crate moves exactly one cell")
	_check(game.crate_id(Vector2i(4, 2)) == 0, "pushing preserves crystal identity")
	_check(game.moves == 1 and game.pushes == 1 and game.history_size() == 1, "one push counts as one move and one push")


func _test_blocked_push() -> void:
	var data := _fixture()
	data["player"] = [4, 2]
	data["crates"] = [[5, 2]]
	var game := _game(data)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked", "wall behind crate blocks push")
	_check(game.snapshot() == before and game.history_size() == 0, "blocked push is atomic")
	data["player"] = [1, 2]
	data["crates"] = [[2, 2], [3, 2]]
	game = _game(data)
	before = game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked", "second crate blocks; no chain pushing")
	_check(game.snapshot() == before and game.history_size() == 0, "no part of blocked crate chain moves")
	data["terrain"] = ["...."]
	data["player"] = [2, 0]
	data["crates"] = [[3, 0]]
	game = _game(data)
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked", "crate cannot be pushed outside the map")


func _test_no_pull() -> void:
	var game := _game(_fixture())
	game.try_move(Vector2i.RIGHT)
	_check(game.try_move(Vector2i.LEFT) == &"moved", "walking away from crate is a regular move")
	_check(game.player == Vector2i(2, 2) and game.crates() == [Vector2i(4, 2)], "walking backward never pulls crate")
	_check(game.moves == 2 and game.pushes == 1, "walking away does not count as a push")


func _test_undo() -> void:
	var game := _game(_fixture())
	_check(not game.undo(), "undo at initial state is safe")
	var initial := game.snapshot()
	var history: Array[Dictionary] = []
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.DOWN]:
		history.append(game.snapshot())
		game.try_move(direction)
	_check(game.moves == 4 and game.pushes == 1, "walk/push sequence counters")
	_check(game.try_move(Vector2i.DOWN) == &"wall", "blocked command after valid moves")
	_check(game.history_size() == 4, "blocked command is absent from history")
	history.reverse()
	for expected in history:
		_check(game.undo(), "undo available for valid command")
		_check(game.snapshot() == expected, "undo restores hero, every crate, moves, and pushes")
	_check(game.snapshot() == initial and not game.undo(), "history fully exhausted at original state")
	var exposed := game.snapshot()
	exposed["crates"].clear()
	_check(game.crates().size() == 1, "snapshot cannot mutate live crate state")
	var cells := game.crates()
	cells.clear()
	_check(game.crates().size() == 1, "crate list is a copy")


func _test_restart() -> void:
	var game := _game(_fixture())
	var initial := game.snapshot()
	game.try_move(Vector2i.RIGHT)
	game.try_move(Vector2i.DOWN)
	game.undo()
	game.restart()
	_check(game.snapshot() == initial and game.history_size() == 0, "restart restores all initial state and clears undo")
	_check(not game.undo(), "cannot undo across restart")
	game.restart()
	_check(game.snapshot() == initial, "repeated restart is idempotent")
	game.try_move(Vector2i.RIGHT)
	var next_level := _fixture()
	next_level["player"] = [1, 1]
	game.load_level(Level.from_dictionary(next_level))
	_check(game.player == Vector2i(1, 1) and game.history_size() == 0 and game.moves == 0, "new map cannot reuse old history")
	var before := game.snapshot()
	_check(not game.load_level(Level.from_dictionary({})), "reject invalid level load")
	_check(game.snapshot() == before, "invalid level load preserves current session")
	var unloaded := State.new()
	unloaded.restart()
	_check(unloaded.try_move(Vector2i.RIGHT) == &"no_level" and not unloaded.undo(), "unloaded model is safe")


func _test_test_objective() -> void:
	var data := _fixture()
	data["player"] = [1, 2]
	data["crates"] = [[2, 2]]
	data["targets"] = [[3, 2]]
	data["objective"] = "all_crates_on_targets"
	var game := _game(data)
	_check(not game.is_complete() and game.occupied_targets() == 0, "test objective begins incomplete")
	game.try_move(Vector2i.RIGHT)
	_check(game.is_complete() and game.occupied_targets() == 1, "crate on target completes temporary objective")
	var solved := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"complete" and game.snapshot() == solved, "completed test waits for undo/restart")
	_check(game.undo() and not game.is_complete(), "undo reopens completed test")
	game.try_move(Vector2i.RIGHT)
	game.restart()
	_check(not game.is_complete() and game.history_size() == 0, "restart clears completion")
	data["objective"] = "none"
	game = _game(data)
	game.try_move(Vector2i.RIGHT)
	_check(not game.is_complete(), "objective none does not infer victory from target overlap")
	data["crates"] = [[3, 2]]
	data["objective"] = "all_crates_on_targets"
	game = _game(data)
	_check(game.is_complete(), "initial completion is derived from data")


func _test_validation() -> void:
	_check(Level.from_dictionary(_fixture()).error.is_empty(), "valid level accepted")
	_check(not Level.from_dictionary([]).error.is_empty(), "array root rejected")
	_check(not Level.from_file("res://levels/does_not_exist.json").error.is_empty(), "missing file reported")
	var invalid_entries := [
		["schema_version", 2], ["terrain", ["###", "#."]],
		["terrain", ["###", "#?#", "###"]], ["terrain", []],
		["player", [0, 0]], ["player", [99, 99]], ["player", [1.5, 1]],
		["player", [true, 1]], ["crates", [[3, 2], [3, 2]]],
		["crates", [[2, 2]]], ["crates", [[0, 0]]], ["crates", "invalid"],
		["targets", [[1, 1], [1, 1]]], ["targets", [[0, 0]]],
		["objective", "unverified_exit_rule"], ["objective", "all_crates_on_targets"],
		["objective", "player_on_exit"], ["exit", [0, 0]], ["exit", [99, 1]],
		["crystal_colors", ["blue", "purple"]], ["crystal_colors", ["orange"]],
		["crystal_colors", "blue"], ["is_temporary", "true"], ["title", 42],
	]
	for entry in invalid_entries:
		var invalid := _fixture()
		invalid[entry[0]] = entry[1]
		_check(not Level.from_dictionary(invalid).error.is_empty(), "invalid %s rejected: %s" % [entry[0], str(entry[1])])


func _test_input_repeat() -> void:
	var gate := KeySteps.new()
	_check(gate.command_for_event(_key(KEY_D)).get("direction") == Vector2i.RIGHT, "first physical press emits a step")
	for i in 20:
		_check(gate.command_for_event(_key(KEY_D, true, true)).is_empty(), "OS echo ignored")
		_check(gate.command_for_event(_key(KEY_D)).is_empty(), "duplicate non-echo press ignored until release")
	_check(gate.command_for_event(_key(KEY_D, false)).is_empty(), "release emits no command")
	_check(not gate.command_for_event(_key(KEY_D)).is_empty(), "fresh press after release emits next step")
	gate.clear()
	_check(not gate.command_for_event(_key(KEY_D)).is_empty(), "focus-loss reset prevents stuck held state")
	_check(gate.command_for_event(InputEventMouseMotion.new()).is_empty(), "mouse motion is not a keyboard step")
	gate.clear()
	var modified := _key(KEY_D)
	modified.ctrl_pressed = true
	_check(gate.command_for_event(modified).is_empty(), "Ctrl shortcut does not move hero")
	gate.command_for_event(_key(KEY_D, false))
	_check(not gate.command_for_event(_key(KEY_D)).is_empty(), "modified key release clears held state")


func _test_input_mappings() -> void:
	var mappings := {
		KEY_W: Vector2i.UP, KEY_UP: Vector2i.UP,
		KEY_S: Vector2i.DOWN, KEY_DOWN: Vector2i.DOWN,
		KEY_A: Vector2i.LEFT, KEY_LEFT: Vector2i.LEFT,
		KEY_D: Vector2i.RIGHT, KEY_RIGHT: Vector2i.RIGHT,
	}
	for key in mappings:
		var gate := KeySteps.new()
		_check(gate.command_for_event(_key(key)).get("direction") == mappings[key], "direction mapping %s" % str(key))
	for key in [KEY_Z, KEY_U, KEY_BACKSPACE]:
		var gate := KeySteps.new()
		_check(gate.command_for_event(_key(key)).get("action") == &"undo", "undo mapping %s" % str(key))
	var gate := KeySteps.new()
	_check(gate.command_for_event(_key(KEY_R)).get("action") == &"restart", "restart mapping")
	_check(gate.command_for_event(_key(KEY_SPACE)).is_empty(), "unmapped key does nothing")
	gate.clear()
	var logical := _key(KEY_D)
	logical.physical_keycode = 0
	_check(gate.command_for_event(logical).get("direction") == Vector2i.RIGHT, "logical key fallback for injected events")


func _test_random_history() -> void:
	var game := _game(_fixture())
	var initial := game.snapshot()
	var history: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1398030674
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for i in 1000:
		var before := game.snapshot()
		var depth := game.history_size()
		var result := game.try_move(directions[rng.randi_range(0, 3)])
		if result in [&"moved", &"pushed"]:
			history.append(before)
			_check(game.moves == before["moves"] + 1 and game.history_size() == depth + 1, "successful step adds exactly one move and snapshot")
			_check(game.pushes == before["pushes"] + (1 if result == &"pushed" else 0), "push count invariant")
		else:
			_check(game.snapshot() == before and game.history_size() == depth, "failed command changes nothing")
		_check(game.level.is_floor(game.player) and game.player not in game.crates(), "hero stays on free floor")
		_check(game.crates().size() == 1 and game.level.is_floor(game.crates()[0]), "crate count and valid floor invariant")
	history.reverse()
	for previous in history:
		_check(game.undo() and game.snapshot() == previous, "every accepted random step can be exactly reversed")
	_check(game.snapshot() == initial and game.history_size() == 0, "1000-command stress run reverses to initial state")


func _test_temporary_map_solution() -> void:
	var level := Level.from_file("res://tests/fixtures/temporary_test.json")
	_check(level.error.is_empty() and level.is_temporary, "bundled map is valid and explicitly temporary")
	_check(level.initial_crates.size() == 2 and level.crystal_colors == PackedStringArray(["blue", "purple"]), "two independently colored temporary crystals")
	_check(level.objective == "player_on_exit", "bundled map uses the user-confirmed player exit rule")
	var game := State.new()
	game.load_level(level)
	var solution := [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.RIGHT, Vector2i.UP, Vector2i.UP]
	for direction in solution:
		_check(game.try_move(direction) in [&"moved", &"pushed"], "documented sandbox solution step succeeds")
	_check(not game.is_complete() and level.exit_cell in game.crates(), "crystal on yellow exit does not win")
	_check(game.try_move(Vector2i.UP) == &"pushed", "hero pushes crystal away from exit")
	_check(game.is_complete() and game.moves == 10 and game.pushes == 7, "hero reaches exit in 10 moves / 7 pushes")
	_check(game.crate_id(Vector2i(8, 1)) == 0 and game.crate_id(Vector2i(9, 5)) == 1, "blue and purple identities remain distinct")
	for i in 10:
		_check(game.undo(), "sandbox solution fully undoable")
	_check(game.player == level.start and game.crates() == level.initial_crates and not game.is_complete(), "sandbox returns to start after undo")


func _test_player_exit() -> void:
	var data := _fixture()
	data["player"] = [1, 2]
	data["crates"] = [[2, 2]]
	data["exit"] = [3, 2]
	data["objective"] = "player_on_exit"
	var game := _game(data)
	game.try_move(Vector2i.RIGHT)
	_check(not game.is_complete() and Vector2i(3, 2) in game.crates(), "crystal on exit is not victory")
	game.try_move(Vector2i.RIGHT)
	_check(game.is_complete() and game.player == Vector2i(3, 2), "only hero entering exit wins")
	_check(game.crates() == [Vector2i(4, 2)], "victory does not require a crystal on any target")
	_check(game.undo() and not game.is_complete(), "undo restores exit session before completion")
	_check(game.crate_id(Vector2i(3, 2)) == 0, "undo retains crystal identity")
	game.try_move(Vector2i.RIGHT)
	game.restart()
	_check(not game.is_complete() and game.moves == 0 and game.history_size() == 0, "restart clears exit victory and history")
	data["crates"] = []
	game = _game(data)
	game.try_move(Vector2i.RIGHT)
	game.try_move(Vector2i.RIGHT)
	_check(game.is_complete() and game.pushes == 0, "walking onto exit wins without pushing")
	data["objective"] = "none"
	game = _game(data)
	game.try_move(Vector2i.RIGHT)
	game.try_move(Vector2i.RIGHT)
	_check(not game.is_complete(), "an exit marker alone does not infer a victory rule")


func _fixture() -> Dictionary:
	return {
		"schema_version": 1, "id": "test", "title": "Temporary fixture",
		"is_temporary": true, "source_note": "Automated test only",
		"terrain": ["#######", "#.....#", "#.....#", "#.....#", "#######"],
		"player": [2, 2], "crates": [[3, 2]], "targets": [], "objective": "none",
	}


func _game(data: Dictionary) -> State:
	var level := Level.from_dictionary(data)
	_check(level.error.is_empty(), "fixture valid: " + level.error)
	var game := State.new()
	_check(game.load_level(level), "fixture loads")
	return game


func _key(key: int, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = key
	event.physical_keycode = key
	event.pressed = pressed
	event.echo = echo
	return event


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
