extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_A,"R":KEY_D,"C":KEY_C}
const GATES=[Vector2i(2,3),Vector2i(6,3),Vector2i(10,3)]
func _run() -> void:
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level21")
 var initial:Dictionary=game.model.snapshot();_check(game.current_level_index==20 and game.model.active_hero_id()=="red" and game.model.level.fence_edges.is_empty(),"21real pooled card,initialred,no fences")
 _check_layout(game);await _capture("north_21_initial.png")
 var event:=InputEventKey.new();event.keycode=KEY_D;event.physical_keycode=KEY_D;event.pressed=true;Input.parse_input_event(event);await _settle();var once:Dictionary=game.model.snapshot()
 event.echo=true;Input.parse_input_event(event);await _settle();event.echo=false;Input.parse_input_event(event);await _settle();_check(game.model.moves==1 and game.model.snapshot()==once,"held/echo never repeats")
 event.pressed=false;Input.parse_input_event(event);await _settle();await _click("MoveRight");_check(game.model.moves==2,"screen and key use same direction pipeline");await _press(KEY_R)
 var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_21.json"));var actions:=0;var choices:=0
 for symbol in solution["path"]:
  var before:Dictionary=game.model.snapshot();var selected:String=game.model.active_hero_id();await _press(KEYS[symbol])
  if symbol=="C":choices+=1;_check(game.model.snapshot()==before,"C selection free,never changes world/history")
  else:actions+=1;_check(game.model.active_hero_id()==selected,"selected hero identity stays stable")
  _check(game.model.moves==actions and game.model.history_size()==actions and game.model.alive and game.model.crates().size()==6,"legal real inputs,119actions preserve all six identities")
  _check(game.model.is_complete()==(actions==119),"not complete until all three different goals")
  if symbol!="C":
   if actions==17:await _capture("north_21_four_plates.png")
   if actions==26:
    for gate in GATES:await _inspect_open(gate)
    await _capture("north_21_all_six_plates.png")
   if actions==27:
    await _capture("north_21_right_crystal_handoff.png");var after:Dictionary=game.model.snapshot();await _press(KEY_Z);_check(game.model.snapshot()==before,"swap undo atomic")
    await _click("MoveDown");_check(game.model.snapshot()==after,"screen redoes same first-visible-target crystal handoff")
   if actions==43:
    await _inspect_open(GATES[0]);await _capture("north_21_blue_crossing.png");await _death_side_path();await _choose("blue")
   if actions==63:await _capture("north_21_left_crystal_handoff.png")
   if actions==84:await _capture("north_21_safe_restoration.png")
   if actions==85:await _capture("north_21_reopened.png")
   if actions==101:
    await _inspect_open(GATES[1]);await _capture("north_21_crystal_crossing.png");await _destroy_side_path();await _choose("green")
   if actions==105:await _capture("north_21_six_crystal_plates.png")
 _check(actions==119 and choices==21 and game.model.pushes==10 and game.model.pulls==8 and game.model.swaps==10 and game.model.occupied_exits()==3,"actual119+21C,10push8pull10swap victory")
 await _capture("north_21_completed.png");await _press(KEY_Z);_check(game.model.moves==118 and not game.model.is_complete() and game.model.active_hero_id()=="red","victoryundo retains current selection")
 await _press(KEY_R);_check(game.model.snapshot()==initial,"restart restores all9objects/sixplates/3solid gates")
 await _click("BackToLevels");_check(game.menu.strip.item_count==game.LEVEL_PATHS.size(),"same persistent virtual menu21")
 await _click("Level20");_check(game.model.level.fence_edges.size()==2 and game.model.moves==0,"20retains original two edge fences")
 await _click("Level21");_check(game.model.snapshot()==initial and game.model.level.fence_edges.is_empty(),"no fence/history leakage into21")
 root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_21_compact_red.png")
 await _click("SwitchHero");_check(game.model.active_hero_id()=="green" and game.model.snapshot()==initial,"compact screen C selects green without undo entry");await _capture("north_21_compact_green.png")
 await _click("SwitchHero");_check(game.model.active_hero_id()=="blue" and game.model.snapshot()==initial,"compact screen C selects blue with original hue");await _capture("north_21_compact_blue.png")
 await _press(KEY_R);await _advance(26)
 for gate in GATES:await _inspect_open(gate)
 await _capture("north_21_compact_open.png");await _advance(43);await _inspect_open(GATES[0]);await _capture("north_21_compact_occupied_energy.png")
 print("NORTH 21 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _death_side_path() -> void:
 await _choose("red");var before:Dictionary=game.model.snapshot();await _click("MoveUp")
 _check(not game.model.alive and not game.model.hero_is_alive(2) and game.model.hero_is_alive(0),"legal plate release kills inactiveblue on left energy")
 await _capture("north_21_death_locked.png");var dead:Dictionary=game.model.snapshot()
 await _press(KEY_C);await _press(KEY_R);await _press(KEY_DOWN);await _press(KEY_ESCAPE);await _click("BackToLevels")
 _check(game.model.snapshot()==dead and not game.menu.visible and game.model.active_hero_id()=="red" and not game.back_to_menu() and not game.select_level(0),"C/R/keys/screen/Esc/API cannot bypass death")
 await _press(KEY_Z);_check(game.model.snapshot()==before and game.model.hero_is_alive(2) and game.model.active_hero_id()=="red","undo revives all world and retains red");await _capture("north_21_revived.png")
func _destroy_side_path() -> void:
 await _choose("blue");var before:Dictionary=game.model.snapshot();await _click("MoveUp")
 _check(game.model.alive and game.model.crates().size()==5 and game.model.crate_id(GATES[1])==-1,"legal release destroys ID5 on restored central energy")
 await _capture("north_21_crystal_destroyed.png");await _press(KEY_Z)
 _check(game.model.snapshot()==before and game.model.crate_id(GATES[1])==5 and game.model.active_hero_id()=="blue","undo restores crystal ID5,all open gates,free current selection")
func _choose(id:String) -> void:
 var before:Dictionary=game.model.snapshot()
 for i in game.model.hero_count():
  if game.model.active_hero_id()==id:return
  await _press(KEY_C)
 _check(game.model.snapshot()==before,"selection never changes snapshot")
func _advance(n:int) -> void:
 var path:String=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_21.json"))["path"]
 var actions:=0;var start:int=game.model.moves
 for symbol in path:
  if symbol!="C":actions+=1
  if actions<=start:continue
  await _press(KEYS[symbol])
  if game.model.moves>=n:return
func _inspect_open(cell:Vector2i) -> void:
 _check(not game.model.barrier_is_active(cell) and game.model.is_walkable(cell) and not game.model.blocks_sight(cell),"absent energy transparent/passable")
 if DisplayServer.get_name()=="headless":return
 await _settle();await RenderingServer.frame_post_draw
 var view:Control=game.board;var level=game.model.level
 var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
 var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2
 var center:Vector2=root.get_final_transform()*(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile)
 var scaled:float=tile*root.get_final_transform().get_scale().x;var colored:=0;var gaps:=0;var transitions:=0;var previous:=false;var first:=true;var im:=root.get_texture().get_image()
 for x in range(int(center.x-scaled*0.4),int(center.x+scaled*0.4)):
  var c:=im.get_pixel(x,roundi(center.y-scaled*0.43));var yellow:=c.r>0.45 and c.g>0.32 and c.r>c.b*1.4
  if yellow:colored+=1
  else:gaps+=1
  if not first and yellow!=previous:transitions+=1
  previous=yellow;first=false
 _check(colored>=4 and gaps>=3 and transitions>=4,"yellow dashed edge remains clear at normal/compact scale,including occupied cell")
