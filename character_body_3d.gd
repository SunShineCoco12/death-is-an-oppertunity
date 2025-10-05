extends CharacterBody3D

@onready var camera: Camera3D = $Camera3D
@onready var animp: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast3D = $Camera3D/GunHolder/gun/RayCast3D
@onready var shieldbreak: AudioStreamPlayer = $shieldbreak
@onready var bus = preload("uid://c7lcjmtc7tdaq")
@onready var laserscene = preload("res://laser.tscn")
@onready var survivetimer: Timer = $survivetimer
@onready var miscclick: AudioStreamPlayer = $miscclick
@onready var gunholder: Node3D = $Camera3D/GunHolder
@onready var crosshair: TextureRect = $UI/crosshair
@onready var gunray: RayCast3D = $Camera3D/gunray
@onready var targetrotation: Node3D = $Camera3D/TargetRotation

@export var sfxbusaudio: float = 1.0

var cards: Dictionary = {
	"doublejump_speed" : preload("res://cards/card_doublejump_speed.tscn"),
	"invis_reaction" : preload("res://cards/card_invis_reaction.tscn"),
	"life_accuracy" : preload("res://cards/card_life_accuracy.tscn"),
	"size_speed" : preload("res://cards/card_size_speed.tscn"),
	"speed_firerate" : preload("res://cards/card_speed_firerate.tscn"),
	"teleport_reaction" : preload("res://cards/card_teleport_reaction.tscn"),
	"xray_speed" : preload("res://cards/card_xray_speed.tscn"),
	"speed_good" : preload("res://cards/card_speed_good.tscn"),
	"life_reaction" : preload("res://cards/card_life_reaction.tscn"),
	"teleport_speed" : preload("res://cards/card_teleport_speed.tscn"),
	"time_firerate" : preload("res://cards/card_time_firerate.tscn"),
	"xray_reaction" : preload("res://cards/card_xray_reaction.tscn"),
	"invis_firerate" : preload("res://cards/card_invis_firerate.tscn"),
	"size_grace" : preload("res://cards/card_size_grace.tscn"),
	"doublejump_steer" : preload("res://cards/card_doublejump_steer.tscn"),
	"size_good" : preload("res://cards/card_size_good.tscn"),
	"invis_grace" : preload("res://cards/card_invis_grace.tscn"),
	"xray_accuracy" : preload("res://cards/card_xray_accuracy.tscn"),
	"life_speed" : preload("res://cards/card_life_speed.tscn"),
}
var cardsbad: Dictionary = {
	"bad_accuracy" : preload("res://cards/card_bad_accuracy.tscn"),
	"bad_grace" : preload("res://cards/card_bad_grace.tscn"),
	"bad_reaction" : preload("res://cards/card_bad_reaction.tscn"),
	"bad_silent" : preload("res://cards/card_bad_silent.tscn"),
	"bad_steer" : preload("res://cards/card_bad_steer.tscn"),
	"bad_speed" : preload("res://cards/card_bad_speed.tscn"),
}
var cardgood = preload("res://cards/card_gun_good.tscn")
var sensitivity: float = 0.002
var base_speed: float = 2.0
var max_jumps = 1
var current_jumps = 0
var dead: bool = false
var run: int = 0
var HP = 100.0
var has_teleport_card: bool = false
var has_gun_card: bool = false
var has_life_card: bool = false
var has_life: bool = false
var won: bool = false
var invistime: float = 0.0
var playtime_multiplier: float = 2.0
var gun_default_pos: Vector3 = Vector3(0.141, -0.14, -0.22)
var collided_last_frame: bool = false
var last_mouse_mode
var mouse_mode_changed: bool = false

func _ready() -> void:
	AudioServer.set_bus_layout(bus)
	$"lacebark pine".play()
	AudioServer.set_bus_volume_linear(1, $MainMenu/Panel/MarginContainer/HBoxContainer/Music.value)

