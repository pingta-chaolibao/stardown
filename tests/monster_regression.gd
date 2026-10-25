extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Monsters=preload("res://scripts/core/monster_rules.gd")
const Swap=preload("res://scripts/core/swap_rules.gd")
var checks:=0
var failures:=0
func _init() -> void:
 _data();_four_directions();_mixed_push();_multi_kills();_swaps_and_green();_energy_and_undo();_not_heroes();_export_replays()
 print("MONSTER RESULT: 7 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _base(kind:String="red") -> Dictionary:
 return {"schema_version":1,"id":"monster_fixture","title":"怪物独立测试","source_note":"机制夹具，不是正式关卡","is_temporary":true,"terrain":[".........",".........",".........",".........",".........",".........",".........",".........","........."],"player":[2,4],"hero_kind":kind,"crates":[],"targets":[],"objective":"none","monsters":_goblins([[4,4]])}
func _load(d:Dictionary) -> State:
 var g:=State.new();_check(g.load_level(Level.from_dictionary(d)),"valid monster fixture loads safely");return g
func _data() -> void:
 var d:=_base();_check(Level.from_dictionary(d).initial_monsters==[Vector2i(4,4)] and Level.from_dictionary(d).monster_kinds==PackedStringArray(["goblin"]),"optional coordinate data and stable numeric IDs")
 for entries in [null,{},[[4,4]],[{"position":[4,4]}],[{"kind":"future_monster","position":[4,4]}],[{"kind":"goblin","position":[4,4]},{"kind":"goblin","position":[4,4]}],[{"kind":"goblin","position":[4.5,4]}],[{"kind":"goblin","position":[true,4]}],[{"kind":"goblin","position":[9,0]}],[{"kind":"goblin","position":[2,4]}],[{"kind":"goblin","position":[4]}],[{"kind":"goblin","position":[4,-1]}]]:
  d=_base();d["monsters"]=entries;_check(not Level.from_dictionary(d).error.is_empty(),"reject invalid/duplicate/outside/hero-overlap monster data")
 d=_base();d["crates"]=[[4,4]];_check(not Level.from_dictionary(d).error.is_empty(),"monster cannot overlap crystal")
 d=_base();d["bushes"]=[[4,4]];_check(not Level.from_dictionary(d).error.is_empty(),"monster cannot overlap bush")
 d=_base();d["terrain"][4]="....#....";_check(not Level.from_dictionary(d).error.is_empty(),"monster cannot start in fixedwall")
 _check(Monsters.is_supported("goblin") and Monsters.is_stationary("goblin") and not Monsters.is_supported("future_monster") and not Monsters.is_stationary("future_monster"),"onlyexplicitgoblinbehavior,no unknown-kind default")
 for n in range(1,22):
  var g:=State.new();_check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and g.monsters().is_empty() and not g.snapshot().has("monster_positions"),"all21legacy maps retain empty monsters and old snapshot shape")
func _four_directions() -> void:
 for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
  var d:=_base();var start:Vector2i=Vector2i(4,4)-dir*2;d["player"]=[start.x,start.y];var g:=_load(d);var before:=g.snapshot()
  _check(not g.monster_danger_at(start) and g.monster_danger_at(start+dir),"only next orthogonal cell threatened")
  _check(g.try_move(dir)==&"died" and not g.alive and g.death_reason=="monster" and g.moves==1,"enter range dies before another input can push monster")
  var dead:=g.snapshot();_check(g.try_move(dir)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and g.snapshot()==dead,"already-dead hero cannot escape by pushing/switch/restart")
  _check(g.undo() and g.snapshot()==before and g.alive and g.monster_at(Vector2i(4,4))==0,"oneUndo restores hero and stationary monster")
 for diagonal in [Vector2i(3,3),Vector2i(5,3),Vector2i(3,5),Vector2i(5,5)]:
  var d:=_base();d["player"]=[diagonal.x,diagonal.y];var g:=_load(d);_check(g.alive and not g.monster_danger_at(diagonal),"all4diagonal corners safe,not 8-neighbor radius")
 var unsafe:=_base();unsafe["player"]=[3,4];var g:=State.new();_check(not g.load_level(Level.from_dictionary(unsafe)),"unsafe initial adjacency rejected,not a push escape loophole")
