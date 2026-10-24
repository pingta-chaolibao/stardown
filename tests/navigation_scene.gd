extends "res://tests/north_02_scene.gd"
const Strip = preload("res://scripts/view/virtual_level_strip.gd")
var activation_events: Array[int] = []
var observations: Dictionary = {}

func _run() -> void:
	root.size=Vector2i(1280,820)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await _settle()
	_check(game.menu.visible and not game.ui_root.visible,"default startup is independent menu")
	_check(game.menu.entries.size()==19 and game.menu.strip.item_count==19,"only19real maps, no synthetic production levels")
	_check(game.menu.strip.pool.size()<=game.menu.strip.capacity_bound(),"startup pool bounded by viewport")
	_check(game.find_child("BackToLevels",true,false)!=null,"game has return entry")
	_check_layout(game);await _capture("navigation_main.png")
	var menu_id:int=game.menu.get_instance_id();var pool_ids:=_ids(game.menu.strip)
	for index in 19:
		game.menu.strip.reveal_index(index);await _settle()
		var offset:float=game.menu.strip.scroll_offset
		await _click("Level%02d" % (index+1))
		_check(not game.menu.visible and game.ui_root.visible and game.current_level_index==index,"rebound card enters correct real map%d" % (index+1))
		_check(game.model.level.id=="north_hero_%02d" % (index+1) and game.model.moves==0 and game.model.history_size()==0,"correct initial model and isolated history")
		await _click("BackToLevels")
		_check(game.menu.visible and game.menu.get_instance_id()==menu_id and _ids(game.menu.strip)==pool_ids,"return retains exact menu/card objects")
		_check(is_equal_approx(offset,game.menu.strip.scroll_offset) and game.menu.strip.selected_index==index,"return preserves scroll and logical selection")
	await _capture("navigation_last.png")
	await _press(KEY_HOME);_check(game.menu.strip.selected_index==0 and game.menu.strip.scroll_offset==0,"Home reaches first")
	await _press(KEY_END);_check(game.menu.strip.selected_index==18 and is_equal_approx(game.menu.strip.scroll_offset,game.menu.strip.max_scroll()),"End reaches last")
	await _press(KEY_LEFT);await _press(KEY_ENTER)
	_check(game.current_level_index==17 and not game.menu.visible,"keyboard selects18 and Enter enters")
	await _capture("navigation_in_level.png")
	await _press(KEY_RIGHT);var preserved_world:Dictionary=game.model.snapshot()
	await _press(KEY_ESCAPE);_check(game.menu.visible and game.menu.strip.selected_index==17,"Escape returns to same context")
	for code in [KEY_C,KEY_R,KEY_Z,KEY_D,KEY_UP]:await _press(code)
	_check(game.model.snapshot()==preserved_world,"menu keyboard never moves,restarts,switches or undoes hidden game")
	await _death_guard()
	await _stress()
	for window in [Vector2i(960,615),Vector2i(1600,820)]:
		root.size=window;await _settle();game.menu.strip.reveal_index(11);await _settle();_check_layout(game)
		await _click("Level12");_check(game.current_level_index==11 and not game.menu.visible,"real card click after window resize")
		await _click("BackToLevels");_check(game.menu.visible,"real return after window resize")
		game.menu.strip.reveal_index(12);await _settle()
		var touch_card:Control=game.menu.strip.card_for_index(12)
		await _touch(touch_card.get_global_rect().get_center(),true);await _touch(touch_card.get_global_rect().get_center(),false)
		_check(game.current_level_index==12 and not game.menu.visible,"touch tap enters rebound card at resized viewport")
		await create_timer(0.2).timeout;await _click("BackToLevels")
		await _capture("navigation_%dx%d.png" % [window.x,window.y])
	_check(game.menu.entries.size()==19 and game.menu.strip.item_count==19,"stress source never changes real catalog")
	observations["real_menu_pool"]=game.menu.strip.pool.size();observations["checks"]=checks;observations["failures"]=failures
	DirAccess.make_dir_recursive_absolute("res://artifacts/verification")
	FileAccess.open("res://artifacts/verification/navigation_observations_%s.json" % DisplayServer.get_name(),FileAccess.WRITE).store_string(JSON.stringify(observations,"  ")+"\n")
	print("NAVIGATION RESULT: %d checks, %d failures; display=%s; observations=%s" % [checks,failures,DisplayServer.get_name(),JSON.stringify(observations)])
	quit(0 if failures==0 else 1)

