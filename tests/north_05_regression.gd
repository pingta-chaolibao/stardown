extends SceneTree
## Confirmed first green-hero layout and legal automatic pulls to the exit.

const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const DIRECTIONS := {"U": Vector2i.UP, "D": Vector2i.DOWN, "L": Vector2i.LEFT, "R": Vector2i.RIGHT}
const WALLS := [Vector2i(3, 0), Vector2i(3, 1), Vector2i(7, 1), Vector2i(7, 2)]
var checks := 0
var failures := 0


func _init() -> void:
	var cases := [_test_map, _test_solution, _test_cannot_push, _test_switch]
	for test: Callable in cases:
		var before := failures
		test.call()
		print("%s %s" % ["PASS" if before == failures else "FAIL", test.get_method()])
	print("NORTH 05 RESULT: %d cases, %d checks, %d failures" % [cases.size(), checks, failures])
	quit(0 if failures == 0 else 1)


func _test_map() -> void:
	var game := _game()
	_check(game.level.width == 11 and game.level.height == 3 and game.level.hero_kind == "green" and game.player == Vector2i(1, 1), "confirmed green hero and rectangle")
	for y in 3:
		for x in 11:
			_check(game.level.is_floor(Vector2i(x, y)) == (Vector2i(x, y) not in WALLS), "confirmed fifth-level terrain")
	_check(game.crates().size() == 2 and game.crate_id(Vector2i(3, 2)) == 0 and game.crate_id(Vector2i(7, 0)) == 1 and game.level.crystal_colors == PackedStringArray(["blue", "purple"]), "confirmed two crystals and colors")
	_check(game.level.exit_cell == Vector2i(9, 1) and game.level.exit_color == "green" and game.level.energy_links.is_empty() and game.level.bushes.is_empty(), "green destination and no invented obstacles")
	var first := Level.from_file("res://levels/north_01.json")
	_check(game.level.terrain == first.terrain and game.level.initial_crates == first.initial_crates and game.level.start == first.start and first.hero_kind == "red", "same first-level layout with independent hero capability")


func _test_solution() -> void:
	var game := _game()
	var initial := game.snapshot()
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_05.json"))
	var history: Array[Dictionary] = []
	var moved: Dictionary = {}
	for index in solution["path"].length():
		var before := game.snapshot()
		history.append(before)
		var result := game.try_move(DIRECTIONS[solution["path"][index]])
		_check(result in [&"moved", &"pulled"] and game.moves == index + 1 and game.alive and game.pushes == 0, "actual green solution input %d" % (index + 1))
		_check(game.is_complete() == (index == solution["path"].length() - 1), "only final hero arrival wins fifth level")
		for cell: Vector2i in before["crates"]:
			if game.crate_id(cell) != before["crates"][cell]:
				moved[before["crates"][cell]] = true
	_check(moved.size() == 2 and game.is_complete() and game.player == Vector2i(9, 1) and game.moves == 24 and game.pulls == 8 and game.pushes == 0, "both crystals participate in 24-move / 8-pull / zero-push victory")
	_check(game.undo() and game.snapshot() == history.pop_back() and not game.is_complete(), "fifth victory undo restores pull history")
	while not history.is_empty():
		_check(game.undo() and game.snapshot() == history.pop_back(), "fifth route reverse restoration")
	_check(game.snapshot() == initial and game.history_size() == 0, "all fifth-level history unwinds to initial state")
	for symbol in solution["path"]:
		game.try_move(DIRECTIONS[symbol])
	_check(game.restart() and game.snapshot() == initial, "fifth victory restart restores pulls and both identities")
	print("NORTH 05 SOLUTION: %s; 24 moves, 8 pulls, 0 pushes" % solution["path"])


func _test_cannot_push() -> void:
	var game := _game()
	game.try_move(Vector2i.DOWN)
	game.try_move(Vector2i.RIGHT)
	var before := game.snapshot()
	_check(game.try_move(Vector2i.RIGHT) == &"cannot_push" and game.snapshot() == before and game.history_size() == 2, "green cannot push original blue crystal through lower gap")
	_check(game.try_move(Vector2i.LEFT) == &"pulled" and game.crate_id(Vector2i(2, 2)) == 0 and game.pulls == 1, "walking away pulls blue crystal toward hero's old cell")


func _test_switch() -> void:
	var game := _game()
	var initial := game.snapshot()
	for symbol in "DRLL":
		game.try_move(DIRECTIONS[symbol])
	_check(game.pulls == 2 and game.load_level(Level.from_file("res://levels/north_04.json")) and game.level.hero_kind == "red" and game.pulls == 0 and game.history_size() == 0, "green role and pull history do not leak into fourth level")
	_check(game.load_level(Level.from_file("res://levels/north_05.json")) and game.snapshot() == initial, "returning to fifth restores independent initial state")


func _game() -> State:
	var definition := Level.from_file("res://levels/north_05.json")
	_check(definition.error.is_empty(), "fifth level validates")
	var game := State.new()
	_check(game.load_level(definition), "fifth level initializes")
	return game


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", message)
