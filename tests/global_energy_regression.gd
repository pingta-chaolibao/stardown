extends SceneTree
## All yellow pressure cells gate all yellow energy cells, across data IDs.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
var checks := 0
var failures := 0


func _init() -> void:
	var cases := [_test_partition_invariance, _test_cross_group_handoff, _test_cross_group_release_death,
		_test_global_block_before_pull, _test_undefined_crystal_restoration, _test_no_mechanisms]
	for test: Callable in cases:
		var before := failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("GLOBAL ENERGY RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_partition_invariance() -> void:
	var plates := [[1, 1], [3, 1], [5, 1]]
	var barriers := [[6, 0], [6, 1], [6, 2]]
	var ray: Array[Vector2i] = [Vector2i(6, 0), Vector2i(6, 1), Vector2i(6, 2)]
	for partition in [[[0], [1], [2]], [[0, 1], [2]], [[0, 1, 2]]]:
		for mask in 8:
			var data := _data()
			for index in 3:
				if mask & (1 << index):
					data["crates"].append(plates[index])
			for group_index in partition.size():
				var group_plates: Array = []
				var group_barriers: Array = []
				for index in partition[group_index]:
					group_plates.append(plates[index])
					group_barriers.append(barriers[index])
				data["energy_links"].append(_link("group_%d" % group_index, group_plates, group_barriers))
			var game := _game(data)
			for cell in ray:
				_check(game.barrier_is_active(cell) == (mask != 7) and game.is_walkable(cell) == (mask == 7) and game.blocks_sight(cell) == (mask != 7), "partition cannot change global movement/sight truth table")
			_check(game.sight_path_is_clear(ray) == (mask == 7), "all plates alone open the complete sight path")


func _test_cross_group_handoff() -> void:
	var data := _data()
	data["player"] = [2, 1]
	data["crates"] = [[1, 1], [5, 1]]
	data["energy_links"] = [_link("a", [[2, 1]], [[3, 1]]), _link("b", [[5, 1]], [[6, 1]])]
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"pulled" and game.alive and game.pressure_is_active("a") and game.pressure_is_active("b"), "green crystal replaces hero pressure in same global action")
	_check(not game.barrier_is_active(Vector2i(3, 1)) and not game.barrier_is_active(Vector2i(6, 1)), "both barriers stay open without an intermediate flicker")
	_check(game.undo() and game.snapshot() == initial and game.restart(), "handoff undo and restart preserve complete global state")


func _test_cross_group_release_death() -> void:
	var data := _data()
	data["player"] = [2, 1]
	data["crates"] = [[1, 1], [5, 1]]
	data["energy_links"] = [_link("a", [[1, 1]], [[6, 0]]), _link("b", [[5, 1]], [[3, 1]])]
	var game := _game(data)
	var initial := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"died" and not game.alive, "release in a restores b barrier on hero despite b plate staying pressed")
	_check(not game.pressure_is_active("a") and game.pressure_is_active("b") and game.barrier_is_active(Vector2i(3, 1)) and game.barrier_is_active(Vector2i(6, 0)), "local occupancy reports do not independently open doors")
	_check(game.moves == 1 and game.pulls == 1 and game.pushes == 0 and game.history_size() == 1, "pull and global restoration death form one undoable action")
	var dead := game.snapshot()
	_check(game.try_move(Vector2i.LEFT) == &"dead" and not game.restart() and not game.load_level(Level.from_dictionary(_data())) and game.snapshot() == dead, "death still allows only undo")
	_check(game.undo() and game.alive and game.snapshot() == initial and game.pulls == 0, "one undo revives and restores every plate/barrier and crystal identity")


func _test_global_block_before_pull() -> void:
	var data := _data()
	data["player"] = [2, 1]
	data["crates"] = [[1, 1], [5, 0]]
	data["energy_links"] = [_link("a", [[5, 0]], [[3, 1]]), _link("b", [[5, 2]], [[6, 1]])]
	var game := _game(data)
	var before := game.snapshot()
	_check(game.pressure_is_active("a") and not game.pressure_is_active("b"), "one local group is occupied")
	_check(game.try_move(Vector2i.RIGHT) == &"energy_blocked" and game.snapshot() == before and game.history_size() == 0, "a barrier stays blocked until b is occupied; rear crystal is not pulled")


func _test_undefined_crystal_restoration() -> void:
	var data := _data()
	data["player"] = [2, 1]
	data["crates"] = [[1, 1], [5, 1]]
	data["energy_links"] = [_link("a", [[1, 1]], [[6, 0]]), _link("b", [[5, 1]], [[2, 1]])]
	var game := _game(data)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"rule_unresolved" and game.snapshot() == before and game.history_size() == 0, "undefined global restoration onto crystal commits no partial action")
	_check(not game.last_mechanism_error.is_empty() and game.alive and game.crate_id(Vector2i(1, 1)) == 0, "no destruction or invented crystal restoration rule")


func _test_no_mechanisms() -> void:
	var data := _data()
	data["player"] = [2, 1]
	data["crates"] = [[1, 1]]
	var game := _game(data)
	_check(game.pressure_states().is_empty() and game.barrier_states().is_empty(), "no yellow mechanisms means no phantom global gate")
	_check(game.try_move(Vector2i.RIGHT) == &"pulled" and game.alive and game.pulls == 1, "plain green pull is unchanged")


func _link(id: String, plates: Array, barriers: Array) -> Dictionary:
	return {"id": id, "plates": plates, "activation": "all", "barriers": barriers, "pressure_sources": ["hero", "crystal"]}


func _data() -> Dictionary:
	return {"schema_version": 1, "id": "global_energy_fixture", "title": "Independent global AND fixture", "is_temporary": true,
		"source_note": "Mechanism tests only; never a reconstructed level", "hero_kind": "green",
		"terrain": [".......", ".......", ".......", "......."], "player": [0, 3], "crates": [], "targets": [], "objective": "none", "energy_links": []}


func _game(data: Dictionary) -> State:
	var definition := Level.from_dictionary(data)
	_check(definition.error.is_empty(), "global fixture validates: " + definition.error)
	var game := State.new()
	_check(game.load_level(definition), "global fixture loads")
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
