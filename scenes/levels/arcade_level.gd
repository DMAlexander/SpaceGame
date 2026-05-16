extends Node2D

signal completed

@export var waves: Array[WaveResource] = []

# --------------------------------------------------
# PLAYER
# --------------------------------------------------

var player = null

# --------------------------------------------------
# WORLD
# --------------------------------------------------

@onready var world_root: Node2D = $WorldRoot
@onready var enemy_container: Node2D = $WorldRoot/EnemyContainer

# --------------------------------------------------
# PARALLAX
# --------------------------------------------------

@onready var parallax_root: Node2D = $ParallaxRoot

@onready var bg_far: TextureRect = $ParallaxRoot/BackgroundFar
@onready var bg_near: TextureRect = $ParallaxRoot/BackgroundNear

# --------------------------------------------------
# WAVE SETTINGS
# --------------------------------------------------

@export var wave_delay: float = 1.5

var current_wave: int = 0
var active_wave: WaveResource = null

# --------------------------------------------------
# DIVE SETTINGS
# --------------------------------------------------

var dive_timer: float = 3.0
var dive_interval: float = 4.0

# --------------------------------------------------
# SCROLL SETTINGS
# --------------------------------------------------

@export var scroll_speed: float = 100.0
@export var scroll_smoothness: float = 0.08
@export var cleanup_y: float = 800.0

var scroll_y: float = 0.0
var camera_y: float = 0.0


# ==================================================
# INIT
# ==================================================

func _ready():
	pass


func set_player(p):
	player = p
	print("PLAYER RECEIVED:", player)


func start_level():
	print("PLAYER INSIDE START_LEVEL:", player)
	
	print("VIEWPORT:", get_viewport_rect().size)
	print("PLAYER SPAWN:", player.global_position)

	var screen_size = get_viewport_rect().size

	# --------------------------------------------------
	# PLAYER SETUP
	# --------------------------------------------------

	if player:

		player.control_mode = player.ControlMode.ARCADE

		player.global_position = Vector2(
			screen_size.x * 0.5,
			screen_size.y * 0.82
		)

	else:
		push_error("ArcadeLevel: player not set!")

	# --------------------------------------------------
	# BACKGROUND SETUP
	# --------------------------------------------------

	bg_far.size = screen_size
	bg_near.size = screen_size

	bg_far.position = Vector2.ZERO
	bg_near.position = Vector2.ZERO

	start()


func start() -> void:

	current_wave = 0
	run_waves()


# ==================================================
# MAIN UPDATE
# ==================================================

func _process(delta):

	dive_timer -= delta

	if dive_timer <= 0.0:
		trigger_random_dive()
		dive_timer = dive_interval

	_handle_scrolling(delta)
	_update_parallax(delta)
	cleanup_enemies()


# ==================================================
# SCROLLING
# ==================================================

func _handle_scrolling(delta: float) -> void:

	scroll_y += scroll_speed * delta

	camera_y = lerp(
		camera_y,
		scroll_y,
		scroll_smoothness
	)

	world_root.position.y = -camera_y


# ==================================================
# PARALLAX
# ==================================================

func _update_parallax(delta: float) -> void:

	bg_far.texture_offset.y += scroll_speed * 0.15 * delta
	bg_near.texture_offset.y += scroll_speed * 0.35 * delta


# ==================================================
# WAVE FLOW
# ==================================================

func run_waves() -> void:

	while current_wave < waves.size():

		await start_wave(current_wave)

		current_wave += 1

		await get_tree().create_timer(wave_delay).timeout

	finish_level()


func start_wave(index: int) -> void:

	if index >= waves.size():
		return

	active_wave = waves[index]

	await spawn_wave(active_wave)
	await wait_for_clear()


# ==================================================
# ENEMY SPAWNING
# ==================================================

func spawn_wave(wave: WaveResource) -> void:

	for i in range(wave.count):

		var spawn_pos: Vector2 = get_spawn_position(i, wave.count)
		var target_pos: Vector2 = get_formation_target(i, wave.count)

		spawn_enemy(spawn_pos, wave, i, target_pos)

		await get_tree().create_timer(wave.delay).timeout


func spawn_enemy(
	pos: Vector2,
	wave: WaveResource,
	index: int,
	target: Vector2
):

	var e = wave.enemy_scene.instantiate()

	e.global_position = pos

	if e.has_method("setup_formation"):
		e.setup_formation(index, wave, target)

	enemy_container.add_child(e)


# ==================================================
# FORMATIONS
# ==================================================

func get_spawn_position(index: int, total: int) -> Vector2:

	var screen_size = get_viewport_rect().size

	return Vector2(
		(screen_size.x * 0.5) + ((index - total * 0.5) * 80.0),
		-camera_y - 150.0
	)


func get_formation_target(index: int, total: int) -> Vector2:

	var screen_size = get_viewport_rect().size

	return Vector2(
		(screen_size.x * 0.5) + ((index - total * 0.5) * 80.0),
		220.0
	)


# ==================================================
# CLEANUP
# ==================================================

func cleanup_enemies() -> void:

	for e in enemy_container.get_children():

		if not is_instance_valid(e):
			continue

		if e.global_position.y > cleanup_y:
			e.queue_free()


# ==================================================
# FLOW CONTROL
# ==================================================

func wait_for_clear() -> void:

	while enemy_container.get_child_count() > 0:
		await get_tree().process_frame


func finish_level() -> void:

	await get_tree().create_timer(1.0).timeout
	emit_signal("completed")


# ==================================================
# DIVE SYSTEM
# ==================================================

func trigger_random_dive() -> void:

	if active_wave == null:
		return

	if randf() > active_wave.dive_chance:
		return

	var candidates: Array = []

	for e in enemy_container.get_children():

		if not is_instance_valid(e):
			continue

		if e.has_method("is_in_formation") and e.is_in_formation():
			candidates.append(e)

	if candidates.is_empty():
		return

	var enemy = candidates.pick_random()

	if enemy.has_method("start_dive"):

		var target = (
			player.global_position
			if player
			else Vector2(500, 500)
		)

		enemy.start_dive(
			target,
			active_wave.dive_speed
		)
