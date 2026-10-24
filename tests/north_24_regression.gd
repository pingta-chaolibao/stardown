extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const GATE=Vector2i(1,1)
const PLATE=Vector2i(2,7)
const MONSTERS=[Vector2i(2,0),Vector2i(5,2),Vector2i(7,2),Vector2i(0,3),Vector2i(2,5),Vector2i(10,5),Vector2i(6,6),Vector2i(3,9)]
const PULLS=[1,8,9,10,27,28,29,30,51,52,53,70,71,72,77]
var checks:=0
var failures:=0
func _init() -> void:
 _map();_route_undo();_closed_gate();_pull_death();_cosmetic_and_isolation()
 print("NORTH 24 RESULT: 5 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _map() -> void:
 var g:=_game();var floors:=0;var danger:=0
 _check(g.level.width==13 and g.level.height==11 and g.player==Vector2i(8,7) and g.active_kind()=="green" and g.hero_count()==1,"confirmed13x11 green100")
 for y in 11:
  for x in 13:
   var c:=Vector2i(x,y);var blocked:bool=(y==9 and x>=10) or (y==10 and x>=7);var threatened:=false
   for m in MONSTERS:
    if absi(c.x-m.x)+absi(c.y-m.y)==1:threatened=true
   _check(g.level.is_floor(c)==not blocked and g.level.is_void(c)==blocked,"all143 corrected terrain/void cells")
   _check(g.monster_danger_at(c)==threatened,"static cardinal danger union independent of purple gate")
   if not blocked:floors+=1
   if not blocked and threatened:danger+=1
 _check(floors==134 and danger==29 and g.level.void_cells.size()==9,"134floor/9void/29inbounds threats")
 for x in range(7,13):_check(g.level.is_floor(Vector2i(x,0)),"user correction8to13 entire top row floor")
 _check(g.level.exit_cell==Vector2i(0,0) and g.crate_id(Vector2i(9,7))==0 and g.level.mechanism_color=="purple","goal1/crystal101/purple display only")
 for i in MONSTERS.size():_check(g.monster_at(MONSTERS[i])==i and g.monsters()[i]["kind"]=="goblin" and g.monsters()[i]["alive"],"eight confirmed typed Goblins")
 _check(g.level.bushes.is_empty() and g.level.fence_edges.is_empty() and g.level.energy_links.size()==1 and g.barrier_is_active(GATE),"no inferred internal walls/bush/fence;single closed energy")
 var initial:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"cannot_push" and g.snapshot()==initial and g.switch_hero()==&"single_hero","green cannot push crystal or select Goblins")
func _route_undo() -> void:
 var g:=_game();var initial:=g.snapshot();var monsters:=g.monsters();var history:Array[Dictionary]=[];var n:=0;var pulls:=0
 for s in _solution()["path"]:
  history.append(g.snapshot());n+=1
  if n in PULLS:pulls+=1
  _check(g.try_move(DIRS[s])==(&"pulled" if n in PULLS else &"moved") and g.alive and g.monsters()==monsters,"89legal single-pull/walk inputs;all Goblins unchanged")
  var active:bool=not(n in [70,71] or n>=76)
  _check(g.moves==n and g.history_size()==n and g.pulls==pulls and g.pushes==0 and g.swaps==0 and g.is_complete()==(n==89),"actual direction and15single-pull counters/no premature victory")
  _check(g.barrier_is_active(GATE)==active and g.blocks_sight(GATE)==active and g.is_walkable(GATE)==not active,"post-action plate/energy movement/sight consistent")
  if n==70:_check(g.player==PLATE and g.crate_id(Vector2i(3,7))==0,"hero alone presses94 opens15")
  if n==71:_check(g.player==Vector2i(1,7) and g.crate_id(PLATE)==0 and not g.barrier_is_active(GATE),"single pull hands pressure to crystal without flicker")
  if n==72:_check(g.player==Vector2i(0,7) and g.crate_id(Vector2i(1,7))==0 and g.barrier_is_active(GATE),"pull off plate restores energy in same action")
  if n==77:_check(g.player==Vector2i(3,7) and g.crate_id(PLATE)==0,"final crystal handoff permanently holds pressure")
  if n==87:_check(g.player==GATE and g.alive and g.crate_id(PLATE)==0,"hero legally passes15energy footprint")
 _check(g.player==Vector2i(0,0) and g.pulls==15 and g.crate_id(PLATE)==0,"hero goal1 wins,crystal remains94")
 while not history.is_empty():_check(g.undo() and g.snapshot()==history.pop_back(),"each undo restores pull,life,pressure and energy atomically")
 _check(g.snapshot()==initial and not g.undo(),"all89undos restore pristine world")
func _closed_gate() -> void:
 var g:=_game()
 for s in "UUULLLLULULL":_check(g.try_move(DIRS[s])==&"moved" and g.alive,"legal approach to closed15 without moving crystal")
 var before:=g.snapshot();_check(g.player==Vector2i(1,2) and g.crate_id(Vector2i(9,7))==0 and g.barrier_is_active(GATE),"closed gate reachable from below")
 _check(g.try_move(Vector2i.UP)==&"energy_blocked" and g.snapshot()==before and g.blocks_sight(GATE),"closed15 blocks movement/sight atomically")
func _pull_death() -> void:
 var g:=_game();_check(g.try_move(Vector2i.LEFT)==&"pulled","first safe single pull")
 var before:=g.snapshot()
 _check(g.try_move(Vector2i.LEFT)==&"died" and not g.alive and g.player==Vector2i(6,7) and g.crate_id(Vector2i(7,7))==0 and g.moves==2 and g.pulls==2,"second pull enters85Goblin threat;hero and crystal move before death settlement")
 var dead:=g.snapshot();_check(g.try_move(Vector2i.UP)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and not g.load_level(Level.from_file("res://levels/north_23.json")) and g.snapshot()==dead,"death lock cannot be bypassed via C/restart/level change")
 _check(g.undo() and g.snapshot()==before and g.alive and g.crate_id(Vector2i(8,7))==0,"one undo revives AND restores pulled crystal identity and counter")
func _cosmetic_and_isolation() -> void:
 var g:=_game();var initial:=g.snapshot();var recolored:=State.new();var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/north_24.json"));d["mechanism_color"]="yellow"
 _check(recolored.load_level(Level.from_dictionary(d)) and recolored.snapshot()==initial,"purple enum affects no initial gameplay state")
 for s in _solution()["path"]:
  _check(g.try_move(DIRS[s])==recolored.try_move(DIRS[s]) and g.snapshot()==recolored.snapshot(),"all89purple/yellow recolor steps and mechanisms identical")
 _check(g.restart() and g.snapshot()==initial,"victory restart restores eight live Goblins/crystal/closed gate")
 for n in range(1,24):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and g.history_size()==0 and g.level.mechanism_color!="purple","prior23no color/pressure/history leakage")
  _check(g.load_level(Level.from_file("res://levels/north_24.json")) and g.snapshot()==initial,"24restores confirmed entities")
func _game() -> State:
 var g:=State.new();_check(g.load_level(Level.from_file("res://levels/north_24.json")),"confirmed24loads");return g
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_24.json"))
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
