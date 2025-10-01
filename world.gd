extends Node3D

@export var mouse_sensitivity: float = 0.002
@export var camera_offset: Vector3 = Vector3(0.0, 1.0, 0.0)

func _process(delta: float) -> void:
	$CameraHolder.global_position = $Rover.global_position + camera_offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		$CameraHolder.rotation.x += event.relative.y * mouse_sensitivity
		$CameraHolder.rotation.y -= event.relative.x * mouse_sensitivity
