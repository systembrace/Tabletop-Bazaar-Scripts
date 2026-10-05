extends Node

signal server_started
signal joined_server
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
var is_hosting=false
var players = {}
var player_info = {"name": "default name"}
var players_loaded = 0

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func start_server(port=null):
	if !port:
		port=7000
	var peer = ENetMultiplayerPeer.new()
	print("Starting server...")
	var error = peer.create_server(port, 2)
	if error:
		print(error)
		return error
	print("Server started successfully!")
	is_hosting=true
	multiplayer.multiplayer_peer = peer
	server_started.emit()
	players[1] = player_info
	player_connected.emit(1, player_info)

func _on_player_connected(id):
	print("Player "+str(id)+" connected.")
	_register_player.rpc_id(id, player_info)

func _on_player_disconnected(id):
	print("Player "+str(id)+" disconnected.")
	players.erase(id)
	player_disconnected.emit(id)

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	print("Registering player: "+str(new_player_id)+" - "+str(new_player_info))
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

@rpc("call_local", "reliable")
func load_game(game_scene_path):
	print("Loading game...")
	get_tree().change_scene_to_packed(load(game_scene_path))

#@rpc("any_peer", "call_local", "reliable")
#func player_loaded():
	#if multiplayer.is_server():
		#players_loaded += 1
		#if players_loaded == players.size():
			#$/root/Game.start_game()
			#players_loaded = 0

func join_server(address = "", port=null):
	if address.is_empty():
		address = "127.0.0.1"
	if !port:
		port=7000
	var peer = ENetMultiplayerPeer.new()
	print("Joining server...")
	var error = peer.create_client(address, port)
	if error:
		print(error)
		return error
	print("Joined server successfully!")
	multiplayer.multiplayer_peer = peer
	joined_server.emit()

func close_connection():
	print("Closing connection")
	for peer_id in players.keys():
		if peer_id==1 or not peer_id in multiplayer.get_peers():
			continue
		multiplayer.multiplayer_peer.disconnect_peer(peer_id)
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players.clear()

func _on_connected_ok():
	print("Connected successfully.")
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail():
	print("Failed to connect.")
	close_connection()

func _on_server_disconnected():
	print("Server disconnected")
	close_connection()
	server_disconnected.emit()
