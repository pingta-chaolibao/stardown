extends SceneTree
## Independent fixtures for confirmed bushes and all-plates pressure groups.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
var checks := 0
var failures := 0


func _init() -> void:
	var cases := [_test_bush, _test_blocked_chain, _test_bush_history, _test_all_combinations,
		_test_mixed_pressure_and_release, _test_handoff, _test_group_death, _test_invalid_data]
	for test: Callable in cases:
		var before := failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("BUSH GROUP RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_bush() -> void:
	var data := _data()
	data["bushes"] = [[1, 1]]
	var game := _game(data)
	var bush = game.level.bush_at(Vector2i(1, 1))
	_check(bush != null and not bush.MOVABLE and not bush.EXCHANGEABLE, "bush is a distinct immovable, nonexchangeable object")
	_check(game.level.is_floor(bush.cell) and game.crate_id(bush.cell) == -1, "bush is neither wall terrain nor a crystal")
	_check(not game.is_walkable(bush.cell) and game.blocks_sight(bush.cell), "bush blocks hero and sight")
	var ray: Array[Vector2i] = [Vector2i(0, 1), bush.cell, Vector2i(2, 1)]
	_check(not game.sight_path_is_clear(ray), "sight query cannot see through bush")
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"bush_blocked" and game.snapshot() == before and game.history_size() == 0, "bush rejects action without moving or writing history")
	_check(game.level.bush_at(Vector2i(1, 1)) == bush, "bush remains the same static object")


func _test_blocked_chain() -> void:
	for count in [1, 2, 4]:
		var data := _data()
		for x in range(1, count + 1):
			data["crates"].append([x, 1])
		data["bushes"] = [[count + 1, 1]]
		var game := _game(data)
		var before := game.snapshot()
		_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked" and game.snapshot() == before and game.history_size() == 0, "bush atomically blocks %d crystals" % count)
		_check(game.level.bush_at(Vector2i(count + 1, 1)).cell == Vector2i(count + 1, 1), "crystal push never moves bush")


func _test_bush_history() -> void:
	var data := _data()
	data["crates"] = [[1, 1]]
	data["bushes"] = [[3, 1]]
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"pushed", "push into space before bush succeeds")
	var pushed := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"crate_blocked" and game.snapshot() == pushed, "subsequent push into bush fails")
	_check(game.undo() and game.snapshot() == initial and game.level.bush_at(Vector2i(3, 1)) != null, "undo changes actors but preserves static bush")
	game.try_move(Vector2i.RIGHT)
	_check(game.restart() and game.snapshot() == initial, "restart restores actors without converting bush")


func _test_all_combinations() -> void:
	for mask in 8:
		var data := _group_data()
		data["player"] = [0, 0]
		var occupied := 0
		for index in 3:
			if mask & (1 << index):
				data["crates"].append(data["energy_links"][0]["plates"][index])
				occupied += 1
		var game := _game(data)
		_check(game.pressure_is_active("all") == (mask == 7), "AND truth table combination %d" % mask)
		_check(game.barrier_is_active(Vector2i(6, 2)) == (mask != 7) and game.blocks_sight(Vector2i(6, 2)) == (mask != 7), "same group state controls movement and sight")
		_check(game.pressure_progress("all") == Vector2i(occupied, 3), "individual pressure progress remains visible")


func _test_mixed_pressure_and_release() -> void:
	var data := _group_data()
	data["crates"] = [[3, 1], [5, 1]]
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.barrier_is_active(Vector2i(6, 2)), "two of three plates keep barrier active")
	game.try_move(Vector2i.RIGHT)
	var held := game.snapshot()
	_check(game.pressure_is_active("all") and game.pressure_progress("all") == Vector2i(3, 3) and game.is_walkable(Vector2i(6, 2)), "hero and two crystals jointly open all-plates group")
	game.try_move(Vector2i.UP)
	_check(not game.pressure_is_active("all") and game.barrier_is_active(Vector2i(6, 2)), "releasing any one of three restores barrier")
	_check(game.undo() and game.snapshot() == held, "undo restores whole open group")
	_check(game.restart() and game.snapshot() == initial and game.history_size() == 0, "restart restores partially occupied group")


