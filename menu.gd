extends Control
class_name Menu

func _ready() -> void:
	Online.server_started.connect(show_lobby)
	Online.joined_server.connect(show_lobby)
	Online.player_connected.connect(add_player)
	Online.player_disconnected.connect(remove_player)
	Online.connection_failed.connect(show_failure)

func host():
	var res=Online.start_server(int($CenterContainer/Host/Port.text))
	if res:
		$CenterContainer/Host.hide()
		show_failure("Failed to host with error:\n"+str(res))
		return
	#var ip=Online.upnp.query_external_address()
	#$CenterContainer/Lobby/IP.text="IP: "+str(ip)
	$CenterContainer/Host.hide()

func join():
	$CenterContainer/Lobby/IP.text="IP: "+$CenterContainer/Join/IP.text
	Online.join_server($CenterContainer/Join/IP.text, int($CenterContainer/Join/Port.text))

func show_failure(message):
	for child in $CenterContainer/Lobby/PlayerList.get_children():
		child.queue_free()
	$CenterContainer/Failure/Label.text=message
	$CenterContainer/Connecting.hide()
	$CenterContainer/Lobby.hide()
	$CenterContainer/Failure.show()

func show_lobby():
	if !multiplayer.is_server():
		$CenterContainer/Lobby/HBoxContainer/Start.hide()
		$CenterContainer/Connecting.hide()
		$CenterContainer/Lobby/HBoxContainer/Cancel.text="Leave lobby"
	else:
		$CenterContainer/Lobby/HBoxContainer/Start.show()
		$CenterContainer/Lobby/HBoxContainer/Cancel.text="Close lobby"
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

func pause_cursor():
	$Cursor.set_process(false)
	$Cursor.set_physics_process(false)
	$Cursor.set_process_input(false)
