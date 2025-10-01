extends VehicleBody3D

@export var engine_power: float = 20.0
@export var max_steer_degrees: float = 17.5

@onready var wheels: Array[VehicleWheel3D] = [$VehicleWheel3D, $VehicleWheel3D2, $VehicleWheel3D3, $VehicleWheel3D4, $VehicleWheel3D5, $VehicleWheel3D6]
@onready var frontwheels: Array[VehicleWheel3D] = [$VehicleWheel3D3, $VehicleWheel3D4]

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Esc"):
		get_tree().quit()
	var forward = Input.get_axis("W", "S")
	var steer = Input.get_axis("D", "A")

	for wheel in wheels:
		wheel.engine_force = engine_power * forward
	for frontwheel in frontwheels:
		frontwheel.steering = deg_to_rad(max_steer_degrees) * steer
