extends CharacterBody2D

signal shot_fired(origin, direction, damage)
signal health_changed(current, max)
signal died
signal boost_changed(value: float)
signal speed_changed(value: float)

enum ControlMode {
	FREE_ROAM,
	ARCADE
}

@export var thrust := 900.0
@export var max_speed := 420.0
@export var damping := 0.985
@export var rotation_speed := 4.0
@export var base_fire_rate := 8.0
@export var base_max_health := 5

var fire_rate: float
var max_health: int
var health: int

@export var boost_multiplier := 1.8
@export var boost_drain := 0.8
@export var boost_recharge := 0.4
var boost_energy := 1.0

@export var brake_damping := 0.92
@export var lateral_damping := 0.85

@export var invuln_duration := 0.6
var invuln_timer := 0.0
var is_invulnerable := false

var vel: Vector2 = Vector2.ZERO
var fire_cd := 0.0

var control_mode: ControlMode = ControlMode.FREE_ROAM

@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: Sprite2D = $Sprite2D


# --------------------------------------------------
# INIT
# --------------------------------------------------

func _ready():
	refresh_run_stats()

	health = max_health
	emit_signal("health_changed", health, max_health)
	emit_signal("boost_changed", boost_energy)


func set_control_mode(mode: ControlMode) -> void:
	control_mode = mode
	vel = Vector2.ZERO
	velocity = Vector2.ZERO


# --------------------------------------------------
# MAIN LOOP
# --------------------------------------------------

func _physics_process(delta: float) -> void:

	match control_mode:
		ControlMode.FREE_ROAM:
			_handle_movement(delta)
			velocity = vel
			move_and_slide()

		ControlMode.ARCADE:
			_handle_arcade_movement(delta)

	_handle_shooting(delta)

	emit_signal("speed_changed", vel.length())
	_handle_invulnerability(delta)


# --------------------------------------------------
# ARCADE MOVEMENT (CLEANED)
# --------------------------------------------------

func _handle_arcade_movement(delta):

	var input_dir := Vector2.ZERO

	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	input_dir = input_dir.normalized()

	# movement
	var move := input_dir * max_speed
	global_position += move * delta
	vel = move

	# always face up
	rotation = 0.0

	# bounds
	var bounds = get_play_bounds()
	global_position.x = clamp(global_position.x, bounds.min.x, bounds.max.x)
	global_position.y = clamp(global_position.y, bounds.min.y, bounds.max.y)


func get_play_bounds() -> Dictionary:
	var size = get_viewport_rect().size

	return {
		"min": Vector2(50, size.y * 0.35),
		"max": Vector2(size.x - 50, size.y - 80)
	}


# --------------------------------------------------
# FREE ROAM MOVEMENT (UNCHANGED LOGIC)
# --------------------------------------------------

func _handle_movement(delta: float) -> void:

	var turn: float = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	rotation += turn * rotation_speed * delta

	var forward: Vector2 = Vector2.UP.rotated(rotation)

	var thrusting: bool = Input.is_action_pressed("thrust")
	var boosting: bool = Input.is_action_pressed("boost") and boost_energy > 0.0
	var braking: bool = Input.is_action_pressed("brake")

	if thrusting:
		var mult: float = boost_multiplier if boosting else 1.0
		var accel: float = thrust * mult

		var speed_ratio: float = clamp(vel.length() / max_speed, 0.0, 1.0)
		accel *= 1.0 - (0.6 * speed_ratio)

		vel += forward * accel * delta

		if boosting:
			boost_energy = max(0.0, boost_energy - boost_drain * delta)
			_emit_boost()
	else:
		boost_energy = min(1.0, boost_energy + boost_recharge * delta)
		_emit_boost()

	vel *= (brake_damping if braking else damping)

	var lateral: Vector2 = vel - vel.project(forward)
	vel -= lateral * (1.0 - lateral_damping)

	if vel.length() > max_speed:
		vel = vel.normalized() * max_speed

	scale = Vector2(1.1, 0.9) if boosting else Vector2.ONE


# --------------------------------------------------
# SHOOTING (CLEANED DIR)
# --------------------------------------------------

func _handle_shooting(delta: float) -> void:

	fire_cd -= delta

	if not Input.is_action_pressed("shoot"):
		return
	if fire_cd > 0.0:
		return

	fire_cd = 1.0 / fire_rate

	var origin: Vector2 = muzzle.global_position
	var dir: Vector2 = Vector2.UP
	var damage := 1 + RunData.damage_bonus

	emit_signal("shot_fired", origin, dir, damage)


# --------------------------------------------------
# DAMAGE (UNCHANGED)
# --------------------------------------------------

func apply_damage(amount: int, source_pos: Vector2 = global_position) -> void:
	if is_invulnerable:
		return

	health = max(health - amount, 0)
	emit_signal("health_changed", health, max_health)

	var dir: Vector2 = (global_position - source_pos).normalized()
	vel += dir * 250.0

	is_invulnerable = true
	invuln_timer = invuln_duration

	if health <= 0:
		emit_signal("died")
		queue_free()


func _handle_invulnerability(delta: float) -> void:
	if not is_invulnerable:
		sprite.modulate = Color.WHITE
		return

	invuln_timer -= delta

	var blink := int(invuln_timer * 20.0) % 2 == 0
	sprite.modulate = Color(1, 0.5, 0.5) if blink else Color.WHITE

	if invuln_timer <= 0.0:
		is_invulnerable = false
		sprite.modulate = Color.WHITE


# --------------------------------------------------
# RUN DATA
# --------------------------------------------------

func refresh_run_stats():

	var old_max := max_health

	fire_rate = base_fire_rate + RunData.fire_rate_bonus
	max_health = base_max_health + RunData.max_health_bonus

	if old_max > 0:
		health += (max_health - old_max)

	health = clamp(health, 0, max_health)

	emit_signal("health_changed", health, max_health)


func _emit_boost() -> void:
	emit_signal("boost_changed", boost_energy)
