extends Control

@export var game_scene: PackedScene
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel

func _ready():
##	start_button.grab_focus()
	start_button.pressed.connect(_on_start_pressed)

	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	await Fade.fade_out(0.4)
	get_tree().change_scene_to_packed(game_scene)

func _on_quit_pressed():
	get_tree().quit()
