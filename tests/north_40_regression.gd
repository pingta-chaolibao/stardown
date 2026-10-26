extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const DIR={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks:int=0
var failures:int=0
func _init()->void:call_deferred("_run")
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _run()->void:
	var l=Level.from_file("res://levels/north_40.json");var g=State.new();_check(l.error.is_empty() and g.load_level(l),"confirmed40 loads")
	if g.level==null:quit(1);return
	var rows:Array=["...#.#.#.",".........","....#.#..","....###..","........."]
	for y in 5:
		for x in 9:_check(l.is_floor(Vector2i(x,y))==(rows[y][x]=="."),"all45confirmed cells")
	_check(g.active_kind()=="yellow" and g.player==Vector2i(1,1) and g.hero_count()==1 and l.exit_cell==Vector2i(2,3),"only yellow11 and goal30")
	_check(g.monsters().size()==7 and l.monster_kinds==PackedStringArray(["goblin","goblin","goblin","goblin","goblin","goblin","fire_dragon"]),"six Goblins and right dragon,explicit kinds")
	_check(l.energy_links.is_empty() and l.monster_clear_barriers.is_empty() and l.bushes.is_empty() and l.fence_edges.is_empty(),"no inferred mechanisms")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_40_route.json"));var initial:Dictionary=g.snapshot();var monsters:Array=g.monsters();var crates:Array=g.crates();var histories:Array[Dictionary]=[];var n:int=0
	for step in proof["trace"]:
		histories.append(g.snapshot());var capture:Dictionary=Events.capture(g);n+=1
		_check(g.try_move(DIR[step["input"]])==&"moved" and g.alive,"actual legal route action%d"%n)
		_check(g.player==Vector2i(step["player"][0],step["player"][1]) and g.moves==n and g.history_size()==n and g.protected_heroes()==[true],"independent coordinates/count/protection%d"%n)
		_check(g.monsters()==monsters and g.crates()==crates and g.pushes==0 and g.pulls==0 and g.swaps==0,"yellow never moves objects or changes monster lives")
		var plan:Dictionary=Events.action(capture,g,DIR[step["input"]]);_check(plan["fire"].is_empty() and plan["goblin"].is_empty() and plan["deaths"].is_empty(),"blocked threats never become real attack/death animations")
		_check(plan["shields"].size()==step["blocked_goblins"].size()+(1 if step["fire_shield"] else 0),"shield feedback equals actually obstructed threats")
		_check(g.is_complete()==(n==17),"victory only at real final goal")
	_check(g.player==Vector2i(2,3) and g.living_monster_count()==7 and g.crates().size()==5,"17steps,all7monsters+5crystals survive")
	while not histories.is_empty():_check(g.undo() and g.snapshot()==histories.pop_back(),"every Undo atomically restores protection/identities/positions")
	_check(g.snapshot()==initial and not g.undo(),"17Undo restore exact initial")
	for i in range(1,40):
		_check(g.load_level(Level.from_file("res://levels/north_%02d.json"%i)) and not g.protected_heroes().has(true),"old maps get no yellow immunity")
		_check(g.load_level(l) and g.snapshot()==initial,"switching restores40 without protection leakage")
	print("NORTH40 RESULT: %d checks,%d failures"%[checks,failures]);quit(0 if failures==0 else 1)
