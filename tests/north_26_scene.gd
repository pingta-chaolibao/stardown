extends "res://tests/north_02_scene.gd"
const Map=preload("res://tests/north_26_regression.gd")
func _run() -> void:
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level26")
 _check(game.current_level_index==25 and game.model.active_kind()=="red" and game.model.monsters().size()==3,"pooled26card enters exact new fire map")
 var initial:Dictionary=game.model.snapshot()
 _check(game.model.monsters()[0]["facing"]==Vector2i.RIGHT and game.model.monsters()[1]["facing"]==Vector2i.UP and game.model.monsters()[2]["alive"],"fixed arrows and no birth attack")
 _check_layout(game);await _inspect_fire();await _capture("north_26_initial.png")
 # A held fresh key moves once; echo/duplicate events never become wait/fire turns.
 var event:=InputEventKey.new();event.keycode=KEY_A;event.physical_keycode=KEY_A;event.pressed=true;Input.parse_input_event(event);await _settle();var once:Dictionary=game.model.snapshot()
 event.echo=true;Input.parse_input_event(event);await _settle();event.echo=false;Input.parse_input_event(event);await _settle()
 _check(game.model.moves==1 and game.model.snapshot()==once and game.model.monsters()[2]["alive"],"echo/held duplicates do not advance fire")
 event.pressed=false;Input.parse_input_event(event);await _settle();await _press(KEY_R)
 await _click("MoveLeft");await _click("MoveLeft");await _click("MoveUp")
 _check(game.model.moves==3 and game.model.pushes==1 and game.model.monsters()[2]["position"]==Vector2i(8,4),"screen buttons use same legal mixed push and fire settlement")
 await _click("Undo");await _click("Restart");_check(game.model.snapshot()==initial,"screenUndo/Restart restore full world")
 for i in Map.PATH.length():
  await _press(_keycode(Map.PATH[i]));_check(game.model.alive and game.model.moves==i+1,"real keyboard legal route action %d" % (i+1))
  if i==4:
   _check(not game.model.monsters()[2]["alive"] and game.status_label.text.contains("死亡"),"step5visible fire kill,dead Goblin no threat")
   await _capture("north_26_fire_kill.png")
  if i==5:
   _check(game.model.crate_id(Vector2i(8,2))==0 and not game.model.fire_danger_at(Vector2i(9,2)),"crystal shields horizontal line")
   await _inspect_fire();await _capture("north_26_crystal_shield.png")
 _check(game.model.is_complete() and game.moves_label.text=="18" and game.pushes_label.text=="09" and game.status_label.text.contains("已抵达终点"),"actual UI explicit living victory18/9")
 await _capture("north_26_completed.png");await _press(KEY_Z);_check(not game.model.is_complete() and game.model.alive,"victoryUndo reverses last actual action");await _press(KEY_R)
 for s in Map.PATH.substr(0,8)+"ULLLLLL":await _press(_keycode(s))
 _check(not game.model.alive and game.model.death_reason=="fire" and game.status_label.text.contains("火焰"),"real legal side branch visibly dies on vertical ray")
 await _capture("north_26_fire_death.png");var dead:Dictionary=game.model.snapshot()
 await _press(KEY_C);await _press(KEY_R);await _press(KEY_D);await _click("BackToLevels")
 _check(game.model.snapshot()==dead and not game.menu.visible and game.find_child("BackToLevels",true,false).disabled,"C/restart/walk/menu cannot bypass fire death")
 await _click("Undo");_check(game.model.alive and game.model.player==Vector2i(4,1),"actualUndo revives");await _click("Restart")
 root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_fire();await _capture("north_26_compact.png")
 await _click("BackToLevels");_check(game.menu.strip.item_count==game.LEVEL_PATHS.size() and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"26real catalog,viewport pool bounded")
 await _capture("north_26_navigation.png");await _click("Level25");_check(game.model.active_kind()=="blue" and game.model.monsters().size()==15 and game.model.fire_rays().is_empty(),"previous25no fire or facing contamination")
 await _click("Level26");_check(game.model.snapshot()==initial,"reentry resets26independent history")
 print("NORTH 26 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _inspect_fire() -> void:
 var rays=game.model.fire_rays();_check(rays.size()==2,"two fixed dragon rays,not Goblin4directions")
 for ray in rays:
  var direction:Vector2i=game.model.monsters()[ray["dragon"]]["facing"];var p:Vector2i=game.model.monsters()[ray["dragon"]]["position"]
  for cell in ray["cells"]:
   p+=direction;_check(p==cell and game.model.level.is_floor(cell) and game.model.crate_id(cell)<0,"contiguous visible ray ends before floor blocker/crystal")
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var view:Control=game.board;var level=game.model.level;var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height));var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2;var im:=root.get_texture().get_image()
 # Actual viewport pixels: both distinct arrowheads remain bright at both sizes.
 for m in game.model.monsters():
  if m["kind"]!="fire_dragon":continue
  var center:Vector2=origin+(Vector2(m["position"])+Vector2.ONE*0.5)*tile;var point:Vector2=root.get_final_transform()*(center+Vector2(m["facing"])*tile*0.20);var bright:=false
  for dx in range(-2,3):
   for dy in range(-2,3):
    var color:=im.get_pixel(roundi(point.x)+dx,roundi(point.y)+dy)
    if color.r>0.8 and color.g>0.65 and color.b>0.35:bright=true
  _check(bright,"actual rendered fixed-facing arrow visible %s %s" % [m["facing"],root.size])
