extends Node2D

signal completed

@export var waves: Array[WaveResource] = []

@onready var enemy_container = $EnemyContainer

var current_wave := 0

func _ready():
	start()

func start():
	start_wave(0)

func spawn_wave(wave: WaveResource) -> void:
	for i in wave.count:
		var pos = get_spawn_position(wave.pattern, i, wave.count)
		spawn_enemy(pos, wave)

		await get_tree().create_timer(wave.delay).timeout

func get_spawn_position(pattern: String, index: int, total: int) -> Vector2:
	match pattern:
		"line":
			var spacing := 80.0
			return Vector2(200 + index * spacing, -50)

		"wide":
			return Vector2(randf_range(50, 950), -50)

		"center":
			return Vector2(500, -50)

		_:
			return Vector2(randf_range(100, 900), -50)

func spawn_enemy(pos: Vector2, wave: WaveResource):
	var e = wave.enemy_scene.instantiate()
	e.global_position = pos
	enemy_container.add_child(e)
	
func wait_for_clear():
	while enemy_container.get_child_count() > 0:
		await get_tree().process_frame

func start_wave(index: int):
	if index >= waves.size():
		finish_level()
		return

	var wave = waves[index]

	await spawn_wave(wave)
	await wait_for_clear()

	start_wave(index + 1)
	
func finish_level():
	await get_tree().create_timer(1.0).timeout
	emit_signal("completed")
