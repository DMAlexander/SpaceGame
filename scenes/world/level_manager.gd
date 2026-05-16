extends Node

signal level_started(index: int)
signal level_completed(index: int)

@export var level_container_path: NodePath
@onready var level_container: Node = get_node(level_container_path)

@export var levels: Array[LevelData] = []
@export var shop_scene: PackedScene
@export var end_screen_scene: PackedScene

var current_level: Node = null
var level_index: int = -1
var player: Node = null


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


# ==================================================
# START FLOW
# ==================================================

func start_flow(p_player):
	player = p_player
	state = FlowState.STARTUP
	level_index = -1
	load_next_level()


# ==================================================
# MAIN FLOW CONTROLLER
# ==================================================

func load_next_level():

	if state == FlowState.IN_SHOP:
		return

	state = FlowState.TRANSITION
	level_index += 1

	# -----------------------------
	# END OF GAME
	# -----------------------------
	if level_index >= levels.size():
		state = FlowState.COMPLETE
		await Fade.fade_out()
		await show_end_screen()
		await Fade.fade_in()
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


# ==================================================
# LEVEL LOADING
# ==================================================

func load_level(level_data: LevelData):

	if is_instance_valid(current_level):
		current_level.queue_free()

	current_level = level_data.scene.instantiate()
	level_container.add_child(current_level)

	if current_level.has_method("set_player"):
		current_level.set_player(player)

	if current_level.has_method("start_level"):
		current_level.start_level(level_index)

	emit_signal("level_started", level_index)

	# reconnect completion signal safely
	if current_level.has_signal("level_completed"):

		if current_level.level_completed.is_connected(_on_level_completed):
			current_level.level_completed.disconnect(_on_level_completed)

		current_level.level_completed.connect(_on_level_completed)


# ==================================================
# LEVEL COMPLETION (CLEAN - NO UI HERE)
# ==================================================

func _on_level_completed(index: int):

##	emit_signal("level_completed", index)
	state = FlowState.TRANSITION
	load_next_level()


# ==================================================
# SHOP FLOW
# ==================================================

func load_shop():

	if shop_scene == null:
		push_error("LevelManager: shop_scene not assigned!")
		return

	var shop = shop_scene.instantiate()
	level_container.add_child(shop)

	await shop.shop_completed

	shop.queue_free()


# ==================================================
# END SCREEN
# ==================================================

func show_end_screen():

	if is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null

	await get_tree().process_frame

	if end_screen_scene == null:
		push_error("LevelManager: end_screen_scene not assigned!")
		return

	var end_screen = end_screen_scene.instantiate()
	level_container.add_child(end_screen)

	end_screen.restart_requested.connect(_on_restart_run)
	end_screen.menu_requested.connect(_on_return_to_menu)


# ==================================================
# RESTART / MENU
# ==================================================

func _on_restart_run():
	level_index = -1
	RunData.reset()
	load_next_level()


func _on_return_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
