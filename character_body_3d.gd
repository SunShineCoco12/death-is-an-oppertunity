extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D

var sensitivity: float = 0.002
var base_speed: float = 1.5
var HP = 100.0

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Esc"):
		get_tree().quit()
	if event is InputEventMouseMotion:
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -PI/2, PI/2)
		rotation.y -= event.relative.x * sensitivity

func _process(delta: float) -> void:
	var speed: float

	var forward = Input.get_axis("W", "S")
	var strafe = Input.get_axis("A", "D")
	if Input.is_action_pressed("Shift") and forward < 0:
		speed = base_speed * 2
		camera.fov = lerpf(camera.fov, 90.0, delta * 8)
	else:
		speed = base_speed
		camera.fov = lerpf(camera.fov, 75.0, delta * 8)
	if is_on_floor():
		velocity.x = 0.0
		velocity.z = 0.0
		velocity += strafe * global_transform.basis.x * speed
		velocity += forward * global_transform.basis.z * speed
		if Input.is_action_just_pressed("Space"):
			velocity.y = 3
	velocity.y -= 9.81 * delta
	move_and_slide()

func death():
	pass
