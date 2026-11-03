class_name NeighborhoodGen
extends Node3D

const DIRECTION_OFFSETS = {
	StreetRes.Directions.NORTH: Vector2i(0, -1),
	StreetRes.Directions.SOUTH: Vector2i(0, 1),
	StreetRes.Directions.EAST: Vector2i(1, 0),
	StreetRes.Directions.WEST: Vector2i(-1, 0),
}

const OPPOSITE_DIRECTIONS = {
	StreetRes.Directions.NORTH: StreetRes.Directions.SOUTH,
	StreetRes.Directions.SOUTH: StreetRes.Directions.NORTH,
	StreetRes.Directions.EAST: StreetRes.Directions.WEST,
	StreetRes.Directions.WEST: StreetRes.Directions.EAST,
}

@export var config: NeighborhoodGenRes
@export var generation_seed: int = 12345
@export_range(1, 200) var street_count: int = 20

var rng := RandomNumberGenerator.new()

var placed_streets: Dictionary = {}



func _ready() -> void:
	var seed_rng := RandomNumberGenerator.new()
	seed_rng.randomize()

	generation_seed = seed_rng.randi()

	print("Neighborhood seed: ", generation_seed)
	generate_neighborhood(generation_seed)


func generate_neighborhood(seed_value: int) -> void:
	if config == null or config.cell_size <= 0.0:
		push_error("Assign a config with a positive cell size.")
		return

	# This first algorithm only supports two-opening pieces.
	var usable_streets: Array[StreetRes] = []

	for street in config.streets:
		if street == null or street.model == null:
			continue

		if street.street_category != StreetRes.StreetCategory.ROAD:
			continue

		if street.openings.size() != 2:
			continue

		if street.openings[0] == street.openings[1]:
			continue

		usable_streets.append(street)

	if usable_streets.is_empty():
		push_error("Add street resources with two distinct openings.")
		return

	clear_streets()
	rng.seed = seed_value

	# Start with a random definition and orientation.
	var first_definition := usable_streets[
		rng.randi_range(0, usable_streets.size() - 1)
	]

	var current := place_street(
	first_definition,
	Vector2i.ZERO,
	rng.randi_range(0, 3)
	)

	if current == null:
		return

	place_grass_beside_straight(current)

	if current == null:
		return

	# Pick one opening as the direction in which to grow.
	var first_openings := current.get_openings()
	var travel_direction: StreetRes.Directions = first_openings[
		rng.randi_range(0, first_openings.size() - 1)
	]

	for step in range(street_count - 1):
		var offset: Vector2i = DIRECTION_OFFSETS[travel_direction]
		var next_cell := current.cell + offset

		var entrance: StreetRes.Directions = (
			OPPOSITE_DIRECTIONS[travel_direction]
		)

		var candidates: Array[StreetPlacement] = []

		for street in usable_streets:
			for turns in range(4):
				# No scene is spawned for this temporary candidate.
				var candidate := StreetPlacement.new(
					street,
					next_cell,
					turns,
					null
				)

				if not candidate.has_opening(entrance):
					continue

				if not fits_neighbors(candidate):
					continue

				# The other opening must lead to an empty cell.
				for direction in candidate.get_openings():
					if direction == entrance:
						continue

					var exit_offset: Vector2i = DIRECTION_OFFSETS[direction]
					var exit_cell := next_cell + exit_offset

					if not placed_streets.has(exit_cell):
						candidates.append(candidate)

		if candidates.is_empty():
			print("Road growth stopped: no valid continuation.")
			break

		var chosen := candidates[
			rng.randi_range(0, candidates.size() - 1)
		]

		current = place_street(
			chosen.definition,
			chosen.cell,
			chosen.quarter_turns
		)

		if current == null:
			break

		place_grass_beside_straight(current)

		for direction in current.get_openings():
			if direction != entrance:
				travel_direction = direction
				break

	print("Generated street count: ", placed_streets.size())

func place_street(
	street: StreetRes,
	cell: Vector2i,
	quarter_turns: int = 0
) -> StreetPlacement:
	if config == null or config.cell_size <= 0.0:
		push_error("Assign a neighborhood config with a positive cell size.")
		return null

	if street == null or street.model == null:
		push_error("Street definition is missing its model.")
		return null

	if placed_streets.has(cell):
		push_warning("A street already occupies cell %s." % cell)
		return null

	var instance := street.model.instantiate()

	if not instance is Node3D:
		instance.free()
		push_error("Street scene must have a Node3D root.")
		return null

	var street_node := instance as Node3D
	var turns := posmod(quarter_turns, 4)

	street_node.position = grid_to_local(cell)
	street_node.rotation.y = -float(turns) * PI / 2.0

	var placement := StreetPlacement.new(
		street,
		cell,
		turns,
		street_node
	)

	placed_streets[cell] = placement
	add_child(street_node)

	return placement


func get_street(cell: Vector2i) -> StreetPlacement:
	return placed_streets.get(cell) as StreetPlacement


func get_connected_neighbor(
	cell: Vector2i,
	direction: StreetRes.Directions
) -> StreetPlacement:
	var placement := get_street(cell)

	if placement == null or not placement.has_opening(direction):
		return null

	var offset: Vector2i = DIRECTION_OFFSETS[direction]
	var neighbor := get_street(cell + offset)

	if neighbor == null:
		return null

	if not neighbor.has_opening(OPPOSITE_DIRECTIONS[direction]):
		return null

	return neighbor


func get_connections(cell: Vector2i) -> Dictionary:
	# Direction -> connected StreetPlacement
	var connections: Dictionary = {}
	var placement := get_street(cell)

	if placement == null:
		return connections

	for direction in placement.get_openings():
		var neighbor := get_connected_neighbor(cell, direction)

		if neighbor != null:
			connections[direction] = neighbor

	return connections


func clear_streets() -> void:
	for value in placed_streets.values():
		var placement := value as StreetPlacement

		if is_instance_valid(placement.node):
			placement.node.queue_free()

	placed_streets.clear()


func fits_neighbors(candidate: StreetPlacement) -> bool:
	if placed_streets.has(candidate.cell):
		return false

	for direction in DIRECTION_OFFSETS:
		var offset: Vector2i = DIRECTION_OFFSETS[direction]
		var neighbor := get_street(candidate.cell + offset)

		if neighbor == null:
			continue

		var opposite: StreetRes.Directions = OPPOSITE_DIRECTIONS[direction]

		var candidate_opens := candidate.has_opening(direction)
		var neighbor_opens := neighbor.has_opening(opposite)

		# An opening against a closed edge is invalid.
		if candidate_opens != neighbor_opens:
			return false

	return true


func grid_to_local(cell: Vector2i) -> Vector3:
	return Vector3(
		cell.x * config.cell_size,
		0.0,
		cell.y * config.cell_size
	)


func get_grass_definition() -> StreetRes:
	for street in config.streets:
		if street != null and street.street_type == StreetRes.StreetType.GRASS:
			return street

	return null


func place_grass_beside_straight(placement: StreetPlacement) -> void:
	if placement == null or placement.definition == null:
		return

	if placement.definition.street_type != StreetRes.StreetType.STRAIGHT:
		return

	var grass := get_grass_definition()

	if grass == null:
		return

	var openings := placement.get_openings()

	for direction in DIRECTION_OFFSETS:
		if openings.has(direction):
			continue

		var offset: Vector2i = DIRECTION_OFFSETS[direction]
		var grass_cell := placement.cell + offset

		if placed_streets.has(grass_cell):
			continue

		place_street(grass, grass_cell)
