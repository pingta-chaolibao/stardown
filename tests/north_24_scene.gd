extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_A,"R":KEY_D}
const BUTTONS={"U":"MoveUp","D":"MoveDown","L":"MoveLeft","R":"MoveRight"}
const Map=preload("res://tests/north_24_regression.gd")
func _run() -> void:
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle();await _click("Level24")
 var initial:Dictionary=game.model.snapshot()
 _check(game.current_level_index==23 and game.model.hero_count()==1 and game.model.active_kind()=="green" and game.model.monsters().size()==8,"24pooled card enters green/single crystal/eight Goblins")
 _check(game.model.level.mechanism_color=="purple" and game._plate_name()=="紫板" and game._mechanism_tint()==game.board.MECHANISM_PURPLE,"purple plate/energy legend accurate without new rule")
 _check_layout(game);await _inspect_danger();await _inspect_energy();await _capture("north_24_initial.png")
 await _press(KEY_D);await _press(KEY_C)
 _check(game.model.snapshot()==initial and game.model.history_size()==0,"green cannot push initial front crystal;C cannot select Goblins")
 await _repeat();await _press(KEY_R)
 for s in "UUULLLLULULL":await _press(KEYS[s])
 var closed_before:Dictionary=game.model.snapshot();await _click("MoveUp")
 _check(game.model.snapshot()==closed_before and game.model.barrier_is_active(Map.GATE) and game.model.player==Vector2i(1,2),"actual screen movement blocked by closed purple energy without partial action")
 await _capture("north_24_closed_gate.png");await _press(KEY_R)
 await _press(KEY_A);var before_death:Dictionary=game.model.snapshot();await _click("MoveLeft")
 _check(not game.model.alive and game.model.player==Vector2i(6,7) and game.model.crate_id(Vector2i(7,7))==0 and game.model.pulls==2,"actual single pull enters Goblin85range and dies after atomic displacement")
 await _capture("north_24_pull_death.png");var dead:Dictionary=game.model.snapshot()
 for code in [KEY_UP,KEY_R,KEY_C,KEY_ESCAPE]:await _press(code)
 await _click("BackToLevels")
 _check(game.model.snapshot()==dead and not game.menu.visible and not game.back_to_menu() and not game.select_level(22),"death locked across key/screen/menu/API;cannot bypass through another map")
 await _click("Undo");_check(game.model.snapshot()==before_death and game.model.alive and game.model.crate_id(Vector2i(8,7))==0,"screenUndo revives and restores pulled crystal/counters");await _capture("north_24_revived.png");await _press(KEY_R)
 var solution:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_24.json"));var n:=0;var pulls:=0;var monsters=game.model.monsters()
 for s in solution["path"]:
  var previous:Dictionary=game.model.snapshot()
  if n%7==6:await _click(BUTTONS[s])
  else:await _press(KEYS[s])
  n+=1
  if n in Map.PULLS:pulls+=1
  _check(game.model.alive and game.model.moves==n and game.model.history_size()==n and game.model.pulls==pulls and game.model.monsters()==monsters,"all89actual keyboard/screen actions match expected fifteen single pulls")
  _check(game.model.is_complete()==(n==89),"only entering goal1 wins")
  if n==70:await _inspect_energy();await _capture("north_24_hero_plate.png")
  if n==71:await _inspect_energy();await _capture("north_24_crystal_handoff.png")
  if n==72:
   await _inspect_energy();await _capture("north_24_energy_restored.png");var restored:Dictionary=game.model.snapshot();await _press(KEY_Z)
   _check(game.model.snapshot()==previous and not game.model.barrier_is_active(Map.GATE),"Undo restoration restores crystal on plate/open energy and counters")
   await _capture("north_24_restoration_undone.png");await _press(KEYS[s]);_check(game.model.snapshot()==restored,"redo legal direction reproduces identical closed-energy state")
  if n==77:await _inspect_energy();await _capture("north_24_plate_held.png")
  if n==87:
   _check(game.model.player==Map.GATE and game.model.crate_id(Map.PLATE)==0,"hero enters energy footprint held open by crystal")
   await _inspect_energy();await _capture("north_24_open_energy_hero.png")
   root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_energy();await _capture("north_24_open_energy_compact.png")
   root.size=Vector2i(1280,820);await _settle()
 _check(game.model.pushes==0 and game.model.swaps==0 and game.model.pulls==15 and game.model.player==Vector2i(0,0),"green final goal with one crystal on94 and no invented push/swap")
 await _capture("north_24_completed.png");await _press(KEY_Z)
 _check(not game.model.is_complete() and game.model.player==Vector2i(0,1) and game.model.moves==88,"victoryUndo returns to last safe cell")
 await _press(KEY_R);_check(game.model.snapshot()==initial,"victory restart restores original crystal/eight Goblins/closed gate")
 await _click("Level23");_check(game.model.monsters().size()==10 and game.model.level.energy_links.is_empty() and game.model.level.mechanism_color=="yellow","prior23has no purple/energy/entity/history leaks")
 await _click("Level24");_check(game.model.snapshot()==initial,"return24isolates history and mechanisms")
 root.size=Vector2i(960,615);await _settle();_check_layout(game);await _inspect_danger();await _inspect_energy();await _capture("north_24_compact.png")
 await _click("BackToLevels");_check_layout(game);_check(game.menu.strip.item_count==24 and game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"24real maps use bounded reused cards")
 await _capture("north_24_navigation.png")
 var old:Control=game;root.remove_child(old);old.queue_free()
 game=load("res://scenes/main.tscn").instantiate();game.start_in_level=true;game.level_path="res://levels/north_24.json";root.add_child(game);await _settle()
 _check(game.model.moves==0 and not game.menu.visible and game.model.active_kind()=="green" and game.status_label.text.contains("哥布林"),"real recording startup selects correct green map at zero actions")
 print("NORTH 24 SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
func _repeat() -> void:
 var e:=InputEventKey.new();e.keycode=KEY_UP;e.physical_keycode=KEY_UP;e.pressed=true;Input.parse_input_event(e);await _settle();var once:Dictionary=game.model.snapshot()
 e.echo=true;Input.parse_input_event(e);await _settle();e.echo=false;Input.parse_input_event(e);await _settle()
 _check(game.model.moves==1 and game.model.snapshot()==once,"held/echo causes one action and one threat settlement")
 e.pressed=false;Input.parse_input_event(e);await _settle();await _press(KEY_UP)
 _check(game.model.moves==2 and game.model.player==Vector2i(8,5) and game.model.pulls==0,"fresh released direction works,sideways crystal not falsely pulled")
func _geometry(cell:Vector2i) -> Vector3:
 var view:Control=game.board;var level=game.model.level;var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
 var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2
 var p:Vector2=root.get_final_transform()*(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile)
 return Vector3(p.x,p.y,tile*root.get_final_transform().get_scale().x)
func _purple(c:Color) -> bool:return c.b>c.r*1.12 and c.r>c.g*1.08 and c.b>0.28
func _inspect_energy() -> void:
 var before:Dictionary=game.model.snapshot();var active:bool=game.model.barrier_is_active(Map.GATE)
 _check(game.model.blocks_sight(Map.GATE)==active and game.model.is_walkable(Map.GATE)==not active,"purple color never changes energy movement/sight semantics")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  var im:=root.get_texture().get_image();var p:=_geometry(Map.GATE);var center:=im.get_pixel(int(p.x),int(p.y))
  if active:_check(_purple(im.get_pixel(int(p.x+p.z*0.10),int(p.y+p.z*0.05))),"closed purple energy field is solid purple between its pale accent lines")
  else:
   var ink:=0;var gaps:=0
   for x in range(int(p.x-p.z*0.40),int(p.x+p.z*0.40)):
    var colored:=false
    for dy in range(-1,2):
     if _purple(im.get_pixel(x,int(p.y-p.z*0.43)+dy)):colored=true
    if colored:ink+=1
    else:gaps+=1
   _check(ink>=4 and gaps>=4,"absent energy retains purple dashed perimeter with visible gaps,including hero overlay/compact")
   if game.model.player!=Map.GATE:_check(maxf(center.r,maxf(center.g,center.b))<0.46,"empty absent energy center stays dim and flat")
 _check(game.model.snapshot()==before,"render inspection never alters action/pressure/life state")
func _inspect_danger() -> void:
 var danger:Array[Vector2i]=[];var safe=[Vector2i(1,1),Vector2i(4,3),Vector2i(8,1),Vector2i(9,7)]
 for y in 11:
  for x in 13:
   var c:=Vector2i(x,y)
   if game.model.level.is_floor(c) and game.model.monster_danger_at(c):danger.append(c)
 _check(danger.size()==29,"29cardinal danger cells;void excluded and no extra diagonals")
 for c in safe:_check(c not in danger,"safe controls including energy terrain are not Goblin threats")
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 var im:=root.get_texture().get_image()
 for c in danger+safe:
  var p:=_geometry(c);var marked:=0
  for edge in [Vector2(-0.43,0),Vector2(0.43,0),Vector2(0,-0.43),Vector2(0,0.43)]:
   var sample:Vector2=Vector2(p.x,p.y)+edge*p.z;var colored:=false
   for dx in range(-1,2):
    for dy in range(-1,2):
     var color:=im.get_pixel(roundi(sample.x)+dx,roundi(sample.y)+dy)
     if color.r>0.3 and color.r>color.g*1.3 and color.r>color.b*1.4:colored=true
   if colored:marked+=1
  _check(marked>=2 if c in danger else marked==0,"cardinal rust perimeter c=%s size=%s marked=%d" % [c,root.size,marked])
