extends SceneTree
const Level=preload("res://scripts/core/level_data.gd")
const State=preload("res://scripts/core/grid_state.gd")
const DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const TERRAIN=["...#...",".......","...#...","#####..","#......",".......","#......"]
const DRAGON_PULLS={2:0,16:1,30:3,31:3,32:3,41:2,42:2}
const CRYSTAL_PULLS=[8,9,10,11,22,23,24,25,38,39]
var checks:=0
var failures:=0
func _init() -> void:
 var d:=Level.from_file("res://levels/north_28.json");_check(d.error.is_empty() and d.width==7 and d.height==7 and d.terrain==PackedStringArray(TERRAIN),"confirmed28exact7x7terrain")
 var sight:=State.new();_check(sight.load_level(d),"valid model for terrain sightqueries")
 for y in 7:
  for x in 7:
   var c:=Vector2i(x,y);_check(d.is_floor(c)==(TERRAIN[y][x]==".") and sight.blocks_sight(c)==(TERRAIN[y][x]=="#"),"all49collision/sightcells")
 _check(d.is_floor(Vector2i(6,0)) and not d.is_floor(Vector2i(0,6)) and d.start==Vector2i(0,0) and d.exit_cell==Vector2i(0,5) and d.initial_crates==[Vector2i(1,1)],"7floor/43rock/hero1/crystal9/goal36")
 _check(d.initial_monsters==[Vector2i(2,0),Vector2i(4,2),Vector2i(1,4),Vector2i(2,4)] and d.monster_facings==[Vector2i.DOWN,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.DOWN],"3/19/30/31fixedfireDragonpositions/facings")
 _check(d.bushes.is_empty() and d.energy_links.is_empty() and d.fence_edges.is_empty(),"no newmechanismorobjects")
 var g:=State.new();_check(g.load_level(d),"real GridState28loads");var initial:=g.snapshot();var history:Array[Dictionary]=[];var dragon_pulls:=0;var crystal_pulls:=0
 var sol:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_28.json"));var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_28_route.json"))
 for i in sol["path"].length():
  history.append(g.snapshot());var result:=g.try_move(DIRS[sol["path"][i]]);var expected:Dictionary=proof["trace"][i]
  if DRAGON_PULLS.has(i+1):dragon_pulls+=1
  elif i+1 in CRYSTAL_PULLS:crystal_pulls+=1
  _check(result==(&"pulled" if DRAGON_PULLS.has(i+1) or i+1 in CRYSTAL_PULLS else &"moved") and g.alive and g.moves==i+1 and g.history_size()==i+1,"living legal action%02d" % (i+1))
  _check(g.player==_cell(expected["hero"]) and g.crates()==[_cell(expected["crystal"])] and g.crate_id(_cell(expected["crystal"]))==0 and g.pulls==expected["pulls"] and g.pushes==0 and g.swaps==0,"independent hero/crystalidentity/pull counters")
  _check(dragon_pulls==expected["dragon_pulls"] and crystal_pulls==expected["crystal_pulls"],"dragon/crystal pull classification")
  for m in g.monsters():_check(m["alive"] and m["position"]==_cell(expected["monsters"][m["id"]]) and m["facing"]==(Vector2i.RIGHT if m["id"]==1 else Vector2i.DOWN),"4dragonspositions/life/facing follow independent commonattack model")
  _check(g.is_complete()==(i==48),"victoryonlylastlivingaction")
 _check(g.is_complete() and g.pulls==17 and dragon_pulls==7 and crystal_pulls==10,"49actions17pulls7dragon10crystalwin")
 for i in range(48,-1,-1):_check(g.undo() and g.snapshot()==history[i],"Undo every action restores allpositions/life/counters")
 _check(g.snapshot()==initial and not g.undo(),"fullrewind exactinitial")
 for s in sol["path"]:g.try_move(DIRS[s])
 _check(g.restart() and g.snapshot()==initial,"restartrestoresall4dragonsandcrystal")
 _check(g.try_move(Vector2i.RIGHT)==&"moved","safe step right before unshielded shortcut")
 var before:=g.snapshot();_check(g.try_move(Vector2i.DOWN)==&"cannot_push" and g.snapshot()==before,"green cannotpushcrystal9")
 g.restart();_check(g.try_move(Vector2i.RIGHT)==&"moved" and g.try_move(Vector2i.DOWN)==&"cannot_push","sameblockedinputnotfirewait")
 g.restart();_check(g.try_move(Vector2i.RIGHT)==&"moved" and g.try_move(Vector2i.RIGHT)==&"cannot_push","green cannotpushdragon3")
 g.restart();_check(g.try_move(Vector2i.DOWN)==&"moved" and g.try_move(Vector2i.DOWN)==&"moved" and g.try_move(Vector2i.RIGHT)==&"moved","safe prefix DDR")
 before=g.snapshot();_check(g.try_move(Vector2i.RIGHT)==&"died" and g.death_reason=="fire" and g.player==Vector2i(2,2),"shortcut DDRR entersdownwardfireanddies")
 var dead:=g.snapshot();_check(g.switch_hero()==&"dead" and not g.restart() and not g.load_level(d) and g.try_move(Vector2i.UP)==&"dead" and g.snapshot()==dead,"deathonlyUndo")
 _check(g.undo() and g.snapshot()==before and g.alive,"oneUndo revives shortcut")
 for n in range(1,28):
  _check(g.load_level(Level.from_file("res://levels/north_%02d.json" % n)),"old27load")
  _check(g.load_level(d) and g.snapshot()==initial,"28history/objectsisolatedfromoldmaps")
 print("NORTH28 RESULT: %d checks, %d failures" % [checks,failures]);quit(0 if failures==0 else 1)
func _cell(a:Array)->Vector2i:return Vector2i(a[0],a[1])
func _check(ok:bool,message:String)->void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+message)
