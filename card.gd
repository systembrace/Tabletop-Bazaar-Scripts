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

func _process(delta):
	if Engine.is_editor_hint():
		return
	$Label.text=str(z_index)
