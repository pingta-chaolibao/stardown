extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var checks:=0
var failures:=0
func _init() -> void:
 _map();_route_undo();_death();_isolation()
 print("NORTH 22 RESULT: 4 cases, %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _map() -> void:
 var g:=_game();var rows=["#..........","...........","........#..","...........","#.........."];var floor_count:=0;var danger:=0
 for y in 5:
  for x in 11:
   var c:=Vector2i(x,y);_check(g.level.is_floor(c)==(rows[y][x]=="."),"all55final corrected terrain")
   if g.level.is_floor(c):floor_count+=1
   if g.monster_danger_at(c):danger+=1
 _check(floor_count==52 and g.player==Vector2i(0,2) and g.hero_count()==1 and g.active_kind()=="red","52floor/onlyred23")
 for c in [Vector2i(1,0),Vector2i(0,1),Vector2i(0,3)]:_check(g.level.is_floor(c),"user corrected2/12/34 to floor")
 _check(not g.level.is_floor(Vector2i(0,0)) and not g.level.is_floor(Vector2i(0,4)) and not g.level.is_floor(Vector2i(8,2)),"only1/45left boundary,31fixedwall")
 _check(g.crates().is_empty() and g.level.bushes.is_empty() and g.level.energy_links.is_empty() and g.level.fence_edges.is_empty(),"no crystal/bush/energy/fences inferred")
 _check(g.level.monster_kinds==PackedStringArray(["goblin","goblin","goblin"]),"allthreeexplicitgoblin,not generic future monster")
 _check(g.monsters().size()==3 and g.monster_at(Vector2i(10,0))==0 and g.monster_at(Vector2i(5,2))==1 and g.monster_at(Vector2i(10,4))==2,"11/28/55three stable monster IDs")
 _check(danger==8 and not g.monster_danger_at(Vector2i(9,1)) and not g.monster_danger_at(Vector2i(9,3)),"exact8orthogonal threats,diagonal corners safe")
 _check(g.level.exit_cell==Vector2i(10,2) and not g.is_complete(),"goal33not a monster requirement")
func _route_undo() -> void:
 var g:=_game();var initial:=g.snapshot();var monsters:=g.monsters();var history:Array[Dictionary]=[];var n:=0
 for s in _solution()["path"]:
  history.append(g.snapshot());n+=1;_check(g.try_move(DIRS[s])==&"moved" and g.alive and g.monsters()==monsters,"all14legal safe walk inputs,monsters never move themselves")
  _check(g.moves==n and g.history_size()==n and g.pushes==0 and g.swaps==0 and g.pulls==0 and g.is_complete()==(n==14),"14walks/no extra actions or premature victory")
  if n==1:_check(g.player==Vector2i(0,1),"route uses corrected12floor")
  if n==3:_check(g.player==Vector2i(1,0),"route uses corrected2floor")
  if n==12:_check(g.player==Vector2i(9,1) and g.alive,"diagonal approach to top-right monster is safe")
 _check(g.player==Vector2i(10,2) and g.occupied_exits()==1,"red enters33wins while3monsters remainalive")
 while not history.is_empty():_check(g.undo() and g.snapshot()==history.pop_back(),"eachUndo restores hero/monsters/life/history")
 _check(g.snapshot()==initial and not g.undo(),"all14undos restore pristine no-history start")
func _death() -> void:
 var g:=_game();g.try_move(Vector2i.RIGHT);g.try_move(Vector2i.RIGHT);g.try_move(Vector2i.RIGHT);var before:=g.snapshot()
 _check(g.try_move(Vector2i.RIGHT)==&"died" and g.player==Vector2i(4,2) and not g.alive and g.monster_at(Vector2i(5,2))==1 and g.moves==4,"walk into central monster range dies immediately")
 var dead:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and not g.load_level(Level.from_file("res://levels/north_21.json")) and g.snapshot()==dead,"cannot push adjacent monster or escape through restart/map/C")
 _check(g.undo() and g.snapshot()==before and g.alive and g.death_reason.is_empty(),"onlyUndo restores before threat entry")
func _isolation() -> void:
 var g:=_game();var initial:=g.snapshot();_check(g.switch_hero()==&"single_hero" and g.snapshot()==initial,"3monsters never selectable as C heroes")
 for n in range(1,22):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)) and g.monsters().is_empty() and g.history_size()==0,"old21no monster/history leaks")
  _check(g.load_level(Level.from_file("res://levels/north_22.json")) and g.snapshot()==initial,"22restores confirmed three monsters/one hero")
 for s in _solution()["path"]:g.try_move(DIRS[s])
 _check(g.restart() and g.snapshot()==initial,"victory restart restores initial identities/alive")
func _game() -> State:
 var g:=State.new();_check(g.load_level(Level.from_file("res://levels/north_22.json")),"confirmed22loads");return g
func _solution() -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_22.json"))
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
