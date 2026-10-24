extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Heroes=preload("res://scripts/core/hero_rules.gd")
var checks:=0
var failures:=0
func _init() -> void:
 _capabilities();_side_and_back();_single_chain();_blocked();_fatal_and_mutual()
 print("GREEN DRAGON PULL RESULT: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _base() -> Dictionary:
 return {"schema_version":1,"id":"green_dragon_fixture","title":"拉龙独立测试","is_temporary":true,"source_note":"独立机制夹具，非第27关通关","terrain":[".........",".........",".........",".........",".........",".........",".........",".........","........."],"player":[4,4],"hero_kind":"green","crates":[],"targets":[],"objective":"none","monsters":[{"kind":"fire_dragon","position":[3,4],"facing":"up"}]}
func _load(d:Dictionary) -> State:
 var g:=State.new();_check(g.load_level(Level.from_dictionary(d)),"valid safe fixture loads");return g
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+message)
func _capabilities() -> void:
 _check(Heroes.can_pull_target("green","crystal") and Heroes.can_pull_target("green","fire_dragon"),"only confirmed green target kinds")
 for kind in ["hero","goblin","future_monster"]:_check(not Heroes.can_pull_target("green",kind),"green cannot pull unsupported target "+kind)
 for role in ["red","blue"]:_check(not Heroes.can_pull_target(role,"fire_dragon"),"other roles do not auto-pull")
func _side_and_back() -> void:
 for direction in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
  for face in [Vector2i(-direction.y,direction.x),-direction]:
   var d:=_base();var p:Vector2i=Vector2i(4,4)-direction;d["monsters"][0]["position"]=[p.x,p.y];d["monsters"][0]["facing"]={Vector2i.UP:"up",Vector2i.DOWN:"down",Vector2i.LEFT:"left",Vector2i.RIGHT:"right"}[face]
   var g:=_load(d);var before:=g.snapshot()
   _check(g.try_move(direction)==&"pulled" and g.alive and g.player==Vector2i(4,4)+direction and g.monsters()[0]["position"]==Vector2i(4,4),"side/back automatic adjacent dragon follows one tile")
   _check(g.monsters()[0]["facing"]==face and g.pulls==1 and g.moves==1 and g.history_size()==1 and g.pushes==0,"facing preserved,one counted action/pull")
   _check(g.undo() and g.snapshot()==before,"Undo restores fixed direction and both positions")
   g.try_move(direction);_check(g.restart() and g.snapshot()==before,"restart restores original dragon and pull count")
 var d:=_base();var g:=_load(d);_check(g.try_move(Vector2i.DOWN)==&"moved" and g.monsters()[0]["position"]==Vector2i(3,4) and g.pulls==0,"side neighbour not dragged sideways")
 d=_base();d["monsters"][0]["position"]=[5,4];g=_load(d);var before:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"cannot_push" and g.snapshot()==before,"green cannot push a fire dragon")
func _single_chain() -> void:
 var d:=_base();d["monsters"].append({"kind":"fire_dragon","position":[2,4],"facing":"up"});var g:=_load(d);var before:=g.snapshot()
 _check(g.try_move(Vector2i.RIGHT)==&"pulled" and g.monsters()[0]["position"]==Vector2i(4,4) and g.monsters()[1]["position"]==Vector2i(2,4) and g.pulls==1,"nearest dragon only,no chain pull")
 _check(g.undo() and g.snapshot()==before,"single chain Undo exact")
 d=_base();d["crates"]=[[2,4]];g=_load(d);_check(g.try_move(Vector2i.RIGHT)==&"pulled" and g.crate_id(Vector2i(2,4))==0,"crystal behind dragon does not follow")
 d=_base();d["crates"]=[[3,4]];d["monsters"][0]["position"]=[2,4];g=_load(d);_check(g.try_move(Vector2i.RIGHT)==&"pulled" and g.crate_id(Vector2i(4,4))==0 and g.monsters()[0]["position"]==Vector2i(2,4),"crystal pull unchanged,dragon behind crystal stays")
 d=_base();d["monsters"][0]["kind"]="goblin";d["monsters"][0].erase("facing");d["monsters"][0]["position"]=[2,4];d["player"]=[4,4];g=_load(d);_check(g.try_move(Vector2i.RIGHT)==&"moved" and g.monsters()[0]["position"]==Vector2i(2,4),"no extension to Goblin pulling")
func _blocked() -> void:
 for obstruction in ["wall","bush","crystal","energy","boundary","fence"]:
  var d:=_base();var expected:StringName=&"wall"
  match obstruction:
   "wall":d["terrain"][4]=".....#..."
   "bush":d["bushes"]=[[5,4]];expected=&"bush_blocked"
   "crystal":d["crates"]=[[5,4]];expected=&"cannot_push"
   "energy":d["energy_links"]=[{"id":"gate","plate":[0,0],"barriers":[[5,4]],"pressure_sources":["hero","crystal"]}];expected=&"energy_blocked"
   "boundary":d["player"]=[8,4];d["monsters"][0]["position"]=[7,4]
   "fence":d["fences"]=[[[3,4],[4,4]]];expected=&"fence_blocked"
  var g:=_load(d);var before:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==expected and g.snapshot()==before and g.history_size()==0,"blocked hero/dragon edge atomically prevents pull and attack: "+obstruction)
func _fatal_and_mutual() -> void:
 # Safe prestate: solid energy shields the hero from the second dragon.
 # Stepping onto the plate both pulls the first dragon and opens their rays.
 var d:=_base();d["player"]=[3,3];d["monsters"]=[{"kind":"fire_dragon","position":[3,4],"facing":"right"},{"kind":"fire_dragon","position":[6,3],"facing":"left"}];d["energy_links"]=[{"id":"shield","plate":[3,2],"barriers":[[4,3]],"pressure_sources":["hero","crystal"]}];var g:=_load(d);var before:=g.snapshot()
 _check(g.try_move(Vector2i.UP)==&"pulled" and g.alive and not g.monsters()[0]["alive"] and not g.monsters()[1]["alive"],"pull dragon into mutual fire,targets sampled after pull,both die")
 _check(g.pulls==1 and g.moves==1 and g.fire_rays().is_empty(),"dead pulled dragons no longer threaten")
 _check(g.undo() and g.snapshot()==before and g.monsters()[0]["facing"]==Vector2i.RIGHT,"Undo restores mutually killed dragons and pull")
 # A safe earlier move positions the hero for a subsequent pull into another ray.
 d=_base();d["player"]=[2,3];d["monsters"]=[{"kind":"fire_dragon","position":[3,4],"facing":"right"},{"kind":"fire_dragon","position":[6,2],"facing":"left"}];g=_load(d)
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and g.alive,"reachable safe prestate before fatal pull")
 before=g.snapshot();_check(g.try_move(Vector2i.UP)==&"died" and g.monsters()[0]["position"]==Vector2i(3,3) and g.monsters()[0]["facing"]==Vector2i.RIGHT and g.pulls==1,"pull commits then other dragon kills hero at new position")
 var dead:=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and g.try_move(Vector2i.LEFT)==&"dead" and g.snapshot()==dead,"fatal pull onlyUndo,not switch/restart/escape")
 _check(g.undo() and g.snapshot()==before and g.alive,"oneUndo restores fatal pull,hero life,dragon and direction")
