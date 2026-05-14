extends Area2D

signal died(position: Vector2, points: int)

@export var max_hp: int = 1
@export var points: int = 10
@export var damage: int = 1

# Optional movement
@export var drift_speed: float = 30.0
var drift_dir: Vector2 = Vector2.ZERO

var hp: int

var damage_cooldown := 0.5
var damage_timer := 0.0
var player_in_range := false
var player_ref = null

var float_text_scene = preload("res://scenes/score_popup/score_popup.tscn")

var formation_active := false
var formation_index := 0
var formation_speed := 100.0
var formation_center := Vector2.ZERO

var formation_pattern: int
var formation_target: Vector2
var in_position := false


func _ready():
	add_to_group("enemy")

	hp = max_hp

	# random drift direction
	drift_dir = Vector2.RIGHT.rotated(randf() * TAU)

	monitoring = true
	monitorable = true

	connect("area_entered", _on_area_entered)
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _physics_process(delta):
	if player_in_range and is_instance_valid(player_ref):
		damage_timer -= delta
		
		if damage_timer <= 0.0:
			player_ref.apply_damage(damage, global_position)
			damage_timer = damage_cooldown

	if formation_active:
		update_formation(delta)
	else:
		# fallback drift
		global_position += drift_dir * drift_speed * delta

# ---------------- DAMAGE ----------------

func apply_damage(amount: int) -> void:
	hp -= amount

	if hp <= 0:
		die()

# ---------------- COLLISIONS ----------------

func _on_body_entered(body):
	if body.has_method("apply_damage"):
		player_in_range = true
		player_ref = body

func _on_body_exited(body):
	if body == player_ref:
		player_in_range = false
		player_ref = null

func _on_area_entered(area: Area2D) -> void:
	# Laser hit
	if area.is_in_group("laser"):
		apply_damage(1)
		area.queue_free()

# ---------------- DEATH ----------------

func die() -> void:
	emit_signal("died", global_position, points)
	queue_free()

func setup_formation(index: int, wave):
	formation_active = true
	formation_index = index
	formation_speed = wave.formation_speed
	formation_pattern = wave.pattern

func update_formation(delta):
	if not in_position:
		var dir = formation_target - global_position
		
		if dir.length() < 5.0:
			in_position = true
		else:
			global_position += dir.normalized() * formation_speed * delta
	else:
		# slight idle motion (optional polish)
		global_position.y += sin(Time.get_ticks_msec() * 0.002 + formation_index) * 0.2
