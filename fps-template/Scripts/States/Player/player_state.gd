class_name PlayerState extends State

const IDLE = "Idle"
const RUNNING = "Running"
const JUMPING = "Jumping"
const FALLING = "Falling"
const SPRINT = "Sprint"
const DASH = "Dash"
const SLIDING = "Sliding"
const WALL_RUN = "WallRun"
const GROUND_POUND = "GroundPound"
const NO_CLIP = "NoClip"

enum MovementType { 
	WISH_DIR,
	FLOATY,
	MOMENTUM
	}

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func update(delta: float) -> void:
	if !player.is_multiplayer_authority() && player.is_multiplayer: return
	
	check_inputs(delta)
	
	if player.is_on_floor() and (player.dash_count > 0 or player.d_jump_count > 0):
		player.reset_air_movement()



func handle_input(event: InputEvent) -> void:
	if !player.is_multiplayer_authority() && player.is_multiplayer: return

	if event is InputEventMouseMotion:
		player.neck.rotate_y(-event.relative.x * player.player_res.mouse_sens)
		player.camera.rotate_x(-event.relative.y * player.player_res.mouse_sens)
		
		player.camera.rotation.x = clamp(
		player.camera.rotation.x,
		deg_to_rad(-90),
		deg_to_rad(90)
	)



func check_inputs(delta: float):
	if Input.is_action_just_pressed("no_clip") and !player.is_no_clip:
		player.is_no_clip = true
	elif Input.is_action_just_pressed("no_clip") and player.is_no_clip:
		player.is_no_clip = false
	crouch_inputs()
	ui_inputs()
	interact_input()
	throw(delta)


func throw(delta: float):
	if player.cur_package == null:
		return
	if Input.is_action_pressed("throw"):
		player.force_multi += (delta / player.charge_time) * 2
		player.force_multi = clampf(player.force_multi, 0.0, 1.0)
	
	if Input.is_action_just_released("throw") and player.force_multi <= 0.25:
		player.drop_package()
		player.force_multi = 0.0
	
	if Input.is_action_just_released("throw") and player.force_multi > 0.25:
		print(player.force_multi)
		player.throw_package()
		player.force_multi = 0.0
	


func crouch_inputs():
	if !player.player_res.crouch:
		return
	player.crouch_shape_cast.force_shapecast_update()

	if player.movement.is_sliding:
		return
	if player.exiting_crouching and !player.crouch_shape_cast.is_colliding():
		player.exit_crouch()
	if Input.is_action_just_pressed("crouch") && player.is_on_floor():
		player.enter_crouch_ground()
	if Input.is_action_just_pressed("crouch") && !player.is_crouching:
		player.enter_crouch_air()
	if Input.is_action_just_released("crouch"):
		player.exiting_crouching = true
	if !Input.is_action_pressed("crouch") and player.is_crouching == true:
		player.exiting_crouching = true


func ui_inputs():
	if Input.is_action_just_released("ui_cancel") and not player.is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		player.is_paused = true
		player.pause_game()
		#get_tree().paused = true
	elif Input.is_action_just_released("ui_cancel") and player.is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		player.is_paused = false
		player.unpause_game()
		get_tree().paused = false


func interact_input():
	if Input.is_action_just_pressed("interact"):
		if player.cur_interactable != null:
			player.cur_interactable.interact(player)
			player.cur_interactable = null
		elif player.cur_area_interactable != null:
			player.cur_area_interactable.interact()
