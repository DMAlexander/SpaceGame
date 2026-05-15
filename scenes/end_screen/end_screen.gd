extends Control

signal restart_requested
signal menu_requested

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var menu_button: Button = $VBoxContainer/MenuButton

func _ready():
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)

	# Example run data hookup (adjust to your system)
	score_label.text = "Score: " + str(RunData.score)
	stats_label.text = "Upgrades: " + str(RunData.upgrades_taken)

func _on_restart():
	emit_signal("restart_requested")

func _on_menu():
	emit_signal("menu_requested")
