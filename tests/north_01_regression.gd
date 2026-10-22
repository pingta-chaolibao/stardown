extends SceneTree
## Regression against the user's explicitly confirmed coordinates, not image guesses.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const Steps = preload("res://scripts/input/step_input.gd")
const SOLUTION := [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT,
	Vector2i.UP, Vector2i.UP, Vector2i.RIGHT, Vector2i.RIGHT,
	Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.RIGHT]
const WALLS := [Vector2i(3, 0), Vector2i(3, 1), Vector2i(7, 1), Vector2i(7, 2)]

var checks: int = 0
var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases: Array[Callable] = [_test_coordinates, _test_walls_and_bounds,
		_test_blue_blocked, _test_purple_blocked, _test_solution_undo_restart,
		_test_continuous_commands]
	for test in cases:
		var previous := failures
		test.call()
		print("%s %s" % ["PASS" if previous == failures else "FAIL", test.get_method()])
	print("NORTH 01 RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_coordinates() -> void:
	var game := _game()
	_check(game.level.width == 11 and game.level.height == 3, "confirmed 11 by 3 rectangle")
	_check(not game.level.is_temporary and game.level.id == "north_hero_01", "confirmed level is the default deliverable")
	_check(game.player == Vector2i(1, 1), "red hero starts at (1,1)")
	_check(game.crates().size() == 2, "exactly two crystals")
	_check(game.crate_id(Vector2i(3, 2)) == 0 and game.level.crystal_colors[0] == "blue", "blue crystal at (3,2)")
	_check(game.crate_id(Vector2i(7, 0)) == 1 and game.level.crystal_colors[1] == "purple", "purple crystal at (7,0)")
	_check(game.level.exit_cell == Vector2i(9, 1) and game.level.objective == "player_on_exit", "yellow exit at (9,1), hero entry wins")
	_check(game.level.targets.is_empty(), "no crystal placement targets")
	for y in 3:
		for x in 11:
			var cell := Vector2i(x, y)
			_check(game.level.is_floor(cell) == (cell not in WALLS), "exact terrain at %s" % str(cell))
	for cell in [Vector2i(-1, 1), Vector2i(11, 1), Vector2i(1, -1), Vector2i(1, 3)]:
		_check(not game.level.is_floor(cell), "outside confirmed rectangle is not floor")


func _test_walls_and_bounds() -> void:
	var game := _game()
	game.try_move(Vector2i.RIGHT)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"wall" and game.snapshot() == before, "left middle wall blocks")
	game.try_move(Vector2i.UP)
	before = game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"wall" and game.snapshot() == before, "left top wall blocks")
	game.restart()
	game.try_move(Vector2i.LEFT)
	before = game.snapshot()
	_check(game.try_move(Vector2i.LEFT) == &"wall" and game.snapshot() == before, "open-looking outer left edge blocks")
	game.try_move(Vector2i.UP)
	_check(game.try_move(Vector2i.UP) == &"wall", "upper outer edge blocks")
	game.restart()
	game.try_move(Vector2i.DOWN)
	_check(game.try_move(Vector2i.DOWN) == &"wall", "lower outer edge blocks")


func _test_blue_blocked() -> void:
	var game := _game()
	for direction in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT]:
		game.try_move(direction)
	_check(game.player == Vector2i(5, 2) and game.crate_id(Vector2i(6, 2)) == 0, "blue pushed along bottom passage")
	var before := game.snapshot()
	var depth := game.history_size()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked", "blue cannot enter right bottom wall")
	_check(game.snapshot() == before and game.history_size() == depth, "blocked blue push has no state/history effect")
	game.try_move(Vector2i.LEFT)
	_check(game.crate_id(Vector2i(6, 2)) == 0, "walking away does not pull blue")


func _test_purple_blocked() -> void:
	var game := _game()
	for i in 8:
		game.try_move(SOLUTION[i])
	_check(game.player == Vector2i(6, 0), "hero reaches purple side of top passage")
	for i in 3:
		_check(game.try_move(Vector2i.RIGHT) == &"pushed", "purple can be pushed one cell at a time")
	_check(game.crate_id(Vector2i(10, 0)) == 1, "purple retains identity at far right edge")
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked" and game.snapshot() == before, "purple cannot be pushed outside rectangle")
	_check(game.try_move(Vector2i.DOWN) == &"moved" and game.is_complete(), "hero entering yellow exit wins while crystals are elsewhere")


func _test_solution_undo_restart() -> void:
	var game := _game()
	var initial := game.snapshot()
	var expected := [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2),
		Vector2i(4, 1), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0),
		Vector2i(7, 0), Vector2i(8, 0), Vector2i(8, 1), Vector2i(9, 1)]
	var pushed_ids: Dictionary = {}
	for i in SOLUTION.size():
		var identity := game.crate_id(game.player + SOLUTION[i])
		var result := game.try_move(SOLUTION[i])
		_check(result in [&"moved", &"pushed"], "confirmed solution step %d succeeds" % (i + 1))
		if result == &"pushed":
			pushed_ids[identity] = true
		_check(game.player == expected[i], "confirmed hero path step %d" % (i + 1))
		_check(game.is_complete() == (i == 11), "victory only on final hero entry")
	_check(pushed_ids.size() == 2 and pushed_ids.has(0) and pushed_ids.has(1), "both crystals actually participate in solution")
	_check(game.moves == 12 and game.pushes == 4, "documented 12-move / 4-push solution")
	_check(game.crate_id(Vector2i(5, 2)) == 0 and game.crate_id(Vector2i(9, 0)) == 1, "final blue/purple positions")
	var solved := game.snapshot()
	_check(game.try_move(Vector2i.UP) == &"complete" and game.snapshot() == solved, "completed level does not accept more movement")
	_check(game.undo() and game.player == Vector2i(8, 1) and not game.is_complete(), "undo after victory returns before exit")
	for i in 11:
		_check(game.undo(), "remaining solution moves undo")
	_check(game.snapshot() == initial and game.history_size() == 0, "full solution reverses to exact initial state")
	for direction in SOLUTION:
		game.try_move(direction)
	game.restart()
	_check(game.snapshot() == initial and not game.is_complete() and not game.undo(), "restart after victory resets crystals, hero, counters, completion and history")


func _test_continuous_commands() -> void:
	var game := _game()
	var input := Steps.new()
	var keys := [KEY_S, KEY_D, KEY_D, KEY_D, KEY_W, KEY_W, KEY_D, KEY_D, KEY_D, KEY_D, KEY_S, KEY_D]
	for key in keys:
		var command := input.command_for_event(_key(key))
		_check(not command.is_empty(), "fresh rapid press is accepted")
		game.try_move(command["direction"])
		var before := game.snapshot()
		for i in 8:
			_check(input.command_for_event(_key(key, true, true)).is_empty(), "echo does not enqueue another step")
			_check(input.command_for_event(_key(key)).is_empty(), "held-key duplicate does not enqueue another step")
		_check(game.snapshot() == before, "held input leaves grid unchanged")
		input.command_for_event(_key(key, false))
	_check(game.is_complete() and game.moves == 12 and game.pushes == 4, "rapid press/release solution has no missing or repeated steps")


func _game() -> State:
	var level := Level.from_file("res://levels/north_01.json")
	_check(level.error.is_empty(), "confirmed map validates: " + level.error)
	var game := State.new()
	_check(game.load_level(level), "confirmed map loads")
	return game


func _key(code: int, pressed: bool = true, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	event.echo = echo
	return event


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
