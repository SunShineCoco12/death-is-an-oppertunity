extends Control

@export var card: Texture2D
@export var icon: Texture2D
@export var cardname: String
@export var textplayer: String
@export var textrover: String

@onready var animp: AnimationPlayer = $AnimationPlayer
@onready var button: Button = $Button
@onready var textplayerlabel: Label = $textplayer
@onready var textroverlabel: Label = $textrover
@onready var labelsettingsplayer = preload("uid://c1dabc5ghihal")
@onready var labelsettingsrover = preload("uid://f3xovpc3xmmq")

func _ready() -> void:
	textplayerlabel.label_settings = labelsettingsplayer
	textroverlabel.label_settings = labelsettingsrover
	name = cardname
	$card.texture = card
	$icon.texture = icon
	$textplayer.text = textplayer
	$textrover.text = textrover
	animp.play("turn")
	button.button_down.connect(on_button_button_down)

func on_button_button_down():
	scale = Vector2(0.9, 0.9)

func _on_button_button_up() -> void:
	get_tree().call_group("players", "clicked", cardname)
	get_tree().call_group("rovers", "clicked", cardname)
	get_tree().call_group("cards", "reset")
	scale = Vector2(1.0, 1.0)

func reset():
	queue_free()
