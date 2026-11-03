extends Control

@export var player_list: VBoxContainer
@export var start_button: Button
@export var leave_button: Button


func _ready() -> void:
	Lobby.players_changed.connect(_refresh_list)
	
	start_button.visible = multiplayer.is_server()
	
	_refresh_list()
	
func _refresh_list() -> void:
	for child in player_list.get_children():
		child.queue_free()
		
	for player_name in Lobby.players.values():
		var label := Label.new()
		label.text = player_name
		player_list.add_child(label)
		
func _on_start_button_pressed() -> void:
	Lobby.start_game()


func _on_start_pressed() -> void:
	pass # Replace with function body.
