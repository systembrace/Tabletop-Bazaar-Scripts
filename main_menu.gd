extends Control
class_name MainMenu

@onready var game_scene_path="res://Scenes/tabletop.tscn"

func _ready() -> void:
	Online.server_started.connect(show_lobby)
	Online.joined_server.connect(show_lobby)
	Online.player_connected.connect(add_player)
	Online.player_disconnected.connect(remove_player)
	Online.server_disconnected.connect(leave_lobby)

func quit_game():
	get_tree().quit()

func start_game():
	if Online.is_hosting:
		Online.rpc("load_game",game_scene_path)
		return
	get_tree().change_scene_to_packed(load(game_scene_path))

func host():
	Online.start_server(int($CenterContainer/Host/Port.text))
	$CenterContainer/Host.hide()

func join():
	Online.join_server($CenterContainer/Join/IP.text, int($CenterContainer/Join/Port.text))
	$CenterContainer/Join.hide()

func show_lobby():
	if !multiplayer.is_server():
		$CenterContainer/Lobby/Start.hide()
	$CenterContainer/Lobby.show()

func add_player(peer_id, player_info):
	var player_label = Label.new()
	player_label.text=str(peer_id)+" - "+player_info["name"]
	$CenterContainer/Lobby/PlayerList.add_child(player_label)

func remove_player(peer_id):
	for label in $CenterContainer/Lobby/PlayerList.get_children():
		if label.text.begins_with(str(peer_id)):
			label.queue_free()
			return

func leave_lobby():
	Online.close_connection()
	for child in $CenterContainer/Lobby/PlayerList.get_children():
		child.queue_free()
	$CenterContainer/Lobby.hide()
	$CenterContainer/Multiplayer.show()
