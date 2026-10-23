extends SceneTree
## Confirmed automatic, nearest-only green pull and shared atomic settlement.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const DIRECTIONS := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
var checks := 0
var failures := 0


func _init() -> void:
	var cases := [_test_single_and_line, _test_blocked_destinations, _test_sideways,
		_test_role_isolation, _test_pressure_handoff, _test_pull_death, _test_undefined_crystal_edge, _test_random_undo]
	for test: Callable in cases:
		var before := failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("GREEN PULL RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_single_and_line() -> void:
	for direction in DIRECTIONS:
		for count in [1, 2, 3]:
			var data := _data()
			for index in range(1, count + 1):
				data["crates"].append(_array(Vector2i(4, 3) - direction * index))
			var game := _game(data)
			var initial := game.snapshot()
			_check(game.try_move(direction) == &"pulled" and game.player == Vector2i(4, 3) + direction, "green automatically pulls while stepping away")
			_check(game.crate_id(Vector2i(4, 3)) == 0 and game.pulls == 1 and game.pushes == 0 and game.moves == 1 and game.history_size() == 1, "nearest identity follows and one pull is counted")
			for index in range(1, count):
				_check(game.crate_id(Vector2i(4, 3) - direction * (index + 1)) == index, "further crystals never follow")
			_check(game.undo() and game.snapshot() == initial, "one undo restores complete pull")
			game.try_move(direction)
			_check(game.restart() and game.snapshot() == initial, "restart restores pull counters and crystal identity")


func _test_blocked_destinations() -> void:
	for obstruction in ["wall", "bush", "crystal", "energy", "boundary"]:
		var data := _data()
		data["crates"] = [[3, 3]]
		var expected: StringName = &"wall"
		match obstruction:
			"wall":
				data["terrain"][3] = ".....#..."
			"bush":
				data["bushes"] = [[5, 3]]
				expected = &"bush_blocked"
			"crystal":
				data["crates"].append([5, 3])
				data["crates"].append([6, 3])
				expected = &"cannot_push"
			"energy":
				data["energy_links"] = [{"id": "test", "plate": [0, 0], "barriers": [[5, 3]], "pressure_sources": ["hero", "crystal"]}]
				expected = &"energy_blocked"
			"boundary":
				data["player"] = [8, 3]
				data["crates"] = [[7, 3]]
		var game := _game(data)
		var before := game.snapshot()
		_check(game.try_move(Vector2i.RIGHT) == expected and game.snapshot() == before and game.history_size() == 0, "blocked destination changes neither hero nor rear crystal: " + obstruction)


func _test_sideways() -> void:
	var data := _data()
	data["crates"] = [[3, 3]]
	var game := _game(data)
	_check(game.try_move(Vector2i.UP) == &"moved" and game.crate_id(Vector2i(3, 3)) == 0 and game.pulls == 0, "side neighbour is not pulled while moving perpendicular")


func _test_role_isolation() -> void:
	var data := _data()
	data.erase("hero_kind")
	data["crates"] = [[3, 3]]
	var game := _game(data)
	_check(game.level.hero_kind == "red" and game.try_move(Vector2i.RIGHT) == &"moved" and game.pulls == 0 and game.crate_id(Vector2i(3, 3)) == 0, "legacy maps remain red and never pull")
	data["hero_kind"] = "green"
	_check(game.load_level(Level.from_dictionary(data)) and game.try_move(Vector2i.RIGHT) == &"pulled", "green role enables only its confirmed pull")
	data["hero_kind"] = "red"
	_check(game.load_level(Level.from_dictionary(data)) and game.pulls == 0 and game.history_size() == 0 and game.try_move(Vector2i.LEFT) == &"pushed", "role switch resets counters and red still pushes")
	for kind in ["purple", "gray", "", null, 3]:
		data["hero_kind"] = kind
		_check(not Level.from_dictionary(data).error.is_empty(), "unsupported hero types rejected")


func _test_pressure_handoff() -> void:
	var data := _mechanism_data()
	data["energy_links"][0]["plate"] = [2, 1]
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"pulled" and game.alive and game.pressure_is_active("test") and not game.barrier_is_active(Vector2i(3, 1)), "pulled crystal replaces hero on plate in same settlement without flicker/death")
	_check(game.undo() and game.snapshot() == initial, "pressure handoff pull undo is complete")


