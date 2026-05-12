extends CharacterBody2D

signal shot_fired(origin, direction)

@export var thrust := 900.0
@export var max_speed := 420.0
@export var damping := 0.985
@export var rotation_speed := 4.0
@export var fire_rate := 8.0
@export var range := 1200.0
@onready var cam: Camera2D = $Camera2D

@onready var muzzle: Marker2D = $Muzzle

var vel: Vector2 = Vector2.ZERO
var fire_cd := 0.0

# --- Boost ---
@export var boost_multiplier: float = 1.8
@export var boost_drain: float = 0.8
@export var boost_recharge: float = 0.4

var boost_energy: float = 1.0   # 0 → 1

const BOOST_MIN := 0.0
const BOOST_EPSILON := 0.02

# --- Brake ---
@export var brake_damping: float = 0.92

# --- Drift Control ---
@export var lateral_damping: float = 0.85

func _physics_process(delta):
	_handle_movement(delta)
	_handle_shooting(delta)

	velocity = vel
	move_and_slide()
	
	if cam:
		cam.offset = cam.offset.lerp(Vector2.ZERO, 0.2)

# ---------------- MOVEMENT ----------------

func _handle_movement(delta):
	var turn: float = Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left")
	rotation += turn * rotation_speed * delta

	var forward: Vector2 = Vector2.UP.rotated(rotation)

	var is_thrusting: bool = Input.is_action_pressed("thrust")
	var boost_pressed := Input.is_action_pressed("boost")
	var is_boosting := boost_pressed
##	var is_boosting: bool = Input.is_action_pressed("boost") and boost_energy > 0.05
	var is_braking: bool = Input.is_action_pressed("brake")

	# --- THRUST ---
	if is_thrusting:
		var thrust_mult: float = boost_multiplier if is_boosting else 1.0
		var accel: float = thrust * thrust_mult

		# soft speed scaling (prevents runaway speed)
		var speed_ratio: float = clamp(vel.length() / max_speed, 0.0, 1.0)
		var accel_scale: float = 1.0 - (0.6 * speed_ratio)
		var scaled_accel: float = accel * accel_scale

		vel += forward * scaled_accel * delta

		# boost drains energy
		if is_boosting and boost_energy > 0.0:
			boost_energy = max(0.0, boost_energy - boost_drain * delta)
			
			# --- CAMERA SHAKE (ADD HERE) ---
			if cam:
				cam.offset = Vector2(randf_range(-1,1), randf_range(-1,1)) * 2
	else:
		# recharge when not thrusting
		boost_energy = min(1.0, boost_energy + boost_recharge * delta)

	# --- DAMPING ---
	var current_damping: float = brake_damping if is_braking else damping
	vel *= current_damping

	# --- DRIFT CONTROL (THIS IS THE MAGIC) ---
	var lateral: Vector2 = vel - vel.project(forward)
	vel -= lateral * (1.0 - lateral_damping)

	# --- SPEED CAP ---
	if vel.length() > max_speed:
		vel = vel.normalized() * max_speed
		
	# --- BOOST VISUAL FEEDBACK (ADD HERE) ---
	if is_boosting:
		scale = Vector2(1.1, 0.9)
	else:
		scale = Vector2.ONE

# ---------------- SHOOTING ----------------

func _handle_shooting(delta):
	fire_cd -= delta
	if not Input.is_action_pressed("shoot"):
		return
	if fire_cd > 0:
		return

	fire_cd = 1.0 / fire_rate

	var origin = muzzle.global_position
	var dir = Vector2.UP.rotated(global_rotation)

	emit_signal("shot_fired", origin, dir)
