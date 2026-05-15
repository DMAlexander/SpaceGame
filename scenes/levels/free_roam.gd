extends Node

@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	if player == null:
		push_warning("FreeRoam: Player not found in scene.")
		return

	player.set_control_mode(player.ControlMode.FREE_ROAM)
