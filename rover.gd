extends VehicleBody3D

@export var engine_power: float = 150.0
@export var speed: float = 0.4
@export var max_steer_degrees: float = 30.0

@onready var wheels: Array[VehicleWheel3D] = [$VehicleWheel3D, $VehicleWheel3D2, $VehicleWheel3D3, $VehicleWheel3D4, $VehicleWheel3D5, $VehicleWheel3D6]
@onready var frontwheels: Array[VehicleWheel3D] = [$VehicleWheel3D3, $VehicleWheel3D4]
@onready var rearwheels: Array[VehicleWheel3D] = [$VehicleWheel3D, $VehicleWheel3D2]
@onready var wheel_colliders: Array[CollisionShape3D] = [$Wheel_1, $Wheel_2, $Wheel_3, $Wheel_4, $Wheel_5, $Wheel_6]
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var shieldbreak: AudioStreamPlayer = $shieldbreak

var target_pos: Vector3
var player_pos: Vector3
var angle_diff: float = 0.0
var laser_disabled: bool = false
var silent = false
var HP: int = 5
var dead: bool = false
var grace_time: float = 3.0
var reset_state = false

func _ready() -> void:
	$grace_period.start()

func set_target_pos(pos):
	nav_agent.target_position = pos
	player_pos = pos

func _integrate_forces(state):
	if reset_state:
		state.transform = Transform3D(Basis(), Vector3.ZERO)
		reset_state = false

func _process(delta: float) -> void:
	if not $grace_period.is_stopped() or dead:
		return

	if linear_velocity.length() < 0.2:
		if $reversetimer.is_stopped() and $reversetimercooldown.is_stopped():
			$reversetimer.start()
	else:
		$reversetimer.stop()
	if HP == 4:
		$GPUParticles3D.emitting = true
	elif HP == 2:
		$GPUParticles3D.amount_ratio = 1.0
		$GPUParticles3D3.emitting = true
	if HP <= 0 and not dead:
		death()
	if not laser_disabled:
		$body/turrettraverse/lasermod/laser/playerdetect.look_at(player_pos)
		if $body/turrettraverse/lasermod/laser.target:
			$body/turrettraverse.look_at_from_position($body/turrettraverse/lasermod/laser.global_position, player_pos)
			$body/turrettraverse.position = Vector3(0.024, 1.31, -0.374)
			$body/turrettraverse.rotation.x = 0
			$body/turrettraverse.rotation.z = 0
			$body/turrettraverse/lasermod.look_at_from_position($body/turrettraverse/lasermod/laser.global_position, player_pos)
			$body/turrettraverse/lasermod.position = Vector3.ZERO
			$body/turrettraverse/lasermod.rotation.z = 0
			$body/turrettraverse/lasermod.rotation.y = 0
		else:
			$body/turrettraverse.rotation = Vector3.ZERO
			$body/turrettraverse/lasermod.rotation = Vector3.ZERO
	target_pos = nav_agent.get_next_path_position()
	var power = engine_power * clampf((speed / linear_velocity.length()), 0.001, 100.0)
	$enginewhine.volume_db = -15.0
	$enginewhine.pitch_scale = clampf((power / engine_power) * 2, 0.3, 1.75)
	var input_vec3: Vector3 = Vector3((target_pos - global_position).x, 0.0, (target_pos - global_position).z)
	var input_forward: Vector3 = -global_transform.basis.z
	input_forward.y = 0.0
	angle_diff = (input_forward).signed_angle_to(input_vec3, Vector3.DOWN)
	var collectiverpm: float
	for wheel in wheels:
		if is_instance_valid(wheel):
			wheel.engine_force = power * -1.0
			collectiverpm -= wheel.get_rpm()
	$tiresrolling.pitch_scale = clampf((collectiverpm / 400) - 0.5, 0.1, 2.0)
	$tiresrolling.volume_db = -20.0 + ((collectiverpm / 400) - 0.5) * 5
	for frontwheel in frontwheels:
		if is_instance_valid(frontwheel):
			frontwheel.steering = clampf(lerpf(frontwheel.steering, -angle_diff, delta * 5), deg_to_rad(-max_steer_degrees), deg_to_rad(max_steer_degrees))
	for rearwheel in rearwheels:
		if is_instance_valid(rearwheel):
			rearwheel.steering = -clampf(-angle_diff, deg_to_rad(-max_steer_degrees* 0.5), deg_to_rad(max_steer_degrees * 0.5))


func clicked(cardname: String):
	var parts = cardname.split("_")
	var name = parts[1]
	match name:
		"speed":
			engine_power *= 2.0
			speed *= 1.1
		"firerate":
			$body/turrettraverse/lasermod/laser/cooldown.wait_time /= 1.5
		"reaction":
			$body/turrettraverse/lasermod/laser/acquiretime.wait_time *= 0.5
		"accuracy":
			$body/turrettraverse/lasermod/laser.spread *= 0.5
		"grace":
			grace_time *= 0.5
		"silent":
			$body/turrettraverse/lasermod/laser/Node3D/lasersfx.process_mode = Node.PROCESS_MODE_DISABLED
			$body/turrettraverse/lasermod/laser/Node3D/target.process_mode = Node.PROCESS_MODE_DISABLED
			$enginewhine.process_mode = Node.PROCESS_MODE_DISABLED
			$tiresrolling.process_mode = Node.PROCESS_MODE_DISABLED
			get_tree().call_group("players", "erase", "bad_silent")
		"steer":
			max_steer_degrees = 45.0
			get_tree().call_group("players", "erase", "bad_steer")
		"good":
			print("good luck")
		_:
			print("invalid name")
	respawn()

func respawn():
	$grace_period.start(grace_time)
	global_transform = Transform3D(Basis(), Vector3.ZERO)
	reset_state = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	$body/turrettraverse/lasermod/laser.target = false

func remove_wheel(idx):
	if is_instance_valid(wheels[int(idx) - 1]):
		wheels[int(idx) - 1].queue_free()

func death():
	for wheel in wheels:
		if is_instance_valid(wheel):
			wheel.queue_free()
	for wheel_collider in wheel_colliders:
		wheel_collider.queue_free()
	dead = true
	$GPUParticles3D3.amount_ratio = 1.0
	$GPUParticles3D2.emitting = true
	get_tree().call_group("players", "win")

func laser_hit():
	laser_disabled = true

func body_hit():
	HP -= 1

func xray():
	var mesh: ArrayMesh = $body.mesh
	if mesh:
		for i in range(mesh.get_surface_count()):
			var mat: Material = mesh.surface_get_material(i)
			mat.next_pass = load("uid://c3i2rmwcua8uq")
			mesh.surface_set_material(i, mat)


func _on_reversetimer_timeout() -> void:
	print("yes")
	engine_power = -engine_power
	max_steer_degrees = -max_steer_degrees
	await get_tree().create_timer(2.0).timeout
	engine_power = -engine_power
	max_steer_degrees = -max_steer_degrees
	$reversetimercooldown.start()


func _on_enginewhine_finished() -> void:
	$enginewhine.play()


func _on_tiresrolling_finished() -> void:
	$tiresrolling.play()
