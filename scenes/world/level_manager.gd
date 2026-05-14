extends Node

signal level_started(index: int)
signal level_completed(index: int)

@export var level_container_path: NodePath
@onready var level_container: Node = get_node_or_null(level_container_path)

var current_level: Node = null
var level_index: int = 0


func load_level(scene: PackedScene):
	if level_container == null:
		push_error("LevelManager: level_container_path is invalid!")
		return

	# cleanup old level safely
	if is_instance_valid(current_level):
		if current_level.has_signal("completed"):
			if current_level.completed.is_connected(_on_level_completed):
				current_level.completed.disconnect(_on_level_completed)

		current_level.queue_free()

	# instantiate new level
	current_level = scene.instantiate()
	level_container.add_child(current_level)

	emit_signal("level_started", level_index)

	if current_level.has_signal("completed"):
		current_level.completed.connect(_on_level_completed)


func _on_level_completed():
	emit_signal("level_completed", level_index)


func next_level(next_scene: PackedScene):
	level_index += 1
	load_level(next_scene)
