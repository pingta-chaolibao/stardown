extends Control
## Virtual extent is a number, never thousands of off-screen Controls.
## Focus belongs to this viewport; recycled cards never own keyboard focus.
signal activated(index: int)
signal context_changed
const Card = preload("res://scripts/view/level_card.gd")
const CARD_WIDTH := 260.0
const GAP := 22.0
const STRIDE := CARD_WIDTH + GAP
const PADDING := 12.0
const OVERSCAN := 2
var item_count := 0
var selected_index := 0
var scroll_offset := 0.0
var content_extent := 0.0
var provider: Callable
var pool: Array[Control] = []
var created_cards := 0
var bind_count := 0
var _hover := -1
var _pointer := -2 # -2 none, -1 mouse, >=0 touch identity
var _press_index := -1
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _dragged := false
var _velocity := 0.0
var _last_ms := 0
var _ignore_mouse_until := 0

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	resized.connect(_resize_pool)
	focus_entered.connect(_paint)
	focus_exited.connect(_paint)
	mouse_exited.connect(func(): _hover=-1; _paint())
	get_window().focus_exited.connect(freeze)
	_resize_pool()

func set_source(count: int, get_item: Callable) -> void:
	freeze()
	item_count = maxi(0,count)
	provider = get_item
	selected_index = clampi(selected_index,0,maxi(0,item_count-1))
	content_extent = maxf(0, PADDING*2 + item_count*STRIDE - GAP)
	for card in pool: card.bound_index = -1
	_resize_pool()

func capacity_bound() -> int:
	return mini(item_count, ceili(maxf(0,size.x)/STRIDE) + OVERSCAN*2 + 1)

func max_scroll() -> float:
	return maxf(0, content_extent - size.x)

func _resize_pool() -> void:
	freeze()
	var capacity := capacity_bound()
	while pool.size() > capacity:
		var card: Control = pool.pop_back()
		remove_child(card)
		card.queue_free()
	while pool.size() < capacity:
		var card := Card.new()
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.focus_mode = Control.FOCUS_NONE
		add_child(card)
		pool.append(card)
		created_cards += 1
	for card in pool:
		card.bound_index = -1
		card.name = "Pooled%d" % card.get_instance_id()
	scroll_offset = clampf(scroll_offset,0,max_scroll())
	_rebind()

func _rebind() -> void:
	if pool.is_empty(): context_changed.emit(); queue_redraw(); return
	var first := maxi(0, floori((scroll_offset-PADDING)/STRIDE)-OVERSCAN)
	var last := mini(item_count-1, floori((scroll_offset+size.x-PADDING)/STRIDE)+OVERSCAN)
	var used: Dictionary = {}
	for index in range(first,last+1):
		var card = pool[index % pool.size()]
		used[card.get_instance_id()] = true
		if card.bound_index != index:
			card.bind(index, provider.call(index))
			bind_count += 1
		card.position = Vector2(PADDING + index*STRIDE-scroll_offset,12)
		card.size = Vector2(CARD_WIDTH, maxf(330,size.y-36))
	for card in pool: card.visible = used.has(card.get_instance_id())
	_paint()
	context_changed.emit()

func _paint() -> void:
	for card in pool:
		card.selected = card.bound_index == selected_index
		card.hovered = card.bound_index == _hover
		card.pressed = card.bound_index == _press_index and _pointer != -2 and not _dragged
		card.keyboard_focus = has_focus()
		card.queue_redraw()
	queue_redraw()

func _set_offset(value: float) -> void:
	scroll_offset = clampf(value,0,max_scroll())
	_rebind()

func _browse_offset(value: float) -> void:
	var offset := clampf(value,0,max_scroll())
	selected_index = clampi(roundi((offset+size.x*0.5-PADDING-CARD_WIDTH*0.5)/STRIDE),0,maxi(0,item_count-1))
	_set_offset(offset)

func reveal_index(index: int) -> void:
	freeze()
	selected_index = clampi(index,0,maxi(0,item_count-1))
	var left := PADDING+selected_index*STRIDE
	if left < scroll_offset: scroll_offset = left-PADDING
	elif left+CARD_WIDTH > scroll_offset+size.x: scroll_offset = left+CARD_WIDTH+PADDING-size.x
	_set_offset(scroll_offset)

func card_for_index(index: int) -> Control:
	for card in pool:
		if card.visible and card.bound_index == index: return card
	return null

func freeze() -> void:
	_pointer = -2
	_press_index = -1
	_dragged = false
	_velocity = 0
	_paint()

