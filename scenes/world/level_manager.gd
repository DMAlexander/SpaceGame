extends Node

signal level_started(index: int)
signal level_completed(index: int)

@export var level_container_path: NodePath
@onready var level_container: Node = get_node(level_container_path)

# Ordered gameplay flow
@export var levels: Array[LevelData] = []
@export var shop_scene: PackedScene

var current_level: Node = null
var level_index: int = -1


# -----------------------------
# FLOW STATE MACHINE
# -----------------------------
enum FlowState {
	STARTUP,
	LEVEL_LOADING,
	IN_LEVEL,
	IN_SHOP,
	TRANSITION,
	COMPLETE
}

var state: FlowState = FlowState.STARTUP


# -----------------------------
# START FLOW
# -----------------------------
func start_flow():
	state = FlowState.STARTUP
	level_index = -1
	load_next_level()


# -----------------------------
# MAIN FLOW CONTROLLER
# -----------------------------
func load_next_level():

	# prevent double transitions
	if state == FlowState.IN_SHOP:
		return

	state = FlowState.TRANSITION

	level_index += 1

	if level_index >= levels.size():
		state = FlowState.COMPLETE
		print("GAME COMPLETE")
		return

	var level_data: LevelData = levels[level_index]

	# -----------------------------
	# SHOP PHASE
	# -----------------------------
	if level_data.has_shop_after:
		state = FlowState.IN_SHOP
		await load_shop()

	# -----------------------------
	# LEVEL PHASE
	# -----------------------------
	state = FlowState.LEVEL_LOADING
	load_level(level_data)
	state = FlowState.IN_LEVEL


# -----------------------------
# LEVEL LOADING
# -----------------------------
func load_level(level_data: LevelData):

	# clean previous level
	if is_instance_valid(current_level):
		current_level.queue_free()

	current_level = level_data.scene.instantiate()
	level_container.add_child(current_level)

	emit_signal("level_started", level_index)

	if current_level.has_signal("completed"):
		current_level.completed.connect(_on_level_completed)


# -----------------------------
# LEVEL COMPLETION (NO FLOW LOGIC HERE)
# -----------------------------
func _on_level_completed():

	emit_signal("level_completed", level_index)

	# ONLY mark state — do NOT advance flow
	state = FlowState.TRANSITION


# -----------------------------
# SHOP FLOW
# -----------------------------
func load_shop():

	if shop_scene == null:
		push_error("LevelManager: shop_scene not assigned in Inspector!")
		return

	var shop = shop_scene.instantiate()
	level_container.add_child(shop)

	await shop.shop_completed

	shop.queue_free()
