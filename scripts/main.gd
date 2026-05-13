extends Node2D

@onready var player = $Player
@onready var lasers: Node2D = $Lasers
@onready var ui = $UI
##@onready var health_bar = $HealthBar
##@onready var health_bar: Control = $UI/HealthBar
@onready var shaker: Node = $ShakeController
@onready var score_label: Label = $UI/ScoreLabel

var explosion_scene = preload("res://scenes/enemy_explosion/enemy_explosion.tscn")
var laser_scene = preload("res://scenes/laser.tscn")
var float_text_scene = preload("res://scenes/score_popup/score_popup.tscn")
var score: int = 0

func _ready():
	# ---------------- PLAYER SIGNALS ----------------
	player.shot_fired.connect(_on_shot_fired)
##	player.health_changed.connect(_on_health_changed)
	player.health_changed.connect(ui._on_health_changed)
	player.health_changed.connect(_on_player_damaged)

	player.boost_changed.connect(ui._on_boost_changed)
	player.speed_changed.connect(ui._on_speed_changed)
##	enemy.died.connect(_on_enemy_died)
	
	for e in get_tree().get_nodes_in_group("enemy"):
		e.died.connect(_on_enemy_died)

# ---------------- SHOOTING ----------------

func _on_shot_fired(origin, dir):
	var l = laser_scene.instantiate()
	l.global_position = origin
	l.dir = dir
	l.rotation = dir.angle()
	lasers.add_child(l)

# ---------------- HEALTH ----------------

func _on_player_damaged(current, max):
	shaker.shake(6.0)
	hit_pause(0.05)

func hit_pause(duration: float = 0.05):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration * Engine.time_scale).timeout
	Engine.time_scale = 1.0

func spawn_explosion(pos: Vector2):
	var e = explosion_scene.instantiate()
	e.global_position = pos
	add_child(e)

	shaker.shake(3.0)

func _on_enemy_died(pos: Vector2, points: int):
	score += points
	score_label.text = str(score)

	spawn_explosion(pos)
	spawn_score(pos, points)
	shaker.shake(3.0)
	
func spawn_score(pos: Vector2, value: int):
	var t = float_text_scene.instantiate()
	t.global_position = pos
	add_child(t)
	t.setup("+%d" % value)
