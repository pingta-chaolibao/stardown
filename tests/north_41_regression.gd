extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Clock=preload("res://scripts/view/feedback_timeline.gd")
const DIR={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks:int=0
var failures:int=0
func _init()->void:call_deferred("_run")
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _cell(a:Array)->Vector2i:return Vector2i(int(a[0]),int(a[1]))
func _prefix(g:RefCounted,path:String)->void:
	for s in path:
		if s=="C":g.switch_hero()
		else:g.try_move(DIR[s])
func _run()->void:
	var l=Level.from_file("res://levels/north_41.json");var g=State.new();_check(l.error.is_empty() and g.load_level(l),"confirmed41 loads")
	if g.level==null:quit(1);return
	var rows:Array=[".#######.",".#.#.#.#.",".........",".##.#.##.",".#######."]
	for y in 5:
		for x in 9:_check(l.is_floor(Vector2i(x,y))==(rows[y][x]=="."),"all45 terrain coordinates")
	var mapping:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/mappings/north_41_markers.json"))["markers"]
	_check(mapping.size()==22 and _cell(mapping["1"]["cell"])==Vector2i(0,0) and _cell(mapping["21"]["cell"])==Vector2i(0,4) and _cell(mapping["22"]["cell"])==Vector2i(8,4),"walkable-only original1–22 mapping")
	_check(g.hero_count()==2 and g.active_hero_id()=="purple" and g.active_kind()=="blue" and l.swap_hero_color=="purple" and g.heroes()[1]["kind"]=="yellow","purple visual blue mechanics plus yellow protector")
	_check(l.objective=="all_heroes_on_exits" and l.exit_cells.size()==2 and g.occupied_exits()==0 and not g.is_complete(),"both different goals required")
	_check(g.crates().is_empty() and l.energy_links.is_empty() and l.monster_clear_barriers.is_empty() and l.bushes.is_empty() and l.fence_edges.is_empty() and g.monsters().size()==5,"only5Goblins,no new mechanics")
	var initial:Dictionary=g.snapshot();var monsters:Array=g.monsters()
	_check(g.protected_heroes()==[false,true] and g.switch_hero()==&"switched" and not g.undo() and g.active_hero_index==1 and g.snapshot()==initial,"emptyUndo never undoes freeC")
	_check(g.switch_hero()==&"switched" and g.history_size()==0 and g.snapshot()==initial,"repeatedC no action or attack")
	var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_41_route.json"));var history:Array[Dictionary]=[];var selections:int=0;var shields:int=0
	for row in proof["trace"]:
		var s:String=row["input"];var before:Dictionary=g.snapshot();var capture:Dictionary=Events.capture(g)
		if s=="C":
			selections+=1;_check(g.switch_hero()==&"switched" and g.snapshot()==before and Events.action(capture,g,Vector2i.RIGHT).is_empty(),"free selection never advances attacks/Undo")
		else:
			history.append(before);var result:StringName=g.try_move(DIR[s]);_check(result==(&"swapped" if row["swapped"] else &"moved") and g.alive,"legal route direction")
			var after:Dictionary=g.snapshot();var plan:Dictionary=Events.action(capture,g,DIR[s]);shields+=plan["shields"].size()
			_check(plan["shields"].size()==row["shield_blocks"].size() and plan["fire"].is_empty() and plan["goblin"].is_empty() and plan["deaths"].is_empty(),"only blocked threats produce shield feedback,no empty attacks")
			var clock=Clock.new();clock.start(plan);clock.advance(2.0);_check(not clock.is_busy() and g.snapshot()==after,"feedback read-only and bounded")
			var selected:int=g.active_hero_index;_check(g.undo() and g.snapshot()==before and g.active_hero_index==selected,"atomicUndo retains chosen identity")
			_check(g.try_move(DIR[s])==result and g.snapshot()==after,"redo identical world")
		_check(g.active_hero_index==int(row["selected"]) and g.moves==int(row["actions"]) and g.history_size()==g.moves and g.swaps==int(row["swaps"]),"separate direction/action/C statistics")
		for h in 2:_check(g.heroes()[h]["position"]==_cell(row["heroes"][h]) and g.hero_is_alive(h),"both stable hero positions")
		_check(g.protected_heroes()==row["protected_heroes"] and g.monsters()==monsters and g.pushes==0 and g.pulls==0,"independent protection and all5monsters unchanged")
		_check(g.is_complete()==row["completed"],"no premature one-hero victory")
	_check(g.is_complete() and g.moves==25 and selections==5 and g.swaps==1 and g.occupied_exits()==2 and shields>0,"25directions5freeC1heroexchange,doublegoal")
	for i in range(history.size()-1,-1,-1):_check(g.undo() and g.snapshot()==history[i] and g.active_hero_index==1,"Undoall actual25actions ignores intervening selections")
	_check(g.snapshot()==initial and g.restart() and g.active_hero_index==0,"restart resets selection and all states")
	_prefix(g,"CUURCDD");_check(g.player==Vector2i(0,2) and g.heroes()[1]["position"]==Vector2i(1,2),"reachable safe diagnostic prefix")
	_check(g.try_move(Vector2i.RIGHT)==&"swapped" and g.protected_heroes()==[true,true],"adjacent hero exchange carries protection")
	var safe:Dictionary=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"died" and not g.alive and not g.hero_is_alive(0) and g.hero_is_alive(1),"moving2away from yellow exposes purple to Goblin at2,1")
	var dead:Dictionary=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(l) and g.snapshot()==dead,"cannot C/restart/load escape one hero death")
	_check(g.undo() and g.snapshot()==safe and g.active_hero_index==0 and g.protected_heroes()==[true,true],"Undo revives and restores protection without selection change")
	_check(g.switch_hero()==&"switched" and g.undo() and g.active_hero_index==1 and g.player==Vector2i(1,2),"switchthenUndo keepsyellow whileundoing actual hero exchange")
	print("NORTH41 RESULT: %d checks,%d failures"%[checks,failures]);quit(0 if failures==0 else 1)
