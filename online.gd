extends Node

signal server_started
signal joined_server
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal connection_failed(message)
var self_id=1
var players = {}
var player_info = {"name": "default name"}
var players_loaded = 0
var host_port=7000
var upnp:UPNP
@onready var connection_timeout: Timer = Timer.new()

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	connection_timeout.wait_time=30
	connection_timeout.one_shot=true
	connection_timeout.timeout.connect(_on_connection_timeout)
	add_child(connection_timeout)

func forward_port(port):
	return 0
	upnp = UPNP.new()
	var discover_result = upnp.discover()

	if discover_result == UPNP.UPNP_RESULT_SUCCESS and upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
		host_port=port
		var udp_res=upnp.add_port_mapping(port, port, "tabletop_bazaar_UDP", "UDP")
		var tcp_res=upnp.add_port_mapping(port, port, "tabletop_bazaar_TCP", "TCP")
		
		if udp_res!=UPNP.UPNP_RESULT_SUCCESS:
			upnp.add_port_mapping(port, port, "", "UDP")
		if tcp_res!=UPNP.UPNP_RESULT_SUCCESS:
			upnp.add_port_mapping(port, port, "", "TCP")
		return UPNP.UPNP_RESULT_SUCCESS
	return discover_result

func close_port():
	upnp.delete_port_mapping(host_port, "UDP")
	upnp.delete_port_mapping(host_port, "TCP")

func start_server(port=null):
	if !port:
		port=7000
	var peer = ENetMultiplayerPeer.new()
	print("Starting server...")
	var res=forward_port(port)
	if res!=UPNP.UPNP_RESULT_SUCCESS:
		print("Failed to forward port with error "+str(res))
		return res
	var error = peer.create_server(port)
	if error:
		print(error)
		return error
	print("Server started successfully!")
	multiplayer.multiplayer_peer = peer
	server_started.emit()
	players[1] = player_info
	player_connected.emit(1, player_info)

func _on_player_connected(id):
	print("Player "+str(id)+" connected to "+str(self_id))
	_register_player.rpc_id(id, player_info)

func _on_player_disconnected(id):
	print("Player "+str(id)+" disconnected from "+str(self_id))
	players.erase(id)
	player_disconnected.emit(id)

@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	print("Registering player: "+str(new_player_id)+" - "+str(new_player_info)+" on "+str(self_id))
	players[new_player_id] = new_player_info
	player_connected.emit(new_player_id, new_player_info)

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
	print("Creating client...")
	var error = peer.create_client(address, port)
	if error:
		print(error)
		return error
	print("Created client successfully!")
	multiplayer.multiplayer_peer = peer
	connection_timeout.start()

func _on_connection_timeout():
	if multiplayer.multiplayer_peer.get_connection_status()!=2:
		_on_connected_fail()

#@rpc("any_peer", "call_remote", "reliable")
#func get_server_data(id, key, value=null):
	#if multiplayer.is_server():
		#rpc("get_server_data",id,key,get(key))
	#elif id==self_id:
		#handle_response(key, value)
#
#func handle_response(key, value):
	#if key=="game_started" and value:
		#load_game("res://Scenes/sandbox.tscn")

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
	connection_timeout.stop()
	joined_server.emit()
	var peer_id = multiplayer.get_unique_id()
	self_id=peer_id
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)

func _on_connected_fail():
	print("Failed to connect.")
	close_connection()
	connection_failed.emit("Timeout: Failed to connect to lobby.")

func _on_server_disconnected():
	print("Server disconnected")
	close_connection()
	connection_failed.emit("Disconnected from lobby.")
