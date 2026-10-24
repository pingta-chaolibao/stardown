extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_A,"R":KEY_D}
func _run() -> void:
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level22")
 var initial:Dictionary=game.model.snapshot();_check(game.current_level_index==21 and game.model.hero_count()==1 and game.model.monsters().size()==3 and game.model.active_kind()=="red","22pooled card enters corrected single-red/three-monster board")
 _check(game.menu.entries[21]["detail"].contains("哥布林") and game.model.level.monster_kinds==PackedStringArray(["goblin","goblin","goblin"]),"typedgoblin config/card name,not an unspecified generic monster")
 _check_layout(game);await _inspect_danger();await _capture("north_22_initial.png")
 await _press(KEY_C);_check(game.model.snapshot()==initial and game.model.hero_count()==1,"C never selects monsters")
 await _repeat();await _press(KEY_R)
 for i in 3:await _press(KEY_D)
 var before:Dictionary=game.model.snapshot();await _click("MoveRight")
 _check(not game.model.alive and game.model.player==Vector2i(4,2) and game.status_label.text.contains("哥布林"),"screen step into orthogonal danger kills hero immediately with monster feedback")
 await _capture("north_22_death_locked.png");var dead:Dictionary=game.model.snapshot()
 await _press(KEY_D);await _press(KEY_R);await _press(KEY_C);await _press(KEY_ESCAPE);await _click("BackToLevels")
 _check(game.model.snapshot()==dead and not game.menu.visible and not game.back_to_menu() and not game.select_level(0),"cannot push already-adjacent monster or use key/menu/API to bypass death")
 await _click("Undo");_check(game.model.snapshot()==before and game.model.alive,"screenUndo restores before danger without moving monsters");await _capture("north_22_revived.png");await _press(KEY_R)
 var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_22.json"));var n:=0;var monsters=game.model.monsters()
 for symbol in solution["path"]:
  await _press(KEYS[symbol]);n+=1
  _check(game.model.moves==n and game.model.history_size()==n and game.model.alive and game.model.monsters()==monsters,"all14actual legal input steps,stationary monsters")
  _check(game.model.is_complete()==(n==14),"onlyhero33wins")
  if n==3:await _capture("north_22_corrected_left_path.png")
  if n==12:await _capture("north_22_diagonal_safe.png")
 _check(game.model.pushes==0 and game.model.pulls==0 and game.model.swaps==0,"formal path uses no impossible direct monster push")
 await _capture("north_22_completed.png");await _press(KEY_Z);_check(not game.model.is_complete() and game.model.player==Vector2i(9,2),"victoryUndo to prior safe cell")
 await _press(KEY_R);_check(game.model.snapshot()==initial,"restart resets hero/all three live monster identities")
 await _click("BackToLevels");_check(game.menu.strip.item_count==22,"persistent pool holds22catalog only")
 await _click("Level21");_check(game.model.monsters().is_empty() and not game.model.snapshot().has("monster_positions"),"old21world and snapshots stay legacy shaped")
 await _click("Level22");_check(game.model.snapshot()==initial,"return22isolates history/life")
 root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_danger();await _capture("north_22_compact.png")
 print("NORTH 22 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _repeat() -> void:
 var event:=InputEventKey.new();event.keycode=KEY_D;event.physical_keycode=KEY_D;event.pressed=true;Input.parse_input_event(event);await _settle();var once:Dictionary=game.model.snapshot()
 event.echo=true;Input.parse_input_event(event);await _settle();event.echo=false;Input.parse_input_event(event);await _settle();_check(game.model.moves==1 and game.model.snapshot()==once,"held/echo does not repeat move or monster logic")
 event.pressed=false;Input.parse_input_event(event);await _settle();await _press(KEY_D);_check(game.model.moves==2,"fresh direction after release works once")
func _inspect_danger() -> void:
 var threats=[Vector2i(9,0),Vector2i(10,1),Vector2i(4,2),Vector2i(6,2),Vector2i(5,1),Vector2i(5,3),Vector2i(9,4),Vector2i(10,3)]
 var diagonal=[Vector2i(4,1),Vector2i(6,1),Vector2i(4,3),Vector2i(6,3),Vector2i(9,1),Vector2i(9,3)]
 for c in threats:_check(game.model.monster_danger_at(c),"four-direction threat cell")
 for c in diagonal:_check(not game.model.monster_danger_at(c),"diagonal cell not shown dangerous")
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var view:Control=game.board;var level=game.model.level;var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
 var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2;var im:=root.get_texture().get_image()
 for c in threats+diagonal:
  var p:Vector2=root.get_final_transform()*(origin+(Vector2(c)+Vector2.ONE*0.5)*tile+Vector2(-0.43,0)*tile);var colored:=0
  for dx in range(-1,2):
   var color:=im.get_pixel(roundi(p.x)+dx,roundi(p.y));if color.r>0.3 and color.r>color.g*1.3 and color.r>color.b*1.4:colored+=1
  _check((colored>0)==(c in threats),"rust threat boundary appears only on orthogonal cells at current window size")
