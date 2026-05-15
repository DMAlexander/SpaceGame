extends Node

signal level_started(index: int)
signal level_completed(index: int)

@export var level_container_path: NodePath
@onready var level_container: Node = get_node(level_container_path)

# Ordered gameplay flow
@export var levels: Array[LevelData] = []

var current_level: Node = null
var level_index: int = -1

func start_flow():
	level_index = -1
	load_next_level()
	
func load_next_level():

	level_index += 1

	if level_index >= levels.size():
		print("GAME COMPLETE")
		return

	var level_data: LevelData = levels[level_index]
	load_level(level_data)

func load_level(level_data: LevelData):

	if current_level:
		current_level.queue_free()

	current_level = level_data.scene.instantiate()

	level_container.add_child(current_level)

	emit_signal("level_started", level_index)

	if current_level.has_signal("completed"):
		current_level.completed.connect(_on_level_completed)

func _on_level_completed():

	emit_signal("level_completed", level_index)

	load_next_level()
