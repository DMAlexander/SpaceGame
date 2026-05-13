extends Node

@onready var shaker = get_parent().get_node("ShakeController")

var explosion_scene = preload("res://scenes/enemy_explosion/enemy_explosion.tscn")
var score_popup_scene = preload("res://scenes/score_popup/score_popup.tscn")
##@onready var combo_label: Label = $"../UI/ComboLabel"
##@onready var combo_label = get_parent().get_node("UI/ComboLabel")
##@onready var ui: CanvasLayer = $"../UI"
##@onready var ui = get_parent().get_node("UI")
@onready var combo_label: Label = get_parent().get_node("UI/ComboLabel")

var combo: int = 0
var combo_timer: float = 0.0

@export var combo_window: float = 2.0

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

##func enemy_death(pos: Vector2, points: int):
##	spawn_explosion(pos)
##	spawn_score(pos, points)
##	shaker.shake(3.0)

func register_kill(points: int, pos: Vector2) -> int:
	# increase combo
	combo += 1
	combo_timer = combo_window

	# scaled score
	var final_points = points * combo

	# stronger FX as combo grows
	var shake_strength = min(2.0 + combo * 0.3, 10.0)

	spawn_explosion(pos, shake_strength)
	spawn_score(pos, final_points)

	return final_points
	
func _process(delta):
	if combo > 0:
		combo_timer -= delta
		
		if combo_timer <= 0.0:
			combo = 0
		update_ui()

func update_ui():
	combo_label.text = "COMBO x%d" % combo
	combo_label.visible = combo >= 1
