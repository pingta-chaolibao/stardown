extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_A,"R":KEY_D}
const BUTTONS={"U":"MoveUp","D":"MoveDown","L":"MoveLeft","R":"MoveRight"}
const MonsterMap=preload("res://tests/north_23_regression.gd")
func _run() -> void:
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level23")
 var initial:Dictionary=game.model.snapshot()
 _check(game.current_level_index==22 and game.model.monsters().size()==10 and game.model.hero_count()==1 and game.model.active_kind()=="red","23pooled card enters ten-Goblin single-red map")
 _check(game.menu.entries[22]["detail"].contains("10 只哥布林"),"card accurately names current typed monsters")
 _check_layout(game);await _inspect_danger();await _capture("north_23_initial.png")
 await _press(KEY_UP);await _press(KEY_LEFT);await _press(KEY_C)
 _check(game.model.snapshot()==initial and game.model.history_size()==0,"corner blocked inputs and single-hero C uncounted;goblins not selectable")
 await _repeat();await _press(KEY_R)
 for s in "DRDR":await _press(KEYS[s])
 var before:Dictionary=game.model.snapshot();await _click("MoveUp")
 _check(not game.model.alive and game.model.player==Vector2i(2,1) and game.model.moves==5 and game.status_label.text.contains("哥布林"),"screen input enters two-Goblin overlap and dies immediately")
 await _capture("north_23_overlap_death.png");var dead:Dictionary=game.model.snapshot()
 await _press(KEY_UP);await _press(KEY_R);await _press(KEY_C);await _press(KEY_ESCAPE);await _click("BackToLevels")
 _check(game.model.snapshot()==dead and not game.menu.visible and not game.back_to_menu() and not game.select_level(21),"death cannot be bypassed with push/C/restart/menu or prior monster level")
 await _click("Undo");_check(game.model.snapshot()==before and game.model.alive,"one screenUndo fully revives from double threat");await _capture("north_23_revived.png");await _press(KEY_R)
 var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_23.json"));var n:=0;var monsters=game.model.monsters()
 for s in solution["path"]:
  if n%3==2:await _click(BUTTONS[s])
  else:await _press(KEYS[s])
  n+=1
  _check(game.model.moves==n and game.model.history_size()==n and game.model.alive and game.model.monsters()==monsters,"31actual keyboard/screen directions keep allten monsters stationary")
  _check(game.model.is_complete()==(n==31),"only hero reaching76wins")
  if n==2:await _capture("north_23_diagonal_safe.png")
  if n==11:await _capture("north_23_lower_passage.png")
 _check(game.model.pushes==0 and game.model.pulls==0 and game.model.swaps==0 and game.model.player==Vector2i(9,6),"no nonexistent crystal/skill action used")
 await _capture("north_23_completed.png");await _press(KEY_Z)
 _check(not game.model.is_complete() and game.model.player==Vector2i(10,6) and game.model.moves==30,"victory undo restores safe corner approach")
 await _press(KEY_R);_check(game.model.snapshot()==initial,"restart restores allten typed life/position and history")
 await _click("Level22");_check(game.model.monsters().size()==3 and game.model.moves==0,"priorGoblin map retains own three identities")
 await _click("Level01");_check(game.model.monsters().is_empty() and not game.model.snapshot().has("monster_positions"),"legacy single hero snapshot shape unchanged")
 await _click("Level23");_check(game.model.snapshot()==initial,"reenter23isolates history/life")
 root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_danger();await _capture("north_23_compact.png")
 await _click("BackToLevels");_check_layout(game)
 _check(game.menu.strip.item_count==game.LEVEL_PATHS.size() and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"23real maps with bounded viewport pool")
 await _capture("north_23_navigation.png")
 var old_game:Control=game;root.remove_child(old_game);old_game.queue_free()
 game=load("res://scenes/main.tscn").instantiate();game.start_in_level=true;game.level_path="res://levels/north_23.json";root.add_child(game);await _settle()
 _check(game.model.moves==0 and not game.menu.visible and game.status_label.text.contains("哥布林") and not game.status_label.text.contains("水晶"),"actual recording startup hint matches no-crystal Goblin map")
 print("NORTH 23 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _repeat() -> void:
 var e:=InputEventKey.new();e.keycode=KEY_DOWN;e.physical_keycode=KEY_DOWN;e.pressed=true;Input.parse_input_event(e);await _settle();var once:Dictionary=game.model.snapshot()
 e.echo=true;Input.parse_input_event(e);await _settle();e.echo=false;Input.parse_input_event(e);await _settle()
 _check(game.model.moves==1 and game.model.player==Vector2i(0,1) and game.model.snapshot()==once,"echo/held direction neither repeats nor triggers extra attacks")
 e.pressed=false;Input.parse_input_event(e);await _settle();await _press(KEY_D)
 _check(game.model.moves==2 and game.model.player==Vector2i(1,1) and game.model.alive,"release then fresh right works;safe diagonal stays safe")
func _inspect_danger() -> void:
 var threats:Array[Vector2i]=[];var safe=[Vector2i(1,1),Vector2i(2,2),Vector2i(9,1),Vector2i(10,6)]
 for y in 7:
  for x in 11:
   var c:=Vector2i(x,y)
   if game.model.monster_danger_at(c):threats.append(c)
 _check(threats.size()==26,"26unique in-bounds danger cells;overlap drawn once,not extra diagonal tiles")
 for c in MonsterMap.OVERLAP:_check(c in threats,"all7double-threat cells including floor67 visible")
 for c in safe:_check(c not in threats,"specified diagonal/edge safe cells not marked dangerous")
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var view:Control=game.board;var level=game.model.level;var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
 var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2;var im:=root.get_texture().get_image()
 # Sample all four sides: a 1.3px border can rasterize below one physical
 # pixel on one side of a 75%-scaled viewport. Require at least two own-cell
 # sides, and no marked side for the explicit safe controls.
 for c in threats+safe:
  var marked_sides:=0
  for edge in [Vector2(-0.43,0),Vector2(0.43,0),Vector2(0,-0.43),Vector2(0,0.43)]:
   var p:Vector2=root.get_final_transform()*(origin+(Vector2(c)+Vector2.ONE*0.5+edge)*tile);var colored:=false
   for dx in range(-1,2):
    for dy in range(-1,2):
     var color:=im.get_pixel(roundi(p.x)+dx,roundi(p.y)+dy)
     if color.r>0.3 and color.r>color.g*1.3 and color.r>color.b*1.4:colored=true
   if colored:marked_sides+=1
  _check(marked_sides>=2 if c in threats else marked_sides==0,"rendered danger perimeter cell=%s window=%s marked_sides=%d expected=%s" % [c,root.size,marked_sides,c in threats])
