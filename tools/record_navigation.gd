extends SceneTree
## Actual UI inputs only: no scroll/index/world assignments during the demo.
var game: Control
var frames := 0
var events: Array[Dictionary] = []
var phases: Array[Dictionary] = []
var report_path := ""
var verify_only := false
var failures := 0

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
		if arg=="--verify-only":verify_only=true
	call_deferred("_run")

func _run() -> void:
	if not verify_only and (DisplayServer.get_name()=="headless" or Engine.get_write_movie_path().is_empty()):
		push_error("Recording requires actual Movie Maker renderer");quit(1);return
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await _frames(60);_check(game.menu.visible,"startup menu");_phase("initial")
	var pool:=_pool_ids();var strip:Control=game.menu.strip
	var point:Vector2=strip.global_position+Vector2(910,150)
	await _button(point,true)
	for i in range(1,19):await _motion(point-Vector2(i*38,0));await _frames(1)
	await _button(point-Vector2(684,0),false);await _frames(30)
	_check(game.menu.visible and strip.scroll_offset>400,"drag scrolls and never enters")
	_phase("mouse_drag")
	await _wheel(strip.global_position+Vector2(550,160));await _frames(18);_phase("mouse_wheel")
	await _key(KEY_END);await _frames(30)
	_check(strip.selected_index==18,"End selects actual19");_phase("last_card")
	var offset:float=strip.scroll_offset
	var card:Control=strip.card_for_index(18)
	await _button(card.get_global_rect().get_center(),true);await _button(card.get_global_rect().get_center(),false)
	await _frames(48);_check(not game.menu.visible and game.current_level_index==18 and game.model.moves==0,"card enters actual19")
	_phase("in_level_19")
	var back:Control=game.find_child("BackToLevels",true,false)
	await _button(back.get_global_rect().get_center(),true);await _button(back.get_global_rect().get_center(),false)
	await _frames(36)
	_check(game.menu.visible and is_equal_approx(offset,strip.scroll_offset) and strip.selected_index==18 and _pool_ids()==pool,"return preserves pool/offset/selection")
	_phase("return_context")
	point=strip.global_position+Vector2(220,150)
	await _touch(point,true)
	for i in range(1,17):await _touch_motion(point+Vector2(i*35,0));await _frames(1)
	await _touch(point+Vector2(560,0),false);await _frames(36)
	_check(game.menu.visible and strip.scroll_offset<offset,"real touch swipe without click")
	_phase("touch_swipe")
	await _key(KEY_HOME)
	for _i in 4:await _key(KEY_RIGHT)
	await _frames(24);_check(strip.selected_index==4,"keyboard selects5");_phase("keyboard_selection")
	await _key(KEY_ENTER);await _frames(42)
	_check(not game.menu.visible and game.current_level_index==4 and game.model.moves==0,"Enter enters real fifth green map");_phase("in_level_05")
	offset=strip.scroll_offset;await _key(KEY_ESCAPE);await _frames(60)
	_check(game.menu.visible and strip.selected_index==4 and is_equal_approx(offset,strip.scroll_offset) and _pool_ids()==pool,"Escape restores same menu context")
	_phase("final_menu")
	var report:Dictionary={"purpose":"level navigation UI demonstration, not a level walkthrough","source_commit":OS.get_environment("STARDOWN_RECORDING_COMMIT"),"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"fps":30,"frames":frames,"events":events,"phases":phases,"final_menu_selected_index":strip.selected_index,"pool_nodes":strip.pool.size(),"created_cards":strip.created_cards,"same_pool_through_enter_return":_pool_ids()==pool,"failures":failures,"input_method":"Actual Input.parse_input_event mouse drag/wheel/touch/key press-release; no index/scroll/world writes"}
	if not report_path.is_empty():
		DirAccess.make_dir_recursive_absolute(report_path.get_base_dir());FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("NAVIGATION DEMO RESULT: %d frames,%d inputs,%d phases,%d failures,pool%d" % [frames,events.size(),phases.size(),failures,strip.pool.size()]);quit(0 if failures==0 else 1)

func _phase(label:String) -> void:
	phases.append({"label":label,"frame":maxi(0,frames-1),"menu":game.menu.visible,"offset":game.menu.strip.scroll_offset,"selected_index":game.menu.strip.selected_index,"level_index":game.current_level_index,"moves":game.model.moves,"pool_nodes":game.menu.strip.pool.size()})
func _pool_ids() -> Array:
	var result:Array=[]
	for card in game.menu.strip.pool:result.append(card.get_instance_id())
	return result
func _frames(count:int) -> void:
	for _i in count:await process_frame;frames+=1
func _send(event:InputEvent,description:Dictionary) -> void:
	description["frame"]=frames;events.append(description);Input.parse_input_event(event);await _frames(1)
func _button(at:Vector2,down:bool) -> void:
	var event:=InputEventMouseButton.new();event.position=root.get_final_transform()*at;event.global_position=event.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
	await _send(event,{"type":"mouse_button","at":[at.x,at.y],"pressed":down})
func _motion(at:Vector2) -> void:
	var event:=InputEventMouseMotion.new();event.position=root.get_final_transform()*at;event.global_position=event.position;event.button_mask=MOUSE_BUTTON_MASK_LEFT
	await _send(event,{"type":"mouse_drag","at":[at.x,at.y]})
func _wheel(at:Vector2) -> void:
	var event:=InputEventMouseButton.new();event.position=root.get_final_transform()*at;event.global_position=event.position;event.button_index=MOUSE_BUTTON_WHEEL_DOWN;event.pressed=true
	await _send(event,{"type":"mouse_wheel","at":[at.x,at.y]})
func _touch(at:Vector2,down:bool) -> void:
	var event:=InputEventScreenTouch.new();event.index=0;event.position=root.get_final_transform()*at;event.pressed=down
	await _send(event,{"type":"touch","at":[at.x,at.y],"pressed":down})
func _touch_motion(at:Vector2) -> void:
	var event:=InputEventScreenDrag.new();event.index=0;event.position=root.get_final_transform()*at
	await _send(event,{"type":"touch_drag","at":[at.x,at.y]})
func _key(code:int) -> void:
	for down in [true,false]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
		await _send(event,{"type":"key","code":code,"pressed":down})
	await _frames(10)
func _check(condition:bool,label:String) -> void:
	if not condition:failures+=1;push_error("UI demo: "+label)
