extends Area2D

signal died(position: Vector2, points: int)

@export var hp: int = 1
@export var points: int = 10

# Optional movement (very simple drift)
@export var drift_speed: float = 30.0
var drift_dir: Vector2 = Vector2.ZERO

func _ready():
	add_to_group("enemy")

	# random drift direction (optional feel)
	drift_dir = Vector2.RIGHT.rotated(randf() * TAU)

	# IMPORTANT: ensure collision works
	monitoring = true
	monitorable = true

	connect("area_entered", _on_area_entered)


func _physics_process(delta):
	# Optional slow drift so enemies aren't static
	global_position += drift_dir * drift_speed * delta


func _on_area_entered(area: Area2D) -> void:
	# Flexible hit detection (works with groups OR naming)
	if area.is_in_group("laser") or area.name == "Laser":
		take_damage(1)
		area.queue_free()


func take_damage(amount: int) -> void:
	hp -= amount

	if hp <= 0:
		die()


func die() -> void:
	emit_signal("died", global_position, points)
	queue_free()
