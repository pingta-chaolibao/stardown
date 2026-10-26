extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Protection=preload("res://scripts/core/protection_rules.gd")
const Heroes=preload("res://scripts/core/hero_rules.gd")
const Events=preload("res://scripts/view/feedback_events.gd")
const Timeline=preload("res://scripts/view/feedback_timeline.gd")
var checks:int=0
var failures:int=0
func _init()->void:call_deferred("_run")
func _run()->void:
	_coverage();_self_and_capabilities();_ally_and_undo();_fire_shields();_blockers();_energy_not_immune();_simultaneous();_displacement()
	print("YELLOW PROTECTION RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _check(ok:bool,message:String)->void:
	checks+=1
	if not ok:failures+=1;push_error("FAIL: "+message)
func _data(heroes:Array,monsters:Array=[],crates:Array=[],links:Array=[]) -> Dictionary:
	var d:Dictionary={"schema_version":1,"id":"yellow_fixture","title":"Yellow rule fixture","is_temporary":true,"source_note":"Independent yellow-protection regression fixture,not campaign","terrain":[".......",".......",".......",".......","......."],"heroes":heroes,"active_hero":heroes[0]["id"],"crates":crates,"targets":[],"monsters":monsters,"energy_links":links}
	if heroes.size()==1:d.merge({"exit":[6,4],"objective":"player_on_exit"})
	else:
		var exits:Array=[]
		for i in heroes.size():exits.append([i,4])
		d.merge({"exits":exits,"objective":"all_heroes_on_exits"})
	return d
func _hero(id:String,kind:String,p:Array)->Dictionary:return {"id":id,"kind":kind,"position":p}
func _goblin(p:Array)->Dictionary:return {"kind":"goblin","position":p}
func _dragon(p:Array,facing:String)->Dictionary:return {"kind":"fire_dragon","position":p,"facing":facing}
func _game(d:Dictionary)->State:
	var l=Level.from_dictionary(d);_check(l.error.is_empty(),"fixture schema:"+l.error)
	var g=State.new();_check(g.load_level(l),"fixture loads alive:"+g.last_mechanism_error);return g
func _coverage()->void:
	var p:Array[Vector2i]=[Vector2i(2,2),Vector2i(2,1),Vector2i(3,2),Vector2i(2,3),Vector2i(1,2),Vector2i(3,3),Vector2i(2,0)]
	var alive:Array[bool]=[true,true,true,true,true,true,true]
	var kinds:=PackedStringArray(["yellow","red","green","blue","red","green","blue"])
	_check(Protection.covered(kinds,p,alive)==[true,true,true,true,true,false,false],"self+fourcardinals only,no diagonal/distance2")
	alive[0]=false
	_check(not Protection.covered(kinds,p,alive).has(true),"dead yellow provides no protection")
	kinds[0]="red";alive[0]=true
	_check(not Protection.covered(kinds,p,alive).has(true),"non-yellow heroes never provide immunity")
	_check(Heroes.is_supported("yellow") and not Heroes.can_push("yellow") and not Heroes.can_pull("yellow") and not Heroes.can_swap("yellow"),"yellow only movement/protection capabilities")
func _self_and_capabilities()->void:
	var g=_game(_data([_hero("yellow","yellow",[1,1])],[_goblin([2,1])],[[1,2]]))
	if g.level==null:return
	_check(g.alive and g.protected_heroes()==[true] and g.monster_danger_at(g.player),"yellow may safely start in actual Goblin adjacency")
	var before:Dictionary=g.snapshot()
	_check(g.try_move(Vector2i.RIGHT)==&"cannot_push" and g.snapshot()==before,"cannot push Goblin despite protection")
	_check(g.try_move(Vector2i.DOWN)==&"cannot_push" and g.snapshot()==before,"cannot push crystal")
	_check(g.try_move(Vector2i.UP)==&"moved" and g.crate_id(Vector2i(1,2))==0 and g.pulls==0,"leaving adjacent crystal does not pull it")
	_check(g.undo() and g.snapshot()==before,"single Undo restores normal yellow movement")
	_check(g.switch_hero()==&"single_hero" and g.moves==0 and g.history_size()==0,"single-hero C is not an action")
	var old:=Level.from_dictionary(_data([_hero("red","red",[1,1])],[_goblin([2,1])]))
	var red=State.new();_check(not red.load_level(old),"unprotected red initial danger remains invalid")
func _ally_and_undo()->void:
	var g=_game(_data([_hero("yellow","yellow",[1,1]),_hero("red","red",[2,1])],[_goblin([3,1])]))
	if g.level==null:return
	_check(g.protected_heroes()==[true,true],"non-selected cardinal ally protected")
	var before:Dictionary=g.snapshot()
	_check(g.try_move(Vector2i.DOWN)==&"died" and not g.hero_is_alive(1) and g.hero_is_alive(0),"moving protector makes diagonal ally vulnerable in same action")
	var dead:Dictionary=g.snapshot()
	_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(g.level) and g.snapshot()==dead,"death cannot bypass C/restart/load")
	_check(g.undo() and g.snapshot()==before and g.protected_heroes()==[true,true] and g.attack_phase().is_empty(),"Undo restores protector/ally and clears transient phase")
	_check(g.switch_hero()==&"switched" and g.moves==0 and g.history_size()==0 and g.protected_heroes()==[true,true],"free C does not change protection or advance attack")
	_check(g.try_move(Vector2i.UP)==&"moved" and g.alive and g.undo() and g.active_hero_id()=="red" and g.protected_heroes()==[true,true],"ally movement and Undo retain current red selection")
