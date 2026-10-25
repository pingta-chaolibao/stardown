extends SceneTree
const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const Events = preload("res://scripts/view/feedback_events.gd")
const Clock = preload("res://scripts/view/feedback_timeline.gd")
const DIRS = {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN = ["######.##",".........",".........",".........","##.######"]
const FACINGS = [Vector2i.DOWN,Vector2i.UP]
var checks := 0
var failures := 0

func _init() -> void:
	var level := Level.from_file("res://levels/north_30.json")
	var state := State.new(); _check(level.error.is_empty() and state.load_level(level),"confirmed level30 loads")
	_check(level.width == 9 and level.height == 5 and level.terrain == PackedStringArray(TERRAIN),"exact9x5 terrain,no extra border floor")
	for y in 5:
		for x in 9:
			var c := Vector2i(x,y)
			_check(level.is_floor(c) == (TERRAIN[y][x] == ".") and state.blocks_sight(c) == (TERRAIN[y][x] == "#"),"all45 floor/wall/sight cells exact")
	_check(state.hero_count() == 3 and state.active_hero_id() == "blue","three heroes,initial blue selection")
	for i in 3:
		_check(state.hero_position(i) == Vector2i(0,i+1) and state.heroes()[i]["kind"] == ["red","green","blue"][i],"10red/19green/28blue,never gray")
	_check(level.initial_crates == [Vector2i(8,2)] and level.exit_cells == [Vector2i(8,1),Vector2i(7,2),Vector2i(8,3)],"27crystal and18/26/36distinct goals")
	_check(level.initial_monsters == [Vector2i(6,0),Vector2i(2,4)] and level.monster_facings == FACINGS,"7down and39up fire dragons")
	_check(level.energy_links.is_empty() and level.fence_edges.is_empty() and level.bushes.is_empty(),"no inferred extra mechanics")
	var initial := state.snapshot()
	_check(state.try_move(Vector2i.LEFT) == &"wall" and state.snapshot() == initial,"failed boundary input cannot advance attacks")
	var solution: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_30.json"))
	var proof: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_30_route.json"))
	var history: Array[Dictionary] = []
	var selections := 0
	for event in solution["path"].length():
		var symbol: String = solution["path"][event]
		var before := Events.capture(state)
		if symbol == "C":
			var old_index: int = state.active_hero_index
			_check(state.switch_hero() == &"switched" and state.active_hero_index == (old_index+1)%3 and state.snapshot() == before["world"],"free C only changes selection")
			_check(Events.action(before,state,Vector2i.ZERO).is_empty(),"selection does not trigger attack feedback")
			selections += 1; continue
		history.append(state.snapshot())
		var result := state.try_move(DIRS[symbol])
		var expected: Dictionary = proof["trace"][state.moves-1]
		_check(result in [&"moved",&"swapped",&"pushed",&"pulled"] and state.alive and state.history_size() == state.moves,"every real direction commits exactly one living action")
		_check(state.active_hero_id() == expected["hero"] and expected["event"] == event+1,"selected hero identity and free-selection sequence agree independently")
		for i in 3: _check(state.hero_position(i) == _cell(expected["heroes"][i]) and state.hero_is_alive(i),"independent hero positions and life")
		_check(state.crates().size() == 1 and state.crate_id(_cell(expected["crystal"])) == 0,"crystal identity and position")
		_check(state.pushes == expected["pushes"] and state.pulls == expected["pulls"] and state.swaps == expected["swaps"],"push/pull/exchange counters agree")
		for monster in state.monsters(): _check(monster["alive"] and monster["position"] == level.initial_monsters[monster["id"]] and monster["facing"] == FACINGS[monster["id"]],"both dragons remain living,fixed and unrotated")
		var plan := Events.action(before,state,DIRS[symbol]); var clock := Clock.new(); clock.start(plan)
		_check(plan["fire"].is_empty() and plan["sight"].size() == 2 and state.fire_rays().all(func(ray: Dictionary)->bool: return ray["target"].is_empty()),"chosen safe route has no attacks,but retains both danger rays")
		_check(is_equal_approx(clock.duration,0.20 if plan["swap"] else 0.16),"no empty attack stage added to walk/pull/push or swap")
		_check(state.is_complete() == (state.moves == 40),"three heroes must occupy all different goals,never partial victory")
	_check(state.moves == 40 and selections == 11 and state.pushes == 3 and state.pulls == 3 and state.swaps == 7 and state.crate_id(Vector2i(6,2)) == 0 and state.is_complete(),"40actions/11freeC,3push3pull7swap living victory")
	var chosen: String = state.active_hero_id()
	for i in range(history.size()-1,-1,-1): _check(state.undo() and state.snapshot() == history[i] and state.active_hero_id() == chosen,"Undo restores each world step while retaining current hero selection")
	_check(not state.undo() and state.snapshot() == initial and state.restart() and state.active_hero_id() == "blue","empty Undo and restart preserve correct conventions")
	state.switch_hero(); state.try_move(Vector2i.RIGHT)
	var before_death := Events.capture(state)
	_check(state.try_move(Vector2i.RIGHT) == &"died" and not state.alive and state.death_reason == "fire","unshielded lower dragon column kills red")
	var attack := Events.action(before_death,state,Vector2i.RIGHT)
	_check(attack["fire"].size() == 1 and attack["fire"][0]["dragon"] == 1 and attack["fire"][0]["target"] == {"kind":"hero","id":0},"actual lethal side action triggers exactly its targeted dragon")
	var dead := state.snapshot()
	_check(state.switch_hero() == &"dead" and not state.restart() and not state.load_level(level) and state.try_move(Vector2i.RIGHT) == &"dead" and state.snapshot() == dead,"death locks C/restart/load/move")
	_check(state.undo() and state.snapshot() == before_death["world"] and state.active_hero_id() == "red","only Undo revives without undoing selection")
	state.restart(); _prefix(state,solution["path"],11)
	_check(state.active_hero_id() == "red" and state.player == Vector2i(1,3) and state.crate_id(Vector2i(2,3)) == 0 and not state.fire_danger_at(Vector2i(2,2)),"left crystal shield opens upper crossing")
	var shield := state.snapshot()
	_check(state.try_move(Vector2i.RIGHT) == &"died" and state.player == Vector2i(2,3) and state.crate_id(Vector2i(3,3)) == 0,"pushing shield away into unprotected column is lethal,not a bypass")
	_check(state.undo() and state.snapshot() == shield,"Undo restores shifted shield and hero life together")
	_check(state.load_level(Level.from_file("res://levels/north_29.json")) and state.load_level(level) and state.snapshot() == initial and state.active_hero_id() == "blue","29/30 history and life remain isolated")
	print("NORTH30 RESULT: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)

func _prefix(state: RefCounted, path: String, count: int) -> void:
	for symbol in path:
		if symbol == "C": state.switch_hero()
		else:
			state.try_move(DIRS[symbol])
			if state.moves == count: return
func _cell(a: Array) -> Vector2i: return Vector2i(a[0],a[1])
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL "+message)
