class_name StreetRes
extends Resource

enum Directions{
	NORTH,
	EAST,
	SOUTH,
	WEST
}

enum StreetType{
	STRAIGHT,
	CORNER,
	END,
	GRASS,
	CROSS,
	T
}

enum StreetCategory{
	ROAD,
	TERRAIN
}

@export var street_type: StreetType
@export var street_category: StreetCategory
@export var model: PackedScene
@export var openings: Array[Directions]
@export var rules: Array[String]
@export var base_street: bool
@export var rotation_amount: float = 90.0
@export var main_opening: Directions
