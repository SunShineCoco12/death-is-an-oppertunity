extends Node3D

func _process(delta: float) -> void:
	$Rover.set_target_pos($CharacterBody3D.global_position)
