extends Area2D

@export var speed := 2000.0
@export var lifetime := 0.5

var dir: Vector2

var damage: int = 1

func _ready():
	add_to_group("laser")
	connect("body_entered", _on_hit)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	position += dir * speed * delta

func _on_hit(body):
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
	queue_free()
