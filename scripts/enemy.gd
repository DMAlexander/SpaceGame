extends Area2D

signal died(position: Vector2, points: int)

@export var max_hp: int = 1
@export var points: int = 10
@export var damage: int = 1

# Optional movement
@export var drift_speed: float = 30.0
var drift_dir: Vector2 = Vector2.ZERO

var hp: int

func _ready():
	add_to_group("enemy")

	hp = max_hp

	# random drift direction
	drift_dir = Vector2.RIGHT.rotated(randf() * TAU)

	monitoring = true
	monitorable = true

	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	global_position += drift_dir * drift_speed * delta

# ---------------- DAMAGE ----------------

func apply_damage(amount: int) -> void:
	hp -= amount

	if hp <= 0:
		die()

# ---------------- COLLISIONS ----------------

func _on_body_entered(body):
	# Damage player on dcontact
	if body.has_method("apply_damage"):
		print('damage', damage)
		body.apply_damage(damage)

func _on_area_entered(area: Area2D) -> void:
	# Laser hit
	if area.is_in_group("laser"):
		apply_damage(1)
		area.queue_free()

# ---------------- DEATH ----------------

func die() -> void:
	emit_signal("died", global_position, points)
	queue_free()
