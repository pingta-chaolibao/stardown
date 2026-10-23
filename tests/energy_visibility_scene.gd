extends "res://tests/north_02_scene.gd"
const KEYS={"U":KEY_UP,"D":KEY_DOWN,"L":KEY_LEFT,"R":KEY_RIGHT,"C":KEY_C}
func _run() -> void:
	root.size=Vector2i(1280,820)
	game=preload("res://scenes/main.tscn").instantiate();root.add_child(game)
	await _settle();await _click("Level17")
	var initial:Dictionary=game.model.snapshot()
	await _capture("energy_closed.png")
	if DisplayServer.get_name()!="headless":
		var actual:=root.get_texture().get_image();var old:=Image.load_from_file("res://docs/screenshots/level_17_initial.png")
		for cell in [Vector2i(0,2),Vector2i(8,2)]:_check(_region(actual,cell).get_data()==_region(old,cell).get_data(),"active yellow energy pixels unchanged from prior delivered screenshot")
	_check(game.model.snapshot()==initial,"drawing closed energy changes no world state")
	await _play("URRRRDLULLRULD")
	await _inspect(Vector2i(0,2),false,"empty yellow absent energy")
	await _capture("energy_open_empty.png")
	await _choose("green");await _play("UU")
	_check(game.model.player==Vector2i(0,2) and game.model.active_hero_id()=="green","legal active hero enters absent energy")
	await _inspect(Vector2i(0,2),false,"active hero overlay")
	root.size=Vector2i(960,615);await _settle()
	await _inspect(Vector2i(0,2),false,"compact active hero overlay")
	await _capture("energy_open_active_hero.png")
	await _choose("blue")
	_check(game.model.hero_position(0)==Vector2i(0,2),"inactive hero remains on absent energy")
	await _inspect(Vector2i(0,2),false,"compact inactive hero overlay")
	await _capture("energy_open_inactive_hero.png")
	await _choose("green");await _play("D");await _choose("red");await _play("U");await _choose("green");await _play("UUDD")
	_check(game.model.crate_id(Vector2i(0,2))==0 and game.model.crate_id(Vector2i(8,2))==2,"legal crystals occupy both absent energy cells")
	await _inspect(Vector2i(0,2),false,"compact blue crystal overlay");await _inspect(Vector2i(8,2),false,"compact pink crystal overlay")
	await _capture("energy_open_crystals_compact.png")
	root.size=Vector2i(1280,820);await _settle()
	await _inspect(Vector2i(0,2),false,"blue crystal overlay");await _inspect(Vector2i(8,2),false,"pink crystal overlay")
	await _capture("energy_block_visibility.png")
	await _choose("blue");var open:Dictionary=game.model.snapshot();await _press(KEY_UP)
	_check(game.model.barrier_is_active(Vector2i(0,2)) and game.model.crates().size()==2 and game.model.alive,"restoration retains existing destruction semantics")
	await _capture("energy_restored.png")
	if DisplayServer.get_name()!="headless":
		var actual:=root.get_texture().get_image();var old:=Image.load_from_file("res://docs/screenshots/level_17_initial.png")
		for cell in [Vector2i(0,2),Vector2i(8,2)]:_check(_region(actual,cell).get_data()==_region(old,cell).get_data(),"restored solid block pixels unchanged")
	await _press(KEY_Z)
	_check(game.model.snapshot()==open and game.model.active_hero_id()=="blue","undo restores crystals, pressure and absent markers without new history")
	await _capture("energy_undo_restored.png")
	await _click("Level11")
	await _play("LLLLLDDDDRD")
	_check(game.model.level.mechanism_color=="green" and not game.model.barrier_is_active(Vector2i(7,1)),"existing green mechanism opens through legal original route")
	await _inspect(Vector2i(7,1),true,"green absent energy")
	await _capture("energy_green_open.png")
	root.size=Vector2i(960,615);await _settle();await _inspect(Vector2i(7,1),true,"compact green absent energy")
	await _capture("energy_green_open_compact.png")
	var green_open:Dictionary=game.model.snapshot();await _press(KEY_LEFT)
	_check(game.model.barrier_is_active(Vector2i(7,1)),"green solid appearance returns through pressure release")
	await _press(KEY_Z);_check(game.model.snapshot()==green_open,"green undo restores absent marker and original world")
	_check_layout(game)
	print("ENERGY VISIBILITY SCENE RESULT: %d checks, %d failures; display=%s" % [checks,failures,DisplayServer.get_name()])
	quit(0 if failures==0 else 1)
func _play(path:String) -> void:
	for symbol in path:
		var before:int=game.model.moves
		await _press(KEYS[symbol])
		_check(game.model.moves==before+1 and game.model.alive,"legal original input for visibility scenario")
func _choose(id:String) -> void:
	var before:Dictionary=game.model.snapshot()
	for _i in game.model.hero_count():
		if game.model.active_hero_id()==id:break
		await _press(KEY_C)
	_check(game.model.active_hero_id()==id and game.model.snapshot()==before,"selection only, no pressure/history change")
func _center_and_tile(cell:Vector2i) -> Vector3:
	var view:Control=game.board;var level=game.model.level
	var tile:float=minf(72.0,minf((view.size.x-32)/level.width,(view.size.y-24)/level.height))
	var origin:Vector2=view.global_position+(view.size-Vector2(level.width,level.height)*tile)/2
	var center:Vector2=root.get_final_transform()*(origin+(Vector2(cell)+Vector2.ONE*0.5)*tile)
	return Vector3(center.x,center.y,tile*root.get_final_transform().get_scale().x)
func _region(image:Image,cell:Vector2i) -> Image:
	var p:=_center_and_tile(cell);var half:=p.z*0.46
	return image.get_region(Rect2i(int(p.x-half),int(p.y-half),int(half*2),int(half*2)))
func _tinted(c:Color,green:bool) -> bool:
	return c.g>c.r*1.25 and c.g>c.b*1.1 and c.g>0.35 if green else c.r>c.b*1.15 and c.g>c.b*1.1 and c.r>0.30 and c.g>0.30
func _inspect(cell:Vector2i,green:bool,label:String) -> void:
	var before:Dictionary=game.model.snapshot();game.board.queue_redraw();await _settle()
	_check(not game.model.barrier_is_active(cell) and game.model.is_walkable(cell) and not game.model.blocks_sight(cell),label+" remains passable and transparent")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var image:=root.get_texture().get_image();var p:=_center_and_tile(cell);var colored:=0;var gaps:=0
		for x in range(int(p.x-p.z*0.40),int(p.x+p.z*0.40)):
			var c:=image.get_pixel(x,int(p.y-p.z*0.43))
			if _tinted(c,green):colored+=1
			else:gaps+=1
		_check(colored>=8 and gaps>=8,label+" has visible colored dashes and clear gaps along top edge")
		if label=="empty yellow absent energy" or label=="green absent energy":
			var c:=image.get_pixel(int(p.x),int(p.y))
			_check(maxf(c.r,maxf(c.g,c.b))<0.46,label+" center stays flat/dim rather than solid raised energy")
	_check(game.model.snapshot()==before,label+" repaint never changes occupancy/life/pressure/history")
