extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready():
	anim.play("explode")
	sound.play()

	anim.animation_finished.connect(_on_done)

func _on_done():
	queue_free()
