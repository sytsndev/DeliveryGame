extends Control

@export var username_input: LineEdit
@export var ip_address_input: LineEdit


func _on_server_pressed() -> void:
	Lobby.host(_get_player_name())


func _on_client_pressed() -> void:
	var host_address := ip_address_input.text.strip_edges()
	if host_address.is_empty():
		host_address = "localhost"
		
	Lobby.join(_get_player_name(), host_address)
	
func _get_player_name() -> String:
	var player_name = username_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	return player_name
