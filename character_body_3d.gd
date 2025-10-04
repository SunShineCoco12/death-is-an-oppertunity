extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D
@onready var animp: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast3D = $Camera3D/GunHolder/gun/RayCast3D
@onready var shieldbreak: AudioStreamPlayer = $shieldbreak

var cards: Dictionary = {
	"doublejump_speed" : preload("res://cards/card_doublejump_speed.tscn").instantiate(),
	"invis_reaction" : preload("res://cards/card_invis_reaction.tscn").instantiate(),
	"life_accuracy" : preload("res://cards/card_life_accuracy.tscn").instantiate(),
	"size_speed" : preload("res://cards/card_size_speed.tscn").instantiate(),
	"speed_firerate" : preload("res://cards/card_speed_firerate.tscn").instantiate(),
	"teleport_reaction" : preload("res://cards/card_teleport_reaction.tscn").instantiate(),
	"xray_speed" : preload("res://cards/card_xray_speed.tscn").instantiate(),
}
var cardsbad: Dictionary = {
	"bad_accuracy" : preload("res://cards/card_bad_accuracy.tscn").instantiate(),
	"bad_grace" : preload("res://cards/card_bad_grace.tscn").instantiate(),
	"bad_reaction" : preload("res://cards/card_bad_reaction.tscn").instantiate(),
	"bad_silent" : preload("res://cards/card_bad_silent.tscn").instantiate(),
	"bad_steer" : preload("res://cards/card_bad_steer.tscn").instantiate(),
	"bad_speed" : preload("res://cards/card_bad_speed.tscn").instantiate(),
}
var cardgood = preload("res://cards/card_gun_good.tscn").instantiate()
var sensitivity: float = 0.002
var base_speed: float = 1.5
var max_jumps = 1
var current_jumps = 0
var HP = 100.0
var dead: bool = false
var run: int = 0
var has_teleport_card: bool = false
var has_gun_card: bool = false
var has_life_card: bool = false
var has_life: bool = false
var invistime: float = 0.0
var gun_default_pos: Vector3 = Vector3(0.141, -0.14, -0.22)

func _ready() -> void:
	$"lacebark pine".play()
	AudioServer.set_bus_volume_linear(1, $MainMenu/Panel/MarginContainer/HBoxContainer/Music.value)

func start() -> void:
	$"lacebark pine".stop()
	$rumble.play()
	$survivetimer.start()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("LMB") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		$miscclick.pitch_scale = 0.5
		$miscclick.play()
	if Input.is_action_just_released("LMB") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		$miscclick.pitch_scale = 0.9
		$miscclick.play()
	if Input.is_action_just_pressed("Ctrl") and $invistime.is_stopped() and $inviscooldown.is_stopped() and invistime > 0.0:
		set_collision_layer_value(3, false)
		set_collision_mask_value(3, false)
		$invison.play()
		$invistime.start(invistime)
	if Input.is_action_just_pressed("Esc"):
		get_tree().quit()
	if event is InputEventMouseMotion and not get_tree().paused:
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * sensitivity, -PI/2, PI/2)
		rotation.y -= event.relative.x * sensitivity
		$Camera3D/GunHolder.rotation.x += event.relative.y * 0.0006
		$Camera3D/GunHolder.rotation.y += event.relative.x * 0.0006

