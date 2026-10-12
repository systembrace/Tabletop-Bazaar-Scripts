extends Node2D
class_name Game

var cursor_scene=load("res://Scenes/cursor.tscn")
@onready var hud_layer=$HUDLayer
@onready var spawner=$MultiplayerSpawner

func _ready() -> void:
	spawner.spawn_function=add_cursor
	call_deferred("rpc", "call_spawner", Online.self_id)

@rpc("any_peer", "call_local", "reliable")
func call_spawner(id):
	if multiplayer.is_server():
		spawner.spawn(id)

func add_cursor(id):
	var new_cursor=cursor_scene.instantiate()
	new_cursor.id=id
	new_cursor.set_multiplayer_authority(id)
	new_cursor.name="Cursor_"+str(id)
	return new_cursor
