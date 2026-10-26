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
	var l=Level.from_file("res://levels/north_37.json");_check(l.error.is_empty(),"confirmed37loads")
	var g=State.new();_check(g.load_level(l),"validinitialworld")
	var initial:Dictionary=g.snapshot();var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_37_route.json"));var sol:Dictionary=proof["solution"]
	_check(l.width==12 and l.height==7 and g.player==Vector2i(4,0) and g.active_kind()=="red","exactmap/hero")
	var mapping:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/mappings/north_37_markers.json"))["marker_to_runtime_cell"]
	_check(mapping.size()==66 and _cell(mapping["64"])==Vector2i(9,4) and _cell(mapping["65"])==Vector2i(10,4) and _cell(mapping["66"])==Vector2i(11,4),"preserved1–63andconfirmedlower64–66")
	for y in 7:
		for x in 12:
			var c:=Vector2i(x,y);_check(l.is_floor(c)==(l.terrain[y][x]=="."),"exactstaticfloor");_check(l.is_void(c)==(l.terrain[y][x]=="#"),"voiddoesnotinventfloor")
	_check(l.monster_kinds==PackedStringArray(["fire_dragon","goblin","goblin","goblin"]) and g.monsters().size()==4 and g.monsters()[0]["facing"]==Vector2i.RIGHT,"onefixedrightdragon/threeGoblins")
	_check(g.barrier_is_active(Vector2i(8,3)) and g.blocks_sight(Vector2i(8,3)) and not g.is_walkable(Vector2i(8,3)),"solidredclearblock")
	var history:Array[Dictionary]=[];var fire_count:int=0;var goblin_count:int=0
	for i in sol["path"].length():
		var before:Dictionary=g.snapshot();history.append(before);var capture:Dictionary=Events.capture(g);var k:String=sol["path"][i];var row:Dictionary=proof["trace"][i]
		var result:StringName=g.try_move(DIRS[k]);_check(result in [&"moved",&"pushed"] and g.alive,"everystepvalidandsurvives")
		_check(g.player==_cell(row["player"]) and g.moves==i+1 and g.pushes==int(row["pushes"]) and g.history_size()==i+1,"positions/countersagree")
		for id in 2:_check(g.crate_id(_cell(row["crystals"][id]))==id,"stablecrystalidentity")
		for id in 4:_check(g.monsters()[id]["position"]==_cell(row["monsters"][id]) and g.monsters()[id]["alive"]==row["monster_alive"][id],"fourtypedidentities/life")
		_check(g.monsters()[0]["facing"]==Vector2i.RIGHT and g.barrier_is_active(Vector2i(8,3))==row["barrier_active"],"facing/gate")
		var after:Dictionary=g.snapshot();var plan:Dictionary=Events.action(capture,g,DIRS[k]);fire_count+=plan["fire"].size();goblin_count+=plan["goblin"].size()
		_check(plan["fire"].size()==row["fire"].size() and plan["goblin"].size()==row["goblin"].size() and plan["deaths"].size()==row["victims"].size(),"onlycommonstateactualattacks/deaths")
		if i+1 in [5,6]:_check(plan["fire"].size()==1 and plan["deaths"].size()==1 and plan["energy"].is_empty(),"onefirsttargetperstep,noprematureclear")
		if i+1==30:_check(g.living_monster_count()==0 and plan["fire"].size()==1 and plan["goblin"].size()==1 and plan["deaths"].size()==2 and plan["energy"].size()==1,"lastDragon/Goblinmutualdeathandclear30")
		var clock=Clock.new();clock.start(plan);clock.advance(2.0);_check(not clock.is_busy() and g.snapshot()==after,"readonlyfeedback")
		_check(g.undo() and g.snapshot()==before and g.attack_phase().is_empty(),"wholeactionUndo")
		_check(g.try_move(DIRS[k])==result and g.snapshot()==after,"normalinputredoexact")
	_check(g.is_complete() and g.moves==43 and g.pushes==10 and g.crates().size()==2 and fire_count==3 and goblin_count==1,"43/10livingvictorywith3fire1strike")
	for i in range(history.size()-1,-1,-1):_check(g.undo() and g.snapshot()==history[i],"reverseall43steps")
	_check(g.snapshot()==initial and g.restart() and g.snapshot()==initial,"restartallentities")
	for reason in proof["fatal_sides"]:
		g.restart();var side:Dictionary=proof["fatal_sides"][reason]
		for k in side["prefix"]:g.try_move(DIRS[k])
		var safe:Dictionary=g.snapshot();_check(g.try_move(DIRS[side["direction"]])==&"died" and not g.alive and g.death_reason==reason,"legaltypeddeathside")
		var dead:Dictionary=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(l) and g.try_move(Vector2i.LEFT)==&"dead" and g.snapshot()==dead,"onlyUndocanrevive")
		_check(g.undo() and g.snapshot()==safe and g.alive,"Undoexactrevival")
	g.restart()
	for k in proof["gate_block_prefix"]:g.try_move(DIRS[k])
	var gate:Dictionary=g.snapshot();_check(g.player==Vector2i(7,3) and g.try_move(Vector2i.RIGHT)==&"energy_blocked" and g.snapshot()==gate,"reachableblockedgateadvancesnothing")
	print("NORTH37 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
