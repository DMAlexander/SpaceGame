extends CanvasLayer

@onready var rect: ColorRect = $ColorRect

func _ready():
	rect.modulate.a = 0.0


func fade_out(duration := 0.3):
	await _fade(0.0, 1.0, duration)


func fade_in(duration := 0.3):
	await _fade(1.0, 0.0, duration)

func _fade(from: float, to: float, duration: float):
	rect.modulate.a = from

	var tween = get_tree().create_tween()
	tween.tween_property(rect, "modulate:a", to, duration)

	await tween.finished
