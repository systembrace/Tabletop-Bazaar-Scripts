extends CharacterBody2D
class_name TableObject

var table: Tabletop
var selected=false
var selected_by=1
var picked_up=false
var speed=0
var under: Dictionary[TableObject,int] = {}
var over: Dictionary[TableObject,int] = {}
@onready var sprite:Sprite2D=$CardSprite
@onready var shadow:Sprite2D=$Shadow
@onready var shape:CollisionShape2D=$CollisionShape2D
@onready var overlapper:Area2D=Area2D.new()

func _ready() -> void:
	mouse_entered.connect(mouse_over)
	mouse_exited.connect(mouse_off)
	overlapper.add_child(shape.duplicate())
	overlapper.set_collision_layer_value(1,false)
	overlapper.set_collision_layer_value(2,true)
	overlapper.set_collision_mask_value(1,false)
	overlapper.set_collision_mask_value(2,true)
	#overlapper.body_entered.connect(check_overlapper.unbind(1))
	#overlapper.body_exited.connect(check_overlapper.unbind(1))
	add_child(overlapper)

func highlight(do_highlight=true):
	var amt=0.0
	if do_highlight:
		amt=0.35
	sprite.material.set_shader_parameter("tint_amt",amt)

func mouse_over():
	if selected and Mouse.dragging[selected_by]:
		return
	Mouse.add_over(self)

func mouse_off():
	Mouse.remove_over(self)

func outline(do_outline=true):
	var width=0.0
	if do_outline:
		width=32.0
	sprite.material.set_shader_parameter("outline_width",width)

@rpc("any_peer", "call_local", "reliable")
func select(id):
	selected=true
	selected_by=id

@rpc("any_peer", "call_local", "reliable")
func deselect():
	selected=false
	selected_by=1
	outline(false)

@rpc("any_peer", "call_local", "reliable")
func pick_up():
	under={}
	picked_up=true
	set_collision_layer_value(1,false)
	sprite.offset.y=-64
	outline(false)
	table.pick_up(self)

@rpc("any_peer", "call_local", "reliable")
func put_down():
	picked_up=false
	set_collision_layer_value(1,true)
	force_update_transform()
	sprite.offset.y=0
	table.put_down(self)
	check_overlapper()
	velocity=Vector2.ZERO
	speed=0

func check_overlapper(sent_by=null):
	if sent_by==self:
		return
	under={}
	over={}
	for area in overlapper.get_overlapping_areas():
		set_under_over(area.get_parent())
	set_z()
	for body in over:
		if sent_by:
			body.check_overlapper(sent_by)
		else:
			body.check_overlapper(self)

func set_under_over(body):
	if body==self or picked_up:
		return
	if body.z_index<z_index:
		under[body]=body.z_index
	elif body.z_index>z_index:
		over[body]=body.z_index

func set_z():
	if picked_up:
		return
	z_index=0
	var used_layers=[]
	for body in under.keys():
		var z=under[body]+1
		if not z in used_layers:
			z_index+=z
			used_layers.append(z)

func _process(delta: float) -> void:
	if multiplayer.get_unique_id()==1 and selected_by!=1:
		print(Mouse.dragging[selected_by])
		print(Mouse.mouse_position[selected_by])
	if picked_up and Mouse.dragging[selected_by]:
		if self==Mouse.main_selected[selected_by]:
			velocity=to_local(Mouse.mouse_position[selected_by])/delta*speed
			speed=move_toward(speed,1.0,delta*1.5)
		else:
			velocity=Mouse.main_selected[selected_by].velocity

func _physics_process(_delta: float) -> void:
	move_and_slide()
