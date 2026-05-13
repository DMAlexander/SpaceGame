extends Node

@onready var boost_bar = $BoostBar
@onready var speed_label = $SpeedLabel
@onready var health_bar: ProgressBar = $HealthBar

# ---------------- BOOST ----------------

func _on_boost_changed(value: float):
	var target: float = value * 100.0
	boost_bar.value = target

# ---------------- SPEED ----------------

func _on_speed_changed(speed: float):
	speed_label.text = str(int(speed))


func _on_health_changed(current: int, max: int) -> void:
	var value: float = (float(current) / float(max)) * 100.0
	health_bar.value = value
