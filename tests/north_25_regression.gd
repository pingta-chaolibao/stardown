extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const CRYSTALS=[16,17,18,19,20,28,29,30,31,32,64,65,66,67,68,76,77,79,80]
const MONSTERS=[4,8,24,42,46,53,56,61,87,90,113,115,124,126,129]
const BLOCKED=[3,5,6,7,9,10,11,12,37,38,39,40,41,43,44,45,49,50,51,52,54,55,57,58,88,89,91,92,93,94,95,96,99,100,101,102,103,104,105,106,107,108,121]
const SWAPS=[3,4,5,6,7,8,9,12,18,19,20,21,22,23,30,31,32]
const GOBLIN_SWAPS={12:2,23:7,30:12,31:13,32:14}
const HERO_PATH=[Vector2i(0,1),Vector2i(0,2),Vector2i(3,2),Vector2i(4,2),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),Vector2i(8,1),Vector2i(11,1),Vector2i(11,2),Vector2i(11,3),Vector2i(11,4),Vector2i(11,5),Vector2i(11,6),Vector2i(7,6),Vector2i(6,6),Vector2i(4,6),Vector2i(3,6),Vector2i(3,5),Vector2i(0,5),Vector2i(0,6),Vector2i(0,7),Vector2i(0,8),Vector2i(1,8),Vector2i(1,9),Vector2i(1,10),Vector2i(3,10),Vector2i(5,10),Vector2i(8,10),Vector2i(8,9),Vector2i(9,9),Vector2i(10,9),Vector2i(11,9)]
var checks:=0
var failures:=0
func _init() -> void:
 _map();_route_undo();_wall_and_death();_isolation()
 print("NORTH 25 RESULT: 4 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _map() -> void:
 var g:=_game();var floor_count:=0
 _check(g.level.width==12 and g.level.height==11 and g.player==Vector2i.ZERO and g.active_kind()=="blue" and g.hero_count()==1,"confirmed12x11 blue1")
 for n in range(1,133):
  var c:=cell(n);_check(g.level.is_floor(c)==(n not in BLOCKED) and g.blocks_sight(c)==(n in BLOCKED),"all132floor/wall/sight cells match final numbered map")
  if n not in BLOCKED:floor_count+=1
 _check(floor_count==89 and g.level.void_cells.is_empty(),"89floors/43fixed blocked terrain;wooden clutter is not crate actors")
 for n in [93,94,95,96,105,106,107,108,121]:_check(not g.level.is_floor(cell(n)),"user-confirmed former question cells blocked")
 for i in CRYSTALS.size():_check(g.crate_id(cell(CRYSTALS[i]))==i and g.level.crystal_colors[i]=="purple","19ordinary crystals with separate stable identities,not bush/cluster or push box")
 for i in MONSTERS.size():_check(g.monster_at(cell(MONSTERS[i]))==i and g.monsters()[i]["kind"]=="goblin" and g.monsters()[i]["alive"],"15explicit Goblins at exact confirmed markers")
 _check(g.crates().size()==19 and g.monsters().size()==15 and g.level.exit_cell==Vector2i(11,9) and not g.is_complete(),"single hero goal120;no crystal/monster goal requirement")
 _check(g.level.bushes.is_empty() and g.level.energy_links.is_empty() and g.level.fence_edges.is_empty(),"no inferred mechanisms or independent fence")
func _route_undo() -> void:
 var g:=_game();var initial:=g.snapshot();var history:Array[Dictionary]=[];var n:=0;var swaps:=0
 for s in _solution()["path"]:
  var before:=g.snapshot();var old_hero:=g.player;var old_monsters:=g.monsters();history.append(before);n+=1
  if n in SWAPS:swaps+=1
  _check(g.try_move(DIRS[s])==(&"swapped" if n in SWAPS else &"moved") and g.alive and g.player==HERO_PATH[n-1],"all36legal exact positions using direction-first passive swap or single walk")
  _check(g.moves==n and g.history_size()==n and g.swaps==swaps and g.pushes==0 and g.pulls==0 and g.is_complete()==(n==36),"36directions/17swaps,no push/pull/early victory")
  _check(g.crates().size()==19 and g.monsters().size()==15,"all original entities survive")
  for m in g.monsters():
   _check(m["alive"] and m["kind"]=="goblin" and m["position"]==(old_hero if n in GOBLIN_SWAPS and m["id"]==GOBLIN_SWAPS[n] else old_monsters[m["id"]]["position"]),"only exchanged Goblin moves;no AI or passive chain ability")
  if n==12:_check(g.monster_at(Vector2i(8,1))==2 and not g.monster_danger_at(Vector2i(11,2)) and g.monster_danger_at(Vector2i(8,2)),"Goblin24exchange moves danger from old right corridor to8,1")
  if n==23:_check(g.monster_at(Vector2i(3,5))==7 and not g.monster_danger_at(Vector2i(0,6)) and g.monster_danger_at(Vector2i(3,6)),"Goblin61exchange opens left descent and threatens its new neighbors")
  if n==32:_check(g.monster_at(Vector2i(5,10))==14 and not g.monster_danger_at(Vector2i(8,9)),"third bottom exchange clears safe upward approach")
 _check(g.player==Vector2i(11,9) and g.swaps==17 and g.occupied_exits()==1,"blue goal120wins with19crystals/15living Goblins")
 while not history.is_empty():_check(g.undo() and g.snapshot()==history.pop_back(),"each undo restores all crystal/Goblin identities,positions,life/counters")
 _check(g.snapshot()==initial and not g.undo(),"all36undos restore exact initial world")
func _wall_and_death() -> void:
 var g:=_game();var target:=g.swap_target(Vector2i.RIGHT)
 _check(target["result"]==&"swap_blocked" and target["cell"]==Vector2i(2,0),"wall3blocks sight to Goblin4;cannot see through clutter")
 _check(g.try_move(Vector2i.RIGHT)==&"moved" and g.player==Vector2i(1,0) and g.swaps==0,"no visible legal target falls back to walking")
 var before:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"wall" and g.snapshot()==before,"walking fallback still cannot cross wall")
 _check(g.restart(),"restart safe wall probe")
 _check(g.try_move(Vector2i.DOWN)==&"moved" and g.player==Vector2i(0,1) and g.swaps==0,"down does not scan side crystal")
 before=g.snapshot();target=g.swap_target(Vector2i.RIGHT)
 _check(target["kind"]==&"crystal" and target["id"]==0 and target["cell"]==Vector2i(3,1),"right sees nearest crystal16 before all later objects")
 _check(g.try_move(Vector2i.RIGHT)==&"died" and not g.alive and g.player==Vector2i(3,1) and g.crate_id(Vector2i(0,1))==0 and g.moves==2 and g.swaps==1,"swap commits then Goblin4adjacency kills;no invented safe-swap exception")
 var dead:=g.snapshot();_check(g.try_move(Vector2i.DOWN)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and not g.load_level(Level.from_file("res://levels/north_24.json")) and g.snapshot()==dead,"death onlyUndo,not C/restart/load")
 _check(g.undo() and g.snapshot()==before and g.alive and g.crate_id(Vector2i(3,1))==0,"Undo revives and restores swapped crystal and counters atomically")
func _isolation() -> void:
 var g:=_game();var initial:=g.snapshot();_check(g.switch_hero()==&"single_hero" and g.snapshot()==initial,"15Goblins not selectable heroes")
 for n in range(1,25):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and g.history_size()==0,"prior24 world/history unchanged")
  _check(g.load_level(Level.from_file("res://levels/north_25.json")) and g.snapshot()==initial,"25restores19crystals/15original Goblins")
 for s in _solution()["path"]:g.try_move(DIRS[s])
 _check(g.restart() and g.snapshot()==initial,"victory restart restores all moved Goblins and original crystal IDs")
static func cell(n:int) -> Vector2i:return Vector2i((n-1)%12,(n-1)/12)
func _game() -> State:
 var g:=State.new();_check(g.load_level(Level.from_file("res://levels/north_25.json")),"confirmed25loads");return g
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_25.json"))
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
