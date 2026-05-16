extends Node2D

var radius := 220.0
var lifetime := 0.25

func _ready():
	queue_redraw()

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _draw():
	draw_circle(Vector2.ZERO, radius, Color(1, 0.2, 0.2, 0.35))
