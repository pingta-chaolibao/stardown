extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Monsters=preload("res://scripts/core/monster_rules.gd")
var checks:=0
var failures:=0
func _init() -> void:
 _data();_single_target();_blockers();_displacement();_energy();_mutual();_unresolved();_inactive_hero_simultaneous()
 print("FIRE DRAGON RESULT: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+message)
func _base() -> Dictionary:
 return {"schema_version":1,"id":"fire_fixture","title":"火龙独立测试","source_note":"独立机制夹具，非正式关卡","is_temporary":true,"terrain":[".........",".........",".........",".........",".........",".........",".........",".........","........."],"player":[0,0],"hero_kind":"red","crates":[],"targets":[],"objective":"none","monsters":[{"kind":"fire_dragon","position":[0,4],"facing":"right"}]}
func _load(d:Dictionary) -> State:
 var g:=State.new();_check(g.load_level(Level.from_dictionary(d)),"valid fire fixture loads without birth attack: "+g.last_mechanism_error);return g
func _data() -> void:
 for facing in [null,"",true,[1,0],"diagonal",1]:
  var d:=_base();d["monsters"][0]["facing"]=facing;_check(not Level.from_dictionary(d).error.is_empty(),"explicit cardinal direction required")
 var d:=_base();d["monsters"][0].erase("facing");_check(not Level.from_dictionary(d).error.is_empty(),"missing facing rejected")
 for facing in ["up","down","left","right"]:
  d=_base();d["monsters"][0]["facing"]=facing;var level:=Level.from_dictionary(d)
  _check(level.error.is_empty() and level.monster_facings[0]==Monsters.parse_facing(facing),"four stable directions parse")
 _check(not Monsters.threatens("fire_dragon",Vector2i(0,3),Vector2i(0,4)),"fire dragon never inherits Goblin cardinal attack")
func _single_target() -> void:
 var d:=_base();d["monsters"].append({"kind":"goblin","position":[3,4]});d["monsters"].append({"kind":"goblin","position":[6,4]})
 var g:=_load(d);var initial:=g.snapshot()
 _check(g.monsters()[1]["alive"] and g.monsters()[2]["alive"] and g.moves==0,"load never adds fire round")
 for i in 3:_check(g.fire_rays()[0]["target"]=={"kind":"monster","id":1} and g.snapshot()==initial,"view queries never attack")
 _check(g.try_move(Vector2i.LEFT)==&"wall" and g.snapshot()==initial,"failed boundary cannot be implicit wait")
 _check(g.try_move(Vector2i.ZERO)==&"invalid_direction" and g.snapshot()==initial,"invalid direction no fire")
 _check(g.switch_hero()==&"single_hero" and g.snapshot()==initial,"selection never advances fire")
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and not g.monsters()[1]["alive"] and g.monsters()[2]["alive"],"first effective action kills exactly nearest monster,not farther target")
 var once:=g.snapshot()
 _check(g.monster_at(Vector2i(3,4))==-1 and not g.monster_danger_at(Vector2i(3,3)),"killed Goblin leaves no collision or threat")
 _check(g.try_move(Vector2i.DOWN)==&"moved" and not g.monsters()[2]["alive"],"next action reaches the next target")
 _check(g.undo() and g.snapshot()==once and g.monsters()[2]["alive"],"Undo restores second victim and entire prior action")
 _check(g.undo() and g.snapshot()==initial and g.monsters()[1]["alive"],"Undo restores first victim and facing")
 d=_base();d.erase("player");d.erase("hero_kind");d["heroes"]=[{"id":"active","kind":"green","position":[0,0]},{"id":"victim","kind":"red","position":[5,4]}];d["active_hero"]="active";d["monsters"].append({"kind":"goblin","position":[3,4]});g=_load(d);initial=g.snapshot()
 _check(g.switch_hero()==&"switched" and g.switch_hero()==&"switched" and g.snapshot()==initial and g.moves==0,"C changes selection only,not attacks/history")
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and g.alive and not g.monsters()[1]["alive"],"near monster protects farther inactive hero for this action")
 once=g.snapshot();_check(g.try_move(Vector2i.DOWN)==&"died" and g.death_reason=="fire" and not g.hero_is_alive(1) and g.hero_is_alive(0),"next action fires once at inactive hero")
 var dead:=g.snapshot();_check(g.switch_hero()==&"dead" and g.try_move(Vector2i.RIGHT)==&"dead" and not g.restart() and not g.load_level(Level.from_dictionary(_base())) and g.snapshot()==dead,"any fire death locks movement,C,restart and reload")
 _check(g.undo() and g.snapshot()==once and g.alive and g.active_hero_id()=="active","onlyUndo revives and restores full step without changing choice")
