extends Node2D

signal completed

@export var waves: Array[WaveResource] = []

@onready var scroll_root: Node2D = $ScrollRoot
@onready var enemy_container: Node2D = $ScrollRoot/EnemyContainer
@onready var bg_far: Sprite2D = $BackgroundFar
@onready var bg_near: Sprite2D = $BackgroundNear

@export var scroll_speed: float = 100.0
@export var scrolling_enabled: bool = true
@export var cleanup_y: float = 800.0

var current_wave: int = 0
##var screen_height: float

func _ready():
##	var screen_height := get_viewport_rect().size.y
	start()


func start():
	current_wave = 0
	start_wave(current_wave)


func _process(delta):
	if scrolling_enabled:
		scroll_root.position.y += scroll_speed * delta

	# parallax movement
	bg_far.position.y += scroll_speed * 0.3 * delta
	bg_near.position.y += scroll_speed * 0.6 * delta

	loop_background(bg_far, get_screen_height())
	loop_background(bg_far, get_screen_height())

	cleanup_enemies()


# ---------------- WAVE FLOW ----------------

func start_wave(index: int):
	if index >= waves.size():
		finish_level()
		return

	current_wave = index
	var wave: WaveResource = waves[index]

	await spawn_wave(wave)
	await wait_for_clear()

	start_wave(index + 1)


# ---------------- SPAWNING ----------------

func spawn_wave(wave: WaveResource) -> void:
	for i in range(wave.count):
		var spawn_pos: Vector2 = get_spawn_position(wave, i, wave.count)
		var target_pos: Vector2 = get_formation_target(wave, i, wave.count)

		spawn_enemy(spawn_pos, wave, i, target_pos)

		await get_tree().create_timer(wave.delay).timeout


func spawn_enemy(pos: Vector2, wave: WaveResource, index: int, target: Vector2):
	var e = wave.enemy_scene.instantiate()
	e.global_position = pos

	if e.has_method("setup_formation"):
		e.setup_formation(index, wave, target)

	enemy_container.add_child(e)


# ---------------- SPAWN POSITION (SCROLL-AWARE) ----------------

func get_spawn_position(wave: WaveResource, index: int, total: int) -> Vector2:
	var base_y := -50 + scroll_root.position.y

	match wave.pattern:

		WaveResource.Pattern.LINE:
			return Vector2(200 + index * wave.spacing, base_y)

		WaveResource.Pattern.WIDE:
			return Vector2(randf_range(50, 950), base_y)

		WaveResource.Pattern.CENTER:
			return Vector2(500, base_y)

		WaveResource.Pattern.V:
			var mid: float = total / 2.0
			var offset: float = (index - mid) * wave.spacing
			var depth: float = abs(index - mid) * (wave.spacing * 0.5)
			return Vector2(500 + offset, base_y - depth)

	return Vector2(500, base_y)


# ---------------- FORMATION TARGET (STATIC WORLD SPACE) ----------------

func get_formation_target(wave: WaveResource, index: int, total: int) -> Vector2:
	var base_y := 200  # fixed formation height on screen

	match wave.pattern:

		WaveResource.Pattern.LINE:
			return Vector2(200 + index * wave.spacing, base_y)

		WaveResource.Pattern.WIDE:
			return Vector2(randf_range(50, 950), base_y)

		WaveResource.Pattern.CENTER:
			return Vector2(500, base_y)

		WaveResource.Pattern.V:
			var mid: float = total / 2.0
			var offset: float = (index - mid) * wave.spacing
			var depth: float = abs(index - mid) * (wave.spacing * 0.5)
			return Vector2(500 + offset, base_y - depth)

	return Vector2(500, base_y)


# ---------------- CLEANUP ----------------

func cleanup_enemies():
	for e in enemy_container.get_children():
		if e.global_position.y > cleanup_y:
			e.queue_free()


# ---------------- FLOW CONTROL ----------------

func wait_for_clear():
	while enemy_container.get_child_count() > 0:
		await get_tree().process_frame


func finish_level():
	await get_tree().create_timer(1.0).timeout
	emit_signal("completed")

func loop_background(bg: Sprite2D, height: float):
	if bg.position.y > height:
		bg.position.y -= height * 2

func get_screen_height() -> float:
	return get_viewport_rect().size.y
