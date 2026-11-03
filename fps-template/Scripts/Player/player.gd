class_name Player extends CharacterBody3D

@onready var object_spawner = get_tree().get_first_node_in_group(
    "object_spawner"
)

@export var player_res: PlayerRes
@export var pause_menu: Control
@export var neck: Node3D
@export var camera: Camera3D
@export var collider: CollisionShape3D
@export var mesh: MeshInstance3D
@export var is_multiplayer: bool = true
@export var crouch_shape_cast: ShapeCast3D
@export var health_res: HealthRes
@export var interact_ray: RayCast3D
@export var weapon_manager: WeaponManager

@export var left_wall_run_rays: Array[RayCast3D]
@export var right_wall_run_rays: Array[RayCast3D]
@export var grapple_cast: RayCast3D

@export var movement: Movement
@export var camera_lean: CameraLean
@export var camera_manager: CameraManager

@export var charge_time : float

var force_multi : float = 0.0

var health: Health
var is_paused = false
var is_crouching = false
var exiting_crouching = false
var is_dead = false
var cur_interactable = null
var is_no_clip = false

signal set_health(new_health: float)
signal set_weapon_name

var d_jump_count: int = 0
var dash_count: int = 0
var wr_reset_timer: float = 0.0
var slide_reset_timer: float = 0.0
var curr_gp_dist: float = 0.0 # this is holding the value of the height of the players current ground pound

var cur_area_interactable = null

var cur_package: PackageRes
var cur_package_model

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	camera.current = true
	if is_multiplayer_authority():
		camera.current = true
		weapon_connection_setup()
		setup()
	game_setup()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if interact_ray.is_colliding() and cur_interactable == null:
		var res = interact_ray.get_collider()
		if res is Node3D:
			cur_interactable = res.get_parent()
			print(cur_interactable)
	elif !interact_ray.is_colliding() and cur_interactable != null:
		cur_interactable = null
		


@rpc("authority", "reliable")
func despawn():
	# Runs only on the peer that is authority for THIS Player node
	queue_free()


#region Setup


func game_setup():
	unpause_game()
	#death_menu.hide()


func setup():
	camera.position = player_res.camera_pos
	weapon_connection_setup()


func weapon_connection_setup():
	weapon_manager.connect_player(self)
	set_weapon_name.emit()


#endregion


#region UI Controls


func ui_controls():
	if Input.is_action_just_released("ui_cancel"):
		toggle_pause()


func toggle_pause(unpause: bool = false):
	if unpause:
		unpause_game()
		return
	
	if not is_paused:
		pause_game()
		
	elif is_paused:
		unpause_game()


func pause_game():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	pause_menu.show()
	get_tree().paused = true
	is_paused = true


func unpause_game():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	pause_menu.hide()
	get_tree().paused = false
	is_paused = false


#endregion

#region Crouching


func enter_crouch_ground():
	if exiting_crouching:
		return
	is_crouching = true
	collider.scale.y = collider.scale.y / 1.5
	camera.position = player_res.camera_pos / 1.5
	velocity.y += -50.0
	move_and_slide()


func  enter_crouch_air():
	collider.scale.y = collider.scale.y / 1.5
	camera.position = player_res.camera_pos / 1.5
	is_crouching = true


func exit_crouch():
	if movement.is_sliding:
		return
	is_crouching = false
	collider.scale.y = collider.scale.y * 1.5
	camera.position = player_res.camera_pos
	
	exiting_crouching = false


#endregion


#region Package


func pickup_package(res: PackageRes) -> void:
	cur_package = res

	_show_held_model.rpc(
		res.model_path,
		res.package_pos,
		res.package_rot
	)


@rpc("any_peer", "call_local", "reliable")
func _show_held_model(
	model_path: String,
	model_pos: Vector3,
	model_rot_degrees: Vector3
) -> void:
	if is_instance_valid(cur_package_model):
		cur_package_model.queue_free()

	var scene := load(model_path) as PackedScene
	cur_package_model = scene.instantiate()

	camera.add_child(cur_package_model)

	cur_package_model.position = model_pos
	cur_package_model.rotation = Vector3(
		deg_to_rad(model_rot_degrees.x),
		deg_to_rad(model_rot_degrees.y),
		deg_to_rad(model_rot_degrees.z)
	)


func drop_package() -> void:
	_delete_held_model.rpc()
	var pos: Vector3 = cur_package_model.global_position
	var rot: Vector3 = cur_package_model.global_rotation
	object_spawner.request_spawn_object(pos, rot)
	cur_package = null
	cur_package_model = null


@rpc("any_peer", "call_local", "reliable")
func _delete_held_model() -> void:
	if is_instance_valid(cur_package_model):
		cur_package_model.queue_free()


func throw_package():
	var pos: Vector3 = cur_package_model.global_position
	var rot: Vector3 = cur_package_model.rotation
	_delete_held_model.rpc()
	var impulse = -camera.global_basis.z * ((player_res.throw_force * force_multi) + velocity.length())
	object_spawner.request_throw_object(pos, rot, impulse)
	cur_package = null
	cur_package_model = null


#endregion


#region State Change Checks

func state_jump():
	if !player_res.double_jump and !is_on_floor():
		return false
	if player_res.auto_bhop and Input.is_action_pressed("jump") and is_on_floor():
		return true
	return Input.is_action_just_pressed("jump") and player_res.max_double_jump_count > d_jump_count

func state_run():
	return Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_forward" )or Input.is_action_pressed("move_back")

func state_sprint():
	if !player_res.sprint:
		return false
	return !is_crouching and Input.is_action_pressed("sprint") and (Input.is_action_pressed("move_forward" ))

func state_idle(input_dir: Vector2):
	return is_equal_approx(input_dir.x, 0.0) && is_equal_approx(input_dir.y, 0.0)

func state_slide():
	if !player_res.slide or !player_res.crouch:
		return false
	return Input.is_action_just_pressed("crouch")

func state_dash():
	if !player_res.dash:
		return false
	return Input.is_action_just_pressed("dash") and dash_count < player_res.max_dash_count

func state_wall_run():
	if !player_res.wall_run:
		return false
	return (left_wall_run_rays.all(func(ray): return ray.is_colliding()) or right_wall_run_rays.all(func(ray): return ray.is_colliding())) and wr_reset_timer == 0.0

func state_grapple():
	if !player_res.grapple:
		return false
	return Input.is_action_just_pressed("grapple") and grapple_cast.is_colliding()

func state_ground_pound():
	if !player_res.ground_pound:
		return false
	return Input.is_action_just_pressed("crouch") and !is_on_floor()

#endregion

func get_speed():
	if is_crouching:
		return player_res.crouch_speed
	else:
		return player_res.speed


func wall_run_timer(delta: float):
	if is_on_floor():
		wr_reset_timer = 0.0
	if wr_reset_timer > 0.0:
		wr_reset_timer -= delta
		if wr_reset_timer <= 0.0:
			wr_reset_timer = 0.0


func slide_timer(delta: float):
	if slide_reset_timer > 0.0:
		slide_reset_timer -= delta
		if slide_reset_timer <= 0.0:
			slide_reset_timer = 0.0


func reset_air_movement(d_jump: bool = true, dash: bool = true):
	if d_jump:
		d_jump_count = 0
	if dash:
		dash_count = 0
