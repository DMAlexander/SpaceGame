extends Node2D

@onready var player = $Player
@onready var lasers: Node2D = $Lasers
@onready var ui = $UI
##@onready var health_bar = $HealthBar
##@onready var health_bar: Control = $UI/HealthBar
@onready var shaker: Node = $ShakeController
@onready var score_label: Label = $UI/ScoreLabel
@onready var fx_manager: Node = $FXManager

@onready var level_manager = $LevelManager

var laser_scene = preload("res://scenes/laser.tscn")
var score: int = 0
var transitioning := false

func _ready():
	# ---------------- PLAYER SIGNALS ----------------
	player.shot_fired.connect(_on_shot_fired)
##	player.health_changed.connect(_on_health_changed)
	player.health_changed.connect(ui._on_health_changed)
	player.health_changed.connect(_on_player_damaged)

	player.boost_changed.connect(ui._on_boost_changed)
	player.speed_changed.connect(ui._on_speed_changed)
##	enemy.died.connect(_on_enemy_died)

	level_manager.level_completed.connect(_on_level_completed)

	level_manager.load_level(preload("res://scenes/levels/arcade_level_01.tscn"))
	level_manager.level_started.connect(_on_level_started)
	
##	for e in get_tree().get_nodes_in_group("enemy"):
##		e.died.connect(_on_enemy_died)

# ---------------- SHOOTING ----------------

func _on_shot_fired(origin, dir):
	var l = laser_scene.instantiate()
	l.global_position = origin
	l.dir = dir
	l.rotation = dir.angle()
	lasers.add_child(l)

func _on_level_started(index: int):
	transitioning = false
	await get_tree().process_frame

	for e in get_tree().get_nodes_in_group("enemy"):
		if e.has_signal("died") and not e.died.is_connected(_on_enemy_died):
			e.died.connect(_on_enemy_died)

# ---------------- HEALTH ----------------

func _on_player_damaged(current, max):
	shaker.shake(6.0)
	fx_manager.hit_pause(0.05)
	
func _on_enemy_died(pos: Vector2, points: int):
	var final_points = fx_manager.register_kill(points, pos)

	score += final_points
	score_label.text = str(score)

func _on_level_completed(index: int):
	if transitioning:
		return

	transitioning = true
	level_manager.next_level(preload("res://scenes/levels/free_roam_01.tscn"))
