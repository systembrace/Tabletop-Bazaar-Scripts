extends Area2D
class_name Cursor

@export var dragging = false
var selected: Array[TableObject] = []
var main_selected: TableObject
var id=1
var highlighted: TableObject
var selected_z_order: Array = []
@onready var pressed_timer: Timer = Timer.new()

func _ready() -> void:
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		return
	
	body_entered.connect(check_bodies.unbind(1))
	body_exited.connect(check_bodies.unbind(1))
	Input.use_accumulated_input=false
	pressed_timer.wait_time=0.15
	pressed_timer.one_shot=true
	pressed_timer.timeout.connect(start_drag)
	add_child(pressed_timer)

func check_bodies():
	if !has_overlapping_bodies():
		if highlighted:
			highlighted.highlight(false)
			highlighted=null
		return
	var highest=null
	for object in get_overlapping_bodies():
		if !highest or object.z_index>highest.z_index:
			highest=object
	if highlighted:
		highlighted.highlight(false)
	highlighted=highest
	highlighted.highlight()

func clear_selected():
	for object in selected:
		object.deselect()
	selected.clear()

func z_sort(o_a, o_b):
	return o_a.z_index<o_b.z_index

func select(obj):
	selected.append(obj)

@rpc("any_peer", "call_local", "reliable")
func set_main_selected(obj_path):
	var obj=get_tree().get_root().get_node(obj_path)
	main_selected=obj

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
	if event is InputEventMouseMotion:
		global_position=event.global_position
		return
	if !Global.tabletop:
		return
	if event.is_action("select"):
		if len(selected)>0 and !highlighted and !dragging:
			clear_selected()
		if event.is_action_pressed("select"):
			pressed_timer.start()
			if highlighted:
				if not highlighted in selected:
					select(highlighted)
				highlighted.rpc("select", get_path())
				rpc("set_main_selected", highlighted.get_path())
		elif event.is_action_released("select"):
			pressed_timer.stop()
			if dragging:
				stop_drag()
			elif len(selected)>0 and highlighted:
				if !Input.is_action_pressed("ctrl"):
					clear_selected()
				highlighted.outline()
				if not highlighted in selected:
					select(highlighted)
				highlighted.rpc("select", get_path())
