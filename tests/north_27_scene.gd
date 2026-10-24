extends "res://tests/north_02_scene.gd"
const Map=preload("res://tests/north_27_regression.gd")
func _run() -> void:
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level27")
 _check(game.current_level_index==26 and game.model.active_kind()=="green" and game.model.hero_count()==1 and game.model.crates().is_empty(),"real pooled27card enters exact correctedgreenmap")
 _check(game.model.level.width==12 and game.model.level.height==9 and game.model.level.void_cells.size()==15 and game.model.player==Vector2i(2,0),"fullperimeterwithuniformtranslation/voiddistinction")
 _check(game.model.monsters().size()==3 and game.model.level.exit_cell==Vector2i(2,2),"three dragons andtranslatedgoal")
 var initial:Dictionary=game.model.snapshot();_check_layout(game);await _capture("north_27_initial.png")
 await _press(KEY_C);_check(game.model.snapshot()==initial,"Cnoaction,nofire")
 var e:=InputEventKey.new();e.keycode=KEY_S;e.physical_keycode=KEY_S;e.pressed=true;Input.parse_input_event(e);await _settle();var once:Dictionary=game.model.snapshot();e.echo=true;Input.parse_input_event(e);await _settle();e.echo=false;Input.parse_input_event(e);await _settle()
 _check(game.model.player==Vector2i(2,1) and game.model.moves==1 and game.model.snapshot()==once and game.model.alive,"held/echoDownneverbecomesfatalimplicitnextaction")
 e.pressed=false;Input.parse_input_event(e);await _settle();await _click("Restart")
 await _click("MoveDown");await _press(KEY_S)
 _check(not game.model.alive and game.model.player==Vector2i(2,2) and not game.model.is_complete() and game.status_label.text.contains("火焰"),"DDshortcutdiesongoal,noinventedgoalimmunity")
 await _capture("north_27_shortcut_death.png");var dead:Dictionary=game.model.snapshot();await _press(KEY_C);await _press(KEY_R);await _press(KEY_D);await _click("BackToLevels")
 _check(game.model.snapshot()==dead and not game.menu.visible and game.find_child("BackToLevels",true,false).disabled,"deathonlyUndo,notC/restart/menu")
 await _click("Undo");_check(game.model.alive and game.model.player==Vector2i(2,1),"actualUndo revives shortcut");await _click("Restart")
 var sol:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_27.json"));var proof:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/verification/north_27_route.json"));var histories:Array[Dictionary]=[]
 for i in sol["path"].length():
  histories.append(game.model.snapshot());var monsters=game.model.monsters();await _press(_keycode(sol["path"][i]));var expected:Dictionary=proof["trace"][i]
  _check(game.model.moves==i+1 and game.model.alive and game.model.player==Vector2i(expected["hero"][0],expected["hero"][1]) and game.model.pulls==expected["pulls"],"actual74routehero/counteraction%02d" % (i+1))
  for m in game.model.monsters():_check(m["alive"] and m["position"]==Vector2i(expected["positions"][m["id"]][0],expected["positions"][m["id"]][1]) and m["facing"]==(Vector2i.RIGHT if m["id"]==1 else Vector2i.LEFT),"actual input dragonidentity/direction/life")
  if Map.PULLS.has(i+1):
   _check(game.status_label.text.contains("火龙") and game.status_label.text.contains("朝向不变") and game.model.monsters()[Map.PULLS[i+1]]["position"]!=monsters[Map.PULLS[i+1]]["position"],"visible single dragon pull message and fixedarrow")
   await _capture("north_27_pull_%02d.png" % (i+1))
  if i==11:await _capture("north_27_right_perimeter.png")
 _check(game.model.is_complete() and game.moves_label.text=="74" and game.pulls_label.text=="03" and game.status_label.text.contains("已抵达终点"),"actual74actions3pullslivingvictory")
 await _capture("north_27_completed.png");await _click("Undo");_check(game.model.snapshot()==histories[-1] and not game.model.is_complete(),"victoryscreenUndo exact");await _click("Restart");_check(game.model.snapshot()==initial,"screenrestart aftervictoryrestoresall3dragons")
 root.size=Vector2i(960,615);await _settle();_check_layout(game);await _capture("north_27_compact.png")
 await _click("BackToLevels");_check(game.menu.strip.item_count==game.LEVEL_PATHS.size() and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"27actualdatacards,boundedpoolnotfullinstantiation");await _capture("north_27_navigation.png")
 await _click("Level26");_check(game.model.active_kind()=="red" and game.model.monsters().size()==3 and game.model.crates().size()==1,"previous26unchanged");await _click("Level27");_check(game.model.snapshot()==initial,"reenter27hasisolatedhistory")
 print("NORTH27 SCENE RESULT: %d checks, %d failures;display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
