extends Node

signal server_started

const DEFAULT_PORT: int = 3491
const MAX_CLIENTS: int = 4

var peer: ENetMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func start_server(port: int = DEFAULT_PORT) -> bool:
	peer = ENetMultiplayerPeer.new()

	var error := peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		push_error("Could not start server: " + error_string(error))
		return false

	multiplayer.multiplayer_peer = peer

	print("Hosting on UDP port ", port)
	print("Host peer ID: ", multiplayer.get_unique_id())

	server_started.emit()
	
	Global.create_session_seed()
	
	HighLevelNetworkHandler.create_and_send_neighborhood_seed()
	
	return true


func start_client(address: String, port: int = DEFAULT_PORT) -> bool:
	peer = ENetMultiplayerPeer.new()

	var clean_address := address.strip_edges()

	if clean_address.is_empty():
		push_error("Enter a host IP address.")
		return false

	var error := peer.create_client(clean_address, port)
	if error != OK:
		push_error("Could not begin connecting: " + error_string(error))
		return false

	multiplayer.multiplayer_peer = peer

	print("Connecting to ", clean_address, ":", port)
	
	return true


func create_and_send_neighborhood_seed() -> void:
	if not multiplayer.has_multiplayer_peer():
		push_error("Cannot create multiplayer world seed without a session.")
		return

	if not multiplayer.is_server():
		push_error("Only the host can create the neighborhood seed.")
		return

	var seed_rng := RandomNumberGenerator.new()
	seed_rng.randomize()

	var new_seed: int = seed_rng.randi()

	print("HOST CREATED SEED: ", new_seed)

	set_neighborhood_seed.rpc(new_seed)


@rpc("authority", "call_local", "reliable")
func set_neighborhood_seed(new_seed: int) -> void:
	print("SET SEED: ", new_seed)
	Global.seed = new_seed

	print("Neighborhood seed set to: ", Global.seed)


func close_connection() -> void:
	if peer:
		peer.close()

	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	peer = null


func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)

	if multiplayer.is_server() and Global.seed != 0:
		set_neighborhood_seed.rpc_id(
			peer_id,
			Global.seed
		)


func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)


func _on_connected_to_server() -> void:
	print("Connected to host. My peer ID: ", multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	push_error("Could not connect to host.")
	close_connection()


func _on_server_disconnected() -> void:
	print("Host disconnected.")
	close_connection()
