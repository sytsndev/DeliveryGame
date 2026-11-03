extends Control

@onready var player: Player = $".."


func _on_resume_pressed() -> void:
	player.toggle_pause()


func _on_quit_pressed() -> void:
	if player and player.is_multiplayer_authority():
		# Ask our own Player node (which we own) to despawn
		player.despawn.rpc()  # no ID needed; "authority" mode targets the node's authority
	# Optionally close the connection after that:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
