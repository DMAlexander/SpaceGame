extends CharacterBody2D

signal shot_fired(origin, direction)

signal health_changed(current, max)
signal died
signal boost_changed(value: float)
signal speed_changed(value: float)

@export var thrust := 900.0
@export var max_speed := 420.0
@export var damping := 0.985
@export var rotation_speed := 4.0
@export var fire_rate := 8.0

@export var max_health := 5
var health: int

# Boost
@export var boost_multiplier := 1.8
@export var boost_drain := 0.8
@export var boost_recharge := 0.4
var boost_energy := 1.0

# Movement tuning
@export var brake_damping := 0.92
@export var lateral_damping := 0.85

# Internal state
var vel: Vector2 = Vector2.ZERO
var fire_cd := 0.0

@onready var muzzle: Marker2D = $Muzzle
@onready var cam: Camera2D = $Camera2D

func _ready():
	health = max_health
	emit_signal("health_changed", health, max_health)
	emit_signal("boost_changed", boost_energy)

func _physics_process(delta):
	_handle_movement(delta)
	_handle_shooting(delta)

	velocity = vel
	move_and_slide()

	# emit once per physics tick (fine for now)
	emit_signal("speed_changed", vel.length())

	if cam:
		cam.offset = cam.offset.lerp(Vector2.ZERO, 0.2)

# ---------------- DAMAGE ----------------

func apply_damage(amount: int):
	health = max(health - amount, 0)
	emit_signal("health_changed", health, max_health)

	if health <= 0:
		emit_signal("died")
		queue_free()

# ---------------- MOVEMENT ----------------

func _handle_movement(delta):
	var turn := Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	rotation += turn * rotation_speed * delta

	var forward := Vector2.UP.rotated(rotation)

	var thrusting := Input.is_action_pressed("thrust")
	var boosting := Input.is_action_pressed("boost") and boost_energy > 0.0
	var braking := Input.is_action_pressed("brake")

	# --- THRUST ---
	if thrusting:
		var mult := boost_multiplier if boosting else 1.0
		var accel := thrust * mult

		var speed_ratio: float = clamp(vel.length() / max_speed, 0.0, 1.0)
		accel *= 1.0 - (0.6 * speed_ratio)

		vel += forward * accel * delta

		if boosting:
			boost_energy = max(0.0, boost_energy - boost_drain * delta)
			_emit_boost()

			if cam:
				cam.offset = Vector2(randf_range(-1,1), randf_range(-1,1)) * 2
	else:
		boost_energy = min(1.0, boost_energy + boost_recharge * delta)
		_emit_boost()

	# --- DAMPING ---
	vel *= (brake_damping if braking else damping)

	# --- DRIFT CONTROL ---
	var lateral := vel - vel.project(forward)
	vel -= lateral * (1.0 - lateral_damping)

	# --- SPEED CAP ---
	if vel.length() > max_speed:
		vel = vel.normalized() * max_speed

	# --- VISUAL BOOST SCALE ---
	scale = Vector2(1.1, 0.9) if boosting else Vector2.ONE

# ---------------- SHOOTING ----------------

func _handle_shooting(delta):
	fire_cd -= delta
	if not Input.is_action_pressed("shoot"):
		return
	if fire_cd > 0:
		return

	fire_cd = 1.0 / fire_rate

	var origin := muzzle.global_position
	var dir := Vector2.UP.rotated(global_rotation)

	emit_signal("shot_fired", origin, dir)

# ---------------- HELPERS ----------------

func _emit_boost():
	emit_signal("boost_changed", boost_energy)