func _blockers() -> void:
 for blocker in ["crystal","wall","bush","energy"]:
  var d:=_base();d.erase("player");d.erase("hero_kind");d["heroes"]=[{"id":"active","kind":"red","position":[0,0]},{"id":"protected","kind":"blue","position":[7,4]}];d["active_hero"]="active"
  match blocker:
   "crystal":d["crates"]=[[3,4]]
   "wall":d["terrain"][4]="...#....."
   "bush":d["bushes"]=[[3,4]]
   "energy":d["energy_links"]=[{"id":"gate","plate":[8,8],"barriers":[[3,4]],"pressure_sources":["hero","crystal"]}]
  var g:=_load(d);_check(g.fire_danger_at(Vector2i(2,4)) and not g.fire_danger_at(Vector2i(3,4)) and not g.fire_danger_at(Vector2i(7,4)),"ray stops before "+blocker)
  _check(g.try_move(Vector2i.RIGHT)==&"moved" and g.alive,"blocker protects inactive hero: "+blocker)
  if blocker=="crystal":_check(g.crate_id(Vector2i(3,4))==0,"fire does not burn crystal")
 var d:=_base();d["player"]=[4,3];d["monsters"][0]["position"]=[0,4];d["energy_links"]=[{"id":"gate","plate":[4,3],"barriers":[[3,4]],"pressure_sources":["hero","crystal"]}]
 var g:=_load(d);_check(not g.barrier_is_active(Vector2i(3,4)) and g.fire_danger_at(Vector2i(7,4)),"absent energy passes fire")
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and g.barrier_is_active(Vector2i(3,4)) and not g.fire_danger_at(Vector2i(7,4)),"restored energy blocks fire in same action")
func _displacement() -> void:
 for kind in ["red","blue"]:
  var d:=_base();d["hero_kind"]=kind;d["player"]=[0,4];d["monsters"][0]={"kind":"fire_dragon","position":[3,4],"facing":"up"}
  if kind=="red":d["player"]=[1,4];d["crates"]=[[2,4]]
  var g:=_load(d);var before:=g.snapshot();var result:=g.try_move(Vector2i.RIGHT)
  _check(result==(&"pushed" if kind=="red" else &"swapped") and g.monsters()[0]["position"]==(Vector2i(4,4) if kind=="red" else Vector2i(0,4)) and g.monsters()[0]["facing"]==Vector2i.UP,"red mixed push / blue swap preserves dragon facing")
  _check(g.undo() and g.snapshot()==before,"Undo displacement restores position and facing")
 var d:=_base();d["player"]=[1,4];d["crates"]=[[2,4]];d["monsters"][0]={"kind":"fire_dragon","position":[3,4],"facing":"up"};d["terrain"][4]="....#....";var g:=_load(d);var before:=g.snapshot()
 _check(g.try_move(Vector2i.RIGHT)==&"crate_blocked" and g.snapshot()==before,"blocked mixed chain does not attack or partially move")
func _energy() -> void:
 var d:=_base();d["player"]=[4,3];d["monsters"][0]={"kind":"fire_dragon","position":[0,4],"facing":"right"};d["energy_links"]=[{"id":"gate","plate":[4,3],"barriers":[[0,4]],"pressure_sources":["hero","crystal"]}]
 var g:=_load(d);var before:=g.snapshot()
 _check(g.try_move(Vector2i.DOWN)==&"moved" and g.alive and not g.monsters()[0]["alive"] and g.fire_rays().is_empty(),"energy kills dragon before it can attack newly aligned hero")
 _check(g.undo() and g.snapshot()==before and g.monsters()[0]["alive"] and g.monsters()[0]["facing"]==Vector2i.RIGHT,"Undo energy kill revives dragon with fixed direction and open gate")