func start() -> void:
	$"lacebark pine".stop()
	$rumble.call_deferred("play")
	survivetimer.start()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	last_mouse_mode = Input.mouse_mode

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("LMB") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		miscclick.pitch_scale = 0.5
		miscclick.play()
	if Input.is_action_just_released("LMB") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		miscclick.pitch_scale = 0.9
		miscclick.play()
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
		gunholder.rotation.x += event.relative.y * 0.0006
		gunholder.rotation.y += event.relative.x * 0.0006

func _process(delta: float) -> void:
	if Input.mouse_mode != last_mouse_mode:
		mouse_mode_changed = true
	if won:
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("sfx"), $MainMenu/Panel/MarginContainer/HBoxContainer/SFX.value * sfxbusaudio)
	if get_tree().paused:
		$inviscooldown.stop()
		$invistime.stop()
		return
	if HP <= 0.0 and not dead:
		death()
	if has_teleport_card and $Camera3D/teleportray.is_colliding():
		if not collided_last_frame:
			crosshair.modulate = Color.RED
		collided_last_frame = true
	elif collided_last_frame:
		crosshair.modulate = Color.WHITE
		collided_last_frame = false
	# gun handling
	if gunray.is_colliding():
		targetrotation.look_at(gunray.get_collision_point())
	else:
		targetrotation.rotation = Vector3.ZERO
	gunholder.rotation = lerp(gunholder.rotation, targetrotation.rotation, delta * 20)
	gunholder.global_position += velocity * -0.0005
	gunholder.position = lerp(gunholder.position, gun_default_pos, delta * 5)

	$UI/teleportreloadUI.value = $teleportcooldown.wait_time - $teleportcooldown.time_left
	if has_teleport_card and mouse_mode_changed:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			$UI/teleportreloadUI.hide()
			crosshair.hide()
		else:
			$UI/teleportreloadUI.show()
			crosshair.show()
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
		$AnimationPlayer2.play("reload")
		$lasershoot.play()
		var laser = laserscene.instantiate()
		laser.global_transform = gunholder.global_transform
		get_tree().root.add_child(laser)
		gunholder.rotation_degrees.x += 5
		gunholder.position.z += 0.1
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
		$UI/timeremaining.text = str(int(survivetimer.time_left - 0.1) + 1)
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
		velocity += (strafe * global_transform.basis.x * speed) / scale.length()
		velocity += (forward * global_transform.basis.z * speed) / scale.length()
	if Input.is_action_just_pressed("Space") and current_jumps < max_jumps:
		velocity.y = 3
		current_jumps += 1
	velocity.y -= 9.81 * delta
	move_and_slide()

func death():
	$rumble.stop()
	$hit.play()
	get_tree().paused = true
	crosshair.hide()
	$UI/teleportreloadUI.hide()
	crosshair.hide()
	dead = true
	animp.play("death")
	await get_tree().create_timer(0.5).timeout
	$"peaceful residence".play()

func disp_cards():
	var indices: Array = []
	for i in range(3):
		var idx = randi_range(0, cardsbad.size() - 1)
		while idx in indices:
			idx = randi_range(0, cardsbad.size() - 1)
		indices.append(idx)
		await get_tree().create_timer(0.35).timeout
		$UI/HBoxContainer.add_child(cardsbad[cardsbad.keys()[idx]].instantiate())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	last_mouse_mode = Input.mouse_mode


