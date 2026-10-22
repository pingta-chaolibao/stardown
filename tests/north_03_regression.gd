extends SceneTree
## Confirmed level 03 plus exhaustive legal-state check of the unknown crystal edge.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const DIRECTIONS := {"R": Vector2i.RIGHT, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "U": Vector2i.UP}
const WALLS := [Vector2i(3, 0), Vector2i(3, 2), Vector2i(7, 0), Vector2i(7, 1)]
const BARRIER := Vector2i(7, 2)

var checks: int = 0
var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases: Array[Callable] = [_test_grid, _test_solution_and_atomic_history, _test_unknown_edge_unreachable]
	for test in cases:
		var previous := failures
		test.call()
		print("%s %s" % ["PASS" if previous == failures else "FAIL", test.get_method()])
	print("NORTH 03 RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_grid() -> void:
	var game := _game()
	_check(game.level.width == 11 and game.level.height == 3 and game.player == Vector2i(0, 1), "confirmed rectangle and hero")
	_check(game.crates().size() == 1 and game.crate_id(Vector2i(5, 1)) == 0 and game.level.crystal_colors[0] == "purple", "confirmed purple crystal")
	_check(game.level.exit_cell == Vector2i(9, 1) and game.level.exit_color == "green", "confirmed green destination")
	for y in 3:
		for x in 11:
			_check(game.level.is_floor(Vector2i(x, y)) == (Vector2i(x, y) not in WALLS), "confirmed fixed terrain at (%d,%d)" % [x, y])
	_check(game.level.energy_links.size() == 1 and game.level.energy_links[0]["plate"] == Vector2i(1, 1), "yellow plate and linkage")
	_check(game.level.energy_links[0]["pressure_sources"] == ["hero", "crystal"], "both confirmed pressure sources")
	_check(game.barrier_is_active(BARRIER) and not game.is_walkable(BARRIER) and game.blocks_sight(BARRIER), "initial energy blocks movement and sight")


func _test_solution_and_atomic_history() -> void:
	var game := _game()
	var initial := game.snapshot()
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_03.json"))
	var snapshots: Array[Dictionary] = []
	for i in solution["path"].length():
		snapshots.append(game.snapshot())
		_check(game.try_move(DIRECTIONS[solution["path"][i]]) in [&"moved", &"pushed"], "legal third-level input %d" % (i + 1))
		_check(game.alive and game.last_mechanism_error.is_empty(), "normal walkthrough has no death or unresolved consequence")
		_check(game.is_complete() == (i == solution["path"].length() - 1), "only final green destination wins")
		if i == 0:
			_check(game.pressure_is_active("yellow_01") and not game.barrier_is_active(BARRIER) and not game.blocks_sight(BARRIER), "hero press opens energy and sight")
		if i == 1:
			_check(not game.pressure_is_active("yellow_01") and game.barrier_is_active(BARRIER) and game.blocks_sight(BARRIER), "hero release restores energy and sight")
		if i >= 11:
			_check(game.crate_id(Vector2i(1, 1)) == 0 and game.pressure_is_active("yellow_01") and not game.barrier_is_active(BARRIER), "crystal holds pressure while hero crosses")
	_check(game.player == Vector2i(9, 1) and game.moves == 21 and game.pushes == 4 and game.is_complete(), "verified 21 moves / 4 pushes victory")
	_check(game.undo() and game.snapshot() == snapshots.back() and not game.is_complete(), "victory undo restores full mechanism state")
	for i in range(snapshots.size() - 2, -1, -1):
		_check(game.undo() and game.snapshot() == snapshots[i], "reverse each whole action")
	_check(game.snapshot() == initial and game.history_size() == 0, "full history returns initial energy and occupancy")
	for symbol in solution["path"]:
		game.try_move(DIRECTIONS[symbol])
	_check(game.restart() and game.snapshot() == initial, "restart after living victory resets whole level")
	print("NORTH 03 SOLUTION: %s; 21 moves, 4 pushes" % solution["path"])


func _test_unknown_edge_unreachable() -> void:
	# FIFO paths give the shortest triggering sequence if an undefined edge is reachable.
	# Every node is reached by replaying legal inputs from the real initial state.
	var definition := Level.from_file("res://levels/north_03.json")
	var initial := _game()
	var paths: Array[String] = [""]
	var visited: Dictionary = {_key(initial): true}
	var head := 0
	var crystal_on_barrier := false
	var unknown_path := ""
	while head < paths.size():
		var path := paths[head]
		head += 1
		var game := State.new()
		game.load_level(definition)
		for symbol in path:
			game.try_move(DIRECTIONS[symbol])
		crystal_on_barrier = crystal_on_barrier or game.crate_id(BARRIER) >= 0
		for symbol in DIRECTIONS:
			var before := game.snapshot()
			var result := game.try_move(DIRECTIONS[symbol])
			if result == &"rule_unresolved":
				unknown_path = path + symbol
				break
			if result in [&"moved", &"pushed", &"died"]:
				var key := _key(game)
				if not visited.has(key):
					visited[key] = true
					paths.append(path + symbol)
				_check(game.undo() and game.snapshot() == before, "search undo restores actual predecessor")
		if not unknown_path.is_empty():
			break
	_check(unknown_path.is_empty(), "undefined crystal restoration unreachable; shortest trigger if found: " + unknown_path)
	_check(not crystal_on_barrier, "crystal never legally enters this level's energy cell")
	print("NORTH 03 REACHABILITY: %d legal states exhausted; crystal-on-barrier=%s; undefined-trigger=%s" % [visited.size(), crystal_on_barrier, unknown_path])


func _key(game: State) -> String:
	# Move/push counters and undo depth do not affect legal future transitions.
	return "%s|%s|%s|%s|%s" % [str(game.player), str(game.crates()[0]), game.alive, game.pressure_is_active("yellow_01"), game.barrier_is_active(BARRIER)]


func _game() -> State:
	var definition := Level.from_file("res://levels/north_03.json")
	_check(definition.error.is_empty(), "third map validates")
	var game := State.new()
	_check(game.load_level(definition), "third map initializes live and resolved")
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
