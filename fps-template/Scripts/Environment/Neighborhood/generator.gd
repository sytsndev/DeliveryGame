extends Node3D


enum StreetType{
	STRAIGHT,
	CORNER,
	END,
	GRASS,
	CROSS,
	T
}

enum Directions{
	NORTH,
	EAST,
	SOUTH,
	WEST
}

enum RowColumn{
	ROW,
	COLUMN,
}

@export var grid_width: int
@export var grid_height: int
@export var neighborhood_res: NeighborhoodGenRes

var grid: Array[int]
var grid_size: int
var start_cell: Vector2

var rng := RandomNumberGenerator.new()


func _ready() -> void:
	setup_grid()
	
	set_cell(18, 1, 1)
	set_cell(18, 2, 1)
	set_cell(18, 3, 1)
	set_cell(18, 4, 1)
	set_cell(17, 4, 1)
	set_cell(16, 4, 1)
	set_cell(15, 4, 1)
	set_cell(14, 4, 1)
	set_cell(13, 4, 1)
	set_cell(13, 5, 1)
	set_cell(13, 6, 1)
	set_cell(13, 7, 1)
	set_cell(13, 8, 1)
	set_cell(13, 9, 1)
	set_cell(13, 10, 1)
	set_cell(17, 10, 1)
	set_cell(16, 10, 1)
	set_cell(15, 10, 1)
	set_cell(14, 10, 1)
	
	set_cell(12, 6, 1)
	set_cell(11, 6, 1)
	set_cell(10, 6, 1)
	set_cell(9, 6, 1)
	set_cell(9, 7, 1)
	set_cell(9, 8, 1)
	set_cell(9, 9, 1)
	set_cell(9, 10, 1)
	set_cell(9, 11, 1)
	set_cell(9, 12, 1)
	set_cell(9, 13, 1)
	set_cell(9, 14, 1)
	set_cell(9, 15, 1)
	set_cell(9, 16, 1)
	set_cell(9, 17, 1)
	set_cell(9, 18, 1)
	set_cell(9, 19, 1)
	set_cell(10, 19, 1)
	set_cell(11, 19, 1)
	set_cell(12, 19, 1)
	set_cell(13, 19, 1)
	set_cell(14, 19, 1)
	set_cell(15, 19, 1)
	set_cell(16, 19, 1)
	set_cell(17, 19, 1)
	
	
	
	
	set_cell(19, 4, 1)
	set_cell(20, 4, 1)
	set_cell(21, 4, 1)
	set_cell(22, 4, 1)
	set_cell(23, 4, 1)
	set_cell(23, 5, 1)
	set_cell(23, 6, 1)
	set_cell(23, 7, 1)
	set_cell(23, 8, 1)
	set_cell(23, 9, 1)
	set_cell(23, 10, 1)
	set_cell(19, 10, 1)
	set_cell(20, 10, 1)
	set_cell(21, 10, 1)
	set_cell(22, 10, 1)
	set_cell(18, 5, 1)
	set_cell(18, 6, 1)
	set_cell(18, 7, 1)
	set_cell(18, 8, 1)
	set_cell(18, 9, 1)
	set_cell(18, 10, 1)
	set_cell(18, 11, 1)
	set_cell(18, 12, 1)
	set_cell(18, 13, 1)
	set_cell(18, 14, 1)
	set_cell(18, 15, 1)
	set_cell(18, 16, 1)
	set_cell(18, 17, 1)
	set_cell(18, 18, 1)
	set_cell(18, 19, 1)
	set_cell(18, 20, 1)
	set_cell(18, 21, 1)
	set_cell(18, 22, 1)
	set_cell(18, 23, 1)
	set_cell(18, 24, 1)
	set_cell(18, 25, 1)

	#rand_gen()
	#set_cell(9, 7, 1)
	#set_cell(10, 7, 1)
	generate()
	var i = 0
	while i < grid_size:
		print(grid.slice(i, i + grid_width))
		i += grid_width



func setup_grid():
	rng.seed = Global.seed
	grid_size = grid_width * grid_height
	grid.resize(grid_size)
	grid.fill(0)


func rand_gen():
	## So my thought currently is to have a "main" road that has smaller areas sticking out of it.
	## This could be done by generating the main road and then from there creating more streets that connect to the main road and to each other
	## these could all be different methods with different works

## **UPDATE**
## Use the set neighbor hoods that can spawn from this and connect them. Probably couldve just built them in blender then, but this is expandable
## so design some way to set up neighbor hoods and translate that to the grid
## possibly having a second grid that translates the local position to the global position
## You could have a road that needs to connect at global position (10, 10) and then so the know the first piece goes there, then you translate i guess

	var starting_dir = rng.randi_range(RowColumn.ROW, RowColumn.COLUMN)
	var starting_row_num
	var cell: Vector2
	var i = 0
	if starting_dir == RowColumn.COLUMN:
		starting_row_num = rng.randi_range(grid_width * .25, grid_width * .75)
		while i < grid_width:
			set_cell(i + 1, starting_row_num, 1)
			print("(", i + 1, ", ", starting_row_num, ", 1)")
			i += 1
	elif starting_dir == RowColumn.ROW:
		starting_row_num = rng.randi_range(grid_height * .25, grid_height * .75)
		while i < grid_height:
			set_cell(starting_row_num, i + 1, 1)
			print("(", starting_row_num, ", ",  i + 1, ", 1)")
			
			i += 1