func _test_handoff() -> void:
	var data := _group_data()
	data["crates"] = [[1, 1], [3, 1], [5, 1]]
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"pushed" and game.pressure_is_active("all") and game.alive, "hero replaces crystal on one plate without intermediate release")
	_check(game.pressure_cell_is_active("all", Vector2i(1, 1)) and game.pressure_progress("all") == Vector2i(3, 3), "individual plate and group agree after handoff")
	_check(game.undo() and game.snapshot() == initial, "one undo restores handoff occupancy and all pressure")


func _test_group_death() -> void:
	var data := _group_data()
	data["player"] = [1, 1]
	data["crates"] = [[2, 1], [3, 0], [5, 0]]
	data["energy_links"][0]["plates"] = [[1, 1], [3, 0], [5, 0]]
	data["energy_links"][0]["barriers"] = [[2, 1]]
	var game := _game(data)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"died" and not game.alive and game.pressure_progress("all") == Vector2i(2, 3), "one plate release restores occupied barrier and kills hero")
	var dead := game.snapshot()
	_check(game.try_move(Vector2i.LEFT) == &"dead" and not game.restart() and not game.load_level(Level.from_dictionary(_data())) and game.snapshot() == dead, "dead state cannot move, restart or switch")
	_check(game.undo() and game.alive and game.snapshot() == before and game.history_size() == 0, "one atomic undo revives and restores all three plates and crystals")


func _test_invalid_data() -> void:
	for cell in [[0, 1], [1, 1], [7, 0]]:
		var data := _data()
		data["crates"] = [[1, 1]]
		data["bushes"] = [cell]
		_check(not Level.from_dictionary(data).error.is_empty(), "invalid bush coordinate/actor overlap rejected")
	var duplicate := _data()
	duplicate["bushes"] = [[2, 1], [2, 1]]
	_check(not Level.from_dictionary(duplicate).error.is_empty(), "duplicate bush rejected")
	for key in ["plates", "barriers"]:
		var data := _group_data()
		data["bushes"] = [data["energy_links"][0][key][0]]
		_check(not Level.from_dictionary(data).error.is_empty(), "bush/energy geometry overlap rejected")
	for entries in [[], [[1, 1], [1, 1]], [[-1, 0]]]:
		var data := _group_data()
		data["energy_links"][0]["plates"] = entries
		_check(not Level.from_dictionary(data).error.is_empty(), "invalid pressure group coordinates rejected")
	for mode in ["", "any"]:
		var data := _group_data()
		data["energy_links"][0]["activation"] = mode
		_check(not Level.from_dictionary(data).error.is_empty(), "unconfirmed group mode rejected")
	var mixed := _group_data()
	mixed["energy_links"][0]["plate"] = [1, 1]
	_check(not Level.from_dictionary(mixed).error.is_empty(), "legacy and multiple plate fields cannot be mixed")


func _data() -> Dictionary:
	return {"schema_version": 1, "id": "bush_group_fixture", "title": "Independent bush/group fixture", "is_temporary": true,
		"source_note": "Mechanism testing only, never used as real level footage", "terrain": [".......", ".......", "......."],
		"player": [0, 1], "crates": [], "targets": [], "objective": "none"}


func _group_data() -> Dictionary:
	var data := _data()
	data["energy_links"] = [{"id": "all", "plates": [[1, 1], [3, 1], [5, 1]], "activation": "all",
		"barriers": [[6, 2]], "pressure_sources": ["hero", "crystal"]}]
	return data


func _game(data: Dictionary) -> State:
	var level := Level.from_dictionary(data)
	_check(level.error.is_empty(), "fixture validates: " + level.error)
	var game := State.new()
	_check(game.load_level(level), "fixture loads")
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
