extends Interactable


@export var package_res: PackageRes
@onready var mp_spawner = get_tree().get_first_node_in_group(
    "object_spawner"
)

func interact(player: Player = null):
	player.pickup_package(package_res)
	mp_spawner.request_delete_object(self)


func interact_ready():
	var instance = get_instance()
	add_child(instance)


func get_instance():
	var scene := load(package_res.model_path) as PackedScene
	return scene.instantiate()
