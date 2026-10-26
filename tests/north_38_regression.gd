extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Clock=preload("res://scripts/view/feedback_timeline.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks:int=0
var failures:int=0
func _init()->void:call_deferred("_run")
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _run()->void:
	var l=Level.from_file("res://levels/north_38.json");_check(l.error.is_empty(),"confirmed38loads")
	var g=State.new();_check(g.load_level(l),"initialGoblinpressurevalid")
	var initial:Dictionary=g.snapshot();var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_38_route.json"));var sol:Dictionary=proof["solution"]
	_check(l.width==15 and l.height==8 and g.player==Vector2i(6,7) and g.active_kind()=="blue" and l.swap_hero_color=="purple","exactpurpleexchangehero/map")
	_check(l.monster_clear_barriers.is_empty() and l.energy_links.size()==1 and l.mechanism_color=="purple" and g.crates().is_empty(),"pressurekindnotinferredfromcolor/noextraobjects")
	var mapping:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/mappings/north_38_markers.json"))["marker_to_runtime_cell"]
	_check(mapping.size()==75 and _cell(mapping["41"])==Vector2i(4,4) and _cell(mapping["73"])==g.player,"75confirmedfloorIDsand41walkable")
	for y in 8:
		for x in 15:
			var c:=Vector2i(x,y);_check(l.is_floor(c)==(l.terrain[y][x]=="."),"exactfloor");_check(l.is_void(c)==(l.terrain[y][x]=="#"),"perimeterdoesnotinventfloor")
	_check(l.monster_kinds==PackedStringArray(["goblin","goblin","goblin","goblin","goblin","goblin","fire_dragon"]) and g.monsters()[6]["facing"]==Vector2i.LEFT,"6Goblins/1leftfixedDragon")
	_check(g.pressure_is_active("purple_01") and g.pressure_progress("purple_01")==Vector2i(1,1),"initialliveGoblinholdssingleplate")
	for c:Vector2i in l.energy_links[0]["barriers"]:_check(not g.barrier_is_active(c) and g.is_walkable(c) and not g.blocks_sight(c),"all5initiallyinactiveandtransparent")
	var history:Array[Dictionary]=[];var fire_count:int=0;var goblin_count:int=0
	for i in sol["path"].length():
		var before:Dictionary=g.snapshot();history.append(before);var capture:Dictionary=Events.capture(g);var k:String=sol["path"][i];var row:Dictionary=proof["trace"][i]
		var result:StringName=g.try_move(DIRS[k]);_check(result in [&"moved",&"swapped"] and g.alive,"everynormaldirectionvalidandsurvives")
		_check(g.player==_cell(row["player"]) and g.moves==i+1 and g.swaps==int(row["swaps"]) and g.history_size()==i+1,"independentpositions/counters")
		for id in 7:_check(g.monsters()[id]["position"]==_cell(row["monsters"][id]) and g.monsters()[id]["alive"]==row["monster_alive"][id],"7stabletypedidentities/life")
		_check(g.monsters()[6]["facing"]==Vector2i.LEFT and g.pressure_is_active("purple_01")==row["pressure_active"],"fixedfacingandpressure")
		for c:Vector2i in l.energy_links[0]["barriers"]:_check(g.barrier_is_active(c)==row["barrier_active"] and g.is_walkable(c)==not row["barrier_active"] and g.blocks_sight(c)==row["barrier_active"],"5globalpressurebarriers/movement/sight")
		var after:Dictionary=g.snapshot();var plan:Dictionary=Events.action(capture,g,DIRS[k]);fire_count+=plan["fire"].size();goblin_count+=plan["goblin"].size()
		_check(plan["fire"].size()==row["fire"].size() and plan["goblin"].size()==row["goblin"].size(),"onlyactualtargetattacks")
		_check(plan["deaths"].size()==row["attack_victims"].size()+row["energy_victims"].size(),"allatomicvictims")
		_check(plan["energy"].size()==(5 if i+1 in [9,31] else 0),"pressurecloses9/reopens31/notclearcount")
		_check(g.attack_phase()["monster_alive"]==row["attack_monster_alive"],"sharedpredeathattackmetadata")
		if i+1==32:_check(g.monsters()[1]["position"]==Vector2i(1,0) and g.monsters()[1]["alive"] and g.living_monster_count()==2 and g.pressure_is_active("purple_01"),"32liveGoblinplatehandoffwhileDragonkillsfirstshield")
		var clock=Clock.new();clock.start(plan);clock.advance(2.0);_check(not clock.is_busy() and g.snapshot()==after,"readonlyfeedback")
		_check(g.undo() and g.snapshot()==before and g.attack_phase().is_empty(),"wholeactionUndoincludingpressure/5barriers/7lives")
		_check(g.try_move(DIRS[k])==result and g.snapshot()==after,"redoexactnormalinput")
	_check(g.is_complete() and g.moves==36 and g.swaps==10 and g.living_monster_count()==2 and fire_count==5 and goblin_count==0,"36/10livingvictoryNOTallmonstersdead")
	for i in range(history.size()-1,-1,-1):_check(g.undo() and g.snapshot()==history[i],"reverseeveryaction")
	_check(g.snapshot()==initial and g.restart() and g.snapshot()==initial,"restartrestoresinitialGoblinplateandopenenergy")
	for reason in proof["fatal_sides"]:
		g.restart();var side:Dictionary=proof["fatal_sides"][reason]
		for k in side["prefix"]:g.try_move(DIRS[k])
		var safe:Dictionary=g.snapshot();_check(g.try_move(DIRS[side["direction"]])==&"died" and not g.alive and g.death_reason==reason,"legalsidefatal")
		var dead:Dictionary=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(l) and g.try_move(Vector2i.LEFT)==&"dead" and g.snapshot()==dead,"deathonlyUndo")
		_check(g.undo() and g.snapshot()==safe and g.alive,"oneUndorevivesexact")
	g.restart();var side:Dictionary=proof["energy_blocked_side"]
	for k in side["prefix"]:g.try_move(DIRS[k])
	var blocked:Dictionary=g.snapshot();_check(g.try_move(DIRS[side["direction"]])==&"energy_blocked" and g.snapshot()==blocked,"normalblockedenergyinputdoesnotadvanceattacks")
	_check(g.switch_hero()==&"single_hero" and g.snapshot()==blocked,"singleheroCfree")
	print("NORTH38 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