func _mixed_push() -> void:
 for dir in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
  var origin:Vector2i=Vector2i(4,4)-dir*3;var d:=_base();d["player"]=[origin.x,origin.y];d["crates"]=[[origin.x+dir.x,origin.y+dir.y]];d["monsters"]=_goblins([[origin.x+dir.x*2,origin.y+dir.y*2],[origin.x+dir.x*3,origin.y+dir.y*3]])
  var g:=_load(d);var before:=g.snapshot();_check(g.try_move(dir)==&"pushed" and g.alive and g.monsters()[0]["position"]==origin+dir*3 and g.monsters()[1]["position"]==origin+dir*4 and not g.monsters()[0]["alive"] and not g.monsters()[1]["alive"] and g.crate_id(origin+dir*2)==0,"red pushes completechain thenadjacentGoblins mutuallydie;hero stays2cells away")
  _check(g.monster_at(origin+dir*3)==-1 and g.monster_at(origin+dir*4)==-1,"pushed deadGoblins no longercollide orreceive interactions")
  _check(g.undo() and g.snapshot()==before,"mixed monster push restores stable IDs/life")
  var end:Vector2i=origin+dir*4;var row:String=d["terrain"][end.y];d["terrain"][end.y]=row.substr(0,end.x)+"#"+row.substr(end.x+1);g=_load(d);before=g.snapshot()
  _check(g.try_move(dir)==&"crate_blocked" and g.snapshot()==before and g.history_size()==0,"wall at mixed-chain end moves no participant")
 var d:=_base();d.erase("player");d.erase("hero_kind");d["heroes"]=[{"id":"red","kind":"red","position":[0,4]},{"id":"blue","kind":"blue","position":[4,4]}];d["active_hero"]="red";d["crates"]=[[1,4],[3,4]];d["monsters"]=_goblins([[2,4]])
 var g:=_load(d);var before:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"pushed" and g.alive and g.hero_position(1)==Vector2i(5,4) and g.monster_at(Vector2i(3,4))==0,"red mixed hero/crystal/monster chain,passive blue does not exchange")
 _check(g.undo() and g.snapshot()==before,"oneUndo restores full mixed entity chain")
func _multi_kills() -> void:
 var d:=_base();d.erase("player");d.erase("hero_kind");d["heroes"]=[{"id":"red","kind":"red","position":[0,2]},{"id":"blue","kind":"blue","position":[4,2]},{"id":"green","kind":"green","position":[3,3]}];d["active_hero"]="red";d["crates"]=[[1,2]];d["monsters"]=_goblins([[2,2]])
 var g:=_load(d);var before:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"died" and g.hero_is_alive(0) and not g.hero_is_alive(1) and not g.hero_is_alive(2),"pushed monster kills both newly adjacent inactive heroes in same settlement")
 _check(g.hero_count()==3 and g.active_hero_id()=="red" and g.switch_hero()==&"dead","monster never C-selectable,any hero death locks party")
 _check(g.undo() and g.snapshot()==before,"atomicUndo restores both dead heroes and monster push")
func _swaps_and_green() -> void:
 _check(Swap.is_interactable(&"monster"),"living monster is explicit exchange target category")
 var d:=_base("blue");d["player"]=[1,4];var g:=_load(d);var before:=g.snapshot();var target:=g.swap_target(Vector2i.RIGHT)
 _check(target["kind"]==&"monster" and target["id"]==0,"first visible monster wins classification")
 _check(g.try_move(Vector2i.RIGHT)==&"swapped" and g.alive and g.player==Vector2i(4,4) and g.monster_at(Vector2i(1,4))==0 and g.swaps==1,"blue swaps distant monster,not a walk/push")
 _check(g.undo() and g.snapshot()==before,"exchangeUndo restores both endpoints/life")
 d=_base("blue");d["player"]=[1,4];d["monsters"]=_goblins([[4,4],[4,5]]);g=_load(d);before=g.snapshot()
 _check(g.try_move(Vector2i.RIGHT)==&"died" and g.death_reason=="monster" and g.monster_at(Vector2i(1,4))==0,"exchange completed then second monster kills new adjacent blue")
 _check(g.undo() and g.snapshot()==before,"fatal exchange reversible atomically")
 d=_base("green");d["player"]=[4,4];d["crates"]=[[3,4]];d["monsters"]=_goblins([[2,4]]);g=_load(d);before=g.snapshot()
 _check(g.try_move(Vector2i.RIGHT)==&"pulled" and g.alive and g.crate_id(Vector2i(4,4))==0 and g.monster_at(Vector2i(2,4))==0,"green only pulls nearest crystal,never monster behind it")
 _check(g.undo() and g.snapshot()==before,"green pull restores only moved crystal/hero")
func _energy_data(multi:bool) -> Dictionary:
 var d:=_base("blue");d["player"]=[4,3];d["monsters"]=_goblins([[3,2]]);d["energy_links"]=[{"id":"yellow","plate":[4,3],"barriers":[[3,2]],"pressure_sources":["hero","crystal"]}]
 if multi:
  d.erase("player");d.erase("hero_kind");d["heroes"]=[{"id":"blue","kind":"blue","position":[4,3]},{"id":"red","kind":"red","position":[1,2]}];d["active_hero"]="blue";d["crates"]=[[0,1]];d["energy_links"][0]["barriers"]=[[3,2],[1,2],[0,1]]
 return d
