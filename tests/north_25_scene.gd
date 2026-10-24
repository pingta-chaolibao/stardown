extends "res://tests/north_02_scene.gd"
const Map=preload("res://tests/north_25_regression.gd")
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_A,"R":KEY_D}
const BUTTONS={"U":"MoveUp","D":"MoveDown","L":"MoveLeft","R":"MoveRight"}
func _run() -> void:
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level25")
 var initial:Dictionary=game.model.snapshot()
 _check(game.current_level_index==24 and game.model.active_kind()=="blue" and game.model.hero_count()==1 and game.model.crates().size()==19 and game.model.monsters().size()==15,"25pooled card enters correct blue/crystal/Goblin map")
 _check(game.swaps_label!=null and game.pushes_label==null and game.pulls_label==null,"blue UI exposes exchanges,not pushing/pulling or skill mode")
 _check_layout(game);await _inspect_danger();await _capture("north_25_initial.png")
 await _press(KEY_D);_check(game.model.player==Vector2i(1,0) and game.model.swaps==0,"wall blocks ray;first Right falls back one safe step")
 var probe:Dictionary=game.model.snapshot();await _click("MoveRight");_check(game.model.snapshot()==probe,"clutter wall still blocks fallback movement")
 await _press(KEY_R);await _press(KEY_C);_check(game.model.snapshot()==initial,"C cannot select Goblins or alter single-blue world")
 await _repeat();await _press(KEY_R)
 await _press(KEY_DOWN);var before:Dictionary=game.model.snapshot();await _click("MoveRight")
 _check(not game.model.alive and game.model.player==Vector2i(3,1) and game.model.crate_id(Vector2i(0,1))==0 and game.model.swaps==1 and game.model.moves==2,"screen direction swaps nearest crystal then Goblin4kills hero adjacent to new location")
 await _capture("north_25_swap_death.png");var dead:Dictionary=game.model.snapshot()
 for code in [KEY_UP,KEY_C,KEY_R,KEY_ESCAPE]:await _press(code)
 await _click("BackToLevels")
 _check(game.model.snapshot()==dead and not game.menu.visible and not game.back_to_menu() and not game.select_level(23),"death cannot bypass through movement/C/restart/Back/Escape/API")
 await _click("Undo");_check(game.model.alive and game.model.snapshot()==before and game.model.crate_id(Vector2i(3,1))==0,"one screenUndo restores hero AND swapped crystal identity/count");await _capture("north_25_revived.png");await _press(KEY_R)
 var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_25.json"));var n:=0;var swaps:=0
 for s in solution["path"]:
  var old_monsters=game.model.monsters();var old_hero:Vector2i=game.model.player
  if n%4==3:await _click(BUTTONS[s])
  else:await _press(KEYS[s])
  n+=1
  if n in Map.SWAPS:swaps+=1
  _check(game.model.alive and game.model.player==Map.HERO_PATH[n-1] and game.model.moves==n and game.model.swaps==swaps and game.model.history_size()==n,"all36actual directions choose first visible object or one walk,matching exact checked positions")
  _check(game.model.is_complete()==(n==36) and game.model.crates().size()==19,"only hero120wins;all19 crystals remain ordinary actors")
  for m in game.model.monsters():_check(m["alive"] and m["position"]==(old_hero if n in Map.GOBLIN_SWAPS and m["id"]==Map.GOBLIN_SWAPS[n] else old_monsters[m["id"]]["position"]),"only exchanged Goblin moves,all15survive and no passive ability fires")
  if n==3:await _capture("north_25_crystal_swap.png")
  if n in [12,23,32]:
   await _inspect_danger();await _capture("north_25_goblin_swap_%02d.png" % n)
   var idle:Dictionary=game.model.snapshot()
   for frame in 20:await process_frame
   _check(game.model.snapshot()==idle,"rendering/idle never autonomously moves Goblins or rescans blue directions")
  if n in [30,31]:await _capture("north_25_bottom_swap_%02d.png" % n)
  if n==33:_check(game.model.player==Vector2i(8,9) and not game.model.monster_danger_at(Vector2i(8,9)) and game.model.swaps==17,"moving bottom Goblin really clears formerly lethal approach")
 await _capture("north_25_completed.png");await _press(KEY_Z)
 _check(not game.model.is_complete() and game.model.player==Vector2i(10,9) and game.model.moves==35 and game.model.swaps==17,"victoryUndo returns one walk without undoing earlier Goblin swaps")
 await _press(KEY_R);_check(game.model.snapshot()==initial,"restart restores all19crystals/15Goblins and counters")
 await _click("Level24");_check(game.model.active_kind()=="green" and game.model.crates().size()==1 and game.model.monsters().size()==8 and game.model.level.mechanism_color=="purple","previous24rules/entities and purple mechanisms remain intact")
 await _click("Level25");_check(game.model.snapshot()==initial and game.model.level.energy_links.is_empty(),"return25isolates history and removes prior mechanisms")
 root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_danger();await _capture("north_25_compact.png")
 await _click("BackToLevels");_check_layout(game);_check(game.menu.strip.item_count==game.LEVEL_PATHS.size() and game.menu.strip.item_count==25 and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"25actual data cards,viewport pool remains bounded")
 await _capture("north_25_navigation.png")
 var previous:Control=game;root.remove_child(previous);previous.queue_free();game=load("res://scenes/main.tscn").instantiate();game.start_in_level=true;game.level_path="res://levels/north_25.json";root.add_child(game);await _settle()
 _check(game.model.moves==0 and game.model.active_kind()=="blue" and not game.menu.visible and game.status_label.text.contains("哥布林"),"formal recorder startup is exact unsolved blue25")
 print("NORTH 25 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _repeat() -> void:
 var event:=InputEventKey.new();event.keycode=KEY_DOWN;event.physical_keycode=KEY_DOWN;event.pressed=true;Input.parse_input_event(event);await _settle();var once:Dictionary=game.model.snapshot()
 event.echo=true;Input.parse_input_event(event);await _settle();event.echo=false;Input.parse_input_event(event);await _settle()
 _check(game.model.moves==1 and game.model.player==Vector2i(0,1) and game.model.snapshot()==once,"one held direction never repeats or scans other rays")
 event.pressed=false;Input.parse_input_event(event);await _settle();await _press(KEY_DOWN)
 _check(game.model.moves==2 and game.model.player==Vector2i(0,2) and game.model.swaps==0,"fresh Down walks without exchanging side crystals")
func _inspect_danger() -> void:
 var danger:Array[Vector2i]=[];var safe:Array[Vector2i]=[];var monsters=game.model.monsters()
 for y in 11:
  for x in 12:
   var c:=Vector2i(x,y)
   if not game.model.level.is_floor(c):continue
   var threatened:=false
   for m in monsters:
    var p:Vector2i=m["position"]
    if m["alive"] and absi(c.x-p.x)+absi(c.y-p.y)==1:threatened=true
   _check(game.model.monster_danger_at(c)==threatened,"danger query follows current Goblin identities after exchange")
   if threatened:danger.append(c)
   elif safe.size()<4 and game.model.monster_at(c)<0 and game.model.crate_id(c)<0 and c!=game.model.player:safe.append(c)
 for c in [Vector2i(11,2),Vector2i(0,6),Vector2i(8,9)]:
  if c not in danger and c not in safe and game.model.monster_at(c)<0 and game.model.crate_id(c)<0 and c!=game.model.player:safe.append(c)
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var view:Control=game.board;var level=game.model.level;var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
 var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2;var im:=root.get_texture().get_image()
 for c in danger+safe:
  var marked:=0
  for edge in [Vector2(-0.43,0),Vector2(0.43,0),Vector2(0,-0.43),Vector2(0,0.43)]:
   var p:Vector2=root.get_final_transform()*(origin+(Vector2(c)+Vector2.ONE*0.5+edge)*tile);var colored:=false
   for dx in range(-1,2):
    for dy in range(-1,2):
     var color:=im.get_pixel(roundi(p.x)+dx,roundi(p.y)+dy)
     if color.r>0.3 and color.r>color.g*1.3 and color.r>color.b*1.4:colored=true
   if colored:marked+=1
  _check(marked>=2 if c in danger else marked==0,"rendered hazard/safe perimeter follows moved Goblins c=%s window=%s sides=%d" % [c,root.size,marked])
