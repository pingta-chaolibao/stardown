extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Energy=preload("res://scripts/core/energy_rules.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
var checks:int=0
var failures:int=0
func _init()->void:call_deferred("_run")
func _check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+label)
func _data()->Dictionary:
	return {"schema_version":1,"id":"goblin_pressure_fixture","title":"独立机关测试","is_temporary":true,"source_note":"独立规则夹具，非正式关卡；出生不推进火龙攻击，下一有效行动统一结算。","terrain":["........","........","........","........","........"],"heroes":[{"id":"red","kind":"red","position":[0,4]},{"id":"blue","kind":"blue","position":[6,3]}],"active_hero":"red","crates":[],"targets":[],"objective":"none","monsters":[{"kind":"fire_dragon","position":[3,0],"facing":"down"},{"kind":"goblin","position":[3,2]}],"energy_links":[{"id":"all","plate":[3,2],"barriers":[[6,3],[3,0]],"pressure_sources":["hero","crystal"]}],"energy_blocks":[{"kind":"all_monsters_defeated","position":[7,3]}]}
func _load(data:Dictionary)->State:
	var l=Level.from_dictionary(data);_check(l.error.is_empty(),"fixturevalid");var g=State.new();_check(g.load_level(l),g.last_mechanism_error);return g
func _run()->void:
	var cells:Array[Vector2i]=[Vector2i(3,2)]
	_check(Energy.pressure_matches(Vector2i(3,2),["hero","crystal"],Vector2i.ZERO,{},cells),"livingGoblinisgloballegacy-compatiblepressuresource")
	_check(not Energy.pressure_matches(Vector2i(3,2),["hero","crystal"],Vector2i.ZERO,{},[]),"dead/absentGoblinnopressure")
	var g=_load(_data());var initial:Dictionary=g.snapshot()
	_check(g.pressure_progress("all")==Vector2i(1,1) and g.pressure_cell_is_active("all",Vector2i(3,2)) and not g.barrier_is_active(Vector2i(6,3)),"livingGoblinholdsplatewithnohero/crystal")
	g.switch_hero();g.switch_hero();_check(g.snapshot()==initial and g.moves==0 and g.history_size()==0 and g.monsters()[0]["alive"],"freeCneitherattacknorreleasepressure")
	var before:Dictionary=Events.capture(g)
	_check(g.try_move(Vector2i.RIGHT)==&"died","effectiveactionfireskillsGoblindropsplateandrestoresenergy")
	_check(not g.monsters()[0]["alive"] and not g.monsters()[1]["alive"] and not g.hero_is_alive(1) and g.hero_is_alive(0),"lateenergykillsdragonandinactivebluewithoutrevivinganyvictim")
	_check(not g.pressure_is_active("all") and g.pressure_progress("all")==Vector2i(0,1) and not g.pressure_cell_is_active("all",Vector2i(3,2)),"Goblinbodydoesnotholdplate")
	_check(g.barrier_is_active(Vector2i(3,0)) and g.barrier_is_active(Vector2i(6,3)) and not g.barrier_is_active(Vector2i(7,3)),"latepressureenergyandfinalallmonsterconditionatomic")
	var phase:Dictionary=g.attack_phase();_check(phase["monster_alive"]==[true,true] and phase["hero_alive"]==[true,true] and not phase["barriers"][Vector2i(6,3)],"frozencommonattackphaseprecedeslategatereappearance")
	var plan:Dictionary=Events.action(before,g,Vector2i.RIGHT)
	_check(plan["fire"].size()==1 and plan["fire"][0]["target"]=={"kind":"monster","id":1} and plan["goblin"].is_empty(),"lateenergykilleddragonretainsitsonevalidattack")
	_check(plan["deaths"].size()==3 and plan["energy"].size()==3,"allrestorationanddeathsrepresentedwithoutsecondround")
	var dead:Dictionary=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(g.level) and g.snapshot()==dead,"cannotbypassinactiveheroenergydeath")
	_check(g.undo() and g.snapshot()==initial and g.attack_phase().is_empty(),"Undoalllives/Goblinpressure/bothblocktypesanddiscardstransientattackmetadata")
	_check(g.try_move(Vector2i.RIGHT)==&"died" and g.undo() and g.snapshot()==initial,"deterministicrepeat")
	var destroyed_data=_data();destroyed_data["crates"]=[[4,3]];destroyed_data["energy_links"][0]["barriers"].append([4,3]);g=_load(destroyed_data);initial=g.snapshot();before=Events.capture(g)
	_check(g.try_move(Vector2i.RIGHT)==&"died" and g.crates().is_empty(),"deathreleasedGoblinpressurealsodestroysenergycrystal")
	plan=Events.action(before,g,Vector2i.RIGHT);_check(plan["fire"].size()==1 and plan["deaths"].size()==4,"lockedattackandcrystalghostsurvivepostattackrestoration")
	_check(g.undo() and g.snapshot()==initial and g.crate_id(Vector2i(4,3))==0,"Undoexactdestroyedcrystalidentitywithpressureandlives")
	var d=_data();d["monsters"]=[{"kind":"goblin","position":[3,2]},{"kind":"goblin","position":[4,2]}];d["energy_links"][0]["barriers"]=[[6,3]];g=_load(d);initial=g.snapshot();before=Events.capture(g)
	_check(g.try_move(Vector2i.RIGHT)==&"died" and g.living_monster_count()==0 and g.pressure_progress("all")==Vector2i(0,1),"mutualGoblinattackdeathreleasesplateinkillsameaction")
	plan=Events.action(before,g,Vector2i.RIGHT);_check(plan["goblin"].size()==2 and plan["fire"].is_empty(),"bothsame-stepdeadGoblinstrikesstilldisplay")
	_check(g.undo() and g.snapshot()==initial,"UndoGoblinsandpressure")
	d=_data();d["monsters"]=[{"kind":"fire_dragon","position":[3,2],"facing":"right"}]
	var l=Level.from_dictionary(d);g=State.new();_check(l.error.is_empty() and not g.load_level(l) and "怪物压板规则尚未确认" in g.last_mechanism_error,"doesnotextendpressuretofireDragon")
	d=_data();d["swap_hero_color"]="purple";l=Level.from_dictionary(d);_check(l.error.is_empty() and l.swap_hero_color=="purple" and l.hero_definitions[1]["kind"]=="blue","purpletintdoesnotchangelogicidentity")
	d["swap_hero_color"]="gray";_check(not Level.from_dictionary(d).error.is_empty(),"unknownvisualtintrejected")
	print("GOBLIN PRESSURE RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
