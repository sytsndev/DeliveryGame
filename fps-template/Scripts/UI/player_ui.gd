class_name PlayerUI extends Control

@export var player: Player
var speed_label: RichTextLabel
var health_label: RichTextLabel
var interact_label: RichTextLabel
var throw_charge: TextureProgressBar

func _ready() -> void:
	speed_label = %Speed
	health_label = %Health
	interact_label = %Interact
	throw_charge = %ThrowCharge

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player:
		if player.is_multiplayer_authority():
			speed_label.text = "Speed: " + str(player.velocity.length())
			throw_charge.visible = throw_charge.value > 0.0
			throw_charge.value = player.force_multi
			
		if player.cur_interactable != null:
			interact_label.visible = true
		else: 
			interact_label.visible = false
		


func connect_to_player(player_node):
	player = player_node
	if player.is_multiplayer_authority():
		print(player.name)
		player.set_health.connect(_on_set_health)
		player.set_weapon_name.connect(_on_set_weapon_name)
		health_label.text = str(player.health_res.max_health)

func _on_set_health(new_health: float):
	health_label.text = str(new_health)

func _on_damage_pressed() -> void:
	player.health._take_damage(-25)


func _on_set_weapon_name():
	%WeaponName.text = player.weapon_manager.weapon_res.weapon_name
