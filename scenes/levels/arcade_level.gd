extends Node2D

signal completed

@export var waves: Array[WaveResource] = []

var player = null

@onready var scroll_root: Node2D = $ScrollRoot
@onready var enemy_container: Node2D = $ScrollRoot/EnemyContainer

@onready var bg_far: Sprite2D = $ScrollRoot/BackgroundFar
@onready var bg_near: Sprite2D = $ScrollRoot/BackgroundNear

@export var scroll_speed: float = 100.0
@export var scroll_smoothness: float = 0.08
@export var cleanup_y: float = 800.0
@export var wave_delay: float = 1.5

var current_wave: int = 0
var active_wave: WaveResource = null

var dive_timer: float = 3.0
var dive_interval: float = 4.0

var scroll_y: float = 0.0


# --------------------------------------------------
# INIT
# --------------------------------------------------

func _ready():
	pass
	# player is injected by LevelManager
##	if player:
##		player.control_mode = player.ControlMode.ARCADE
##	else:
##		push_error("ArcadeLevel: player was not injected!")

##	start()

func start_level():
	if player:
		player.control_mode = player.ControlMode.ARCADE
	else:
		push_error("ArcadeLevel: player not set!")

	start()


func set_player(p):
	player = p

func start() -> void:
	current_wave = 0
	run_waves()


# --------------------------------------------------
# FLOW
# --------------------------------------------------

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


# --------------------------------------------------
# UPDATE
# --------------------------------------------------

func _process(delta):

	dive_timer -= delta

	if dive_timer <= 0.0:
		trigger_random_dive()
		dive_timer = dive_interval

	_handle_scrolling(delta)
	_update_parallax()
	cleanup_enemies()


# --------------------------------------------------
# SCROLLING (CLEANED)
# --------------------------------------------------

func _handle_scrolling(delta: float) -> void:
	scroll_y += scroll_speed * delta
	scroll_root.position.y = scroll_y


# --------------------------------------------------
# PARALLAX
# --------------------------------------------------

func _update_parallax() -> void:
	bg_far.position.y = scroll_root.position.y * 0.3
	bg_near.position.y = scroll_root.position.y * 0.6


# --------------------------------------------------
# WAVES
# --------------------------------------------------

func spawn_wave(wave: WaveResource) -> void:

	for i in range(wave.count):

		var spawn_pos: Vector2 = get_spawn_position(i, wave.count)
		var target_pos: Vector2 = get_formation_target(i, wave.count)

		spawn_enemy(spawn_pos, wave, i, target_pos)

		await get_tree().create_timer(wave.delay).timeout


func spawn_enemy(pos: Vector2, wave: WaveResource, index: int, target: Vector2):

	var e = wave.enemy_scene.instantiate()
	e.global_position = pos

	if e.has_method("setup_formation"):
		e.setup_formation(index, wave, target)

	enemy_container.add_child(e)


# --------------------------------------------------
# SPAWN POSITIONS (DECOUPLED FROM CAMERA)
# --------------------------------------------------

func get_spawn_position(index: int, total: int) -> Vector2:
	var base_y := -100.0  # fixed world offset

	return Vector2(200 + index * 80, base_y)


func get_formation_target(index: int, total: int) -> Vector2:
	var base_y := 200.0

	return Vector2(200 + index * 80, base_y)


# --------------------------------------------------
# CLEANUP
# --------------------------------------------------

func cleanup_enemies() -> void:
	for e in enemy_container.get_children():

		if not is_instance_valid(e):
			continue

		if e.global_position.y > scroll_y + cleanup_y:
			e.queue_free()


# --------------------------------------------------
# FLOW CONTROL
# --------------------------------------------------

func wait_for_clear() -> void:
	while enemy_container.get_child_count() > 0:
		await get_tree().process_frame


func finish_level() -> void:
	await get_tree().create_timer(1.0).timeout
	emit_signal("completed")


# --------------------------------------------------
# DIVE SYSTEM (UNCHANGED BUT SAFE)
# --------------------------------------------------

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
		var target = player.global_position if player else Vector2(500, 500)
		enemy.start_dive(target, active_wave.dive_speed)
