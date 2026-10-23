extends SceneTree
## Replay the confirmed second-level grid through the actual Godot model.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const ROWS := ["...#...#...", "R..VB....BV", "...#...#...", "#########V#",
	"...#...#...", ".GB..VBVV..", "...#...#..."]
const BLUE := [Vector2i(4, 1), Vector2i(9, 1), Vector2i(2, 5), Vector2i(6, 5)]
const PURPLE := [Vector2i(3, 1), Vector2i(10, 1), Vector2i(9, 3), Vector2i(5, 5), Vector2i(7, 5), Vector2i(8, 5)]
const DIRECTIONS := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}

var checks: int = 0
var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases: Array[Callable] = [_test_grid_and_ten_crystals, _test_blocked_line,
		_test_confirmed_right_cells, _test_solution_undo_restart, _test_exit_color_data]
	for test in cases:
		var previous := failures
		test.call()
		print("%s %s" % ["PASS" if previous == failures else "FAIL", test.get_method()])
	print("NORTH 02 RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_grid_and_ten_crystals() -> void:
	var game := _game()
	_check(game.level.width == 11 and game.level.height == 7, "11 by 7 grid")
	_check(game.player == Vector2i(0, 1) and not game.level.is_temporary, "confirmed red player start")
	_check(game.level.exit_cell == Vector2i(1, 5) and game.level.exit_color == "green", "green exit is not another hero")
	_check(game.level.objective == "player_on_exit" and game.level.targets.is_empty(), "hero entry, no crystal-placement target")
	for y in 7:
		for x in 11:
			_check(game.level.is_floor(Vector2i(x, y)) == (ROWS[y][x] != "#"), "exact confirmed terrain at (%d,%d)" % [x, y])
	_check(game.crates().size() == 10, "exactly ten crystals")
	for i in BLUE.size():
		_check(game.crate_id(BLUE[i]) == i and game.level.crystal_colors[i] == "blue", "initial blue position and identity")
	for i in PURPLE.size():
		_check(game.crate_id(PURPLE[i]) == i + 4 and game.level.crystal_colors[i + 4] == "purple", "initial purple position and identity")
	for cell in [Vector2i(-1, 1), Vector2i(11, 1), Vector2i(1, -1), Vector2i(1, 7)]:
		_check(not game.level.is_floor(cell), "outer rectangle blocks")


func _test_blocked_line() -> void:
	var game := _game()
	var before_last: Dictionary
	for i in 6:
		before_last = game.snapshot()
		_check(game.try_move(Vector2i.RIGHT) in [&"moved", &"pushed"], "reach upper right blocked line")
	_check(game.player == Vector2i(6, 1), "hero before four-crystal line")
	_check(game.crate_id(Vector2i(7, 1)) == 4 and game.crate_id(Vector2i(8, 1)) == 0 and game.crate_id(Vector2i(9, 1)) == 1 and game.crate_id(Vector2i(10, 1)) == 5, "four contiguous upper crystals retain identities")
	var blocked := game.snapshot()
	var depth := game.history_size()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked", "four-crystal line blocked by boundary")
	_check(game.snapshot() == blocked and game.history_size() == depth, "blocked line is atomic")
	_check(game.undo() and game.snapshot() == before_last, "blocked input adds no history; undo restores preceding whole-line push")


func _test_confirmed_right_cells() -> void:
	var game := _game()
	var solution := _solution()
	for i in 13:
		game.try_move(DIRECTIONS[solution["path"][i]])
	_check(game.player == Vector2i(9, 3), "hero reaches connecting bridge")
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"wall" and game.snapshot() == before, "confirmed (10,3) is an impassable wall")
	game.try_move(Vector2i.UP)
	_check(game.try_move(Vector2i.RIGHT) == &"moved" and game.player == Vector2i(10, 2), "confirmed (10,2) is walkable")


func _test_solution_undo_restart() -> void:
	var game := _game()
	var initial := game.snapshot()
	var solution := _solution()
	var snapshots: Array[Dictionary] = []
	var max_line := 0
	for i in solution["path"].length():
		var before := game.snapshot()
		snapshots.append(before)
		var result := game.try_move(DIRECTIONS[solution["path"][i]])
		_check(result in [&"moved", &"pushed"], "legal solution input %d" % (i + 1))
		_check(game.moves == i + 1 and game.crates().size() == 10, "one legal step preserves all ten crystals")
		_check(game.is_complete() == (i == solution["path"].length() - 1), "only final hero entry wins")
		var moved := 0
		for cell in before["crates"]:
			if game.crate_id(cell) != before["crates"][cell]:
				moved += 1
		max_line = maxi(max_line, moved)
		if i == 22:
			_check(game.crate_id(game.level.exit_cell) == 2 and not game.is_complete(), "blue crystal on green exit does not win")
		if i == 23:
			_check(game.crate_id(game.level.exit_cell) == 7 and not game.is_complete(), "purple crystal on green exit does not win")
	_check(game.player == Vector2i(1, 5) and game.is_complete(), "actual player reaches green exit")
	_check(game.moves == solution["moves"] and game.pushes == solution["pushes"], "verified 27 moves and 12 push actions")
	_check(max_line == 3, "solution actually uses whole-line pushing")
	var solved := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"complete" and game.snapshot() == solved, "victory freezes movement")
	_check(game.undo() and game.snapshot() == snapshots.back() and not game.is_complete(), "undo after victory restores preceding grid and counters")
	for i in range(snapshots.size() - 2, -1, -1):
		_check(game.undo() and game.snapshot() == snapshots[i], "reverse every solution action exactly")
	_check(game.snapshot() == initial and game.history_size() == 0, "full undo returns initial ten-crystal state")
	for symbol in solution["path"]:
		game.try_move(DIRECTIONS[symbol])
	game.restart()
	_check(game.snapshot() == initial and not game.is_complete() and not game.undo(), "restart after victory restores whole second level")
	print("NORTH 02 SOLUTION: %s; %d moves, %d pushes" % [solution["path"], solution["moves"], solution["pushes"]])


func _test_exit_color_data() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_02.json"))
	for invalid in ["cyan", true, ""]:
		data["exit_color"] = invalid
		_check(not Level.from_dictionary(data).error.is_empty(), "invalid exit color is rejected")


func _game() -> State:
	var level := Level.from_file("res://levels/north_02.json")
	_check(level.error.is_empty(), "second-level data validates: " + level.error)
	var game := State.new()
	_check(game.load_level(level), "second-level data loads")
	return game


func _solution() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_02.json"))
	_check(data["level_id"] == "north_hero_02" and data["moves"] == 27 and data["pushes"] == 12, "checked solution metadata")
	return data


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