func spawn_side_streets():
	pass


func set_cell(x: int, y: int, value: int):
	var index = get_grid_index(x, y)
	grid[index] = value


func get_cell(x: int, y: int) -> int:
	if x < 1 or x > grid_width or y < 1 or y > grid_height:
		return -1
	var index = get_grid_index(x, y)
	return grid[index] if grid[index] != null else -1


func get_neighbors(x: int, y: int):
	return {
		"NORTH": get_cell(x, y - 1),
		"SOUTH": get_cell(x, y + 1),
		"EAST": get_cell(x + 1, y),
		"WEST": get_cell(x - 1, y)
	}
	

func get_grid_index(x: int, y: int):
	return (y - 1) * grid_width + (x - 1)


func generate():
	var i = 0
	while i < grid.size():
		if grid[i] == 0:
			var grass = neighborhood_res.streets.filter(func(street): return street.street_type == StreetType.GRASS).front()
			var instance = grass.model.instantiate()
			var cell_pos = get_cell_offset(i)
			instance.position.x = cell_pos.x * neighborhood_res.cell_size
			instance.position.z = cell_pos.y * neighborhood_res.cell_size
			add_child(instance)
		elif grid[i] == 1:
			var x_y = get_cell_x_y(i)
			var neighbors = get_neighbors(x_y.x, x_y.y)
			var street_count = neighbors.values().filter(func(value): return value == 1).size()
			var directions: Array[String]
			for direction in neighbors:
				if neighbors[direction] == 1:
					directions.append(direction)
			match street_count:
				1: ## End
					var street = neighborhood_res.streets.filter(func(street): return street.street_type == StreetType.END).front()
					var instance = instance_street(street, i)
					var turn_amount = get_turn_count(directions[0], Directions.keys()[street.main_opening])
					instance.rotation.y = deg_to_rad(turn_amount * street.rotation_amount)
				2: ## Straight or Corner
					if !is_corner(directions):
						var street = neighborhood_res.streets.filter(func(street): return street.street_type == StreetType.STRAIGHT).front()
						var instance = instance_street(street, i)
						var turn_amount = get_turn_count(directions[0], Directions.keys()[street.main_opening])
						instance.rotation.y = deg_to_rad(turn_amount * street.rotation_amount)
					else:
						var street = neighborhood_res.streets.filter(func(street): return street.street_type == StreetType.CORNER).front()
						var instance = instance_street(street, i)
						var turn_amount = get_turn_count(find_corner_orientation(directions), Directions.keys()[street.main_opening])
						instance.rotation.y = deg_to_rad(turn_amount * street.rotation_amount)
				3: ## T
					var street = neighborhood_res.streets.filter(func(street): return street.street_type == StreetType.T).front()
					var instance = instance_street(street, i)
					var turn_amount = get_turn_count(find_t_orientation(directions), Directions.keys()[street.main_opening])
					instance.rotation.y = deg_to_rad(turn_amount * street.rotation_amount)
				4: ## Cross	
					var street = neighborhood_res.streets.filter(func(street): return street.street_type == StreetType.CROSS).front()
					var instance = instance_street(street, i)
				_:
					var street = neighborhood_res.streets.filter(func(street): return street.street_type == StreetType.STRAIGHT).front()
					var instance = instance_street(street, i)
		i += 1


func instance_street(street: StreetRes, index: int):
	var instance = street.model.instantiate()
	var cell_pos = get_cell_offset(index)
	instance.position.x = cell_pos.x * neighborhood_res.cell_size
	instance.position.z = cell_pos.y * neighborhood_res.cell_size
	add_child(instance)
	return instance

func get_cell_offset(index: int):
	var x: int = index / grid_width
	var y: int = index % grid_width
	return {
		"x": x,
		"y": y
	}


func get_cell_x_y(index: int) -> Dictionary:
	if index < 0 or index >= grid.size():
		return {"x": -1, "y": -1}

	var x: int = index % grid_width + 1
	var y: int = index / grid_width + 1

	return {
		"x": x,
		"y": y
	}


func get_turn_count(ending_dir: String, connection_dir: String):
	var dir = Directions[ending_dir]
	return dir - Directions[connection_dir] 


func is_corner(dirs: Array[String]) -> bool:
	if dirs.size() != 2:
		return false

	var current: int = Directions[dirs[0]]
	var higher: int = current + 1 if current < 3 else 0
	var lower: int = current - 1 if current > 0 else 3

	if higher == Directions[dirs[1]] or lower == Directions[dirs[1]]:
		return true
	else:
		return false


func find_corner_orientation(dirs: Array[String]):
	if (Directions[dirs[0]] + 3) % 4 == Directions[dirs[1]]:
		return dirs[0]
	else:
		return dirs[1]


func find_t_orientation(dirs: Array[String]):
	var i = 0

	while i < dirs.size():
		var higher_index = i + 1 if i + 1 < dirs.size() else 0
		var lower_index = i - 1 if i - 1 >= 0 else dirs.size() - 1

		var current: int = Directions[dirs[i]]
		var lower: int = (current + 3) % 4
		var higher: int = (current + 1) % 4

		var other_a: int = Directions[dirs[higher_index]]
		var other_b: int = Directions[dirs[lower_index]]

		if (lower == other_a and higher == other_b) or (lower == other_b and higher == other_a):
			return dirs[i]

		i += 1

	return null
