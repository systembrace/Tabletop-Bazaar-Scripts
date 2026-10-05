@tool
extends TableObject
class_name Card

@export var size: Vector2 = Vector2(64*5,64*7.5)

func _ready():
	sprite.scale=size/sprite.texture.get_size()
	sprite.material=sprite.material.duplicate()
	shadow.texture=sprite.texture
	shadow.scale=sprite.scale
	shape.shape.size=size
	if Engine.is_editor_hint():
		return
	super._ready()

func pick_up():
	set_collision_layer_value(2,false)
	super.pick_up()

func put_down():
	set_collision_layer_value(2,true)
	super.put_down()

func _process(delta):
	if Engine.is_editor_hint():
		return
	super._process(delta)
	$Label.text=str(z_index)
