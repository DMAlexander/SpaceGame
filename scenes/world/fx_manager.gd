extends Node

@onready var shaker = get_parent().get_node("ShakeController")

var explosion_scene = preload("res://scenes/enemy_explosion/enemy_explosion.tscn")
var score_popup_scene = preload("res://scenes/score_popup/score_popup.tscn")

func spawn_explosion(pos: Vector2, strength: float = 3.0):
	var e = explosion_scene.instantiate()
	e.global_position = pos
	get_parent().add_child(e)

	shaker.shake(strength)
	
func spawn_score(pos: Vector2, value: int):
	var t = score_popup_scene.instantiate()
	t.global_position = pos
	get_parent().add_child(t)

	t.setup("+%d" % value)
	
func hit_pause(duration: float = 0.05):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration).timeout
	Engine.time_scale = 1.0

func enemy_death(pos: Vector2, points: int):
	spawn_explosion(pos)
	spawn_score(pos, points)
	shaker.shake(3.0)
