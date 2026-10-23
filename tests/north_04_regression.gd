extends SceneTree
## The confirmed 7x6 fourth level, with no substitutions to make the route work.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const DIRECTIONS := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
const WALLS := [Vector2i(5, 0), Vector2i(5, 1)]
const BUSHES := [Vector2i(3, 3), Vector2i(0, 4)]
const PLATES := [Vector2i(1, 4), Vector2i(3, 4), Vector2i(5, 4)]
const GATE := Vector2i(6, 1)
var checks := 0
var failures := 0


func _init() -> void:
	var cases := [_test_confirmed_grid, _test_actual_solution, _test_bush_obstruction, _test_switch_isolation]
	for test: Callable in cases:
		var before := failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("NORTH 04 RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_confirmed_grid() -> void:
	var game := _game()
	_check(game.level.width == 7 and game.level.height == 6 and game.player == Vector2i(1, 1), "confirmed full rectangle and hero")
	for y in 6:
		for x in 7:
			_check(game.level.is_floor(Vector2i(x, y)) == (Vector2i(x, y) not in WALLS), "confirmed terrain (%d,%d)" % [x, y])
	for cell in [Vector2i(-1, 0), Vector2i(7, 0), Vector2i(0, -1), Vector2i(0, 6)]:
		_check(not game.is_walkable(cell), "outer boundary is blocked")
	_check(game.crates().size() == 3 and game.crate_id(Vector2i(2, 1)) == 0 and game.crate_id(Vector2i(1, 2)) == 1 and game.crate_id(Vector2i(2, 2)) == 2, "all three initial crystal identities")
	_check(game.level.bushes.size() == 2, "two separate bush objects")
	for cell in BUSHES:
		var bush = game.level.bush_at(cell)
		_check(bush != null and not bush.MOVABLE and not bush.EXCHANGEABLE and not game.is_walkable(cell) and game.blocks_sight(cell), "confirmed immovable, nonexchangeable, obstructing bush")
	_check(game.level.energy_links.size() == 1 and game.level.energy_links[0]["plates"] == PLATES and game.pressure_progress("yellow_01") == Vector2i(0, 3), "exact three-plate AND group")
	_check(game.barrier_is_active(GATE) and game.blocks_sight(GATE) and game.level.exit_cell == Vector2i(6, 0), "exit above separate active gate")


func _test_actual_solution() -> void:
	var game := _game()
	var initial := game.snapshot()
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_04.json"))
	var snapshots: Array[Dictionary] = []
	var opened := false
	for index in solution["path"].length():
		snapshots.append(game.snapshot())
		_check(game.try_move(DIRECTIONS[solution["path"][index]]) in [&"moved", &"pushed"], "legal fourth-level input %d" % (index + 1))
		_check(game.alive and game.last_mechanism_error.is_empty(), "walkthrough remains alive and uses defined rules")
		var all_pressed := game.pressure_progress("yellow_01").x == 3
		_check(game.pressure_is_active("yellow_01") == all_pressed and game.barrier_is_active(GATE) == not all_pressed and game.blocks_sight(GATE) == not all_pressed, "all three plates alone control movement and sight")
		_check(game.is_complete() == (index == solution["path"].length() - 1), "only final hero arrival at destination wins")
		_check(game.player not in BUSHES, "hero never enters bush")
		for cell in game.crates():
			_check(cell not in BUSHES, "crystal never enters bush")
		if game.player == GATE:
			_check(all_pressed, "actual crossing requires three plates held")
		opened = opened or all_pressed
	_check(opened and game.is_complete() and game.moves == solution["moves"] and game.pushes == solution["pushes"] and game.player == Vector2i(6, 0), "34 moves / 13 pushes reach actual exit")
	for cell in PLATES:
		_check(game.crate_id(cell) >= 0, "three crystals hold every plate at victory")
	_check(game.undo() and game.snapshot() == snapshots.back() and not game.is_complete(), "victory undo restores whole preceding state")
	for index in range(snapshots.size() - 2, -1, -1):
		_check(game.undo() and game.snapshot() == snapshots[index], "every reverse action is atomic")
	_check(game.snapshot() == initial and game.history_size() == 0, "full undo restores closed gate and initial objects")
	_walk(game, solution["path"])
	_check(game.restart() and game.snapshot() == initial, "victory restart restores actors, pressure and energy")
	print("NORTH 04 SOLUTION: %s; %d moves, %d pushes" % [solution["path"], solution["moves"], solution["pushes"]])


func _test_bush_obstruction() -> void:
	var game := _game()
	_walk(game, "URRDD")
	var before := game.snapshot()
	var depth := game.history_size()
	_check(game.try_move(Vector2i.DOWN) == &"bush_blocked" and game.snapshot() == before and game.history_size() == depth, "upper route meets bush (3,3)")
	game.restart()
	_walk(game, "ULDDD")
	before = game.snapshot()
	_check(game.try_move(Vector2i.DOWN) == &"bush_blocked" and game.snapshot() == before, "lower-left bush blocks hero")
	game.restart()
	_walk(game, "RDLD")
	before = game.snapshot()
	depth = game.history_size()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked" and game.snapshot() == before and game.history_size() == depth, "real crystal cannot be pushed into (3,3) bush")


func _test_switch_isolation() -> void:
	var game := _game()
	var initial := game.snapshot()
	_walk(game, "RDD")
	_check(game.load_level(Level.from_file("res://levels/north_03.json")) and game.level.bushes.is_empty() and game.pressure_progress("yellow_01") == Vector2i(0, 1) and game.history_size() == 0, "fourth bushes and three-plate state do not leak into third")
	_check(game.load_level(Level.from_file("res://levels/north_04.json")) and game.snapshot() == initial and game.history_size() == 0, "returning to fourth restores independent initial state")


func _walk(game: State, path: String) -> void:
	for symbol in path:
		_check(game.try_move(DIRECTIONS[symbol]) in [&"moved", &"pushed"], "setup uses legal input " + symbol)


func _game() -> State:
	var definition := Level.from_file("res://levels/north_04.json")
	_check(definition.error.is_empty(), "confirmed fourth map validates")
	var game := State.new()
	_check(game.load_level(definition), "fourth map initializes")
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
