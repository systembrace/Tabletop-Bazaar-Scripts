extends Node

var tabletop: Tabletop

func _ready():
	get_tree().auto_accept_quit=false

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if multiplayer.multiplayer_peer!=OfflineMultiplayerPeer and multiplayer.is_server() and Online.upnp:
			Online.close_port()
		get_tree().quit()
