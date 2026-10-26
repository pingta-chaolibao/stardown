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
	var l=Level.from_file("res://levels/north_36.json");_check(l.error.is_empty(),"confirmed36loads")
	var g=State.new();_check(g.load_level(l),"validinitialworld")
	var initial:Dictionary=g.snapshot();var route:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_36_route.json"));var solution:Dictionary=route["solution"]
	_check(l.width==11 and l.height==7 and l.hero_kind=="blue" and l.swap_hero_color=="purple","11x7 purpledisplay exchangeability")
	_check(g.player==Vector2i(2,3) and g.crate_id(Vector2i(3,2))==0 and g.crate_id(Vector2i(3,4))==1 and g.monster_at(Vector2i(4,3))==0,"exactstartingidentities")
	_check(g.barrier_is_active(Vector2i(5,1)) and g.barrier_is_active(Vector2i(7,3)) and not g.is_complete(),"bothdistinctbarriersinitiallysolid")
	var history:Array[Dictionary]=[]
	for i in solution["path"].length():
		var before:Dictionary=g.snapshot();history.append(before);var captured:Dictionary=Events.capture(g);var k:String=solution["path"][i]
		var result:StringName=g.try_move(DIRS[k]);var row:Dictionary=route["trace"][i]
		_check(result in [&"moved",&"swapped"] and g.alive,"eachinputlegalandsurvives%d" % (i+1))
		_check(g.player==_cell(row["player"]) and g.moves==i+1 and g.swaps==int(row["swaps"]) and g.history_size()==i+1,"positionandcounter%d" % (i+1))
		for id in row["crystals"]:_check(g.crate_id(_cell(row["crystals"][id]))==int(id),"stablecrystalID")
		_check(g.monsters()[0]["position"]==_cell(row["goblin"]) and g.monsters()[0]["alive"]==row["goblin_alive"],"Goblinposition/life%d" % (i+1))
		_check(g.barrier_is_active(Vector2i(5,1))==row["yellow_active"] and g.barrier_is_active(Vector2i(7,3))==row["red_active"],"typedenergyagreement%d" % (i+1))
		for p in [Vector2i(1,1),Vector2i(1,5),Vector2i(5,5)]:
			var occupied:bool=g.player==p or g.crates().has(p) or (g.monsters()[0]["alive"] and g.monsters()[0]["position"]==p)
			_check(g.pressure_cell_is_active("yellow_01",p)==occupied,"liveGoblinplatequeryagrees")
		var after:Dictionary=g.snapshot();var plan:Dictionary=Events.action(captured,g,DIRS[k]);_check(plan["fire"].is_empty() and plan["goblin"].is_empty(),"safeformalroutehasnoemptyattackorpostenergyGoblinattack")
		if i+1==21:
			_check(g.living_monster_count()==0 and g.barrier_is_active(Vector2i(5,1)) and not g.barrier_is_active(Vector2i(7,3)),"yellowrestorationkillsGoblin21/redopenssameaction")
			_check(plan["deaths"].size()==1 and plan["deaths"][0]["energy"] and plan["energy"].size()==2,"oneenergydeath/twodistincttransitions")
		var clock=Clock.new();clock.start(plan);clock.advance(2.0);_check(not clock.is_busy() and g.snapshot()==after,"feedbackreadonlysettles")
		_check(g.undo() and g.snapshot()==before and g.attack_phase().is_empty(),"atomicUndoandtransientattackreset")
		_check(g.try_move(DIRS[k])==result and g.snapshot()==after,"redoexactnormalinput")
	_check(g.is_complete() and g.player==Vector2i(9,3) and g.moves==26 and g.swaps==8 and g.crates().size()==2,"26actions8swapslivingvictory")
	for i in range(history.size()-1,-1,-1):_check(g.undo() and g.snapshot()==history[i],"full26stepUndo")
	_check(g.snapshot()==initial and g.restart() and g.snapshot()==initial,"restartrestoresallidentitiesandpressure")
	for k in "DRU":g.try_move(DIRS[k])
	var safe:Dictionary=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"died" and not g.alive,"legaladjacentGoblinfatalbranch")
	var dead:Dictionary=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(l) and g.try_move(Vector2i.LEFT)==&"dead" and g.snapshot()==dead,"deathcannotC/restart/reload/move")
	_check(g.undo() and g.snapshot()==safe and g.alive,"onlyUndorevives")
	_check(g.restart() and g.snapshot()==initial,"restartafterrevival")
	print("NORTH36 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
