extends MultiplayerSpawner

@export var network_player: PackedScene


func _ready() -> void:
	#multiplayer.peer_connected.connect(_on_peer_connected)
	#HighLevelNetworkHandler.server_started.connect(_on_server_started)
	Lobby.players_loaded.connect(load_players)


func _on_server_started() -> void:
	spawn_player(multiplayer.get_unique_id())


func _on_peer_connected(id: int) -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		spawn_player(id)


func spawn_player(id: int) -> void:
	if not multiplayer.has_multiplayer_peer():
		return

	if not multiplayer.is_server():
		return

	var player: Node = network_player.instantiate()
	player.name = str(id)

	var player_container := get_node(spawn_path)
	player_container.call_deferred("add_child", player)
	
func load_players() -> void:
	for id in Lobby.players:
		spawn_player(id)
