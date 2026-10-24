extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const PULLS={36:2,49:1,62:0}
var checks:=0
var failures:=0
func _init() -> void:
 var d:=Level.from_file("res://levels/north_27.json");_check(d.error.is_empty() and d.width==12 and d.height==9,"complete confirmed12x9 translated map")
 var mapping:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/mappings/north_27_markers.json"));_check(_cell(mapping["normalization_offset"])==Vector2i(2,0) and mapping["markers"].size()==93,"stable original1–93mapping")
 var floors:int=0;var voids:int=0;var walls:int=0
 for y in 9:
  for x in 12:
   var c:=Vector2i(x,y)
   if d.is_floor(c):floors+=1
   elif d.is_void(c):voids+=1
   else:walls+=1
 _check(floors==87 and voids==15 and walls==6,"no invented external floor or removed9wall")
 for m in mapping["markers"]:
  var c:=Vector2i(m["position"][0],m["position"][1]);_check(c==Vector2i(m["original"][0]+2,m["original"][1]) and d.is_floor(c)==m["walkable"],"every marker uses sameoffset,exact walkability")
 _check(not d.is_floor(Vector2i(11,0)) and not d.is_floor(Vector2i(10,0)) and d.start==Vector2i(2,0) and d.exit_cell==Vector2i(2,2),"above73andoriginal9walls,hero/goaltranslated")
 _check(d.initial_monsters==[Vector2i(10,2),Vector2i(3,4),Vector2i(10,6)] and d.monster_facings==[Vector2i.LEFT,Vector2i.RIGHT,Vector2i.LEFT],"all3dragonpositions/facings translated uniformly")
 _check(d.initial_crates.is_empty() and d.bushes.is_empty() and d.fence_edges.is_empty() and d.energy_links.is_empty(),"no unrequestedobjects/mechanisms")
 var sol:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_27.json"));var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_27_route.json"));var g:=State.new();_check(g.load_level(d),"actual GridState loads correctedmap")
 var initial:=g.snapshot();var history:Array[Dictionary]=[]
 for i in sol["path"].length():
  history.append(g.snapshot());var before:=g.monsters();var result:=g.try_move(DIRS[sol["path"][i]]);var expected:Dictionary=proof["trace"][i]
  _check(result==(&"pulled" if PULLS.has(i+1) else &"moved") and g.moves==i+1 and g.alive and g.history_size()==i+1,"legal effective living action%02d" % (i+1))
  _check(g.player==_cell(expected["hero"]) and g.pulls==expected["pulls"] and g.pushes==0 and g.swaps==0,"independent hero/pull/counter trace")
  for m in g.monsters():
   _check(m["position"]==_cell(expected["positions"][m["id"]]) and m["alive"] and m["facing"]==(Vector2i.RIGHT if m["id"]==1 else Vector2i.LEFT),"all dragon identities/facing/life match independent trace")
   if m["position"]!=before[m["id"]]["position"]:_check(PULLS.get(i+1,-1)==m["id"],"only nearest one dragon moves during a counted pull")
  _check(g.is_complete()==(i==73),"victory only at correctlivinggoalafter74")
 _check(g.is_complete() and g.pulls==3 and g.player==Vector2i(2,2),"real model74actions3dragonpullsvictory")
 for i in range(73,-1,-1):_check(g.undo() and g.snapshot()==history[i],"everyUndo restores position/facing/life/counters")
 _check(g.snapshot()==initial and not g.undo(),"full rewind exact")
 for s in sol["path"]:g.try_move(DIRS[s])
 _check(g.restart() and g.snapshot()==initial,"victoryrestart restores initial three dragons")
 _check(g.try_move(Vector2i.DOWN)==&"moved" and g.try_move(Vector2i.DOWN)==&"died" and g.player==d.exit_cell and not g.is_complete(),"sideDDgoalstilllethalbeforemovingdragon27")
 var dead:=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"dead" and g.switch_hero()==&"dead" and not g.restart() and not g.load_level(d) and g.snapshot()==dead,"deathonlyUndo,not goal/C/restart/load")
 _check(g.undo() and g.alive and g.player==Vector2i(2,1),"Undo revives illegal shortcut")
 for n in range(1,27):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)),"old26load")
  _check(g.load_level(d) and g.snapshot()==initial,"oldhistorydoesnotleakinto27")
 print("NORTH27 RESULT: %d checks,%d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(a:Array) -> Vector2i:return Vector2i(a[0],a[1])
func _check(ok:bool,message:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+message)
