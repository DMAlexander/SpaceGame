extends Node2D

@onready var player = $Player
@onready var ui = $UI
@onready var shaker: Node = $ShakeController
@onready var score_label: Label = $UI/ScoreLabel
@onready var fx_manager: Node = $FXManager
@onready var level_manager = $LevelManager
@onready var gos: Control = $UI/GameOverScreen
@onready var level_completed_ui: Control = $UI/LevelCompleted
@onready var shop_scene_ui: Control = $UI/ShopScene
@onready var end_scene_ui: Control = $UI/EndScreen


var laser_scene = preload("res://scenes/laser.tscn")

var lasers: Node2D = null
var transitioning := false


# ==================================================
# INIT
# ==================================================

func _ready():
	await get_tree().process_frame
	await Fade.fade_in(0.4)

	# ---------------- PLAYER SIGNALS ----------------
	if not player.shot_fired.is_connected(_on_shot_fired):
		player.shot_fired.connect(_on_shot_fired)

	if not player.health_changed.is_connected(ui._on_health_changed):
		player.health_changed.connect(ui._on_health_changed)

	if not player.health_changed.is_connected(_on_player_damaged):
		player.health_changed.connect(_on_player_damaged)

	if not player.boost_changed.is_connected(ui._on_boost_changed):
		player.boost_changed.connect(ui._on_boost_changed)

	if not player.speed_changed.is_connected(ui._on_speed_changed):
		player.speed_changed.connect(ui._on_speed_changed)
		
			## BOMB ##
	# ---------------- BOMB ----------------
	if not player.bomb_used.is_connected(_on_bomb_used):
		player.bomb_used.connect(_on_bomb_used)
		
	if not player.bombs_changed.is_connected(ui._on_bombs_changed):
		player.bombs_changed.connect(ui._on_bombs_changed)

	# ---------------- LEVEL FLOW ----------------
	if not level_manager.level_started.is_connected(_on_level_started):
		level_manager.level_started.connect(_on_level_started)
		


	level_manager.start_flow(player)
	ui._on_bombs_changed(player.bombs, player.max_bombs)
	level_manager.set_ui_references(level_completed_ui, shop_scene_ui, end_scene_ui)


# ==================================================
# LEVEL START
# ==================================================

func _on_level_started(index: int):
	transitioning = false

	await get_tree().process_frame

	var current_level = level_manager.current_level
	if current_level == null:
		push_error("No current level found!")
		return

	# ---------------- PROJECTILES ----------------
	lasers = current_level.get_node_or_null("ProjectileContainer")

	if lasers == null:
		push_error("ProjectileContainer missing in current level!")
		return

	# ---------------- ENEMIES ----------------
	for e in get_tree().get_nodes_in_group("enemy"):

		if not get_tree().node_added.is_connected(_on_node_added):
			get_tree().node_added.connect(_on_node_added)

	# ---------------- LEVEL COMPLETE ----------------
	if current_level.level_completed.is_connected(_on_level_completed):
		current_level.level_completed.disconnect(_on_level_completed)

	current_level.level_completed.connect(_on_level_completed)


# ==================================================
# LEVEL COMPLETE
# ==================================================

##func _on_level_completed(index: int):
##	if transitioning:
##		return

##	transitioning = true

	# stop gameplay
##	Engine.time_scale = 0.1
##	get_tree().paused = true
	
##	level_completed_ui.visible = true
##	level_completed_ui.set_score(RunData.score)

##	if not level_completed_ui.next_level_pressed.is_connected(_on_next_level_pressed):
##		level_completed_ui.next_level_pressed.connect(_on_next_level_pressed)

##	if not level_completed_ui.menu_pressed.is_connected(_on_return_to_menu):
##		level_completed_ui.menu_pressed.connect(_on_return_to_menu)
	
	## Show level completed screen
	
	
func _on_level_completed(index: int):

	# ONLY visual pause, no flow control
	Engine.time_scale = 0.1

	level_completed_ui.visible = true
	level_completed_ui.set_score(RunData.score)

	# show UI
#	gos.visible = true
#	gos.set_score(RunData.score)
#	gos.set_high_score(RunData.score)


# ==================================================
# NEXT LEVEL (called by UI button)
# ==================================================

##func _on_next_level_pressed():
##	Engine.time_scale = 1.0
##	get_tree().paused = false
##	level_completed_ui.visible = false

##	transitioning = false

##	level_manager.load_next_level()
	
func _on_next_level_pressed():

	Engine.time_scale = 1.0
	get_tree().paused = false

	level_completed_ui.visible = false

func _on_return_to_menu():
	Engine.time_scale = 1.0
	transitioning = true

	get_tree().paused = false

	# optional safety reset
	RunData.reset_run()

	# small buffer so everything unsubscribes cleanly
	await get_tree().process_frame

	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# ==================================================
# SHOOTING
# ==================================================

func _on_shot_fired(origin, dir, damage):
	if lasers == null:
		push_error("No projectile container bound!")
		return

	var l = laser_scene.instantiate()
	l.global_position = origin
	l.dir = dir
	l.rotation = dir.angle()

	lasers.add_child(l)

# ==================================================
# BOMB
# ==================================================

func _on_bomb_used(pos: Vector2):

	# --------------------------------------------------
	# DEBUG
	# --------------------------------------------------

	print("BOMB USED AT:", pos)

	# --------------------------------------------------
	# DEBUG VISUAL
	# --------------------------------------------------

##	var debug = preload("res://scenes/fx/bomb_debug.tscn").instantiate()
	var debug = preload("res://scenes/bomb_debug/bomb_debug.tscn").instantiate()
	debug.global_position = pos
	add_child(debug)

	# --------------------------------------------------
	# GAME FEEL
	# --------------------------------------------------

	shaker.shake(12.0)
	fx_manager.hit_pause(0.12)

	# --------------------------------------------------
	# DAMAGE ENEMIES
	# --------------------------------------------------

	for e in get_tree().get_nodes_in_group("enemy"):

		if not is_instance_valid(e):
			continue

		var dist = e.global_position.distance_to(pos)

		if dist <= player.bomb_radius:

			print("HIT ENEMY:", e.name)

			if e.has_method("apply_damage"):
				e.apply_damage(player.bomb_damage)

# ==================================================
# COMBAT / SCORE
# ==================================================

func _on_player_damaged(current, max):
	Engine.time_scale = 1.0
	shaker.shake(6.0)
	fx_manager.hit_pause(0.05)


func _on_enemy_died(pos: Vector2, points: int):
	var final_points = fx_manager.register_kill(points, pos)

	RunData.score += final_points
	score_label.text = str(RunData.score)


# ==================================================
# GAME OVER
# ==================================================

func _on_player_died():
	gos.set_score(RunData.score)
	gos.set_high_score(RunData.score)

	await get_tree().create_timer(1.5).timeout
	gos.visible = true
	
func _on_node_added(node):

	if node.is_in_group("enemy"):

		if node.has_signal("died") and not node.died.is_connected(_on_enemy_died):
			node.died.connect(_on_enemy_died)
