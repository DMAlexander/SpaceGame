extends Camera2D

@export var target_path: NodePath
var target: Node2D

func _ready():
	target = get_node_or_null(target_path)

func _process(delta):
	if is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, 0.15)