func _unresolved() -> void:
 # Safe reachable prestate: solid energy shields Goblin until hero steps on plate.
 var d:=_base();d["player"]=[3,3];d["monsters"]=[{"kind":"fire_dragon","position":[4,0],"facing":"down"},{"kind":"goblin","position":[4,2]}];d["energy_links"]=[{"id":"gate","plate":[3,2],"barriers":[[4,1]],"pressure_sources":["hero","crystal"]}];var g:=_load(d);var before:=g.snapshot()
 _check(g.barrier_is_active(Vector2i(4,1)) and g.monsters()[1]["alive"] and not g.fire_danger_at(Vector2i(4,2)),"prestate safe: blocked flame and hero distance2 from Goblin")
 _check(g.try_move(Vector2i.UP)==&"died" and not g.alive and not g.monsters()[1]["alive"] and g.monsters()[0]["alive"] and g.death_reason=="monster" and g.moves==1 and not g.barrier_is_active(Vector2i(4,1)),"legal gate-opening action kills Goblin AND adjacent hero simultaneously")
 var dead:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and g.snapshot()==dead,"simultaneous death locks all normal actions")
 _check(g.undo() and g.snapshot()==before and g.monsters()[1]["alive"] and g.barrier_is_active(Vector2i(4,1)),"Undo restores both victims and pre-opening energy/pressure state")
 d=_base();d["fences"]=[[[1,4],[2,4]]];g=_load(d);before=g.snapshot()
 _check(g.try_move(Vector2i.RIGHT)==&"rule_unresolved" and g.snapshot()==before,"unconfirmed flame/fence behavior explicitly deferred")

func _mutual() -> void:
 var d:=_base();d["monsters"]=[{"kind":"fire_dragon","position":[0,4],"facing":"right"},{"kind":"fire_dragon","position":[3,4],"facing":"left"}];var g:=_load(d);var before:=g.snapshot()
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and not g.monsters()[0]["alive"] and not g.monsters()[1]["alive"] and g.fire_rays().is_empty(),"mutual dragons attack simultaneously,neither survives by array order")
 _check(g.undo() and g.snapshot()==before,"oneUndo restores both dragons,facing and action counters")
 d["monsters"].reverse();g=_load(d)
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and not g.monsters()[0]["alive"] and not g.monsters()[1]["alive"],"reversed definition order does not change mutual death")
 for facing in ["up","down","left","right"]:
  d=_base();d["monsters"][0]={"kind":"fire_dragon","position":[4,4],"facing":facing};var cell:Vector2i=Vector2i(4,4)+Monsters.parse_facing(facing);d["monsters"].append({"kind":"goblin","position":[cell.x,cell.y]});g=_load(d);before=g.snapshot()
  _check(g.try_move(Vector2i.RIGHT)==&"moved" and not g.monsters()[0]["alive"] and not g.monsters()[1]["alive"],"adjacent Goblin and facing dragon kill each other simultaneously "+facing)
  _check(g.undo() and g.snapshot()==before,"Undo restores mutual typed monster deaths "+facing)
 d=_base();d["monsters"]=[{"kind":"fire_dragon","position":[0,4],"facing":"right"},{"kind":"goblin","position":[1,4]},{"kind":"goblin","position":[3,4]}];g=_load(d)
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and not g.monsters()[0]["alive"] and not g.monsters()[1]["alive"] and g.monsters()[2]["alive"],"mutual death does not pierce to farther Goblin")
 _check(g.try_move(Vector2i.DOWN)==&"moved" and g.monsters()[2]["alive"] and g.fire_rays().is_empty(),"dead dragon never attacks on next action")
 d=_base();d["monsters"]=[{"kind":"goblin","position":[3,4]},{"kind":"goblin","position":[4,4]}];g=_load(d)
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and g.monsters()[0]["alive"] and g.monsters()[1]["alive"],"no unrequested Goblin-vs-Goblin behavior added")

func _inactive_hero_simultaneous() -> void:
 var d:=_base();d.erase("player");d.erase("hero_kind");d["heroes"]=[{"id":"red","kind":"red","position":[2,4]},{"id":"blue","kind":"blue","position":[3,0]}];d["active_hero"]="red";d["crates"]=[[3,3]];d["monsters"]=[{"kind":"fire_dragon","position":[0,1],"facing":"right"},{"kind":"goblin","position":[3,2]}];var g:=_load(d)
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and g.alive and g.monsters()[1]["alive"],"legal effective prefix: no pre-existing Goblin on fire line,no hero adjacent")
 var before:=g.snapshot()
 _check(g.try_move(Vector2i.UP)==&"died" and g.hero_is_alive(0) and not g.hero_is_alive(1) and not g.monsters()[1]["alive"] and g.pushes==1,"red mixed push brings Goblin into fire AND next to inactive blue;both victims die")
 _check(g.undo() and g.snapshot()==before and g.hero_is_alive(1) and g.monsters()[1]["alive"],"atomicUndo restores pushed crystal,Goblin,inactive hero and counters")