func _energy_and_undo() -> void:
 var d:=_energy_data(false);d.erase("player");d.erase("hero_kind");d["heroes"]=[{"id":"blue","kind":"blue","position":[4,3]},{"id":"red","kind":"red","position":[5,3]}];d["active_hero"]="blue"
 var g:=_load(d);var before:=g.snapshot()
 _check(g.try_move(Vector2i.UP)==&"moved" and g.alive and not g.monsters()[0]["alive"] and g.monster_at(Vector2i(3,2))==-1 and not g.monster_danger_at(Vector2i(4,2)),"energy reappears kills monster BEFORE its new adjacency could attack blue")
 _check(g.swap_target(Vector2i.LEFT)["result"]!=&"target","dead monster absent from exchange targets")
 g.switch_hero();_check(g.try_move(Vector2i.LEFT)==&"moved" and not g.monsters()[0]["alive"] and not g.barrier_is_active(Vector2i(3,2)),"red holds plate,reopening energy never revives monster")
 g.switch_hero();_check(g.try_move(Vector2i.LEFT)==&"moved" and g.player==Vector2i(3,2) and g.alive,"dead monster leaves no collision,hero occupies last cell while red holds plate")
 for i in 3:_check(g.undo(),"Undo actual action")
 _check(g.snapshot()==before and g.monsters()[0]["alive"],"Undo death step alone revives monster and all pressure state")
 g=_load(_energy_data(true));before=g.snapshot()
 _check(g.try_move(Vector2i.UP)==&"died" and g.hero_is_alive(0) and not g.hero_is_alive(1) and not g.monsters()[0]["alive"] and g.crates().is_empty(),"one restoration kills hero/monster and destroys crystal;dead monster does not attack survivingblue")
 _check(g.undo() and g.snapshot()==before and g.monsters()[0]["alive"] and g.crates().size()==1,"one atomicUndo restores all three entity categories/energy")
func _not_heroes() -> void:
 var d:=_base();d["player"]=[0,0];d["monsters"]=_goblins([[4,4]]);d["exit"]=[4,4];d["objective"]="player_on_exit";var g:=_load(d)
 _check(g.hero_count()==1 and g.hero_at(Vector2i(4,4))==-1 and g.occupied_exits()==0 and not g.is_complete() and g.switch_hero()==&"single_hero","monster cannot select or satisfy hero goal")
 var before:=g.monsters();_check(g.try_move(Vector2i.RIGHT)==&"moved" and g.monsters()==before,"unrelated input never moves stationary monster")
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)

func _export_replays() -> void:
 var cases:Array[Dictionary]=[]
 var blue:=_base("blue");blue["player"]=[1,4];blue["exit"]=[4,4];blue["objective"]="player_on_exit";cases.append({"name":"blue_swap","data":blue,"input":"R","dir":Vector2i.RIGHT})
 var red:=_base();red["player"]=[1,4];red["crates"]=[[2,4]];red["monsters"]=_goblins([[3,4]]);red["crystal_colors"]=["blue"];red["exit"]=[2,4];red["objective"]="player_on_exit";cases.append({"name":"red_push","data":red,"input":"R","dir":Vector2i.RIGHT})
 var energy:=_energy_data(false);energy["exit"]=[4,2];energy["objective"]="player_on_exit";cases.append({"name":"energy_kills_first","data":energy,"input":"U","dir":Vector2i.UP})
 var folder:="res://artifacts/verification/monster_replay_cases";DirAccess.make_dir_recursive_absolute(folder)
 for entry in cases:
  var g:=_load(entry["data"]);var initial:=_evidence(g);var result:=g.try_move(entry["dir"]);_check(g.alive and g.is_complete(),"actual model fixture ends in living goal")
  var final:=_evidence(g);var step:=final.duplicate(true);step["input"]=entry["input"];step["action"]="swap" if result==&"swapped" else "move"
  var solution:Dictionary={"level_id":g.level.id,"path":entry["input"],"moves":1,"pushes":g.pushes,"pulls":g.pulls,"swaps":g.swaps}
  var replay:Dictionary={"display":DisplayServer.get_name(),"game_implementation_commit":"model_fixture_no_video","path":entry["input"],"initial_state":initial,"final_state":final,"trace":[step]}
  for file in {"level":entry["data"],"solution":solution,"replay":replay}:
   FileAccess.open(folder+"/"+entry["name"]+"_"+file+".json",FileAccess.WRITE).store_string(JSON.stringify({"level":entry["data"],"solution":solution,"replay":replay}[file],"  ")+"\n")
func _evidence(g:State) -> Dictionary:
 var monsters:Array=[];var crystals:Array=[];var barriers:Array=[]
 for m in g.monsters():monsters.append({"id":m["id"],"kind":m["kind"],"position":[m["position"].x,m["position"].y],"alive":m["alive"]})
 for c in g.crates():crystals.append({"id":g.crate_id(c),"position":[c.x,c.y],"color":g.level.crystal_colors[g.crate_id(c)]})
 for c in g.barrier_states():barriers.append({"position":[c.x,c.y],"active":g.barrier_is_active(c)})
 return {"level_id":g.level.id,"player":[g.player.x,g.player.y],"hero_kind":g.active_kind(),"moves":g.moves,"pushes":g.pushes,"pulls":g.pulls,"swaps":g.swaps,"alive":g.alive,"completed":g.is_complete(),"crystals":crystals,"monsters":monsters,"death_reason":g.death_reason,"pressure":g.pressure_states(),"barriers":barriers}

func _goblins(cells:Array) -> Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for cell in cells:result.append({"kind":"goblin","position":cell})
 return result