func _fire_shields()->void:
	var d=_data([_hero("yellow","yellow",[2,1]),_hero("red","red",[5,1])],[_dragon([0,1],"right")]);d["active_hero"]="red"
	var g=_game(d)
	if g.level==null:return
	var before:Dictionary=g.snapshot();var capture:Dictionary=Events.capture(g)
	_check(g.try_move(Vector2i.RIGHT)==&"moved" and g.alive and not g.protected_heroes()[1],"far unprotected ally survives behind protected yellow")
	var ray:Dictionary=g.fire_rays()[0]
	_check(ray["cells"]==[Vector2i(1,1),Vector2i(2,1)] and ray["target"].is_empty() and ray["shielded_hero"]==0,"protected first hero blocks ray before farther target")
	var plan:Dictionary=Events.action(capture,g,Vector2i.RIGHT);var clock=Timeline.new();clock.start(plan)
	_check(plan["fire"].is_empty() and plan["goblin"].is_empty() and plan["shields"].size()==1 and is_equal_approx(clock.duration,Timeline.MOVE_SECONDS),"blocked attack gets shield feedback without attack animation/wait")
	_check(g.undo() and g.snapshot()==before,"Undo restores fire shield geometry")
	g.switch_hero();before=g.snapshot()
	_check(g.try_move(Vector2i.DOWN)==&"died" and not g.hero_is_alive(1) and g.hero_is_alive(0),"leaving fire line exposes formerly screened ally")
	_check(g.undo() and g.snapshot()==before and g.active_hero_id()=="yellow","Undo restores fire occluder without undoing selection")
	d=_data([_hero("yellow","yellow",[2,0]),_hero("red","red",[2,1]),_hero("green","green",[5,1])],[_dragon([0,1],"right")]);d["active_hero"]="green";g=_game(d)
	if g.level==null:return
	_check(g.try_move(Vector2i.RIGHT)==&"moved" and g.alive and g.fire_rays()[0].get("shielded_hero")==1,"protected non-yellow ally also blocks fire for distant hero")
