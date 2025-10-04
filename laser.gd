extends RayCast3D

@onready var mesh: MeshInstance3D = $Node3D/MeshInstance3D
@onready var playerray: RayCast3D = $playerdetect

var distance: float
var target: bool = false
var spread = 0.075

func _process(delta: float) -> void:
	if not $"../../../../grace_period".is_stopped():
		return
	if is_colliding() and get_collider().is_in_group("players"):
		if $cooldown.is_stopped() and target:
			rotation = Vector3(randf_range(-spread, spread), randf_range(-spread, spread), 0.0)
			force_raycast_update()
			fire(get_collider())
	if playerray.is_colliding():
		if playerray.get_collider().is_in_group("players"):
			if not target and $acquiretime.is_stopped():
				$acquiretime.start()
			$losetime.stop()
		else:
			$acquiretime.stop()
			if $losetime.is_stopped():
				$losetime.start()
	else:
		$acquiretime.stop()
		if $losetime.is_stopped():
			$losetime.start()

func fire(player):
	$Node3D/lasersfx.play()
	if player and "HP" in player:
		if not player.has_life:
			player.HP -= 100.0
		else:
			player.has_life = false
			player.shieldbreak.play()
		print("die")
	distance = (global_position - get_collision_point()).length()
	mesh.mesh.size = Vector3(0.02, distance, 0.02)
	mesh.position = Vector3(0.0, 0.0, -distance/2)
	$AnimationPlayer.play("fire")
	$cooldown.start()

func _on_acquiretime_timeout() -> void:
	target = true


func _on_losetime_timeout() -> void:
	target = false

func resetrot():
	rotation = Vector3.ZERO
