extends SceneTree
## Independent mechanism fixtures, not footage or a replacement for level 03.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")

var checks: int = 0
var failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cases: Array[Callable] = [_test_hero_pressure_and_sight, _test_crystal_pressure,
		_test_source_predicate, _test_atomic_handoff, _test_blocked_push,
		_test_death_and_atomic_undo, _test_unknown_crystal_reactivation,
		_test_global_links, _test_data_validation]
	for test in cases:
		var previous := failures
		test.call()
		print("%s %s" % ["PASS" if previous == failures else "FAIL", test.get_method()])
	print("ENERGY RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_hero_pressure_and_sight() -> void:
	var data := _data()
	data["energy_links"][0]["barriers"] = [[3, 1], [4, 1]]
	var game := _game(data)
	var ray: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)]
	_check(not game.pressure_is_active("yellow") and game.barrier_is_active(Vector2i(3, 1)), "initial unpressed plate keeps energy active")
	_check(not game.is_walkable(Vector2i(3, 1)) and game.blocks_sight(Vector2i(3, 1)) and not game.sight_path_is_clear(ray), "active energy blocks movement and sight")
	game.try_move(Vector2i.RIGHT)
	_check(game.pressure_is_active("yellow") and not game.barrier_is_active(Vector2i(3, 1)) and not game.barrier_is_active(Vector2i(4, 1)), "hero press removes every linked block")
	_check(game.is_walkable(Vector2i(3, 1)) and not game.blocks_sight(Vector2i(3, 1)) and game.sight_path_is_clear(ray), "inactive energy blocks neither movement nor sight")
	var held := game.snapshot()
	_check(game.snapshot() == held, "pressure remains held without an action")
	game.try_move(Vector2i.RIGHT)
	_check(not game.pressure_is_active("yellow") and game.barrier_is_active(Vector2i(3, 1)) and game.blocks_sight(Vector2i(3, 1)), "leaving plate restores energy and sight blocking")
	var blocked := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"energy_blocked" and game.snapshot() == blocked and game.history_size() == 2, "active energy rejects movement without a history entry")
	_check(game.undo() and game.snapshot() == held, "undo restores pressure and all linked blocks atomically")
	_check(game.blocks_sight(Vector2i(-1, 1)), "outside level blocks sight")


func _test_crystal_pressure() -> void:
	var data := _data()
	data["crates"] = [[1, 1]]
	var game := _game(data)
	_check(game.pressure_is_active("yellow") and not game.barrier_is_active(Vector2i(3, 1)), "crystal alone can hold plate")
	game.try_move(Vector2i.UP)
	game.try_move(Vector2i.RIGHT)
	_check(game.pressure_is_active("yellow"), "crystal pressure persists while hero walks elsewhere")
	data["energy_links"][0]["pressure_sources"] = ["crystal"]
	game = _game(data)
	game.try_move(Vector2i.RIGHT)
	_check(not game.pressure_is_active("yellow") and game.barrier_is_active(Vector2i(3, 1)), "configured crystal-only predicate releases when crystal leaves, even with hero on plate")


func _test_source_predicate() -> void:
	var data := _data()
	data["player"] = [1, 1]
	data["energy_links"][0]["pressure_sources"] = ["crystal"]
	var game := _game(data)
	_check(not game.pressure_is_active("yellow"), "hero excluded by explicit source configuration")
	data["player"] = [0, 1]
	data["crates"] = [[1, 1]]
	data["energy_links"][0]["pressure_sources"] = ["hero"]
	game = _game(data)
	_check(not game.pressure_is_active("yellow"), "crystal excluded by explicit source configuration")
	data["energy_links"][0]["pressure_sources"] = ["hero", "crystal"]
	game = _game(data)
	_check(game.pressure_is_active("yellow"), "confirmed either-object predicate")


func _test_atomic_handoff() -> void:
	var data := _data()
	data["player"] = [1, 1]
	data["crates"] = [[2, 1]]
	data["energy_links"][0]["plate"] = [2, 1]
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"pushed", "crystal can enter an inactive energy cell")
	_check(game.player == Vector2i(2, 1) and game.crate_id(Vector2i(3, 1)) == 0 and game.alive, "hero replaces crystal on plate in same action")
	_check(game.pressure_is_active("yellow") and not game.barrier_is_active(Vector2i(3, 1)), "handoff has no intermediate release or death")
	_check(game.history_size() == 1 and game.undo() and game.snapshot() == initial, "handoff undo includes every mechanism state")


func _test_blocked_push() -> void:
	var data := _data()
	data["energy_links"][0]["plate"] = [0, 0]
	data["crates"] = [[1, 1], [2, 1]]
	var game := _game(data)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked" and game.snapshot() == before and game.history_size() == 0, "active energy blocks an entire crystal line")


func _test_death_and_atomic_undo() -> void:
	var data := _data()
	data["player"] = [1, 1]
	data["crates"] = [[2, 1]]
	data["energy_links"][0]["barriers"] = [[2, 1]]
	data["exit"] = [2, 1]
	data["objective"] = "player_on_exit"
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"died", "leaving plate while entering restored barrier kills hero")
	_check(not game.alive and game.player == Vector2i(2, 1) and game.crate_id(Vector2i(3, 1)) == 0, "push and death resolve in one action")
	_check(not game.pressure_is_active("yellow") and game.barrier_is_active(Vector2i(2, 1)) and game.blocks_sight(Vector2i(2, 1)), "death state keeps restored barrier")
	_check(game.moves == 1 and game.pushes == 1 and game.history_size() == 1 and not game.is_complete(), "death takes precedence over exit victory")
	var dead := game.snapshot()
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_check(game.try_move(direction) == &"dead" and game.snapshot() == dead, "dead hero cannot act or revive automatically")
	_check(not game.restart() and game.snapshot() == dead, "restart cannot revive dead hero")
	_check(not game.load_level(Level.from_dictionary(_data())) and game.snapshot() == dead, "switching cannot bypass death")
	_check(game.undo() and game.snapshot() == initial and game.alive, "one undo revives hero and restores crystal, plate, barrier and counters")
	_check(not game.undo() and game.restart() and game.snapshot() == initial, "revived session restarts normally")
	_check(game.try_move(Vector2i.RIGHT) == &"died", "repeated action has deterministic death")


