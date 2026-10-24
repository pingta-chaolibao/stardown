extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=["#..........","#..........","...........","#.....#....","#.....#....","#.....##.##","#.....#....","###.###...."]
const PATH="LLUUUURULLLLLULLUL"
var checks:=0
var failures:=0
func _init() -> void:
 var d:=Level.from_file("res://levels/north_26.json");_check(d.error.is_empty() and d.width==11 and d.height==8 and d.terrain==PackedStringArray(TERRAIN),"confirmed26terrain exact")
 _check(d.start==Vector2i(10,7) and d.exit_cell==Vector2i(1,0) and d.initial_crates==[Vector2i(8,6)],"hero88/crystal75/goal2 positions")
 _check(d.monster_kinds==PackedStringArray(["fire_dragon","fire_dragon","goblin"]) and d.initial_monsters==[Vector2i(0,2),Vector2i(3,7),Vector2i(8,5)] and d.monster_facings==[Vector2i.RIGHT,Vector2i.UP,Vector2i.ZERO],"right23/up81/Goblin64 exact typed positions and directions")
 _check(d.bushes.is_empty() and d.energy_links.is_empty() and d.fence_edges.is_empty(),"no invented mechanism")
 var g:=State.new();_check(g.load_level(d),"actual GridState26 loads")
 var initial:=g.snapshot();var histories:Array[Dictionary]=[]
 var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_26_route.json"))
 var sol:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_26.json"));_check(sol["path"]==PATH,"solution path exact")
 for i in PATH.length():
  histories.append(g.snapshot());var result:=g.try_move(DIRS[PATH[i]]);var expected:Dictionary=proof["trace"][i]
  _check(result in [&"moved",&"pushed"] and g.alive and g.moves==i+1 and g.history_size()==i+1,"effective legal living action %d" % (i+1))
  _check(g.player==_cell(expected["hero"]) and g.crates()==[_cell(expected["crystal"])] and g.pushes==expected["pushes"],"independent position/ID/counter trace %d" % (i+1))
  for m in g.monsters():
   _check(m["position"]==_cell(expected["monster_positions"][m["id"]]) and m["alive"]==expected["monster_alive"][m["id"]],"independent monster life/position")
   if m["kind"]=="fire_dragon":_check(m["facing"]==(Vector2i.RIGHT if m["id"]==0 else Vector2i.UP),"fixed facing throughout campaign")
  _check(g.is_complete()==(i==17),"victory only last action")
  if i==4:_check(not g.monsters()[2]["alive"] and not g.monster_danger_at(Vector2i(8,3)),"actual action5 single fire kill clears Goblin threat")
 _check(g.is_complete() and g.pushes==9 and g.pulls==0 and g.swaps==0,"18 actions9 pushes reaches goal alive")
 for i in range(17,-1,-1):_check(g.undo() and g.snapshot()==histories[i],"every Undo restores monster deaths,crystal/facing/counters")
 _check(g.snapshot()==initial and not g.undo(),"full rewind exact initial")
 for s in PATH:g.try_move(DIRS[s])
 _check(g.restart() and g.snapshot()==initial,"restart resurrects killed Goblin and resets fire position/facing/history")
 var fatal:=PATH.substr(0,8)+"ULLLLLL"
 for s in fatal:g.try_move(DIRS[s])
 _check(not g.alive and g.death_reason=="fire" and g.player==Vector2i(3,1),"legal side branch crosses vertical fire before crystal shields col3")
 var dead:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and not g.load_level(d) and g.snapshot()==dead,"death locked,onlyUndo")
 _check(g.undo() and g.alive and g.player==Vector2i(4,1),"Undo revives legal side branch")
 for n in range(1,26):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)),"old25load")
  _check(g.load_level(d) and g.snapshot()==initial,"oldhistory/facing never leaks into26")
 print("NORTH 26 RESULT: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(v:Array) -> Vector2i:return Vector2i(v[0],v[1])
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+message)
