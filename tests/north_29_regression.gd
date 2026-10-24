extends SceneTree
const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const DIRS = {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN = ["#..#######","#..#######","#.......##","#.......##","#.......##","#######.##","..........","...#......","##........"]
const FACINGS = [Vector2i.DOWN,Vector2i.UP,Vector2i.DOWN,Vector2i.UP]
var checks := 0
var failures := 0

func _init() -> void:
	var definition := Level.from_file("res://levels/north_29.json")
	_check(definition.error.is_empty() and definition.width == 10 and definition.height == 9 and definition.terrain == PackedStringArray(TERRAIN),"confirmed exact 10x9 terrain")
	var state := State.new(); _check(state.load_level(definition),"valid green/fire-dragon map")
	for y in 9:
		for x in 10:
			var cell := Vector2i(x,y)
			_check(definition.is_floor(cell) == (TERRAIN[y][x] == ".") and state.blocks_sight(cell) == (TERRAIN[y][x] == "#"),"all90 floor/wall and sight cells exact")
	_check(definition.start == Vector2i(0,7) and definition.exit_cell == Vector2i(1,0) and definition.initial_crates == [Vector2i(7,7)] and definition.hero_kind == "green","71 hero,78 crystal,2 goal")
	_check(not definition.is_floor(Vector2i(3,7)) and definition.bushes.is_empty() and definition.energy_links.is_empty() and definition.fence_edges.is_empty(),"74 is fixed wall,no guessed mechanisms")
	_check(definition.initial_monsters == [Vector2i(3,2),Vector2i(1,4),Vector2i(7,5),Vector2i(6,8)] and definition.monster_facings == FACINGS,"24/42/58/87 identities and fixed facing")
	_check(state.fire_danger_at(Vector2i(7,6)) and not state.fire_danger_at(Vector2i(7,8)) and state.fire_danger_at(Vector2i(6,6)),"initial crystal shields87 approach while87 blocks crossing its own column")
	var initial := state.snapshot()
	_check(state.switch_hero() == &"single_hero" and state.snapshot() == initial,"C has no attack round or action")
	_check(state.try_move(Vector2i.LEFT) == &"wall" and state.snapshot() == initial,"failed input cannot wait or fire")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_29.json"))
	var proof: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_29_route.json"))
	var history: Array[Dictionary] = []
	var dragon_pulls := 0; var crystal_pulls := 0
	for i in solution["path"].length():
		history.append(state.snapshot())
		var result := state.try_move(DIRS[solution["path"][i]])
		var expected: Dictionary = proof["trace"][i]
		if expected["pulled"] is String: crystal_pulls += 1
		elif expected["pulled"] != null: dragon_pulls += 1
		_check(result == (&"pulled" if expected["pulled"] != null else &"moved") and state.alive and state.moves == i+1 and state.history_size() == i+1,"living legal action %02d" % (i+1))
		_check(state.player == _cell(expected["hero"]) and state.crate_id(_cell(expected["crystal"])) == 0 and state.crates().size() == 1,"independent hero/crystal position and identity")
		_check(state.pulls == expected["pulls"] and state.pushes == 0 and state.swaps == 0 and dragon_pulls == expected["dragon_pulls"] and crystal_pulls == expected["crystal_pulls"],"single-pull categories and all action counters")
		for monster in state.monsters():
			var identity: int = monster["id"]
			_check(monster["position"] == _cell(expected["monsters"][identity]) and monster["alive"] == expected["monster_alive"][identity] and monster["facing"] == FACINGS[identity],"each dragon identity,life,position and fixed facing")
			if not monster["alive"]: _check(state.monster_at(monster["position"]) < 0,"dead dragon does not occupy grid")
		_check(state.is_complete() == (i == 63),"only final living input wins")
		if i+1 == 21: _check(not state.monsters()[2]["alive"] and not state.monsters()[3]["alive"] and state.monsters()[0]["alive"] and state.monsters()[1]["alive"],"moving first crystal shield triggers simultaneous58/87 mutual kill")
		if i+1 == 56: _check(state.fire_rays().is_empty() and not state.monsters().any(func(m: Dictionary)->bool: return m["alive"]),"second crystal handoff simultaneously kills24/42,no remaining fire")
	_check(state.is_complete() and state.pulls == 23 and dragon_pulls == 13 and crystal_pulls == 10 and state.crate_id(Vector2i(5,3)) == 0,"64actions/23pulls,living win with crystal preserved")
	for i in range(63,-1,-1): _check(state.undo() and state.snapshot() == history[i],"Undo restores every full step,including mutual victims")
	_check(state.snapshot() == initial and not state.undo(),"all64Undo restore initial life/facings/positions/counters")
	for symbol in solution["path"]: state.try_move(DIRS[symbol])
	_check(state.restart() and state.snapshot() == initial,"restart revives all4dragons and resets crystal/hero/history")
	for symbol in "URRRRR": state.try_move(DIRS[symbol])
	var before := state.snapshot()
	_check(state.try_move(Vector2i.RIGHT) == &"died" and state.player == Vector2i(6,6) and state.death_reason == "fire","unshielded87column is lethal")
	var dead := state.snapshot()
	_check(state.switch_hero() == &"dead" and not state.restart() and not state.load_level(definition) and state.try_move(Vector2i.UP) == &"dead" and state.snapshot() == dead,"death locks everything except Undo")
	_check(state.undo() and state.snapshot() == before and state.alive,"oneUndo revives side route without extra attack")
	for number in range(1,29):
		_check(state.load_level(Level.from_file("res://levels/north_%02d.json" % number)),"prior28level loads")
		_check(state.load_level(definition) and state.snapshot() == initial,"29 history/life/objects isolated from previous levels")
	print("NORTH29 RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _cell(a: Array) -> Vector2i: return Vector2i(a[0],a[1])
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL "+message)
