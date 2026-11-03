class_name HouseRes
extends Resource

@export var house_scene: PackedScene

@export_category("House Materials")
@export var door_material: ShaderMaterial
@export var wall_material: ShaderMaterial
@export var roof_material: ShaderMaterial

@export_category("Material Textures")
@export var wall_texture: Array[MaterialRes]
@export var door_texture: Array[MaterialRes]
@export var roof_texture: Array[MaterialRes]

@export_category("Colors")
@export var wall_colors: Array[Color]
@export var roof_colors: Array[Color]
@export var door_colors: Array[Color]
