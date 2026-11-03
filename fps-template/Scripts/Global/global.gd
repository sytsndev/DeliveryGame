extends Node

var seed: int

var rng := RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func create_session_seed() -> void:
	rng.randomize()
	seed = rng.randi()
	print("Global Seed: ", seed)
