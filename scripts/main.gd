extends Node2D

@onready var player = $Player
@onready var lasers: Node2D = $Lasers
@onready var ui = $UI
##@onready var health_bar = $HealthBar
##@onready var health_bar: Control = $UI/HealthBar

var laser_scene = preload("res://scenes/laser.tscn")

func _ready():
	# ---------------- PLAYER SIGNALS ----------------
	player.shot_fired.connect(_on_shot_fired)
##	player.health_changed.connect(_on_health_changed)
	player.health_changed.connect(ui._on_health_changed)

	player.boost_changed.connect(ui._on_boost_changed)
	player.speed_changed.connect(ui._on_speed_changed)

# ---------------- SHOOTING ----------------

func _on_shot_fired(origin, dir):
	var l = laser_scene.instantiate()
	l.global_position = origin
	l.dir = dir
	l.rotation = dir.angle()
	lasers.add_child(l)

# ---------------- HEALTH ----------------

##func _on_health_changed(current, max):
##	health_bar.update_health(current, max)
