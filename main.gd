extends Node2D
class_name Main

var game_scene_path="res://Scenes/sandbox.tscn"
@onready var game_spawner: MultiplayerSpawner = $MultiplayerSpawner

func _ready():
	game_spawner.spawn_function=spawn_game

func quit_game():
	get_tree().quit()

@rpc("any_peer", "call_local", "reliable")
func start_game():
	if multiplayer.is_server():
		game_spawner.spawn()

func spawn_game(_data=null):
	Online.players[Online.self_id]=Online.player_info
	$Menu.hide() 
	$Menu.pause_cursor()
	var game_scene=load(game_scene_path).instantiate()
	return game_scene
