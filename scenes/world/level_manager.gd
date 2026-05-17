extends Node

signal level_started(index: int)
signal level_completed(index: int)

@export var level_container_path: NodePath
@onready var level_container: Node = get_node(level_container_path)

@export var levels: Array[LevelData] = []
@export var shop_scene: PackedScene
@export var end_screen_scene: PackedScene
##@onready var level_completed_ui: Control = $UI/LevelCompleted
var current_level: Node = null
var level_index: int = -1
var player: Node = null

var level_completed_ui = null
var shop_scene_ui = null;
var end_scene_ui = null;

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

func set_ui_references(ui_node, ui_node2, ui_node3):
	level_completed_ui = ui_node
	shop_scene_ui = ui_node2
	end_scene_ui = ui_node3

# ==================================================
# MAIN FLOW CONTROLLER
# ==================================================

func load_next_level():
	
	if state == FlowState.IN_SHOP:
		return

##	if state == FlowState.TRANSITION:
##		return

	level_index += 1

	# END OF RUN
	if level_index >= levels.size():
		state = FlowState.COMPLETE
		await show_end_screen()
		return

	var level_data = levels[level_index]

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

	state = FlowState.TRANSITION

	await show_level_completed_screen()

	var level_data = levels[index]

	if level_data.has_shop_after:
		await load_shop()

	load_next_level()

func show_level_completed_screen() -> void:

	# Optional safety: stop gameplay activity
##	get_tree().paused = true
	Engine.time_scale = 0.1

	# Instantiate or show UI
##	var ui = level_container.get_node_or_null("LevelCompleted")

	if level_completed_ui == null:
		push_error("LevelCompleted UI not found in scene tree!")
		return

	level_completed_ui.visible = true
	level_completed_ui.set_score(RunData.score)

	# Make sure we don't double-connect
	if not level_completed_ui.next_level_pressed.is_connected(_on_next_level_pressed):
		level_completed_ui.next_level_pressed.connect(_on_next_level_pressed)

	if not level_completed_ui.menu_pressed.is_connected(_on_return_to_menu):
		level_completed_ui.menu_pressed.connect(_on_return_to_menu)

	# IMPORTANT: wait until player chooses
	await level_completed_ui.next_level_pressed

func _on_next_level_pressed():

	Engine.time_scale = 1.0
	get_tree().paused = false

	level_completed_ui.visible = false

func show_level_completed(score: int) -> void:

	level_completed_ui.visible = true
	level_completed_ui.set_score(score)

	get_tree().paused = true


# ==================================================
# SHOP FLOW
# ==================================================

#func load_shop():

#	if shop_scene == null:
#		push_error("LevelManager: shop_scene not assigned!")
#		return

#	var shop = shop_scene.instantiate()
#	level_container.add_child(shop)

#	state = FlowState.IN_SHOP

#	await shop.shop_completed

#	shop.queue_free()

#	state = FlowState.TRANSITION
	
func load_shop():

	if shop_scene == null:
		push_error("LevelManager: shop_scene not assigned!")
		return

	shop_scene_ui.visible = true
#	var shop = shop_scene.instantiate()
#	level_container.add_child(shop)

	state = FlowState.IN_SHOP

	await shop_scene_ui.shop_completed

	shop_scene_ui.queue_free()

	state = FlowState.TRANSITION
	

# ==================================================
# END SCREEN
# ==================================================

func show_end_screen():

	if is_instance_valid(current_level):
		current_level.queue_free()
		current_level = null

	await get_tree().process_frame

	if end_scene_ui == null:
		push_error("LevelManager: end_scene_ui not assigned!")
		return

	state = FlowState.COMPLETE

	end_scene_ui.visible = true
##	end_scene_ui.set_score(RunData.score)

	# prevent duplicate connections
	if not end_scene_ui.restart_requested.is_connected(_on_restart_run):
		end_scene_ui.restart_requested.connect(_on_restart_run)

	if not end_scene_ui.menu_requested.is_connected(_on_return_to_menu):
		end_scene_ui.menu_requested.connect(_on_return_to_menu)


# ==================================================
# RESTART / MENU
# ==================================================

func _on_restart_run():
	level_index = -1
##	RunData.reset()
	start_flow(player)


func _on_return_to_menu():
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