func _process(delta: float) -> void:
	if get_tree().paused:
		$UI/crosshair.hide()
		$UI/teleportreloadUI.hide()
		$UI/crosshair.hide()
	else:
		if has_gun_card:
			$UI/crosshair.show()
		if has_teleport_card:
			$UI/teleportreloadUI.show()
			$UI/crosshair.show()
	if get_tree().paused:
		$inviscooldown.stop()
		$invistime.stop()
		return
	if HP <= 0.0 and not dead:
		death()
	if $Camera3D/teleportray.is_colliding():
		$UI/crosshair.modulate = Color.GREEN
	else:
		$UI/crosshair.modulate = Color.WHITE
	# gun handling
	if $Camera3D/gunray.is_colliding():
		$Camera3D/TargetRotation.look_at($Camera3D/gunray.get_collision_point())
	else:
		$Camera3D/TargetRotation.rotation = Vector3.ZERO
	$Camera3D/GunHolder.rotation = lerp($Camera3D/GunHolder.rotation, $Camera3D/TargetRotation.rotation, delta * 5)
	$Camera3D/GunHolder.position += velocity * 0.0005
	$Camera3D/GunHolder.position = lerp($Camera3D/GunHolder.position, gun_default_pos, delta * 5)

	$UI/teleportreloadUI.value = $teleportcooldown.wait_time - $teleportcooldown.time_left
	if has_teleport_card:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			$UI/teleportreloadUI.hide()
			$UI/crosshair.hide()
		else:
			$UI/teleportreloadUI.show()
			$UI/crosshair.show()
	# set teleport progress bar color
	if $UI/teleportreloadUI.value == $teleportcooldown.wait_time:
		var style: StyleBoxFlat = $UI/teleportreloadUI.get_theme_stylebox("fill")
		style.bg_color = Color.GREEN
		$UI/teleportreloadUI.add_theme_stylebox_override("fill", style)
	else:
		var style: StyleBoxFlat = $UI/teleportreloadUI.get_theme_stylebox("fill")
		style.bg_color = Color.RED
		$UI/teleportreloadUI.add_theme_stylebox_override("fill", style)
	# teleport on RMB
	if Input.is_action_just_pressed("RMB") and has_teleport_card and $teleportcooldown.is_stopped():
		if $Camera3D/teleportray.is_colliding():
			global_position = $Camera3D/teleportray.get_collision_point() + Vector3(0.0, ($MeshInstance3D.mesh.height * $MeshInstance3D.scale.y) + 0.1, 0.0)
			$teleportcooldown.start()
	# shoot
	if Input.is_action_pressed("LMB") and $shootcooldown.is_stopped() and has_gun_card:
		$shootcooldown.start()
		$lasershoot.play()
		var laser = preload("res://laser.tscn").instantiate()
		laser.global_transform = $Camera3D/GunHolder.global_transform
		get_tree().root.add_child(laser)
		$Camera3D/GunHolder.rotation_degrees.x += 5
		$Camera3D/GunHolder.position.z += 0.1
		if raycast.is_colliding() and not raycast.get_collider().is_in_group("terrain"):
			animp.play("hit")
			var target = raycast.get_collider()
			var shape_id = raycast.get_collider_shape()
			var owner_id = target.shape_find_owner(shape_id)
			var shape = target.shape_owner_get_owner(owner_id)
			var parts = shape.name.split("_")
			if parts.size() > 1:
				get_tree().call_group("rovers", "remove_wheel", parts[1])
			elif shape.name == "laser":
				get_tree().call_group("rovers", "laser_hit")
			elif shape.name == "Body":
				get_tree().call_group("rovers", "body_hit")
	if not get_tree().paused:
		$UI/timeremaining.text = str(int($survivetimer.time_left - 0.1) + 1)
	else:
		$UI/timeremaining.text = "0"
	# movement
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
		current_jumps = 0
		velocity.x = 0.0
		velocity.z = 0.0
		velocity += strafe * global_transform.basis.x * speed
		velocity += forward * global_transform.basis.z * speed
	if Input.is_action_just_pressed("Space") and current_jumps < max_jumps:
		velocity.y = 3
		current_jumps += 1
	velocity.y -= 9.81 * delta
	move_and_slide()

func death():
	$rumble.stop()
	$hit.play()
	get_tree().paused = true
	dead = true
	animp.play("death")
	await get_tree().create_timer(0.5).timeout
	$"peaceful residence".play()

