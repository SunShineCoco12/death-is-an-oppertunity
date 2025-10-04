extends VehicleBody3D

@export var engine_power: float = 150.0
@export var speed: float = 0.4
@export var max_steer_degrees: float = 30.0

@onready var wheels: Array[VehicleWheel3D] = [$VehicleWheel3D, $VehicleWheel3D2, $VehicleWheel3D3, $VehicleWheel3D4, $VehicleWheel3D5, $VehicleWheel3D6]
@onready var frontwheels: Array[VehicleWheel3D] = [$VehicleWheel3D3, $VehicleWheel3D4]
@onready var rearwheels: Array[VehicleWheel3D] = [$VehicleWheel3D, $VehicleWheel3D2]
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var shieldbreak: AudioStreamPlayer = $shieldbreak

var target_pos: Vector3
var player_pos: Vector3
var angle_diff: float = 0.0
var laser_disabled: bool = false
var HP: int = 3
var dead: bool = false
var grace_time: float = 3.0

func _ready() -> void:
	$grace_period.start()

func set_target_pos(pos):
	nav_agent.target_position = pos
	player_pos = pos

func _process(delta: float) -> void:
	if HP <= 0 and not dead:
		death()
	if not $grace_period.is_stopped():
		return
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
	$enginewhine.volume_db = -20.0
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
	$tiresrolling.pitch_scale = (collectiverpm / 400) - 0.5
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
			$enginewhine.autoplay = false
			$enginewhine.playing = false
			$tiresrolling.autoplay = false
			$tiresrolling.playing = false
			$body/turrettraverse/lasermod/laser/Node3D/lasersfx.volume_db = -80.0
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
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO
	$body/turrettraverse/lasermod/laser.target = false

func remove_wheel(idx):
	if is_instance_valid(wheels[int(idx) - 1]):
		wheels[int(idx) - 1].queue_free()

func death():
	pass

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
