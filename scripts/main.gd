extends Node2D

@onready var player = $Player
@onready var ui = $UI
@onready var shaker: Node = $ShakeController
@onready var score_label: Label = $UI/ScoreLabel
@onready var fx_manager: Node = $FXManager
@onready var level_manager = $LevelManager
@onready var gos: Control = $GameOverScreen

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

	# ---------------- LEVEL FLOW ----------------
	if not level_manager.level_started.is_connected(_on_level_started):
		level_manager.level_started.connect(_on_level_started)

	level_manager.start_flow(player)


# ==================================================
# LEVEL HOOK
# ==================================================

func _on_level_started(index: int):
	transitioning = false

	await get_tree().process_frame

	var current_level = level_manager.current_level
	if current_level == null:
		push_error("No current level found!")
		return

	# bind projectile container dynamically
	lasers = current_level.get_node_or_null("ProjectileContainer")

	if lasers == null:
		push_error("ProjectileContainer missing in current level!")
		return

	# reconnect enemies safely (avoid duplicate connections)
	for e in get_tree().get_nodes_in_group("enemy"):

		if not e.has_signal("died"):
			continue

		if not e.died.is_connected(_on_enemy_died):
			e.died.connect(_on_enemy_died)


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
# HEALTH / COMBAT FEEDBACK
# ==================================================

func _on_player_damaged(current, max):
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
