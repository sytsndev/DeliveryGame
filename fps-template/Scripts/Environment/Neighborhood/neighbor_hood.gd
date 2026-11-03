class_name NeighborHood
extends Node

var seed: int

@export var houses_container: Node3D

var houses: Array[HouseGenerator]


func _ready() -> void:
	houses.assign(houses_container.get_children())
	print(houses)
