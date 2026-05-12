extends Area2D

@export var speed: float = 2000.0
@export var lifetime: float = 0.5

var dir: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("laser")
	connect("area_entered", _on_hit)

	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	global_position += dir * speed * delta

func _on_hit(area):
	queue_free()
