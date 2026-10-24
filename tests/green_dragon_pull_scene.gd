extends "res://tests/north_02_scene.gd"
func _run() -> void:
 var data:Dictionary={"schema_version":1,"id":"green_dragon_input_fixture","title":"机制夹具 · 绿拉火龙","is_temporary":true,"source_note":"独立输入验证，不是第27关，不用于通关演示","terrain":[".........",".........",".........",".........",".........",".........",".........",".........","........."],"player":[4,4],"hero_kind":"green","crates":[],"targets":[],"objective":"none","monsters":[{"kind":"fire_dragon","position":[3,4],"facing":"up"}]}
 DirAccess.make_dir_recursive_absolute("res://artifacts/task27");var f:=FileAccess.open("res://artifacts/task27/green_dragon_input_fixture.json",FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
 root.size=Vector2i(1280,820);game=load("res://scenes/main.tscn").instantiate();game.start_in_level=true;game.level_path="res://artifacts/task27/green_dragon_input_fixture.json";root.add_child(game);await _settle();var initial:Dictionary=game.model.snapshot()
 await _press(KEY_D)
 _check(game.model.player==Vector2i(5,4) and game.model.monsters()[0]["position"]==Vector2i(4,4) and game.model.monsters()[0]["facing"]==Vector2i.UP and game.model.pulls==1,"actualDkeyboard pulls one dragon and preserves facing")
 _check(game.pulls_label.text=="01" and game.status_label.text.contains("火龙") and game.status_label.text.contains("朝向不变"),"UI reports dragon pull accurately,not a crystal")
 await _click("Undo");_check(game.model.snapshot()==initial,"screenUndo restores entire dragon pull")
 await _click("MoveRight");_check(game.model.monsters()[0]["position"]==Vector2i(4,4) and game.model.pulls==1,"screenDpad identical pull")
 await _capture("green_dragon_input_fixture_pulled.png");await _click("Restart");_check(game.model.snapshot()==initial,"screenrestart restores facing/position/counters")
 await _press(KEY_W);_check(game.model.pulls==0 and game.model.monsters()[0]["position"]==Vector2i(3,4),"actual perpendicular input does not pull side dragon")
 await _click("Restart");root.size=Vector2i(960,615);await _settle();_check_layout(game);await _click("MoveRight")
 _check(game.model.pulls==1 and game.model.monsters()[0]["facing"]==Vector2i.UP,"compactscreen buttons still pull,unrotated arrow")
 print("GREEN DRAGON INPUT SCENE RESULT: %d checks,%d failures;independentfixture,notcampaignvictory;display=%s" % [checks,failures,DisplayServer.get_name()]);quit(0 if failures==0 else 1)
