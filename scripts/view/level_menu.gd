extends Control
signal level_requested(index: int)
const Strip = preload("res://scripts/view/virtual_level_strip.gd")
const FONT = preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")
var strip: Control
var entries: Array[Dictionary] = []
var context_label: Label
var previous: Button
var next: Button

func configure(paths: Array) -> void:
	for path in paths:
		var map: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var kinds: Array = []
		for hero in map.get("heroes",[{"kind":map.get("hero_kind","red")}]):
			if hero["kind"] not in kinds: kinds.append(hero["kind"])
		var title: String = "三英雄协作" if kinds.size()==3 else ("双英雄协作" if kinds.size()==2 else {"red":"推之英雄","green":"拉之英雄","blue":"交换之英雄","yellow":"保护之英雄"}[kinds[0]])
		var detail:String="%d × %d   ·   %d 枚水晶" % [map["terrain"][0].length(),map["terrain"].size(),map["crates"].size()]
		if not map.get("monsters",[]).is_empty():
			var known:bool=map["monsters"].all(func(m:Dictionary)->bool:return m.get("kind")=="goblin")
			detail="%d × %d   ·   %d 只%s" % [map["terrain"][0].length(),map["terrain"].size(),map["monsters"].size(),"哥布林" if known else ("火龙 / 哥布林" if map["monsters"].any(func(m:Dictionary)->bool:return m.get("kind")=="fire_dragon") else "未支持的怪物")]
		entries.append({"title":title,"kinds":kinds,"map":map,"detail":detail})

func _ready() -> void:
	name="LevelMenu"
	var t:=Theme.new();t.default_font=FONT;t.default_font_size=16;theme=t
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin:=MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,44)
	var layout:=VBoxContainer.new();layout.add_theme_constant_override("separation",20);margin.add_child(layout)
	var top:=HBoxContainer.new();layout.add_child(top)
	top.add_child(_label("✦  沉星之序",36,Color("e3e9e6")))
	var spacer:=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(spacer)
	top.add_child(_label("STARDOWN  /  LEVEL SELECT",12,Color("8ebbb9")))
	var head:=VBoxContainer.new();head.add_theme_constant_override("separation",8);layout.add_child(head)
	head.add_child(_label("CHAPTER 01     /     NORTHERN REALM",13,Color("dfbb78")))
	head.add_child(_label("第一章 · 北部英雄",40,Color("e3e9e6")))
	head.add_child(_label("推、拉与换位。选择一关，开启你的下一步。",16,Color("93aeb9")))
	var space:=Control.new();space.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(space)
	strip=Strip.new();strip.name="LevelStrip";strip.custom_minimum_size.y=370
	layout.add_child(strip);strip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	strip.set_source(entries.size(),func(index:int)->Dictionary:return entries[index])
	strip.activated.connect(func(index:int):level_requested.emit(index))
	strip.context_changed.connect(_context)
	var bottom:=HBoxContainer.new();layout.add_child(bottom)
	context_label=_label("",15,Color("dfbb78"));bottom.add_child(context_label)
	var gap:=Control.new();gap.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bottom.add_child(gap)
	previous=_arrow("←","BrowsePrevious");bottom.add_child(previous)
	next=_arrow("→","BrowseNext");bottom.add_child(next)
	previous.pressed.connect(func():strip.reveal_index(strip.selected_index-1);strip.grab_focus())
	next.pressed.connect(func():strip.reveal_index(strip.selected_index+1);strip.grab_focus())
	layout.add_child(_label("左右轻扫 / 鼠标拖动 / 滚轮浏览     ·     ← → 选择，Enter 进入",13,Color("7e9ba8")))
	var tail:=Control.new();tail.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(tail)
	_context()
	call_deferred("focus_strip")

func focus_strip() -> void:
	if is_visible_in_tree(): strip.grab_focus()

func _context() -> void:
	if context_label==null:return
	context_label.text="当前选择  %02d  /  %02d     ·     自由选关" % [strip.selected_index+1,entries.size()]
	previous.disabled=strip.selected_index<=0
	next.disabled=strip.selected_index>=entries.size()-1

func _label(text:String,pixels:int,tint:Color)->Label:
	var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",pixels);node.add_theme_color_override("font_color",tint);return node

func _arrow(text:String,id:String)->Button:
	var button:=Button.new();button.text=text;button.name=id;button.custom_minimum_size=Vector2(56,44)
	for state in ["normal","hover","pressed","focus","disabled"]:
		var s:=StyleBoxFlat.new();s.bg_color=Color("142c37") if state!="pressed" else Color("294551");s.border_color=Color("dfbb78") if state in ["hover","focus"] else Color("35515d");s.set_border_width_all(1);s.set_corner_radius_all(12);button.add_theme_stylebox_override(state,s)
	return button

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("0a1721"))
	for i in 42:
		draw_circle(Vector2(fmod(i*173.3+47,size.x),fmod(i*97.7+41,size.y)),1.2,Color(0.5,0.72,0.74,0.12))
	draw_arc(Vector2(size.x-150,-70),340,0,TAU,128,Color(0.4,0.65,0.68,0.08),1.5,true)
