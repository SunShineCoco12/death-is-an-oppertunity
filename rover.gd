extends VehicleBody3D

@export var engine_power: float = 100.0
@export var speed: float = 0.2
@export var max_steer_degrees: float = 45.0

@onready var wheels: Array[VehicleWheel3D] = [$VehicleWheel3D, $VehicleWheel3D2, $VehicleWheel3D3, $VehicleWheel3D4, $VehicleWheel3D5, $VehicleWheel3D6]
@onready var frontwheels: Array[VehicleWheel3D] = [$VehicleWheel3D3, $VehicleWheel3D4]
@onready var rearwheels: Array[VehicleWheel3D] = [$VehicleWheel3D, $VehicleWheel3D2]
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var target_pos: Vector3
var player_pos: Vector3
var angle_diff: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_target_pos(pos):
	nav_agent.target_position = pos
	player_pos = pos

func _process(delta: float) -> void:
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
	var input_vec3: Vector3 = Vector3((target_pos - global_position).x, 0.0, (target_pos - global_position).z)
	var input_forward: Vector3 = -global_transform.basis.z
	input_forward.y = 0.0
	angle_diff = (input_forward).signed_angle_to(input_vec3, Vector3.DOWN)
	for wheel in wheels:
		wheel.engine_force = power * -1.0
	for frontwheel in frontwheels:
		frontwheel.steering = clampf(lerpf(frontwheel.steering, -angle_diff, delta * 5), deg_to_rad(-max_steer_degrees), deg_to_rad(max_steer_degrees))
	for rearwheel in rearwheels:
		rearwheel.steering = -clampf(-angle_diff, deg_to_rad(-max_steer_degrees* 0.5), deg_to_rad(max_steer_degrees * 0.5))