func _blockers()->void:
	for kind in ["crystal","wall","bush","energy"]:
		var d:Dictionary=_data([_hero("yellow","yellow",[4,1])],[_dragon([0,1],"right")])
		if kind=="crystal":d["crates"]=[[2,1]]
		if kind=="wall":d["terrain"][1]="..#...."
		if kind=="bush":d["bushes"]=[[2,1]]
		if kind=="energy":d["energy_links"]=[{"id":"yellow","plate":[6,3],"barriers":[[2,1]],"pressure_sources":["hero","crystal"]}]
		var g=_game(d)
		if g.level==null:continue
		var ray:Dictionary=g.fire_rays()[0]
		_check(ray["cells"]==[Vector2i(1,1)] and ray["target"].is_empty() and not ray.has("shielded_hero"),kind+" blocks before protected hero,no immunity-based penetration")
		_check(g.try_move(Vector2i.LEFT)==&"moved" and g.alive,kind+"existing blocker preserves effective-action safety")
func _energy_not_immune()->void:
	var d:Dictionary=_data([_hero("red","red",[0,0]),_hero("yellow","yellow",[3,1])],[_goblin([4,1])],[],[{"id":"yellow","plate":[0,0],"barriers":[[3,1]],"pressure_sources":["hero","crystal"]}])
	var g=_game(d)
	if g.level==null:return
	var before:Dictionary=g.snapshot()
	_check(g.protected_heroes()==[false,true] and not g.barrier_is_active(Vector2i(3,1)),"yellow protected from adjacent Goblin on inactive energy")
	_check(g.try_move(Vector2i.DOWN)==&"died" and not g.hero_is_alive(1) and g.death_reason=="energy","yellow protection never prevents energy restoration death")
	_check(g.undo() and g.snapshot()==before and g.protected_heroes()==[false,true],"atomic Undo restores energy/protector/life")
func _simultaneous()->void:
	var d:Dictionary=_data([_hero("yellow","yellow",[1,1]),_hero("red","red",[2,1]),_hero("green","green",[0,3])],[_goblin([3,1]),_dragon([3,2],"up")]);d["active_hero"]="green"
	var g=_game(d)
	if g.level==null:return
	var before:Dictionary=g.snapshot();var capture:Dictionary=Events.capture(g)
	_check(g.try_move(Vector2i.UP)==&"moved" and g.alive and g.living_monster_count()==0,"protection does not cancel same-snapshot monster mutual death")
	var plan:Dictionary=Events.action(capture,g,Vector2i.UP)
	_check(plan["fire"].size()==1 and plan["goblin"].size()==1 and plan["shields"].size()==1 and g.hero_is_alive(1),"dead attackers retain real mutual attacks,protected red gets no Goblin strike")
	_check(g.undo() and g.snapshot()==before and g.living_monster_count()==2,"Undo restores both simultaneous attackers and protection")
func _displacement()->void:
	var g=_game(_data([_hero("red","red",[0,1]),_hero("yellow","yellow",[1,1])]))
	if g.level==null:return
	var before:Dictionary=g.snapshot()
	_check(g.try_move(Vector2i.RIGHT)==&"pushed" and g.hero_position(1)==Vector2i(2,1) and g.protected_heroes()==[true,true],"red can passively push yellow,protection follows new identity position")
	_check(g.undo() and g.snapshot()==before,"Undo restores passively displaced protector")
	var d:Dictionary=_data([_hero("blue","blue",[0,1]),_hero("yellow","yellow",[3,1]),_hero("red","red",[4,1])],[_goblin([5,1])]);g=_game(d)
	if g.level==null:return
	before=g.snapshot()
	_check(g.try_move(Vector2i.RIGHT)==&"died" and g.hero_position(0)==Vector2i(3,1) and g.hero_position(1)==Vector2i(0,1) and not g.hero_is_alive(2),"blue exchange moves yellow away and immediately releases ally protection,no passive exchange chain")
	_check(g.undo() and g.snapshot()==before and g.active_hero_id()=="blue" and g.protected_heroes()==[false,true,true],"atomic exchange Undo restores range and red life,keeps selection")
