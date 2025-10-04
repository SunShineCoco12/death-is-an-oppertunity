extends Control

@export var card: Texture2D
@export var icon: Texture2D
@export var cardname: String
@export var textplayer: String
@export var textrover: String
@onready var animp: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	name = cardname
	$card.texture = card
	$icon.texture = icon
	$textplayer.text = textplayer
	$textrover.text = textrover
	animp.play("turn")


func _on_button_button_up() -> void:
	get_tree().call_group("players", "clicked", cardname)
	get_tree().call_group("rovers", "clicked", cardname)
	get_tree().call_group("cards", "reset")

func reset():
	queue_free()
