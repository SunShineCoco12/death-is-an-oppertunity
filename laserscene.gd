extends RayCast3D

@onready var mesh: MeshInstance3D = $MeshInstance3D

var distance: float

func _ready():
	if is_colliding():
		distance = (global_position - get_collision_point()).length()
	else:
		distance = target_position.length()
	mesh.mesh.size = Vector3(0.1, distance, 0.1)
	mesh.position = Vector3(0.0, 0.0, -distance/2)
	await get_tree().create_timer(0.1).timeout
	queue_free()
