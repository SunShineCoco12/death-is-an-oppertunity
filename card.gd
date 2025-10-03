extends Node2D

@export var card: Texture2D
@export var icon: Texture2D
@export var cardname: String
@export var textplayer: String
@export var textrover: String

func _ready() -> void:
	name = cardname
	$card.texture = card
	$icon.texture = icon
	$textplayer.text = textplayer
	$textrover.text = textrover
