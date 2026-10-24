extends "res://tools/record_playthrough.gd"
## Presentation-only, non-winning comparison; every world change is a legal input.
const DEMO_KEYS={"U":KEY_W,"D":KEY_S,"L":KEY_A,"R":KEY_D,"C":KEY_C,"Z":KEY_Z}
const DEMO_DIRS={"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
const DEMO_PHASES=[
	{"hero":"blue","path":"URRRRDLULLRULD","pause":24,"caption":"能量消失：虚线边框和浅地纹保留原格，可通行。"},
	{"hero":"green","path":"UU","pause":24,"caption":"当前英雄站上能量格，边缘标记仍可辨认。"},
	{"hero":"blue","path":"","pause":24,"caption":"非当前英雄占格：保留本色，能量格边框仍清楚。"},
	{"hero":"green","path":"D","pause":0,"caption":""},
	{"hero":"red","path":"U","pause":0,"caption":""},
	{"hero":"green","path":"UUDD","pause":36,"caption":"两枚水晶占住消失的能量格，虚线保留原位置。"},
	{"hero":"blue","path":"U","pause":30,"caption":"实体恢复：维持原实心能量块，按原规则摧毁格内水晶。"},
	{"hero":"blue","path":"Z","pause":30,"caption":"撤销整步：水晶与消失标记一起恢复。"},
	{"hero":"blue","path":"U","pause":45,"caption":"显示优化对比结束；玩法、视线和撤销规则未改变。"}
]
var demo_frames:=0
var demo_trace:Array[Dictionary]=[]
var demo_path:=""
var verify_path:=""
func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="):report_path=arg.trim_prefix("--report=")
		if arg.begins_with("--verify-report="):verify_path=arg.trim_prefix("--verify-report=")
	call_deferred("_verify_demo" if not verify_path.is_empty() else "_run")
func _run() -> void:
	if DisplayServer.get_name()=="headless" or Engine.get_write_movie_path().is_empty() or report_path.is_empty():_fail("Demo requires Movie Maker, X11 and report path");return
	root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();game.start_in_level=true;game.level_path="res://levels/north_17.json";root.add_child(game)
	await _frames(45);var initial:=_state();var phases:Array[Dictionary]=[]
	for phase in DEMO_PHASES:
		while game.model.active_hero_id()!=phase["hero"]:await _demo_input("C")
		for symbol in phase["path"]:await _demo_input(symbol)
		if phase["pause"]>0:
			var before:Dictionary=game.model.snapshot()
			game._refresh(phase["caption"])
			if game.model.snapshot()!=before:_fail("Caption changed world state");return
			phases.append({"caption":phase["caption"],"review_frame":demo_frames+10,"event_index":demo_trace.size(),"state":_state()})
			await _frames(phase["pause"])
	var final:=_state()
	if final["completed"] or final["moves"]!=23 or final["crystals"].size()!=2 or not final["alive"]:_fail("Non-winning comparison final state differs");return
	var report={"purpose":"energy visibility comparison, not a completed level","game_implementation_commit":OS.get_environment("STARDOWN_RECORDING_COMMIT"),"display":DisplayServer.get_name(),"fps":30,"frames":demo_frames,"frames_per_input":12,"initial_pause_frames":45,"path":demo_path,"input_events":demo_trace.size(),"selection_events":selection_events,"initial_state":initial,"trace":demo_trace,"final_state":final,"phases":phases,"capture":"Actual Godot Movie Maker viewport with normal WASD/C/Z press-release; captions change UI only"}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir());var file:=FileAccess.open(report_path,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  ")+"\n")
	print("ENERGY VISIBILITY RECORD RESULT: %d frames,%d input events,23 net actions,actual comparison complete" % [demo_frames,demo_trace.size()]);quit(0)
func _demo_input(symbol:String) -> void:
	var before:Dictionary=game.model.snapshot();var count:int=game.model.moves
	_send_key(DEMO_KEYS[symbol],true);await _frames(1);_send_key(DEMO_KEYS[symbol],false);await _frames(1)
	if symbol=="C":
		selection_events+=1
		if game.model.snapshot()!=before:_fail("Free C changed world");return
	elif symbol=="Z":
		if game.model.moves!=count-1:_fail("Undo failed");return
	elif game.model.moves!=count+1 or not game.model.alive:_fail("Illegal demo direction");return
	demo_path+=symbol;var state:=_state();state["input"]=symbol;state["event_index"]=demo_trace.size()+1;demo_trace.append(state)
	await _frames(10)
func _frames(count:int) -> void:
	for _i in count:await process_frame;demo_frames+=1
func _verify_demo() -> void:
	var r:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(verify_path));game=load("res://scenes/main.tscn").instantiate();game.start_in_level=true;game.level_path="res://levels/north_17.json";root.add_child(game);await _frames(2)
	var checks:=0
	if _normalized(_state())!=_normalized(r["initial_state"]):_fail("Demo initial world differs");return
	for expected in r["trace"]:
		var symbol:String=expected["input"]
		if symbol=="C":game.model.switch_hero();selection_events+=1
		elif symbol=="Z":
			if not game.model.undo():_fail("Replay undo failed");return
		else:
			var result:StringName=game.model.try_move(DEMO_DIRS[symbol])
			if result not in [&"moved",&"pushed",&"pulled",&"swapped"]:_fail("Replay direction illegal");return
		var state:Dictionary=expected.duplicate(true);state.erase("input");state.erase("event_index")
		if _normalized(_state())!=_normalized(state):_fail("Demo replay state differs");return
		checks+=1
	if _normalized(_state())!=_normalized(r["final_state"]) or r["frames"]!=666 or r["input_events"]!=34:_fail("Demo final state/timing differs");return
	print("ENERGY VISIBILITY REPLAY RESULT: %d legal events,34 state comparisons,666frames expected" % checks);quit(0)

# Godot JSON parses integral grid coordinates as floats; normalize comparison
# values only, never any actual model or recorded world state.
func _normalized(value:Variant) -> Variant:
	if value is float and value==floor(value):return int(value)
	if value is Array:
		var result:Array=[]
		for entry in value:result.append(_normalized(entry))
		return result
	if value is Dictionary:
		var result:Dictionary={}
		for key in value:result[key]=_normalized(value[key])
		return result
	return value
