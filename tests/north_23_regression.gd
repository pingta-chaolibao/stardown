extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const MONSTERS=[Vector2i(2,0),Vector2i(10,0),Vector2i(3,1),Vector2i(7,2),Vector2i(0,3),Vector2i(4,4),Vector2i(0,5),Vector2i(8,5),Vector2i(1,6),Vector2i(7,6)]
const OVERLAP=[Vector2i(0,4),Vector2i(0,6),Vector2i(1,5),Vector2i(2,1),Vector2i(3,0),Vector2i(7,5),Vector2i(8,6)]
var checks:=0
var failures:=0
func _init() -> void:
 _map_and_risks();_route_undo();_death();_isolation()
 print("NORTH 23 RESULT: 4 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _map_and_risks() -> void:
 var g:=_game();var danger:=0;var overlaps:=0
 _check(g.level.width==11 and g.level.height==7 and g.player==Vector2i(0,0) and g.hero_count()==1 and g.active_kind()=="red","confirmed11x7 single red marker1")
 for y in 7:
  for x in 11:
   var cell:=Vector2i(x,y);var count:=0
   for m in MONSTERS:
    if absi(cell.x-m.x)+absi(cell.y-m.y)==1:count+=1
   _check(g.level.is_floor(cell),"all77 floor including dangerous67")
   _check(g.monster_danger_at(cell)==(count>0),"exact cardinal union,not diagonal or box radius")
   if count>0:danger+=1
   if count>1:overlaps+=1;_check(cell in OVERLAP,"seven specified overlapping threat cells")
 _check(danger==26 and overlaps==7 and g.level.is_floor(Vector2i(0,6)) and g.monster_danger_at(Vector2i(0,6)),"67walkable terrain remains doubly dangerous,not invented wall")
 for c in [Vector2i(-1,0),Vector2i(11,0),Vector2i(0,-1),Vector2i(0,7)]:_check(not g.level.is_floor(c) and g.blocks_sight(c),"out of bounds not walkable and blocks sight;range query itself is geometric")
 for i in MONSTERS.size():_check(g.monster_at(MONSTERS[i])==i and g.monsters()[i]["kind"]=="goblin" and g.monsters()[i]["alive"],"ten fixed typed IDs at confirmed markers")
 _check(g.crates().is_empty() and g.level.bushes.is_empty() and g.level.energy_links.is_empty() and g.level.fence_edges.is_empty(),"no invented mechanisms/objects")
 _check(g.level.exit_cell==Vector2i(9,6) and not g.is_complete(),"goal76not initially complete")
 var initial:=g.snapshot()
 _check(g.try_move(Vector2i.UP)==&"wall" and g.try_move(Vector2i.LEFT)==&"wall" and g.snapshot()==initial and g.history_size()==0,"corner boundary inputs atomic and uncounted")
func _route_undo() -> void:
 var g:=_game();var initial:=g.snapshot();var monsters:=g.monsters();var history:Array[Dictionary]=[];var n:=0;var solution:=_solution()
 for s in solution["path"]:
  history.append(g.snapshot());n+=1
  _check(g.try_move(DIRS[s])==&"moved" and g.alive and g.monsters()==monsters,"all31 legal safe steps,ten goblins stationary")
  _check(g.moves==n and g.history_size()==n and g.pushes==0 and g.swaps==0 and g.pulls==0 and g.is_complete()==(n==solution["moves"]),"no extra counted action or early victory")
 _check(g.player==Vector2i(9,6) and g.occupied_exits()==1,"hero76wins with allten goblins alive")
 while not history.is_empty():_check(g.undo() and g.snapshot()==history.pop_back(),"each undo restores all entity identities/life/world")
 _check(g.snapshot()==initial and not g.undo(),"all31undos restore pristine state")
func _death() -> void:
 var g:=_game()
 for s in "DRDR":g.try_move(DIRS[s])
 var before:=g.snapshot()
 _check(g.player==Vector2i(2,2) and g.try_move(Vector2i.UP)==&"died" and g.player==Vector2i(2,1) and not g.alive and g.moves==5,"enter overlap of goblins3/15 dies on action5")
 var dead:=g.snapshot()
 _check(g.try_move(Vector2i.UP)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and not g.load_level(Level.from_file("res://levels/north_22.json")) and g.snapshot()==dead,"dead hero cannot push adjacent goblin or escape by C/restart/load")
 _check(g.undo() and g.snapshot()==before and g.alive and g.monsters().size()==10,"one undo completely revives after double threat")
func _isolation() -> void:
 var g:=_game();var initial:=g.snapshot()
 _check(g.switch_hero()==&"single_hero" and g.snapshot()==initial,"goblins not selectable heroes")
 for n in range(1,23):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and g.history_size()==0 and g.monsters().size()==(3 if n==22 else 0),"prior22 worlds preserve original monster counts and clean history")
  _check(g.load_level(Level.from_file("res://levels/north_23.json")) and g.snapshot()==initial,"return23 restores ten original goblins")
 for s in _solution()["path"]:g.try_move(DIRS[s])
 _check(g.restart() and g.snapshot()==initial,"victory restart resets original entities/history")
func _game() -> State:
 var g:=State.new();_check(g.load_level(Level.from_file("res://levels/north_23.json")),"confirmed23loads");return g
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_23.json"))
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