func disp_cards():
	for i in range(3):
		var idx = randi_range(0, cardsbad.size() - 1)
		await get_tree().create_timer(0.35).timeout
		$UI/HBoxContainer.add_child(cardsbad[cardsbad.keys()[idx]].duplicate())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func disp_cards_good():
	if run < randi_range(1, 1):
		for i in range(3):
			var idx = randi_range(0, cards.size() - 1)
			$UI/HBoxContainer.add_child(cards[cards.keys()[idx]].duplicate())
			await get_tree().create_timer(0.35).timeout
	else:
		for i in range(2):
			var idx = randi_range(0, cards.size() - 1)
			$UI/HBoxContainer.add_child(cards[cards.keys()[idx]].duplicate())
			await get_tree().create_timer(0.35).timeout
		$UI/HBoxContainer.add_child(cardgood.duplicate())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func clicked(cardname: String):
	var parts = cardname.split("_")
	var name = parts[0]
	match name:
		"doublejump":
			max_jumps += 1
		"doublespeed":
			base_speed *= 1.5
		"invis":
			invistime += 2.0
		"life":
			has_life_card = true
			cards.erase("life_accuracy")
		"xray":
			get_tree().call_group("rovers", "xray")
			cards.erase("xray_speed")
		"teleport":
			$UI/crosshair.show()
			$UI/teleportreloadUI.show()
			has_teleport_card = true
			cards.erase("teleport_reaction")
		"size":
			scale *= 0.5
			cards.erase("size_speed")
		"gun":
			$Camera3D/GunHolder.show()
			$Camera3D/GunHolder/gun/RayCast3D.enabled = true
			$UI/crosshair.show()
			has_gun_card = true
		"bad":
			print("bad luck")
		_:
			print("invalid cardname")
	respawn()

func respawn():
	set_collision_layer_value(3, true)
	set_collision_mask_value(3, true)
	$"peaceful residence".stop()
	$rumble.play()
	run += 1
	if has_life_card:
		has_life = true
	get_tree().paused = false
	$survivetimer.start()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	animp.play("RESET")
	dead = false
	HP = 100.0
	var vec2coords = Vector2(randf_range(-25, 25), randf_range(-25, 25))
	var query = PhysicsRayQueryParameters3D.create(Vector3(vec2coords.x, 100, vec2coords.y), Vector3(vec2coords.x, -100, vec2coords.y))
	var ray = get_world_3d().direct_space_state.intersect_ray(query)
	while not ray and not ray["position"]:
		vec2coords = Vector2(randf_range(-25, 25), randf_range(-25, 25))
		query = PhysicsRayQueryParameters3D.create(Vector3(vec2coords.x, 100, vec2coords.y), Vector3(vec2coords.x, -100, vec2coords.y))
		randomize()
	global_position = ray["position"] + Vector3(0.0, 2.0, 0.0)

func timeout():
	$rumble.stop()
	get_tree().paused = true
	animp.play("timeout")
	await get_tree().create_timer(0.5).timeout
	$"peaceful residence".play()


func _on_start_game_button_up() -> void:
	$MainMenu.hide()
	$UI.show()
	get_tree().paused = false
	start()


func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(0, value)


func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(2, value)


func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(1, value)


func _on_help_button_up() -> void:
	$MainMenu/HelpLabel.visible = !$MainMenu/HelpLabel.visible


func _on_invistime_timeout() -> void:
	$inviscooldown.start()
	$invisoff.play()
	set_collision_layer_value(3, true)
	set_collision_mask_value(3, true)

func _on_inviscooldown_timeout() -> void:
	$invisready.play()
	await get_tree().create_timer(0.12).timeout
	$invisready.play()

func erase(key: String):
	cardsbad.erase(str(key))

func win():
	$survivetimer.stop()
	get_tree().paused = true
	$rumble.stop()
	$"rumcherry(reprise)".play()
	$UI.hide()
	$Win.show()


func _on_sensitvity_value_changed(value: float) -> void:
	sensitivity = value * 0.1
