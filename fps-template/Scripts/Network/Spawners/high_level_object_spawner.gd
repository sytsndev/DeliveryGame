extends MultiplayerSpawner

@export var network_package: PackedScene
@export var spawn_pos: Marker3D


func _ready() -> void:
	# this is connecting the method to the signal to listen to any server start ups
	HighLevelNetworkHandler.server_started.connect(_on_server_started)
	# this is calling the method incase the server has already connected
	call_deferred("spawn_object", spawn_pos.global_position, spawn_pos.global_rotation)


func _on_server_started() -> void:
	call_deferred("spawn_object", spawn_pos.global_position, spawn_pos.global_rotation)


func request_spawn_object(pos: Vector3, rot: Vector3) -> void:
	if multiplayer.is_server():
		# Host player.
		spawn_object(pos, rot)
	else:
		# Connected player requests spawning on the server.
		_request_spawn_object.rpc_id(1, pos, rot)


@rpc("any_peer", "call_remote", "reliable")
func _request_spawn_object(pos: Vector3, rot: Vector3) -> void:
	if not multiplayer.is_server():
		return
	
	spawn_object(pos, rot)


func spawn_object(pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> RigidBody3D:
	if not multiplayer.has_multiplayer_peer():
		return null
	
	if not multiplayer.is_server():
		return null

	var object_container := get_node(spawn_path) as Node3D
	var package := network_package.instantiate() as RigidBody3D

	var world_transform := Transform3D(Basis.from_euler(rot), pos)

	package.transform = (
		object_container.global_transform.affine_inverse()
		* world_transform
	)

	object_container.add_child(package, true)

	return package


func request_throw_object(pos: Vector3, rot: Vector3, impulse: Vector3) -> void:
	if multiplayer.is_server():
		# Host player.
		throw_object(pos, rot, impulse)
	else:
		# Connected player requests spawning on the server.
		_request_throw_object.rpc_id(1, pos, rot, impulse)


@rpc("any_peer", "call_remote", "reliable")
func _request_throw_object(pos: Vector3, rot: Vector3, impulse: Vector3) -> void:
	if not multiplayer.is_server():
		return
	
	throw_object(pos, rot, impulse)


func throw_object(pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO, impulse: Vector3 = Vector3.ZERO):
	if not multiplayer.has_multiplayer_peer():
		return null
	
	if not multiplayer.is_server():
		return null
	
	var package = spawn_object(pos, rot)
	
	package.apply_impulse(impulse)



func request_delete_object(object: Node) -> void:
	if multiplayer.is_server():
		delete_object(object)
	else:
		_request_delete_object.rpc_id(1, object.get_path())


@rpc("any_peer", "call_remote", "reliable")
func _request_delete_object(object_path: NodePath) -> void:
	print("Delete request received on peer: ", multiplayer.get_unique_id())

	if not multiplayer.is_server():
		return

	var object := get_node_or_null(object_path)

	if object == null:
		push_error("Server could not find object: %s" % object_path)
		return

	delete_object(object)


func delete_object(object: Node) -> void:
	object.queue_free()
