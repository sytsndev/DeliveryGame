class_name StreetPlacement
extends RefCounted

const CLOCKWISE_DIRECTIONS = [
	StreetRes.Directions.NORTH,
	StreetRes.Directions.EAST,
	StreetRes.Directions.SOUTH,
	StreetRes.Directions.WEST,
]

var definition: StreetRes
var cell: Vector2i
var quarter_turns: int
var node: Node3D


func _init(
	street_definition: StreetRes,
	grid_cell: Vector2i,
	turns: int,
	instance: Node3D
) -> void:
	definition = street_definition
	cell = grid_cell
	quarter_turns = posmod(turns, 4)
	node = instance


func get_openings() -> Array[StreetRes.Directions]:
	var rotated: Array[StreetRes.Directions] = []

	for direction in definition.openings:
		var index := CLOCKWISE_DIRECTIONS.find(direction)
		var rotated_index := posmod(index + quarter_turns, 4)

		rotated.append(CLOCKWISE_DIRECTIONS[rotated_index])

	return rotated


func has_opening(direction: StreetRes.Directions) -> bool:
	return get_openings().has(direction)
