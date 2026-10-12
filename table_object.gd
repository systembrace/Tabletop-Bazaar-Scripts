extends CharacterBody2D
class_name TableObject

var table: Tabletop
var selected=false
var selected_by: Cursor
var picked_up=false
var speed=0
var under: Dictionary[TableObject,int] = {}
var over: Dictionary[TableObject,int] = {}
@onready var sprite:Sprite2D=$CardSprite
@onready var shadow:Sprite2D=$Shadow
@onready var shape:CollisionShape2D=$CollisionShape2D
@onready var overlapper:Area2D=Area2D.new()

func _ready() -> void:
	overlapper.add_child(shape.duplicate())
	overlapper.set_collision_layer_value(1,false)
	overlapper.set_collision_layer_value(2,true)
	overlapper.set_collision_mask_value(1,false)
	overlapper.set_collision_mask_value(2,true)
	overlapper.body_entered.connect(body_entered)
	overlapper.body_exited.connect(body_exited)
	add_child(overlapper)

func highlight(do_highlight=true):
	var amt=0.0
	if do_highlight:
		amt=0.35
	sprite.material.set_shader_parameter("tint_amt",amt)

func outline(do_outline=true):
	var width=0.0
	if do_outline:
		width=32.0
	sprite.material.set_shader_parameter("outline_width",width)

@rpc("any_peer", "call_local", "reliable")
func select(cursor_path):
	selected=true
	selected_by=get_tree().get_root().get_node(cursor_path)

@rpc("any_peer", "call_local", "reliable")
func deselect():
	selected=false
	selected_by=null
	outline(false)

@rpc("any_peer", "call_local", "reliable")
func pick_up():
	if picked_up:
		return
	under={}
	picked_up=true
	set_collision_layer_value(2,false)
	sprite.offset.y=-64
	outline(false)
	table.pick_up(self)

@rpc("any_peer", "call_local", "reliable")
func put_down():
	if !picked_up:
		return
	picked_up=false
	set_collision_layer_value(2,true)
	force_update_transform()
	sprite.offset.y=0
	table.put_down(self)
	check_overlapper()
	velocity=Vector2.ZERO
	speed=0

func body_entered(body):
	if !body==self:
		check_overlapper()

func body_exited(body):
	if !body==self:
		check_overlapper()

func check_overlapper(sent_by=null):
	if sent_by==self:
		return
	under={}
	over={}
	for area in overlapper.get_overlapping_areas():
		set_under_over(area.get_parent())
	set_z()
	for body in over.keys():
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
	z_index=-1
	var highest_z=-1
	for body in under.keys():
		var z=under[body]
		if z>highest_z:
			highest_z=z
	z_index=highest_z+1

func _physics_process(delta: float) -> void:
	if !picked_up or !selected_by:
		return
	if self==selected_by.main_selected:
		velocity=to_local(selected_by.global_position)/delta*speed
		speed=move_toward(speed,1.0,delta*1.5)
	else:
		velocity=selected_by.main_selected.velocity
	move_and_slide()
