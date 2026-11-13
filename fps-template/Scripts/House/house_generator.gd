class_name HouseGenerator
extends Node3D

@export var house_res: HouseRes

@export_category("House Generation")

# -1 = random color choices every time this generator starts.
# Any other number = repeatable color choices for this house.
var seed: int

@export var generate_on_ready: bool = true

var rng := RandomNumberGenerator.new()

var wall_colors: Array[Color] = [
	Color("FF3B30"), # bright red
	Color("FF9500"), # orange
	Color("FFCC00"), # yellow
	Color("34C759"), # green
	Color("007AFF"), # blue
	Color("AF52DE"), # purple
	Color("FF2D55"), # pink
	Color("00C7BE")  # cyan
]

var roof_colors: Array[Color] = [
	Color("FF1744"), # vivid red
	Color("FF6D00"), # vivid orange
	Color("FFD600"), # vivid yellow
	Color("00C853"), # vivid green
	Color("2979FF"), # vivid blue
	Color("D500F9"), # vivid purple
	Color("00B8D4")  # vivid cyan
]

var door_colors: Array[Color] = [
	Color("B71C1C"), # dark red
	Color("C75B12"), # orange-brown
	Color("E0A82E"), # mustard yellow
	Color("2E7D32"), # dark green
	Color("1565C0"), # dark blue
	Color("4A2A1B"), # dark brown wood
	Color("F2F0E8")  # off-white
]

func _ready() -> void:
	if generate_on_ready:
		seed = Global.seed
		generate_house()


func generate_house(seed_override: int = -1) -> Node3D:
	if Global.seed == 0:
		print("Seed 0")

	var seed_to_use := seed_override

	if seed_to_use == -1:
		rng.seed = hash(str(Global.seed) + self.name)
	else:
		rng.seed = seed_to_use

	var wall_color := wall_colors[rng.randi_range(0, wall_colors.size() - 1)]
	var roof_color := roof_colors[rng.randi_range(0, roof_colors.size() - 1)]
	var door_color := door_colors[rng.randi_range(0, door_colors.size() - 1)]
	
	var house := house_res.house_scene.instantiate() as Node3D
	house.name = "GeneratedHouse"

	add_child(house)

	var walls := house.find_child("Walls", true, false) as MeshInstance3D
	var roof := house.find_child("Roof", true, false) as MeshInstance3D
	var door := house.find_child("Door", true, false) as MeshInstance3D

	if walls == null:
		push_error(
			"Could not find MeshInstance3D node 'Walls' in TestHouse.glb. " +
			"Ensure the Blender wall object is named exactly Walls."
		)
	else:
		var wall_material := house_res.wall_material.duplicate() as ShaderMaterial

		if house_res.wall_texture.size() > 0:
			var index = rng.randi_range(0, house_res.wall_texture.size() - 1)
			wall_material.set_shader_parameter("diffuse_texture", house_res.wall_texture[index].diffuse)
			wall_material.set_shader_parameter("normal_texture", house_res.wall_texture[index].normal)
			wall_material.set_shader_parameter("roughness_texture", house_res.wall_texture[index].roughness)

		wall_material.set_shader_parameter("texture_tiling", Vector2(4.0, 4.0))
		wall_material.set_shader_parameter("normal_strength", 0.7)
		wall_material.set_shader_parameter("roughness_strength", 1.0)

		wall_material.set_shader_parameter("base_color", wall_color)

		walls.material_override = wall_material

	if roof == null:
		push_error(
			"Could not find MeshInstance3D node 'Roof' in TestHouse.glb. " +
			"Ensure the Blender roof object is named exactly Roof."
		)
	else:
		var roof_surface := find_surface_by_material_name(roof, "M_Roof")

		if roof_surface == -1:
			push_error(
				"Could not find material surface 'M_Roof' on the Roof mesh. " +
				"Check the Blender roof material name, then export TestHouse.glb again."
			)
		else:
			var roof_material := house_res.roof_material.duplicate() as ShaderMaterial

			if house_res.roof_texture.size() > 0:
				var index = rng.randi_range(0, house_res.roof_texture.size() - 1)
				roof_material.set_shader_parameter("diffuse_texture", house_res.roof_texture[index].diffuse)
				roof_material.set_shader_parameter("normal_texture", house_res.roof_texture[index].normal)
				roof_material.set_shader_parameter("roughness_texture", house_res.roof_texture[index].roughness)

			roof_material.set_shader_parameter(
				"texture_tiling",
				Vector2(4.0, 4.0)
			)
			roof_material.set_shader_parameter(
				"normal_strength",
				0.7
			)
			roof_material.set_shader_parameter(
				"roughness_strength",
				1.0
			)

			roof_material.set_shader_parameter(
				"base_color",
				roof_color
			)

			roof.set_surface_override_material(
				roof_surface,
				roof_material
			)

	if door == null:
		push_error(
			"Could not find MeshInstance3D node 'Door' in TestHouse.glb. " +
			"Ensure the Blender door object is named exactly Door."
		)
	else:
		var door_surface := find_surface_by_material_name(door, "M_Door")

		if door_surface == -1:
			push_error(
				"Could not find material surface 'M_Door' on the Door mesh. " +
				"Confirm the Blender material slot is named M_Door and re-export TestHouse.glb."
			)
		else:
			var door_material := house_res.door_material.duplicate() as ShaderMaterial

			if house_res.door_texture.size() > 0:
				var index = rng.randi_range(0, house_res.door_texture.size() - 1)
				door_material.set_shader_parameter("diffuse_texture", house_res.door_texture[index].diffuse)
				door_material.set_shader_parameter("normal_texture", house_res.door_texture[index].normal)
				door_material.set_shader_parameter("roughness_texture", house_res.door_texture[index].roughness)

			door_material.set_shader_parameter(
				"base_color",
				door_color
			)

			door.set_surface_override_material(
				door_surface,
				door_material
			)

	return house


func clear_generated_house() -> void:
	var old_house := get_node_or_null("GeneratedHouse")

	if old_house != null:
		old_house.queue_free()


func find_surface_by_material_name(
	mesh_instance: MeshInstance3D,
	material_name: String
) -> int:
	for surface_index in range(mesh_instance.mesh.get_surface_count()):
		var surface_material := mesh_instance.mesh.surface_get_material(surface_index)

		if surface_material != null and surface_material.resource_name == material_name:
			return surface_index

	return -1
