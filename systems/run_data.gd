extends Node

var score: int = 0

# Persistent run upgrades
var damage_bonus: int = 0
var fire_rate_bonus: float = 0.0
var max_health_bonus: int = 0

func reset_run():
	score = 0

	damage_bonus = 0
	fire_rate_bonus = 0.0
	max_health_bonus = 0
