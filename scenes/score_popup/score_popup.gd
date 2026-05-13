extends Node2D

@onready var label: Label = get_node("Label")

var velocity := Vector2.UP * 40.0
var life := 0.8

func setup(text: String, color := Color.WHITE):
	label.text = text
	label.modulate = color

func _process(delta):
	global_position += velocity * delta
	life -= delta
	modulate.a = life / 0.8

	if life <= 0:
		queue_free()
