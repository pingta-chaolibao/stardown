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
func _prefix(g,sequence:String)->void:
	for k in sequence:
		if k=="C":g.switch_hero()
		else:g.try_move(DIRS[k])
func _run()->void:
	var l=Level.from_file("res://levels/north_39.json");_check(l.error.is_empty(),"confirmed39loads:"+l.error)
	if not l.error.is_empty():quit(1);return
	var g=State.new();_check(g.load_level(l),"initialtwo-colorworldvalid")
	var initial:Dictionary=g.snapshot();var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_39_route.json"));var sol:Dictionary=proof["solution"]
	_check(l.width==10 and l.height==5 and g.hero_count()==2 and g.active_kind()=="green" and g.active_hero_index==0 and l.monster_clear_barriers.is_empty(),"green/redonlydual-goal/noexchange/no clear energy")
	var mapping:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/mappings/north_39_markers.json"))["marker_to_runtime_cell"]
	_check(mapping.size()==34 and _cell(mapping["34"])==Vector2i(9,2) and _cell(mapping["23"])==Vector2i(9,3),"old1–33kept,new34aboveDragon")
	for y in 5:
		for x in 10:
			var c:=Vector2i(x,y);_check(l.is_floor(c)==(l.terrain[y][x]=="."),"exactfloor");_check(l.is_void(c)==(l.terrain[y][x]=="#"),"exactperimeter")
	_check(l.monster_kinds==PackedStringArray(["goblin","goblin","fire_dragon"]) and g.monsters()[2]["facing"]==Vector2i.LEFT,"twoGoblins/fixedleftDragon")
	_check(g.barrier_is_active(Vector2i(3,1)) and not g.barrier_is_active(Vector2i(3,3)) and not g.pressure_is_active("blue_01") and g.pressure_is_active("yellow_01"),"initialblueclosed/yellowGoblinpressureopen")
	var history:Array[Dictionary]=[];var fires:int=0;var strikes:int=0;var switches:int=0
	for i in sol["path"].length():
		var k:String=sol["path"][i];var row:Dictionary=proof["trace"][i];var before:Dictionary=g.snapshot();var capture:Dictionary=Events.capture(g)
		if k=="C":
			_check(g.switch_hero()==&"switched" and g.snapshot()==before,"Cchangesonlyselection,noaction/history/pressure");switches+=1
		else:
			history.append(before);var result:StringName=g.try_move(DIRS[k]);_check(result in [&"moved",&"pushed",&"pulled"] and g.alive,"validnormaldirection")
			var after:Dictionary=g.snapshot();var plan:Dictionary=Events.action(capture,g,DIRS[k]);fires+=plan["fire"].size();strikes+=plan["goblin"].size()
			_check(plan["fire"].size()==row["fire"].size() and plan["goblin"].size()==row["goblin"].size(),"onlyactualcommonstateattacks")
			_check(plan["deaths"].size()==row["victims"].size()+row["energy_victims"].size(),"wholeactionmonsterlife")
			_check(plan["energy"].size()==(1 if int(row["actions"]) in [29,56,62] else 0),"onlybluegroupchanges,yellowindependent")
			var clock=Clock.new();clock.start(plan);clock.advance(2.0);_check(not clock.is_busy() and g.snapshot()==after,"feedbackreadonly")
			var active:int=g.active_hero_index;_check(g.undo() and g.snapshot()==before and g.active_hero_index==active and g.attack_phase().is_empty(),"atomicUndoandretainselection")
			_check(g.try_move(DIRS[k])==result and g.snapshot()==after,"redoexactnormalinput")
		_check(g.active_hero_index==int(row["selected"]) and g.moves==int(row["actions"]) and g.history_size()==int(row["actions"]) and g.pushes==int(row["pushes"]) and g.pulls==int(row["pulls"]),"freeC/actionstatistics")
		for h in 2:_check(g.heroes()[h]["position"]==_cell(row["heroes"][h]) and g.heroes()[h]["alive"],"stableheroidentitypassivemovesdonottriggerability")
		_check(g.crate_id(_cell(row["crystal"]))==0,"singlecrystalstableidentity")
		for m in 3:_check(g.monsters()[m]["position"]==_cell(row["monsters"][m]) and g.monsters()[m]["alive"]==row["monster_alive"][m],"monsterIDsandlife")
		_check(g.monsters()[2]["facing"]==Vector2i.LEFT,"push/pullneverrotatesDragon")
		for e in 2:
			var c:=Vector2i(3,1 if e==0 else 3);_check(g.barrier_is_active(c)==row["barriers"][e] and g.blocks_sight(c)==row["barriers"][e] and g.is_walkable(c)==not row["barriers"][e],"separateblueyellowmovement/sight")
	_check(g.is_complete() and g.moves==73 and g.pushes==7 and g.pulls==8 and switches==11 and g.swaps==0 and fires==1 and strikes==0,"73actions11freeC7push8pull1actualfire")
	_check(g.crate_id(Vector2i(5,0))==0 and g.monsters()[0]["alive"] and g.monsters()[0]["position"]==Vector2i(0,4) and g.monsters()[2]["alive"] and g.monsters()[2]["position"]==Vector2i(9,3),"crystalblue/GoblinyellowhandoffandDragonwallshield")
	for i in range(history.size()-1,-1,-1):_check(g.undo() and g.snapshot()==history[i] and g.active_hero_index==1,"Undoall73actionsignores11Cretainscurrentred")
	_check(g.snapshot()==initial and g.restart() and g.active_hero_index==0,"restartresetsselectionandworld")
	for reason in proof["fatal_sides"]:
		g.restart();var side:Dictionary=proof["fatal_sides"][reason];_prefix(g,side["prefix"]);var safe:Dictionary=g.snapshot();var selected:int=g.active_hero_index
		_check(g.try_move(DIRS[side["direction"]])==&"died" and not g.alive and g.death_reason==reason,"legalsideinactiveheroenergydeath")
		var dead:Dictionary=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(l) and g.snapshot()==dead,"cannotbypassanyhero death")
		_check(g.undo() and g.snapshot()==safe and g.alive and g.active_hero_index==selected,"Undoalllives/coloredbarrierswhilekeepingselection")
	for color in proof["blocked_energy_sides"]:
		g.restart();var side:Dictionary=proof["blocked_energy_sides"][color];_prefix(g,side["prefix"]);var blocked:Dictionary=g.snapshot()
		_check(g.try_move(DIRS[side["direction"]])==&"energy_blocked" and g.snapshot()==blocked,"reachablecolorbarrierblocksatomicallywithoutwaiting")
	print("NORTH39 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
