extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const Energy=preload("res://scripts/core/energy_rules.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const PLATES=[Vector2i(3,0),Vector2i(7,0),Vector2i(10,0),Vector2i(5,1),Vector2i(0,2),Vector2i(12,2)]
const GATES=[Vector2i(2,3),Vector2i(6,3),Vector2i(10,3)]
var checks:=0
var failures:=0
func _init() -> void:
 _map();_route_undo();_six_and();_real_death_and_crystal_undo();_simultaneous_destruction();_isolation()
 print("NORTH 21 RESULT: 6 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _map() -> void:
 var g:=_game();var rows=["....#...#....","....#...#....","....#...#....","##.###.###.##","##.........##","##.........##","##.........##","#####..######","#####...#####"];var count:=0
 for y in 9:
  for x in 13:
   _check(g.level.is_floor(Vector2i(x,y))==(rows[y][x]=="."),"all117 confirmed terrain")
   if g.level.is_floor(Vector2i(x,y)):count+=1
 _check(count==68 and g.hero_count()==3 and g.active_hero_id()=="red","68floors,3heroes,initialred")
 _check(g.hero_position(0)==Vector2i(0,0) and g.hero_position(1)==Vector2i(6,0) and g.hero_position(2)==Vector2i(12,0),"confirmed1red7green13blue")
 _check(g.level.fence_edges.is_empty() and g.level.bushes.is_empty(),"user confirmed nofences,no inferred decoration")
 var crystals=[Vector2i(5,0),Vector2i(2,1),Vector2i(10,1),Vector2i(10,6),Vector2i(6,8),Vector2i(7,8)]
 for i in 6:_check(g.crate_id(crystals[i])==i,"six crystal stable identities")
 _check(g.level.exit_cells==[Vector2i(5,5),Vector2i(6,5),Vector2i(7,5)] and g.occupied_exits()==0 and not g.is_complete(),"three ordinary green targets")
 _check(g.pressure_progress("yellow_01")==Vector2i(0,6),"six plates initially empty")
 for c in GATES:_check(g.barrier_is_active(c) and not g.is_walkable(c) and g.blocks_sight(c),"all three solid barriers block movement/sight")
 var before:=g.snapshot();_check(g.try_move(Vector2i.UP)==&"wall" and g.snapshot()==before,"initial boundary rejected atomically")
func _route_undo() -> void:
 var g:=_game();var initial:=g.snapshot();var history:Array[Dictionary]=[];var n:=0;var c:=0
 for s in _solution()["path"]:
  var before:=g.snapshot();var selected:=g.active_hero_id()
  if s=="C":c+=1;_check(g.switch_hero()==&"switched" and g.snapshot()==before,"C free,not in game history")
  else:
   n+=1;history.append(before);_check(g.try_move(DIRS[s]) in [&"moved",&"pushed",&"pulled",&"swapped"] and g.active_hero_id()==selected,"constructed119actions legal in shared Godot model")
   if n==26:_check(g.pressure_progress("yellow_01")==Vector2i(6,6),"first all-six opens all-three")
   if n==27:_check(g.hero_position(2)==Vector2i(10,6) and g.crate_id(Vector2i(10,0))==3,"blue exchanges through open right gate,crystal takes plate")
   if n==34:_check(g.crate_id(Vector2i(6,4))==4,"blue lifts first bottom crystal without editing state")
   if n==63:_check(g.crate_id(Vector2i(0,2))==4,"left plate crystal handoff")
   if n==84:_check(g.pressure_progress("yellow_01")==Vector2i(5,6) and g.alive,"deliberate safe release restores allthree")
   if n==85:_check(g.crate_id(Vector2i(7,0))==0 and g.pressure_progress("yellow_01")==Vector2i(6,6),"red push reopens allthree")
   if n==102:_check(g.crate_id(Vector2i(6,2))==5 and g.pulls==8,"last crystal pulled up central passage")
   if n==105:
    for p in PLATES:_check(g.crate_id(p)>=0,"six crystals replace every hero plate holder")
  _check(g.moves==n and g.history_size()==n and g.alive and g.crates().size()==6 and g.last_mechanism_error.is_empty(),"atomic world/counters/life")
  _check(g.is_complete()==(n==119),"only three distinct hero goals win")
  for gate in GATES:_check(g.barrier_is_active(gate)==(n<26 or n==84) and g.blocks_sight(gate)==g.barrier_is_active(gate),"global all-six determines movement and sight together")
 _check(n==119 and c==21 and g.pushes==10 and g.pulls==8 and g.swaps==10,"119actions21freeC,10push8pull10swap")
 _check(g.hero_position(0)==Vector2i(6,5) and g.hero_position(1)==Vector2i(5,5) and g.hero_position(2)==Vector2i(7,5),"final goals without color assignment")
 while not history.is_empty():_check(g.undo() and g.snapshot()==history.pop_back() and g.active_hero_id()=="red","119atomicundos restore entireworld,retain currentred")
 _check(g.snapshot()==initial and not g.undo(),"empty history after all actual actions")
func _six_and() -> void:
 var g:=_game()
 for mask in 64:
  var crystals:Dictionary={}
  for i in 6:
   if mask & (1<<i):crystals[PLATES[i]]=i
  var result:=Energy.settle(g.level.energy_links,[Vector2i(0,0),Vector2i(6,0),Vector2i(12,0)],crystals,{})
  _check(result["error"].is_empty() and result["pressure"]["yellow_01"]==(mask==63),"all64six-plate subsets,only allsix")
  for gate in GATES:_check(result["barriers"][gate]==(mask!=63),"all3synchronized,never independentgroups")
 var mixed:=Energy.settle(g.level.energy_links,[PLATES[0],PLATES[1],PLATES[2]],{PLATES[3]:0,PLATES[4]:1,PLATES[5]:2},{})
 _check(mixed["pressure"]["yellow_01"] and mixed["alive"],"inactive heroes and crystals both hold plates")
func _real_death_and_crystal_undo() -> void:
 var g:=_game();_advance(g,43);_choose(g,"red");var before:=g.snapshot()
 _check(g.hero_position(2)==GATES[0] and g.player==Vector2i(0,2),"actual route prefix blue on left energy,red on plate")
 _check(g.try_move(Vector2i.UP)==&"died" and not g.hero_is_alive(2) and g.hero_is_alive(0),"release plate kills inactive blue")
 var dead:=g.snapshot();_check(g.switch_hero()==&"dead" and g.try_move(Vector2i.RIGHT)==&"dead" and not g.restart() and not g.load_level(Level.from_file("res://levels/north_20.json")) and g.snapshot()==dead,"no C/direction/restart/map death bypass")
 _check(g.undo() and g.snapshot()==before and g.active_hero_id()=="red" and g.hero_is_alive(2),"Undo revives all original world,retains currentred")
 g.restart();_advance(g,101);_choose(g,"blue");before=g.snapshot()
 _check(g.crate_id(GATES[1])==5,"actual last crystal on passable central energy")
 _check(g.try_move(Vector2i.UP)==&"moved" and g.alive and g.crates().size()==5 and g.crate_id(GATES[1])==-1,"release sixplate destroys crystalID5,not a cold-start removal")
 for gate in GATES:_check(g.barrier_is_active(gate),"one release restores allthree")
 _check(g.undo() and g.snapshot()==before and g.crate_id(GATES[1])==5 and g.active_hero_id()=="blue","single Undo restores destroyed identity/all six plates/open gates")
func _simultaneous_destruction() -> void:
 var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_21.json"))
 for i in 3:d["heroes"][i]["position"]=[PLATES[i].x,PLATES[i].y]
 d["crates"]=[[5,1],[0,2],[12,2],[2,3],[6,3],[10,3]]
 var g:=State.new();_check(g.load_level(Level.from_dictionary(d)),"independent test fixture:6held,crystals on all3absent gates")
 var before:=g.snapshot();_check(g.try_move(Vector2i.DOWN)==&"moved" and g.alive and g.crates().size()==3,"one release destroys3gatecrystals simultaneously")
 _check(g.undo() and g.snapshot()==before and g.crates().size()==6,"oneundo restores all3destroyed IDs and mechanism state")
func _isolation() -> void:
 var g:=_game();var initial:=g.snapshot();g.switch_hero();_check(not g.undo() and g.snapshot()==initial and g.active_hero_id()=="green","no-history C remains selected")
 for n in range(1,21):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and g.moves==0 and g.history_size()==0,"old20independent history")
  _check(g.load_level(Level.from_file("res://levels/north_21.json")) and g.snapshot()==initial and g.level.fence_edges.is_empty() and g.active_hero_id()=="red","21restores confirmed nofence world")
 _advance(g,119);_check(g.restart() and g.snapshot()==initial and g.active_hero_id()=="red","victoryrestart resets all6crystals/3heroes/6plates")
func _advance(g:State,n:int) -> void:
 for s in _solution()["path"]:
  if g.moves>=n:return
  if s=="C":g.switch_hero()
  else:_check(g.try_move(DIRS[s]) in [&"moved",&"pushed",&"pulled",&"swapped"],"legal tested prefix")
func _choose(g:State,id:String) -> void:
 for i in g.hero_count():
  if g.active_hero_id()==id:return
  g.switch_hero()
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_21.json"))
func _game() -> State:
 var g:=State.new();_check(g.load_level(Level.from_file("res://levels/north_21.json")),"confirmed21 loads");return g
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