func _test_pull_death() -> void:
	var game := _game(_mechanism_data())
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"died" and not game.alive and game.player == Vector2i(3, 1) and game.crate_id(Vector2i(2, 1)) == 0, "pulling crystal off plate restores barrier under hero")
	_check(game.moves == 1 and game.pulls == 1 and game.pushes == 0 and game.history_size() == 1, "pull and death are one recorded action")
	var dead := game.snapshot()
	_check(game.try_move(Vector2i.LEFT) == &"dead" and not game.restart() and not game.load_level(Level.from_dictionary(_data())) and game.snapshot() == dead, "dead green hero cannot act, restart or switch")
	_check(game.undo() and game.alive and game.snapshot() == before and game.pulls == 0, "one undo restores life, pressure, crystal and pull counter")


func _test_undefined_crystal_edge() -> void:
	var data := _mechanism_data()
	data["energy_links"][0]["barriers"] = [[2, 1]]
	var game := _game(data)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"rule_unresolved" and game.snapshot() == before and game.history_size() == 0, "unconfirmed barrier restoration on pulled crystal is diagnosed without inventing a result")


func _test_random_undo() -> void:
	var data := _data()
	data["crates"] = [[2, 2], [3, 2], [6, 4]]
	data["bushes"] = [[4, 4]]
	var game := _game(data)
	var initial := game.snapshot()
	var history: Array[Dictionary] = []
	var random := RandomNumberGenerator.new()
	random.seed = 3052026
	for index in 1000:
		var direction: Vector2i = DIRECTIONS[random.randi_range(0, 3)]
		var before := game.snapshot()
		var depth := game.history_size()
		var result := game.try_move(direction)
		if result in [&"moved", &"pulled"]:
			history.append(before)
			_check(game.moves == before["moves"] + 1 and game.pushes == 0 and game.pulls == before["pulls"] + (1 if result == &"pulled" else 0), "green random counters")
			_check(game.history_size() == depth + 1 and game.player == before["player"] + direction, "green random single step and history")
			var changed := 0
			for cell: Vector2i in before["crates"]:
				if game.crate_id(cell) != before["crates"][cell]:
					changed += 1
			_check(changed == (1 if result == &"pulled" else 0), "at most the nearest single crystal changes position")
		else:
			_check(game.snapshot() == before and game.history_size() == depth, "failed green input is atomic")
		_check(game.is_walkable(game.player) and game.player not in game.crates(), "green hero remains on free walkable cell")
	while not history.is_empty():
		_check(game.undo() and game.snapshot() == history.pop_back(), "every random pull and walk reverses exactly")
	_check(game.snapshot() == initial, "all random inputs undo to initial green state")


func _data() -> Dictionary:
	return {"schema_version": 1, "id": "green_fixture", "title": "Independent green fixture", "is_temporary": true,
		"source_note": "Mechanism tests only", "hero_kind": "green", "terrain": [".........", ".........", ".........", ".........", ".........", ".........", "........."],
		"player": [4, 3], "crates": [], "targets": [], "objective": "none"}


func _mechanism_data() -> Dictionary:
	var data := _data()
	data["player"] = [2, 1]
	data["crates"] = [[1, 1]]
	data["energy_links"] = [{"id": "test", "plate": [1, 1], "barriers": [[3, 1]], "pressure_sources": ["hero", "crystal"]}]
	return data


func _array(cell: Vector2i) -> Array:
	return [cell.x, cell.y]


func _game(data: Dictionary) -> State:
	var definition := Level.from_dictionary(data)
	_check(definition.error.is_empty(), "green fixture validates: " + definition.error)
	var game := State.new()
	_check(game.load_level(definition), "green fixture initializes")
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
