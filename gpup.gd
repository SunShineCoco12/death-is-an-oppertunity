extends GPUParticles3D

func _ready() -> void:
	$"../GPUParticles3D2".emitting = true
	emitting = true
	$"../GPUParticles3D3".emitting = true
	await get_tree().process_frame
	emitting = false
	$"../GPUParticles3D3".emitting = false
