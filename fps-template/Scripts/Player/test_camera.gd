extends CharacterBody3D


const SPEED = 15
const JUMP_VELOCITY = 4.5

@export var neck: Node3D
@export var camera: Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	# Handle jump.
	if Input.is_action_pressed("jump"):
		velocity.y = SPEED

	if Input.is_action_pressed("sprint"):
		velocity.y = -SPEED
	
	if Input.is_action_just_released("jump") or Input.is_action_just_released("sprint"):
		velocity.y = 0
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (neck.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		neck.rotate_y(-event.relative.x * .001)
		camera.rotate_x(-event.relative.y * .001)
		
		camera.rotation.x = clamp(
		camera.rotation.x,
		deg_to_rad(-90),
		deg_to_rad(90)
	)