func _test_unknown_crystal_reactivation() -> void:
	var data := _data()
	data["player"] = [1, 1]
	data["crates"] = [[2, 1]]
	data["energy_links"][0]["plate"] = [2, 1]
	var game := _game(data)
	game.try_move(Vector2i.RIGHT)
	var before := game.snapshot()
	var depth := game.history_size()
	_check(game.try_move(Vector2i.UP) == &"rule_unresolved", "unconfirmed restoration on crystal is explicitly reported")
	_check(not game.last_mechanism_error.is_empty() and game.snapshot() == before and game.history_size() == depth, "undefined consequence commits no partial occupancy or pressure")
	_check(game.crate_id(Vector2i(3, 1)) == 0, "unconfirmed rule never destroys crystal")
	_check(game.undo() and game.alive, "last valid step remains undoable")


func _test_global_links() -> void:
	var data := _data()
	data["energy_links"].append({"id": "other", "plate": [1, 0], "barriers": [[4, 1]], "pressure_sources": ["hero", "crystal"]})
	var game := _game(data)
	game.try_move(Vector2i.RIGHT)
	_check(game.pressure_is_active("yellow") and not game.pressure_is_active("other"), "local pressure reports individual occupied plates")
	_check(game.barrier_is_active(Vector2i(3, 1)) and game.barrier_is_active(Vector2i(4, 1)), "one occupied group cannot open any yellow barrier")
	var first := game.snapshot()
	game.try_move(Vector2i.UP)
	_check(not game.pressure_is_active("yellow") and game.pressure_is_active("other"), "post-action occupancy settles all links together")
	_check(game.barrier_is_active(Vector2i(3, 1)) and game.barrier_is_active(Vector2i(4, 1)), "different occupied group still cannot open either barrier")
	_check(game.undo() and game.snapshot() == first, "multi-link undo is complete")
	var exposed := game.snapshot()
	exposed["pressure"].clear()
	exposed["barriers"].clear()
	_check(game.snapshot() == first, "external snapshot cannot mutate mechanism state")
	data["crates"] = [[1, 1]]
	game = _game(data)
	game.try_move(Vector2i.UP)
	game.try_move(Vector2i.RIGHT)
	var all_held := game.snapshot()
	_check(game.pressure_is_active("yellow") and game.pressure_is_active("other") and not game.barrier_is_active(Vector2i(3, 1)) and not game.barrier_is_active(Vector2i(4, 1)), "all yellow plates across IDs open every barrier together")
	game.try_move(Vector2i.LEFT)
	_check(game.barrier_is_active(Vector2i(3, 1)) and game.barrier_is_active(Vector2i(4, 1)), "releasing any group restores every yellow barrier")
	_check(game.undo() and game.snapshot() == all_held, "undo restores global all-open state atomically")


func _test_data_validation() -> void:
	for field in ["plate", "barriers", "pressure_sources", "id"]:
		var data := _data()
		data["energy_links"][0].erase(field)
		_check(not Level.from_dictionary(data).error.is_empty(), "missing mechanism field rejected: " + field)
	for sources in [[], ["hero", "hero"], ["unknown"]]:
		var data := _data()
		data["energy_links"][0]["pressure_sources"] = sources
		_check(not Level.from_dictionary(data).error.is_empty(), "invalid pressure sources rejected")
	var data := _data()
	data["energy_links"][0]["barriers"] = [[1, 1]]
	_check(not Level.from_dictionary(data).error.is_empty(), "plate and barrier overlap rejected")
	data = _data()
	data["energy_links"].append(data["energy_links"][0].duplicate(true))
	_check(not Level.from_dictionary(data).error.is_empty(), "duplicate link rejected")
	var game := _game(_data())
	var before := game.snapshot()
	data = _data()
	data["player"] = [3, 1]
	_check(not game.load_level(Level.from_dictionary(data)) and game.snapshot() == before, "initial dead spawn cannot replace session")
	data = _data()
	data["crates"] = [[3, 1]]
	_check(not game.load_level(Level.from_dictionary(data)) and game.snapshot() == before, "initial active-barrier crystal ambiguity is not guessed")


func _data() -> Dictionary:
	return {"schema_version": 1, "id": "energy_fixture", "title": "Mechanism regression fixture",
		"is_temporary": true, "source_note": "Independent mechanics tests only",
		"terrain": [".....", ".....", "....."], "player": [0, 1], "crates": [], "targets": [], "objective": "none",
		"energy_links": [{"id": "yellow", "plate": [1, 1], "barriers": [[3, 1]], "pressure_sources": ["hero", "crystal"]}]}


func _game(data: Dictionary) -> State:
	var level := Level.from_dictionary(data)
	_check(level.error.is_empty(), "energy fixture validates: " + level.error)
	var game := State.new()
	_check(game.load_level(level), "energy fixture loads: " + game.last_mechanism_error)
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
