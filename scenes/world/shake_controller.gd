extends Node

var shake_strength: float = 0.0
var shake_decay: float = 8.0
var shake_direction: Vector2 = Vector2.ZERO

@onready var camera: Camera2D = get_parent().get_node("Camera2D")

func _process(delta):
	if not is_instance_valid(camera):
		return

	if shake_strength > 0.0:
		camera.offset = (
			Vector2(randf_range(-1,1), randf_range(-1,1)) +
			shake_direction
		) * shake_strength
		
		shake_strength = lerpf(shake_strength, 0.0, shake_decay * delta)
	else:
		camera.offset = Vector2.ZERO

func shake(amount: float, direction: Vector2 = Vector2.ZERO):
	shake_strength = max(shake_strength, amount)
	shake_direction = direction.normalized()
