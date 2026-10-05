extends Node

var mouse_position: Dictionary[int,Vector2] = {}
var dragging: Dictionary[int,bool] = {}
var selected: Dictionary[int,Array] = {}
var main_selected: Dictionary[int,TableObject] = {}

var highlighted: TableObject
var over: Array = []
var selected_z_order: Array = []
@onready var pressed_timer: Timer = Timer.new()

func _ready() -> void:
	set_players()
	Input.use_accumulated_input=false
	pressed_timer.wait_time=0.15
	pressed_timer.one_shot=true
	add_child(pressed_timer)

func set_players():
	if pressed_timer.timeout.is_connected(rpc):
		pressed_timer.timeout.disconnect(rpc)
	for peer_id in dragging.keys():
		if not peer_id in multiplayer.get_peers():
			multiplayer.multiplayer_peer.disconnect_peer(peer_id) 
	for peer_id in multiplayer.get_peers():
		if not peer_id in dragging.keys():
			mouse_position[peer_id]=Vector2.ZERO
			dragging[peer_id]=false
			selected[peer_id]=[]
			main_selected[peer_id]=null
	var self_id=multiplayer.get_unique_id()
	mouse_position[self_id]=Vector2.ZERO
	dragging[self_id]=false
	selected[self_id]=[]
	main_selected[self_id]=null
	pressed_timer.timeout.connect(rpc.bind("start_drag",self_id))

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

@rpc("any_peer", "call_local", "reliable")
func clear_selected(id):
	for object in selected[id]:
		object.deselect()
	selected[id].clear()

func z_sort(o_a, o_b):
	return o_a.z_index<o_b.z_index

@rpc("any_peer", "call_local", "reliable")
func select(id, obj_path):
	var obj=Global.tabletop.get_node(obj_path)
	selected[id].append(obj)

@rpc("any_peer", "call_local", "reliable")
func set_main_selected(id, obj_path):
	var obj=Global.tabletop.get_node(obj_path)
	main_selected[id]=obj

@rpc("any_peer", "call_local", "reliable")
func start_drag(id):
	selected_z_order=selected[id].duplicate()
	selected_z_order.sort_custom(z_sort)
	for object in selected_z_order:
		object.rpc("pick_up")
	dragging[id]=true

@rpc("any_peer", "call_local", "reliable")
func stop_drag(id):
	dragging[id]=false
	if len(selected[id])==0:
		return
	rpc("clear_selected",id)
	for object in selected_z_order:
		object.rpc("put_down")

@rpc("any_peer", "call_local", "reliable")
func set_mouse_position(id,position):
	mouse_position[id]=position

func _input(event: InputEvent) -> void:
	if !Global.tabletop:
		return
	var self_id=multiplayer.get_unique_id()
	if event is InputEventMouseMotion:
		rpc("set_mouse_position",self_id,event.global_position)
	elif event.is_action("select"):
		if len(selected[self_id])>0 and len(over)==0 and !dragging[self_id]:
			rpc("clear_selected",self_id)
		if event.is_action_pressed("select"):
			pressed_timer.start()
			if highlighted:
				if not highlighted in selected[self_id]:
					rpc("select",self_id,highlighted.get_path())
				highlighted.rpc("select",self_id)
				rpc("set_main_selected",self_id,highlighted.get_path())
		elif event.is_action_released("select"):
			pressed_timer.stop()
			if dragging[self_id]:
				rpc("stop_drag",self_id)
			elif len(selected[self_id])>0 and highlighted:
				if !Input.is_action_pressed("ctrl"):
					rpc("clear_selected",self_id)
				highlighted.outline()
				if not highlighted in selected[self_id]:
					rpc("select",self_id,highlighted.get_path())
				highlighted.rpc("select",self_id)
