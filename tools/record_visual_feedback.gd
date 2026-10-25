extends SceneTree
## Unified, approved visual demonstration: nine explicit sandboxes, not a campaign video.
## Each segment starts from declared data; all subsequent changes are real input.
const Cases = preload("res://tests/feedback_cases.gd")
const Level = preload("res://scripts/core/level_data.gd")
const State = preload("res://scripts/core/grid_state.gd")
const Keys = {"U":KEY_W,"D":KEY_S,"L":KEY_A,"R":KEY_D,"C":KEY_C,"Z":KEY_Z}
const Dirs = {"U":Vector2i.UP,"D":Vector2i.DOWN,"L":Vector2i.LEFT,"R":Vector2i.RIGHT}
var game: Control
var frames := 0
var report_path := ""
var verify_only := false
var segments: Array[Dictionary] = []
var failures := 0

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): report_path = arg.trim_prefix("--report=")
		if arg == "--verify-only": verify_only = true
	call_deferred("_verify" if verify_only else "_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless" or Engine.get_write_movie_path().is_empty() or report_path.is_empty():
		_fail("Preview requires real Movie Maker and report path"); return
	root.size = Vector2i(1280,820)
	game = load("res://scenes/main.tscn").instantiate(); game.start_in_level = true; root.add_child(game)
	await _frames(2)
	var badge := Label.new(); badge.text = "视觉反馈演示 · 效果已确认"; badge.position = Vector2(515,42); badge.add_theme_font_size_override("font_size",20); badge.add_theme_color_override("font_color",Color("e4c78c")); badge.mouse_filter = Control.MOUSE_FILTER_IGNORE; game.add_child(badge)
	for case in Cases.cases():
		if not game.model.alive:
			_fail("Previous sandbox must end alive before switching"); return
		game.board.cancel_feedback()
		if not game.model.load_level(Level.from_dictionary(case["data"])):
			_fail("Sandbox load failed: "+case["id"]); return
		game._rebuild_ui(); game.menu.hide(); game.ui_root.show()
		# These labels identify review fixtures, not a new official level.
		_relabel(game.ui_root)
		game._refresh(case["caption"])
		var segment: Dictionary = {"id":case["id"],"caption":case["caption"],"data":case["data"],"start_frame":frames,"initial":_state(game.model),"events":[],"review_frames":[]}
		await _frames(75 if case["id"] == "chain" else 30)
		segment["initial_review_frame"] = frames-10
		for symbol in case["path"]:
			var before := _state(game.model)
			var at := frames
			_send_key(Keys[symbol],true); await _frames(1)
			_send_key(Keys[symbol],false); await _frames(1)
			var state := _state(game.model)
			if symbol == "C":
				_check(state["world"] == before["world"] and state["selected"] != before["selected"],"free selection only")
			elif symbol == "Z": _check(state["world"]["moves"] == before["world"]["moves"]-1,"legal Undo")
			elif case["id"] == "victory" and symbol == "U": _check(state["world"] == before["world"],"blocked move is not an attack round")
			else: _check(state["world"]["moves"] == before["world"]["moves"]+1,"one legal direction action")
			segment["events"].append({"input":symbol,"frame":at,"state":state})
			var review_offset: int = {"chain":3,"pull":3,"swap":3,"energy":4,"fire":8,"goblin":8,"mutual":10,"destruction":9,"victory":8}[case["id"]]
			segment["review_frames"].append({"input":symbol,"frame":at+review_offset})
			await _frames(28)
			_check(not game.board.feedback.is_busy(),"short action animation has settled before next input")
		await _frames(18)
		segment["final"] = _state(game.model); segment["end_frame"] = frames; segments.append(segment)
	await _frames(30)
	var report := {"purpose":"Approved visual feedback demonstration;not an official level walkthrough",
		"preview_base_commit":"5d3fed265eeea9b9d3d676a70738cb51e2123d32","unpublished_preview":false,"game_implementation_commit":OS.get_environment("STARDOWN_RECORDING_COMMIT"),
		"capture":"Actual Godot Movie Maker viewport;temporary fixture initialization between segments;all subsequent world changes via normal WASD/C/Z press-release",
		"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"fps":30,"frames":frames,"duration_seconds":float(frames)/30.0,"segments":segments,"failures":failures}
	DirAccess.make_dir_recursive_absolute(report_path.get_base_dir()); FileAccess.open(report_path,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
	print("VISUAL PREVIEW RESULT: %d frames,9 sandboxes,%d failures;approved effects" % [frames,failures])
	quit(0 if failures == 0 else 1)

func _verify() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(report_path))
	var inputs := 0
	_check(report["segments"].size() == 9,"one complete nine-sandbox demonstration")
	for segment in report["segments"]:
		var state := State.new()
		_check(state.load_level(Level.from_dictionary(segment["data"])),"sandbox initialization valid")
		_check(_normalized(_state(state)) == _normalized(segment["initial"]),"initial exact state")
		for event in segment["events"]:
			var symbol: String = event["input"]
			if symbol == "C": state.switch_hero()
			elif symbol == "Z": _check(state.undo(),"Undo has real history")
			else: state.try_move(Dirs[symbol])
			_check(_normalized(_state(state)) == _normalized(event["state"]),"independent legal input state: "+segment["id"]+symbol)
			inputs += 1
		_check(_normalized(_state(state)) == _normalized(segment["final"]),"final state exact")
	print("VISUAL PREVIEW REPLAY RESULT: %d inputs,9 sandboxes,%d failures" % [inputs,failures])
	quit(0 if failures == 0 else 1)

func _state(state: RefCounted) -> Dictionary:
	return {"world":_serial(state.snapshot()),"selected":state.active_hero_id(),"complete":state.is_complete(),"history":state.history_size()}

func _serial(value: Variant) -> Variant:
	if value is Vector2i or value is Vector2: return [value.x,value.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[str(key)] = _serial(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(_serial(item))
		return result
	return value

func _normalized(value: Variant) -> Variant:
	if value is float and value == floor(value): return int(value)
	if value is Array:
		var result: Array = []
		for item in value: result.append(_normalized(item))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = _normalized(value[key])
		return result
	return value

func _relabel(node: Node) -> void:
	if node is Label and node.text.begins_with("北部英雄  / "): node.text = "统一效果演示 / 非正式关卡"
	for child in node.get_children(): _relabel(child)

func _send_key(code: int, down: bool) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = down; Input.parse_input_event(event)

func _frames(count: int) -> void:
	for _i in count: await process_frame; frames += 1

func _check(ok: bool, message: String) -> void:
	if not ok: failures += 1; printerr("FAIL: "+message)

func _fail(message: String) -> void:
	printerr("FAIL: "+message); quit(1)
