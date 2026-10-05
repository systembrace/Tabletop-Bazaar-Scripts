extends Node2D
class_name Tabletop

var objects: Array[TableObject] = []
@export var highest_z=0
@export var picked_up_objects=[]

func _ready() -> void:
	Global.tabletop=self
	for child in get_children():
		if child is TableObject:
			objects.append(child)
			child.table=self

func set_highest_z():
	highest_z=0
	for object in objects:
		if object.z_index>highest_z:
			highest_z=object.z_index
	highest_z+=2

func pick_up(object:TableObject):
	set_highest_z()
	picked_up_objects.append(object)
	object.z_index=highest_z

func put_down(object:TableObject):
	picked_up_objects.erase(object)
