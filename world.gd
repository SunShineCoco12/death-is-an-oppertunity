extends Node3D

func _ready() -> void:
	get_tree().paused = true

func _process(delta: float) -> void:
	$Rover.set_target_pos($CharacterBody3D.camera.global_position)
