extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player.is_no_clip = true
	player.velocity = Vector3.ZERO
	player.collider.disabled = true
	if player.player_res.c_fov_change:
		player.camera_manager.smooth_change_fov(player.player_res.fov * 1.1)
	#player.animation_player.play("run")
	pass


func physics_update(delta: float) -> void:
	if !player.is_multiplayer_authority() && player.is_multiplayer: return

	# Handle jump.
	if Input.is_action_pressed("jump"):
		player.velocity.y = player.player_res.no_clip_speed

	if Input.is_action_pressed("sprint"):
		player.velocity.y = -player.player_res.no_clip_speed
	
	if Input.is_action_just_released("jump") or Input.is_action_just_released("sprint"):
		player.velocity.y = 0
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (player.neck.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		player.velocity.x = direction.x * player.player_res.no_clip_speed
		player.velocity.z = direction.z * player.player_res.no_clip_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.player_res.no_clip_speed)
		player.velocity.z = move_toward(player.velocity.z, 0, player.player_res.no_clip_speed)

	player.move_and_slide()
	
	if !player.is_no_clip:
		finished.emit(FALLING)


func exit() -> void:
	player.collider.disabled = false
	if player.player_res.c_fov_change:
		player.camera_manager.smooth_change_fov(player.player_res.fov)
	
