extends Node2D

signal completed

@export var waves: Array[WaveResource] = []

var player = null
@onready var scroll_root: Node2D = $ScrollRoot
@onready var enemy_container: Node2D = $ScrollRoot/EnemyContainer

@onready var bg_far: Sprite2D = $BackgroundFar
@onready var bg_near: Sprite2D = $BackgroundNear

@export var scroll_speed: float = 100.0

var current_wave: int = 0
var active_wave: WaveResource
var dive_timer: float = 3.0
var dive_interval: float = 4.0

# Camera simulation
var scroll_target_y: float = 0.0
var camera_y: float = 0.0

# Optional tuning
@export var scroll_smoothness: float = 0.08
@export var cleanup_y: float = 800.0

@export var wave_delay: float = 1.5

func _ready():
	player = get_tree().get_first_node_in_group("player")
	start()


func start():
	current_wave = 0
	await start_wave(current_wave)


func _process(delta):
	dive_timer -= delta

	if dive_timer <= 0.0:
		trigger_random_dive()
		dive_timer = dive_interval
	
	_handle_scrolling(delta)
	_update_parallax()
	cleanup_enemies()


# ---------------- CAMERA SCROLL ----------------

func _handle_scrolling(delta):
	scroll_target_y += scroll_speed * delta
	camera_y = lerp(camera_y, scroll_target_y, scroll_smoothness)

	# Move world (inverted camera motion)
	scroll_root.position.y = -camera_y


# ---------------- PARALLAX ----------------

func _update_parallax():
	bg_far.position.y = -camera_y * 0.3
	bg_near.position.y = -camera_y * 0.6


# ---------------- WAVES ----------------

func start_wave(index: int):
	if index >= waves.size():
		finish_level()
		return

	current_wave = index

	var wave: WaveResource = waves[index]
	active_wave = wave

	await spawn_wave(wave)
	await wait_for_clear()

	await get_tree().create_timer(wave_delay).timeout

	await start_wave(index + 1)


func spawn_wave(wave: WaveResource) -> void:
	for i in range(wave.count):
		var spawn_pos: Vector2 = get_spawn_position(wave, i, wave.count)
		var target_pos: Vector2 = get_formation_target(wave, i, wave.count)

		spawn_enemy(spawn_pos, wave, i, target_pos)

		await get_tree().create_timer(wave.delay).timeout


# ---------------- ENEMY SPAWNING ----------------

func spawn_enemy(pos: Vector2, wave: WaveResource, index: int, target: Vector2):
	var e = wave.enemy_scene.instantiate()
	e.global_position = pos

	if e.has_method("setup_formation"):
		e.setup_formation(index, wave, target)

	enemy_container.add_child(e)


# ---------------- SPAWN POSITION (WORLD ENTRY) ----------------

func get_spawn_position(wave: WaveResource, index: int, total: int) -> Vector2:
	var base_y := -50 + camera_y

	match wave.pattern:

		WaveResource.Pattern.LINE:
			return Vector2(200 + index * wave.spacing, base_y)

		WaveResource.Pattern.WIDE:
			return Vector2(randf_range(50, 950), base_y)

		WaveResource.Pattern.CENTER:
			return Vector2(500, base_y)

		WaveResource.Pattern.V:
			var mid: float = float(total) / 2.0
			var diff: float = float(index) - mid

			var offset: float = diff * wave.spacing
			var depth: float = abs(diff) * (wave.spacing * 0.5)

			return Vector2(500 + offset, base_y - depth)

	return Vector2(500, base_y)


# ---------------- FORMATION TARGET (STATIC SPACE) ----------------

func get_formation_target(wave: WaveResource, index: int, total: int) -> Vector2:
	var base_y := 200.0

	match wave.pattern:

		WaveResource.Pattern.LINE:
			return Vector2(200 + index * wave.spacing, base_y)

		WaveResource.Pattern.WIDE:
			return Vector2(randf_range(50, 950), base_y)

		WaveResource.Pattern.CENTER:
			return Vector2(500, base_y)

		WaveResource.Pattern.V:
			var mid: float = float(total) / 2.0
			var diff: float = float(index) - mid

			var offset: float = diff * wave.spacing
			var depth: float = abs(diff) * (wave.spacing * 0.5)

			return Vector2(500 + offset, base_y - depth)

	return Vector2(500, base_y)


# ---------------- CLEANUP ----------------

func cleanup_enemies():
	for e in enemy_container.get_children():
		if e.global_position.y > camera_y + cleanup_y:
			e.queue_free()


# ---------------- FLOW CONTROL ----------------

func wait_for_clear():
	while enemy_container.get_child_count() > 0:
		await get_tree().process_frame


func finish_level():
	await get_tree().create_timer(1.0).timeout
	emit_signal("completed")

func trigger_random_dive():

	if active_wave == null:
		return

	# Chance roll
	if randf() > active_wave.dive_chance:
		return

	var enemies := []

	for e in enemy_container.get_children():
		if is_instance_valid(e) and e.state == e.State.FORMATION:
			enemies.append(e)

	if enemies.is_empty():
		return

	var enemy = enemies.pick_random()

	if enemy.has_method("start_dive"):
		var target = get_dive_target()
		enemy.start_dive(target, active_wave.dive_speed)

func get_dive_target() -> Vector2:
	if player:
		return player.global_position
	return Vector2(500, 500)
