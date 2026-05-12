extends Node2D

@onready var player = $Player
@onready var lasers: Node2D = $Lasers



##@onready var enemies = $Enemies
@onready var boost_bar: ProgressBar = $UI/BoostBar

var laser_scene = preload("res://scenes/laser.tscn")

func _ready():
	player.shot_fired.connect(_on_shot_fired)

##	for e in enemies.get_children():
##		e.died.connect(_on_enemy_died)

# ---------------- SHOOTING ----------------

func _on_shot_fired(origin, dir):
	var l = laser_scene.instantiate()
	l.global_position = origin
	l.dir = dir
	
	l.rotation = dir.angle()
	
	lasers.add_child(l)

# ---------------- ENEMY ----------------

func _on_enemy_died():
##	score += points
	print("enemy killed")
	
func _on_enemy_spawned(enemy):
	enemy.died.connect(_on_enemy_died)

func _process(delta):
	print('player boost energy: ', player.boost_energy)
	var target: float = player.boost_energy * 100.0

	boost_bar.value = lerp(boost_bar.value, target, 0.2)

	# --- SNAP FIX ---
	if abs(boost_bar.value - target) < 0.5:
		boost_bar.value = target