func _death_guard() -> void:
	await _click("Level19")
	var path:String=JSON.parse_string(FileAccess.get_file_as_string("res://levels/solutions/north_19.json"))["path"]
	for symbol in path:
		if game.model.moves>=36:break
		await _press({"C":KEY_C,"U":KEY_UP,"D":KEY_DOWN,"L":KEY_LEFT,"R":KEY_RIGHT}[symbol])
	while game.model.active_hero_id()!="green":await _press(KEY_C)
	var before:Dictionary=game.model.snapshot();await _press(KEY_UP)
	_check(not game.model.alive,"legal19side path kills inactive red")
	var dead:Dictionary=game.model.snapshot();await _click("BackToLevels");await _press(KEY_ESCAPE)
	_check(not game.menu.visible and game.model.snapshot()==dead,"return button and Escape cannot bypass death")
	_check(not game.back_to_menu() and not game.select_level(0) and game.model.snapshot()==dead,"public navigation APIs share death lock")
	await _capture("navigation_death_locked.png");await _press(KEY_Z)
	_check(game.model.snapshot()==before and game.model.active_hero_id()=="green","Undo revives with current selection and complete world")
	await _click("BackToLevels");_check(game.menu.visible,"revived hero can return normally")

func _stress() -> void:
	game.hide()
	var strip:=Strip.new();strip.position=Vector2(40,180);strip.size=Vector2(1180,370);root.add_child(strip)
	var calls: Array[int]=[0]
	var source:=func(index:int)->Dictionary:
		calls[0]+=1
		return {"title":"测试关卡 %d" % (index+1),"kinds":["red"],"detail":"仅用于压力测试"}
	var started:=Time.get_ticks_usec();strip.set_source(1000,source);await _settle()
	_check(strip.pool.size()<=strip.capacity_bound() and strip.created_cards<20 and calls[0]<20,"1000items create only viewport cards")
	var initial_ids:=_ids(strip);var created:int=strip.created_cards
	strip.set_source(5000,source);await _settle();_check(_ids(strip)==initial_ids and strip.created_cards==created,"5000items reuse same pool; no per-level instantiation")
	strip.activated.connect(func(index:int):activation_events.append(index))
	for index in [0,4999,2500,1,3141,4998,0,4999,127]:
		strip.reveal_index(index);await _settle()
		var card:Control=strip.card_for_index(index)
		_check(card!=null and card.bound_index==index and card.entry["title"]=="测试关卡 %d" % (index+1),"first/middle/end binding exact")
		_check(_ids(strip)==initial_ids and strip.created_cards==created,"fast reverse scrolling creates zero new nodes")
		await _mouse(card.get_global_rect().get_center(),true);await _mouse(card.get_global_rect().get_center(),false)
		_check(not activation_events.is_empty() and activation_events[-1]==index,"recycled card click emits current index")
	strip.grab_focus();await _press(KEY_END);_check(strip.selected_index==4999,"logical keyboard focus survives recycling")
	await _press(KEY_HOME);_check(strip.selected_index==0,"keyboard first after recycled last")
	await _press(KEY_PAGEDOWN);_check(strip.selected_index>0 and strip.selected_index<10,"PageDown advances viewport-sized selection")
	await _press(KEY_PAGEUP);_check(strip.selected_index==0,"PageUp returns to first")
	strip.reveal_index(3141);await _press(KEY_ENTER);_check(activation_events[-1]==3141,"Enter activates logical selection after many rebindings")
	strip.reveal_index(2500);await _settle();var count:int=activation_events.size();var offset:float=strip.scroll_offset
	var point:=strip.global_position+Vector2(500,130)
	await _mouse(point,true);await _motion(point-Vector2(210,0));await _mouse(point-Vector2(210,0),false)
	_check(strip.scroll_offset>offset and activation_events.size()==count,"mouse drag scrolls, never clicks")
	strip.freeze();offset=strip.scroll_offset;await _wheel(point)
	_check(strip.scroll_offset>offset,"vertical mouse wheel maps to horizontal browsing")
	strip.reveal_index(2500);await _settle();offset=strip.scroll_offset
	await _touch(point,true);await _touch_drag(point-Vector2(190,0));await _touch(point-Vector2(190,0),false)
	_check(strip.scroll_offset>offset and activation_events.size()==count,"touch swipe scrolls without activation")
	strip.freeze();await _settle();await _touch(point,true)
	var cancel:=InputEventScreenTouch.new();cancel.index=0;cancel.position=root.get_final_transform()*point;cancel.pressed=false;cancel.canceled=true;Input.parse_input_event(cancel);await _settle()
	_check(activation_events.size()==count,"canceled touch never activates")
	await create_timer(0.2).timeout # let touch-generated mouse suppression expire
	await _mouse(point,true);strip.reveal_index(4999);await _mouse(point,false)
	_check(activation_events.size()==count,"rebind during pressed gesture cancels stale click")
	await _mouse(point,true);strip.size.x=500;await _settle();await _mouse(point,false)
	_check(activation_events.size()==count,"resize during press cancels stale click")
	strip.freeze();await _settle()
	for width in [360,1550,480,1180]:
		strip.size.x=width;await _settle()
		if not observations.has("resize_pools"):observations["resize_pools"]=[]
		observations["resize_pools"].append({"width":width,"cards":strip.pool.size()})
		_check(strip.pool.size()<=strip.capacity_bound() and strip.get_child_count()==strip.pool.size(),"resize has only bounded pool nodes")
		_check(strip.scroll_offset>=0 and strip.scroll_offset<=strip.max_scroll(),"resize clamps virtual extent")
		_check(root.gui_get_focus_owner()==strip,"focus stays on stable viewport rather than recycled card")
	strip.reveal_index(4999);await _settle();_check(is_equal_approx(strip.scroll_offset,strip.max_scroll()),"last reachable after resize")
	var last_card:Control=strip.card_for_index(4999);await _mouse(last_card.get_global_rect().get_center(),true);await _mouse(last_card.get_global_rect().get_center(),false)
	_check(activation_events[-1]==4999,"resized recycled card activates correct last binding")
	observations["synthetic_item_count"]=5000;observations["pool_nodes"]=strip.pool.size();observations["created_including_resizes"]=strip.created_cards;observations["provider_calls"]=calls[0];observations["bind_count"]=strip.bind_count;observations["stress_elapsed_ms"]=(Time.get_ticks_usec()-started)/1000.0
	strip.set_source(0,source);_check(strip.pool.is_empty() and strip.get_child_count()==0 and strip.scroll_offset==0,"empty source releases pool and resets range")
	root.remove_child(strip);strip.queue_free();game.show();game.menu.focus_strip();await _settle()

