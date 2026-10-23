extends SceneTree
## Confirmed sixth map; reuse green pull and single-plate core unchanged.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const DIRECTIONS := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
const BLUE := [Vector2i(4, 0), Vector2i(9, 1), Vector2i(6, 2), Vector2i(3, 4)]
const PURPLE := [Vector2i(3, 1), Vector2i(2, 4), Vector2i(9, 6)]
const PLATE := Vector2i(9, 5)
const GATE := Vector2i(7, 6)
var checks := 0
var failures := 0


func _init() -> void:
	var cases := [_test_map, _test_solution, _test_close_and_blocked_pull, _test_switch]
	for test: Callable in cases:
		var before := failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("NORTH 06 RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_map() -> void:
	var game := _game()
	_check(game.level.width == 11 and game.level.height == 7 and game.level.hero_kind == "green" and game.player == Vector2i(0, 1), "confirmed sixth green hero and rectangle")
	var walls: Array[Vector2i] = [Vector2i(3, 0), Vector2i(7, 0), Vector2i(3, 2), Vector2i(7, 1), Vector2i(3, 5), Vector2i(3, 6), Vector2i(7, 4), Vector2i(7, 5)]
	for x in 11:
		if x != 9:
			walls.append(Vector2i(x, 3))
	for y in 7:
		for x in 11:
			_check(game.level.is_floor(Vector2i(x, y)) == (Vector2i(x, y) not in walls), "all 77 confirmed terrain cells")
	for cell in [Vector2i(-1, 0), Vector2i(11, 0), Vector2i(0, -1), Vector2i(0, 7)]:
		_check(not game.is_walkable(cell), "outside blocked")
	_check(game.crates().size() == 7, "exact seven crystals")
	for index in BLUE.size():
		_check(game.crate_id(BLUE[index]) == index and game.level.crystal_colors[index] == "blue", "all four blue coordinates and identities")
	for index in PURPLE.size():
		_check(game.crate_id(PURPLE[index]) == index + 4 and game.level.crystal_colors[index + 4] == "purple", "all three purple coordinates and identities")
	_check(game.level.exit_cell == Vector2i(1, 5) and game.level.exit_color == "green", "confirmed lower-left green destination")
	_check(game.level.bushes.is_empty() and game.level.energy_links.size() == 1 and game.level.energy_links[0]["plates"] == [PLATE] and game.barrier_states().size() == 1, "one plate, one energy cell and no invented bushes")
	_check(game.barrier_is_active(GATE) and not game.is_walkable(GATE) and game.blocks_sight(GATE), "initial energy blocks movement and sight")


func _test_solution() -> void:
	var game := _game()
	var initial := game.snapshot()
	var solution := _solution()
	var history: Array[Dictionary] = []
	var moved: Dictionary = {}
	for index in solution["path"].length():
		var before := game.snapshot()
		history.append(before)
		_check(game.try_move(DIRECTIONS[solution["path"][index]]) in [&"moved", &"pulled"], "sixth legal input %d" % (index + 1))
		_check(game.alive and game.pushes == 0 and game.last_mechanism_error.is_empty() and game.moves == index + 1, "sixth walkthrough remains defined and never pushes")
		_check(game.is_complete() == (index == solution["path"].length() - 1), "only final hero arrival wins")
		for cell: Vector2i in before["crates"]:
			if game.crate_id(cell) != before["crates"][cell]:
				moved[before["crates"][cell]] = true
		if index == 28:
			_check(game.player == PLATE and game.pressure_is_active("yellow_01") and game.is_walkable(GATE) and not game.blocks_sight(GATE), "hero press opens movement and sight")
		if index >= 29:
			_check(game.crate_id(PLATE) == 6 and game.pressure_is_active("yellow_01") and not game.barrier_is_active(GATE), "purple handoff continuously holds pressure while hero leaves")
		if index == 35:
			_check(game.player == GATE, "actual hero crosses open energy cell")
	_check(moved.size() == 7 and game.moves == 65 and game.pulls == 17 and game.pushes == 0 and game.is_complete(), "all seven crystals participate in 65-move / 17-pull victory")
	_check(game.undo() and game.snapshot() == history.pop_back() and not game.is_complete(), "sixth victory undo restores exact preceding mechanism state")
	while not history.is_empty():
		_check(game.undo() and game.snapshot() == history.pop_back(), "each reverse action restores every field")
	_check(game.snapshot() == initial and game.history_size() == 0, "full undo restores closed gate and seven crystals")
	for symbol in solution["path"]:
		game.try_move(DIRECTIONS[symbol])
	_check(game.restart() and game.snapshot() == initial, "sixth victory restart restores full initial state")
	print("NORTH 06 SOLUTION: %s; 65 moves, 17 pulls, 0 pushes" % solution["path"])


func _test_close_and_blocked_pull() -> void:
	var game := _game()
	var solution := _solution()
	for index in 29:
		game.try_move(DIRECTIONS[solution["path"][index]])
	var pressed := game.snapshot()
	_check(game.player == PLATE and not game.barrier_is_active(GATE), "real map setup uses hero-held pressure")
	_check(game.try_move(Vector2i.LEFT) == &"moved" and game.barrier_is_active(GATE) and game.blocks_sight(GATE), "leaving real plate restores movement and sight blocking")
	game.try_move(Vector2i.DOWN)
	var before := game.snapshot()
	var depth := game.history_size()
	_check(game.player == Vector2i(8, 6) and game.crate_id(Vector2i(9, 6)) == 6, "closed gate is ahead and purple crystal directly behind hero")
	_check(game.try_move(Vector2i.LEFT) == &"energy_blocked" and game.snapshot() == before and game.history_size() == depth, "closed gate blocks both hero movement and rear automatic pull atomically")
	_check(game.undo() and game.undo() and game.snapshot() == pressed and not game.barrier_is_active(GATE), "two ordinary undos restore exact hero press and open gate")
	_check(game.try_move(Vector2i.UP) == &"pulled" and game.crate_id(PLATE) == 6 and game.alive and not game.barrier_is_active(GATE), "single pull hands off pressure without intermediate restoration")


func _test_switch() -> void:
	var game := _game()
	var initial := game.snapshot()
	game.try_move(Vector2i.RIGHT)
	_check(game.load_level(Level.from_file("res://levels/north_05.json")) and game.barrier_states().is_empty() and game.pressure_states().is_empty() and game.history_size() == 0 and game.pulls == 0, "sixth energy and history do not leak into fifth")
	_check(game.load_level(Level.from_file("res://levels/north_06.json")) and game.snapshot() == initial and game.history_size() == 0, "returning to sixth restores independent initial mechanism state")


func _solution() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_06.json"))


func _game() -> State:
	var definition := Level.from_file("res://levels/north_06.json")
	_check(definition.error.is_empty(), "sixth confirmed data validates")
	var game := State.new()
	_check(game.load_level(definition), "sixth initializes")
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
