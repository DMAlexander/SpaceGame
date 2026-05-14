extends Node2D

signal completed

@export var waves: Array[WaveResource] = []

@onready var enemy_container: Node2D = $EnemyContainer

var current_wave: int = 0


func _ready():
	start()


func start():
	current_wave = 0
	start_wave(current_wave)


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
		var pos: Vector2 = get_spawn_position(wave.pattern, i, wave.count)
		spawn_enemy(pos, wave, i)

		await get_tree().create_timer(wave.delay).timeout


func spawn_enemy(pos: Vector2, wave: WaveResource, index: int):
	var e = wave.enemy_scene.instantiate()
	e.global_position = pos

	if e.has_method("setup_formation"):
		var target = get_spawn_position(wave.pattern, index, wave.count)
		e.setup_formation(index, wave, target)

	enemy_container.add_child(e)


# ---------------- FORMATIONS ----------------

func get_spawn_position(pattern: int, index: int, total: int) -> Vector2:
	match pattern:

		WaveResource.Pattern.LINE:
			var spacing: float = 80.0
			return Vector2(200 + index * spacing, -50)

		WaveResource.Pattern.WIDE:
			return Vector2(randf_range(50, 950), -50)

		WaveResource.Pattern.CENTER:
			return Vector2(500, -50)

		WaveResource.Pattern.V:
			var mid: float = total / 2.0
			var offset: float = (index - mid) * 60.0
			var depth: float = abs(index - mid) * 30.0
			return Vector2(500 + offset, -50 - depth)

		_:
			return Vector2(randf_range(100, 900), -50)


# ---------------- FLOW CONTROL ----------------

func wait_for_clear():
	while enemy_container.get_child_count() > 0:
		await get_tree().process_frame


func finish_level():
	await get_tree().create_timer(1.0).timeout
	emit_signal("completed")