func disp_cards_good():
	if run < randi_range(8 * playtime_multiplier, 16 * playtime_multiplier):
		var indices: Array = []
		for i in range(3):
			var idx = randi_range(0, cards.size() - 1)
			while idx in indices:
				idx = randi_range(0, cards.size() - 1)
			$UI/HBoxContainer.add_child(cards[cards.keys()[idx]].instantiate())
			await get_tree().create_timer(0.35).timeout
	else:
		for i in range(2):
			var idx = randi_range(0, cards.size() - 1)
			$UI/HBoxContainer.add_child(cards[cards.keys()[idx]].instantiate())
			await get_tree().create_timer(0.35).timeout
		$UI/HBoxContainer.add_child(cardgood.instantiate())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	last_mouse_mode = Input.mouse_mode

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
			for key in cards.keys():
				var part = key.split("_")[0]
				if part == "life":
					cards.erase(str(key))
		"xray":
			get_tree().call_group("rovers", "xray")
			for key in cards.keys():
				var part = key.split("_")[0]
				if part == "xray":
					cards.erase(str(key))
		"teleport":
			crosshair.show()
			$UI/teleportreloadUI.show()
			has_teleport_card = true
			for key in cards.keys():
				var part = key.split("_")[0]
				if part == "teleport":
					cards.erase(str(key))
		"size":
			scale *= 0.5
			for key in cards.keys():
				var part = key.split("_")[0]
				if part == "size":
					cards.erase(str(key))
		"gun":
			gunholder.show()
			$Camera3D/GunHolder/gun/RayCast3D.enabled = true
			crosshair.show()
			has_gun_card = true
		"time":
			survivetimer.wait_time -= 5.0
			if survivetimer.wait_time == 25.0:
				for key in cards.keys():
					var part = key.split("_")[0]
					if part == "time":
						cards.erase(str(key))
		"bad":
			print("bad luck")
		_:
			print("invalid cardname")
	respawn()

func respawn():
	set_collision_layer_value(3, true)
	set_collision_mask_value(3, true)
	$"peaceful residence".stop()
	if has_gun_card:
		$chalksnap.play()
	else:
		$rumble.play()
	run += 1
	if has_life_card:
		has_life = true
	get_tree().paused = false
	if has_gun_card:
		crosshair.show()
	if has_teleport_card:
		$UI/teleportreloadUI.show()
		crosshair.show()
	if not has_gun_card:
		survivetimer.start()
	else:
		$UI/timeremaining.text = "-1"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	last_mouse_mode = Input.mouse_mode
	animp.play("RESET")
	HP = 100.0
	dead = false
	var vec2coords = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	var query = PhysicsRayQueryParameters3D.create(Vector3(vec2coords.x, 100, vec2coords.y), Vector3(vec2coords.x, -100, vec2coords.y))
	var ray = get_world_3d().direct_space_state.intersect_ray(query)
	while not ray and not ray["position"]:
		vec2coords = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		query = PhysicsRayQueryParameters3D.create(Vector3(vec2coords.x, 100, vec2coords.y), Vector3(vec2coords.x, -100, vec2coords.y))
		randomize()
	global_position = ray["position"] + Vector3(0.0, 2.0, 0.0)

func timeout():
	$rumble.stop()
	get_tree().paused = true
	crosshair.hide()
	$UI/teleportreloadUI.hide()
	crosshair.hide()
	animp.play("timeout")
	await get_tree().create_timer(0.5).timeout
	$"peaceful residence".play()


func _on_start_game_button_up() -> void:
	$MainMenu.hide()
	$UI.show()
	get_tree().paused = false
	start()

func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)

func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("sfx"), value)

func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), value)

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

func erase(name: String):
	for key in cardsbad.keys():
		var part = key.split("_")[1]
		if part == str(name):
			cards.erase(str(key))

func win():
	won = true
	animp.stop()
	animp.play("win")
	survivetimer.stop()
	$"rumcherry(reprise)".play()
	await get_tree().create_timer(11.0).timeout
	get_tree().paused = true


func _on_sensitvity_value_changed(value: float) -> void:
	sensitivity = value * 0.1


func _on_playtime_value_changed(value: float) -> void:
	playtime_multiplier = value

func _on_chalksnap_finished() -> void:
	$chalksnap.play()


func _on_rumble_finished() -> void:
	$rumble.play()
