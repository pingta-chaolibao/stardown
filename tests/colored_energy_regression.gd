extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Energy=preload("res://scripts/core/energy_rules.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
var checks:int=0
var failures:int=0
func _init()->void:call_deferred("_run")
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _run()->void:
	var links:Array[Dictionary]=[
		{"id":"y1","color":"yellow","plates":[Vector2i(0,0)],"barriers":[Vector2i(0,3)],"pressure_sources":["hero","crystal"]},
		{"id":"y2","color":"yellow","plates":[Vector2i(1,0)],"barriers":[Vector2i(1,3)],"pressure_sources":["hero","crystal"]},
		{"id":"b1","color":"blue","plates":[Vector2i(3,0)],"barriers":[Vector2i(3,3)],"pressure_sources":["hero","crystal"]}]
	var result:Dictionary=Energy.settle(links,Vector2i(2,2),{Vector2i(0,0):0,Vector2i(1,0):1},{})
	_check(not result["barriers"][Vector2i(0,3)] and not result["barriers"][Vector2i(1,3)] and result["barriers"][Vector2i(3,3)],"yellowANDacrossIDsindependentfromemptyblue")
	result=Energy.settle(links,Vector2i(3,0),{Vector2i(0,0):0},{})
	_check(result["barriers"][Vector2i(0,3)] and result["barriers"][Vector2i(1,3)] and not result["barriers"][Vector2i(3,3)],"oneunpressedyellowclosesbothyellowwhileblueopen")
	result=Energy.settle(links,Vector2i(3,0),{Vector2i(0,0):0},{},{},[Vector2i(1,0)])
	_check(not result["barriers"].values().has(true),"liveGoblinfillsyellowANDandbothcolorsopen")
	var legacy:Array[Dictionary]=links.duplicate(true)
	for link in legacy:link.erase("color")
	result=Energy.settle(legacy,Vector2i(2,2),{Vector2i(0,0):0,Vector2i(1,0):1},{})
	_check(result["barriers"].values().count(true)==3,"legacyuncoloredlinksretainoneglobalAND")
	var level39=Level.from_file("res://levels/north_39.json");_check(level39.error.is_empty(),"confirmed39withoptionalgroupcolorloads")
	_check(level39.pressure_color_at(Vector2i(3,1))=="blue" and level39.pressure_color_at(Vector2i(3,3))=="yellow" and level39.pressure_colors()==["blue","yellow"],"cellpaletteandcontrollercolorsconsistent")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_39.json"));data["energy_links"][0]["color"]="unknown"
	_check(not Level.from_dictionary(data).error.is_empty(),"unknowncolorexplicitlyrejected")
	var fixture:Dictionary={"schema_version":1,"id":"color_death_fixture","title":"Color atomic fixture","is_temporary":true,"source_note":"Independent color settlement regression fixture","terrain":["......","......","......","......","......"],"heroes":[{"id":"red","kind":"red","position":[0,1]},{"id":"green","kind":"green","position":[4,3]}],"active_hero":"red","crates":[[1,1],[0,0],[5,3]],"targets":[],"exits":[[5,0],[5,4]],"objective":"all_heroes_on_exits","monsters":[{"kind":"goblin","position":[2,1]},{"kind":"goblin","position":[4,1]}],"energy_links":[{"id":"blue","color":"blue","plates":[[0,0]],"activation":"all","barriers":[[0,3]],"pressure_sources":["hero","crystal"]},{"id":"yellow","color":"yellow","plates":[[4,1]],"activation":"all","barriers":[[4,3],[5,3]],"pressure_sources":["hero","crystal"]}]}
	var l=Level.from_dictionary(fixture);_check(l.error.is_empty(),"safelegalcoloreddeathfixtureloads:"+l.error)
	if not l.error.is_empty():quit(1);return
	var g=State.new();_check(g.load_level(l) and g.alive and g.pressure_is_active("blue") and g.pressure_is_active("yellow"),"initialbluecrystalandlivingyellowGoblinpressure")
	var before:Dictionary=g.snapshot();var capture:Dictionary=Events.capture(g);_check(g.try_move(Vector2i.RIGHT)==&"died","legalmixedpushmutualGdeathreleasesyellowkillsinactivehero")
	_check(g.living_monster_count()==0 and not g.heroes()[1]["alive"] and g.heroes()[0]["alive"],"commonstateGoblinmutualdeathandlateenergyhero")
	_check(g.barrier_is_active(Vector2i(4,3)) and g.barrier_is_active(Vector2i(5,3)) and not g.barrier_is_active(Vector2i(0,3)),"yellowrestoreswithoutclosingblue")
	_check(g.crates().size()==2 and g.crate_id(Vector2i(0,0))==1 and g.crate_id(Vector2i(2,1))==0,"yellowrestorationdestroysonlyoccupyingcrystalblueholderpreserved")
	var plan:Dictionary=Events.action(capture,g,Vector2i.RIGHT);_check(plan["goblin"].size()==2 and plan["fire"].is_empty() and plan["energy"].size()==2,"bothalreadytriggeredGoblinattacksretainedwithoutsecondround")
	var dead:Dictionary=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(l) and g.snapshot()==dead,"deathcannotbypassselection/restart/load")
	_check(g.undo() and g.snapshot()==before and g.alive and g.heroes()[1]["alive"] and g.crates().size()==3 and g.living_monster_count()==2,"atomicUndorestoresbothcolorsallentitiesandlives")
	_check(g.attack_phase().is_empty(),"Undoclearstransientattackmetadata")
	print("COLORED ENERGY RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
