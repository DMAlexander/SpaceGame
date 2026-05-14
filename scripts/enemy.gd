extends Area2D

enum State {
	FORMATION,
	TELEGRAPH,
	DIVE,
	RETURN
}

var state: State = State.FORMATION
var dive_target: Vector2 = Vector2.ZERO
var dive_speed: float = 0.0

signal died(position: Vector2, points: int)

@export var max_hp: int = 1
@export var points: int = 10
@export var damage: int = 1
@export var dive_exit_y: float = 900.0
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
##var formation_target: Vector2
var in_position := false

var telegraph_timer: float = 0.0
var formation_target: Vector2 = Vector2.ZERO

@export var telegraph_duration: float = 0.6
@export var telegraph_flash_speed: float = 12.0
@export var chargeback_strength: float = 40.0

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

	match state:

		State.TELEGRAPH:
			_handle_telegraph(delta)
			return

		State.DIVE:

			if global_position.y > dive_exit_y:
				state = State.RETURN
				return

			_handle_dive(delta)
			return

		State.RETURN:
			_handle_return(delta)
			return

	# ---------------- PLAYER CONTACT DAMAGE ----------------

	if player_in_range and is_instance_valid(player_ref):

		damage_timer -= delta

		if damage_timer <= 0.0:
			player_ref.apply_damage(damage, global_position)
			damage_timer = damage_cooldown

	# ---------------- MOVEMENT ----------------

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

func setup_formation(index: int, wave, target: Vector2):
	formation_active = true

	formation_index = index
	formation_speed = wave.formation_speed
	formation_pattern = wave.pattern

	formation_target = target

func update_formation(delta):

	if not in_position:

		var dir: Vector2 = formation_target - global_position

		if dir.length() < 5.0:
			in_position = true
			global_position = formation_target
		else:
			global_position += dir.normalized() * formation_speed * delta

	else:
		# subtle idle float
		global_position.y += sin(
			Time.get_ticks_msec() * 0.002 + formation_index
		) * 0.2

func start_dive(target: Vector2, speed: float):
	state = State.TELEGRAPH

	dive_target = target
	dive_speed = speed

	telegraph_timer = telegraph_duration

func _handle_dive(delta):
	if not is_instance_valid(player_ref):
		queue_free()
		return

	var dir: Vector2 = (dive_target - global_position).normalized()
	global_position += dir * dive_speed * delta

	# Optional: face direction (feels better)
	rotation = dir.angle()
	
func _handle_return(delta):

	var dir: Vector2 = (formation_target - global_position).normalized()

	global_position += dir * formation_speed * 1.5 * delta

	rotation = dir.angle() + PI / 2.0

	# Close enough → resume formation
	if global_position.distance_to(formation_target) < 10.0:
		state = State.FORMATION
		modulate = Color.WHITE

func _handle_telegraph(delta):

	telegraph_timer -= delta

	# Flash effect
	var flash := sin(Time.get_ticks_msec() * 0.02 * telegraph_flash_speed)

	if flash > 0.0:
		modulate = Color.RED
	else:
		modulate = Color.WHITE

	# Pull backward slightly before dive
	var dive_dir: Vector2 = (dive_target - global_position).normalized()
	rotation = dive_dir.angle() + PI / 2.0
	global_position -= dive_dir * chargeback_strength * delta

	# Finished telegraphing
	if telegraph_timer <= 0.0:
		modulate = Color.WHITE
		state = State.DIVE
