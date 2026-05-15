extends Control

signal shop_completed

const DAMAGE_COST := 100
const FIRE_RATE_COST := 150
const HEALTH_COST := 200

@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var damage_button: Button = $VBoxContainer/DamageButton
@onready var fire_rate_button: Button = $VBoxContainer/FireRateButton
@onready var health_button: Button = $VBoxContainer/HealthButton
@onready var continue_button: Button = $VBoxContainer/ContinueButton


func _ready():
	update_ui()


func update_ui():
	score_label.text = "Score: %d" % RunData.score

	damage_button.disabled = RunData.score < DAMAGE_COST
	fire_rate_button.disabled = RunData.score < FIRE_RATE_COST
	health_button.disabled = RunData.score < HEALTH_COST


# -----------------------------
# Upgrade helper (IMPORTANT)
# -----------------------------
func apply_upgrade_and_refresh(callback: Callable):
	callback.call()
	_apply_player_refresh()
	update_ui()


func _apply_player_refresh():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.refresh_run_stats()


# -----------------------------
# UPGRADES
# -----------------------------

func _on_damage_button_pressed():
	if RunData.score < DAMAGE_COST:
		return

	apply_upgrade_and_refresh(func():
		RunData.score -= DAMAGE_COST
		RunData.damage_bonus += 1
	)


func _on_fire_rate_button_pressed():
	if RunData.score < FIRE_RATE_COST:
		return

	apply_upgrade_and_refresh(func():
		RunData.score -= FIRE_RATE_COST
		RunData.fire_rate_bonus += 0.5
	)


func _on_health_button_pressed():
	if RunData.score < HEALTH_COST:
		return

	apply_upgrade_and_refresh(func():
		RunData.score -= HEALTH_COST
		RunData.max_health_bonus += 1
	)


# -----------------------------
# CONTINUE FLOW
# -----------------------------

func _on_continue_button_pressed():
	emit_signal("shop_completed")
