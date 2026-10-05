extends Node

var highlighted: TableObject
var over: Array[TableObject] = []
var selected: Array[TableObject] = []
var selected_z_order: Array[TableObject] = []
var main_selected: TableObject
var dragging=false
@onready var pressed_timer: Timer = Timer.new()

func _ready() -> void:
	Input.use_accumulated_input=false
	pressed_timer.wait_time=0.15
	pressed_timer.one_shot=true
	pressed_timer.timeout.connect(start_drag)
	add_child(pressed_timer)

func add_over(object):
	if highlighted:
		if highlighted.z_index>object.z_index:
			over.insert(1,object)
			return
		highlighted.highlight(false)
	over.insert(0,object)
	highlighted=object
	object.highlight()

func remove_over(object):
	over.erase(object)
	if highlighted==object:
		object.highlight(false)
		highlighted=null
	if len(over)>0:
		highlighted=over[0]
		highlighted.highlight()

func clear_selected():
	for object in selected:
		object.deselect()
	selected.clear()

func z_sort(o_a, o_b):
	return o_a.z_index<o_b.z_index

func start_drag():
	selected_z_order=selected.duplicate()
	selected_z_order.sort_custom(z_sort)
	for object in selected_z_order:
		object.rpc("pick_up")
	dragging=true

func stop_drag():
	dragging=false
	if len(selected)==0:
		return
	clear_selected()
	for object in selected_z_order:
		object.rpc("put_down")

func _input(event: InputEvent) -> void:
	if event.is_action("select"):
		if len(selected)>0 and len(over)==0 and !dragging:
			clear_selected()
		if event.is_action_pressed("select"):
			pressed_timer.start()
			if highlighted:
				if not highlighted in selected:
					selected.append(highlighted)
				highlighted.select()
				main_selected=highlighted
		elif event.is_action_released("select"):
			pressed_timer.stop()
			if dragging:
				stop_drag()
			elif len(selected)>0 and highlighted:
				if !Input.is_action_pressed("ctrl"):
					clear_selected()
				highlighted.outline()
				if not highlighted in selected:
					selected.append(highlighted)
