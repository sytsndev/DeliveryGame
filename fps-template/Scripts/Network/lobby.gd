extends Node

signal players_changed
signal players_loaded

const MENU_SCENE := "res://Scenes/UI/Menus/NetworkUI.tscn"
const LOBBY_SCENE := "res://Scenes/UI/Menus/lobby.tscn"
const WORLD_SCENE := "res://Scenes/Environment/world.tscn"

var local_name := "Player"
var players: Dictionary = {}
var _loaded_count := 0

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
func host(player_name: String) -> void:
	local_name = player_name
	if HighLevelNetworkHandler.start_server():
		players = { 1: player_name }
		get_tree().change_scene_to_file(LOBBY_SCENE)

func join(player_name: String, address: String) -> void:
	local_name = player_name
	HighLevelNetworkHandler.start_client(address)
	
func _on_connected_to_server() -> void:
	register_player.rpc_id(1, local_name)
	get_tree().change_scene_to_file(LOBBY_SCENE)
	
@rpc("any_peer", "call_remote", "reliable")
func register_player(player_name: String) -> void:
	if not multiplayer.is_server(): return
	players[multiplayer.get_remote_sender_id()] = player_name.strip_edges().left(16)
	sync_players.rpc(players)
	
@rpc("authority", "call_local", "reliable")
func sync_players(new_players: Dictionary) -> void:
	players = new_players
	players_changed.emit()
	
func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		players.erase(id)
		sync_players.rpc(players)
		
func _on_server_disconnected() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MENU_SCENE)
	
func start_game() -> void:
	if not multiplayer.is_server(): return
	HighLevelNetworkHandler.peer.refuse_new_connections = true
	_loaded_count = 0
	begin_game.rpc()
	
@rpc("authority", "call_local", "reliable")
func begin_game() -> void:
	get_tree().change_scene_to_file(WORLD_SCENE)
	
@rpc("any_peer", "call_local", "reliable")
func world_loaded() -> void:
	if not multiplayer.is_server(): return
	_loaded_count += 1
	if _loaded_count == players.size():
		players_loaded.emit()