func _hit(point: Vector2) -> int:
	if not Rect2(Vector2.ZERO,size).has_point(point) or point.y < 12 or point.y > size.y-24: return -1
	var local_x := point.x+scroll_offset-PADDING
	var index := floori(local_x/STRIDE)
	return index if index>=0 and index<item_count and fposmod(local_x,STRIDE)<CARD_WIDTH else -1

func _begin(point: Vector2, pointer: int) -> void:
	freeze()
	grab_focus()
	_pointer = pointer
	_start = point
	_last = point
	_last_ms = Time.get_ticks_msec()
	_press_index = _hit(point)
	_paint()

func _motion(point: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if point.distance_to(_start)>10: _dragged = true
	if _dragged:
		var distance := _last.x-point.x
		_velocity = clampf(distance / maxf(0.008,(now-_last_ms)/1000.0),-2400,2400)
		_browse_offset(scroll_offset+distance)
	_last = point
	_last_ms = now
	_paint()

func _end(point: Vector2, canceled: bool = false) -> void:
	var index := _hit(point)
	var activate := not canceled and not _dragged and index == _press_index and index>=0
	_pointer = -2
	_press_index = -1
	if activate:
		selected_index = index
		_velocity = 0
		_paint()
		context_changed.emit()
		activated.emit(index)
	elif canceled: freeze()
	else: _paint()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	var inverse := get_global_transform_with_canvas().affine_inverse()
	# Claim genuine touch before GUI mouse emulation can turn a cancellation
	# into an ordinary mouse-up click. A second finger cannot steal this gesture.
	if event is InputEventScreenTouch and event.pressed:
		var point: Vector2 = inverse*event.position
		if _pointer < 0 and Rect2(Vector2.ZERO,size).has_point(point):
			_ignore_mouse_until = Time.get_ticks_msec()+180
			_begin(point,event.index)
			get_viewport().set_input_as_handled()
		return
	if _pointer == -2: return
	if _pointer == -1 and event is InputEventMouseMotion:
		_motion(inverse*event.position);get_viewport().set_input_as_handled()
	elif _pointer == -1 and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		_end(inverse*event.position);get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index==_pointer:
		_motion(inverse*event.position);get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.index==_pointer and not event.pressed:
		_ignore_mouse_until = Time.get_ticks_msec()+180
		_end(inverse*event.position,event.canceled);get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if Time.get_ticks_msec() < _ignore_mouse_until: accept_event(); return
		if event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
			_begin(event.position,-1);accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_WHEEL_LEFT,MOUSE_BUTTON_WHEEL_RIGHT]:
			freeze()
			_browse_offset(scroll_offset+(1 if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN,MOUSE_BUTTON_WHEEL_RIGHT] else -1)*STRIDE*0.75*event.factor)
			accept_event()
	elif event is InputEventMouseMotion:
		_hover = _hit(event.position);_paint()
	elif event is InputEventScreenTouch and event.pressed and _pointer == -2:
		_ignore_mouse_until = Time.get_ticks_msec()+180
		_begin(event.position,event.index);accept_event()
	elif event is InputEventPanGesture:
		freeze();_browse_offset(scroll_offset+(event.delta.x if absf(event.delta.x)>absf(event.delta.y) else event.delta.y)*32);accept_event()
	elif event is InputEventKey and event.pressed:
		var index := selected_index
		match event.keycode:
			KEY_LEFT: index -= 1
			KEY_RIGHT: index += 1
			KEY_HOME: index = 0
			KEY_END: index = item_count-1
			KEY_PAGEUP: index -= maxi(1,floori(size.x/STRIDE))
			KEY_PAGEDOWN: index += maxi(1,floori(size.x/STRIDE))
			KEY_ENTER,KEY_KP_ENTER,KEY_SPACE:
				if not event.echo and item_count>0: activated.emit(selected_index)
				accept_event();return
			_: return
		reveal_index(index);accept_event()

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _pointer != -2 or absf(_velocity)<5: return
	_browse_offset(scroll_offset+_velocity*minf(delta,0.05))
	_velocity = move_toward(_velocity,0,3400*delta)
	if scroll_offset<=0 or scroll_offset>=max_scroll(): _velocity=0

func _draw() -> void:
	var width := maxf(1,size.x-24)
	draw_line(Vector2(12,size.y-7),Vector2(size.x-12,size.y-7),Color("28414d"),2,true)
	var thumb := maxf(38,width*minf(1,size.x/maxf(1,content_extent)))
	var x := 12 + (width-thumb)*(scroll_offset/maxf(1,max_scroll()))
	draw_line(Vector2(x,size.y-7),Vector2(x+thumb,size.y-7),Color("dfbb78"),3,true)