func _ids(strip:Control) -> Array:
	var ids:Array=[]
	for card in strip.pool:ids.append(card.get_instance_id())
	return ids
func _mouse(at:Vector2,down:bool) -> void:
	var event:=InputEventMouseButton.new();event.position=root.get_final_transform()*at;event.global_position=event.position;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;Input.parse_input_event(event);await _settle()
func _motion(at:Vector2) -> void:
	var event:=InputEventMouseMotion.new();event.position=root.get_final_transform()*at;event.global_position=event.position;event.button_mask=MOUSE_BUTTON_MASK_LEFT;Input.parse_input_event(event);await _settle()
func _wheel(at:Vector2) -> void:
	var event:=InputEventMouseButton.new();event.position=root.get_final_transform()*at;event.global_position=event.position;event.button_index=MOUSE_BUTTON_WHEEL_DOWN;event.pressed=true;Input.parse_input_event(event);await _settle()
func _touch(at:Vector2,down:bool) -> void:
	var event:=InputEventScreenTouch.new();event.index=0;event.position=root.get_final_transform()*at;event.pressed=down;Input.parse_input_event(event);await _settle()
func _touch_drag(at:Vector2) -> void:
	var event:=InputEventScreenDrag.new();event.index=0;event.position=root.get_final_transform()*at;Input.parse_input_event(event);await _settle()
