extends Control

signal next_level_pressed
signal menu_pressed

##@onready var next_button: Button = $Panel/NextLevelButton
##@onready var menu_button: Button = $Panel/MenuButton
##@onready var score_label: Label = $Panel/ScoreLabel


@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var next_button: Button = $Panel/VBoxContainer/NextLevelButton
@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton

# ==================================================
# INIT
# ==================================================

func _ready():

	print("LevelCompleted READY")

	if next_button:

		if not next_button.pressed.is_connected(_on_next_level_button_pressed):
			next_button.pressed.connect(_on_next_level_button_pressed)

	else:
		push_error("NextLevelButton not found!")

	if menu_button:

		if not menu_button.pressed.is_connected(_on_menu_button_pressed):
			menu_button.pressed.connect(_on_menu_button_pressed)

	else:
		push_error("MenuButton not found!")

# ==================================================
# PUBLIC API
# ==================================================

func set_score(score: int) -> void:
	score_label.text = "Score: " + str(score)


# ==================================================
# BUTTON HANDLERS
# ==================================================

func _on_next_level_button_pressed():
	print("LEVEL COMPLETE: NEXT pressed")
	emit_signal("next_level_pressed")


func _on_menu_button_pressed():
	print("LEVEL COMPLETE: MENU pressed")
	emit_signal("menu_pressed")
