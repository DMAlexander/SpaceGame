extends Resource
class_name WaveResource

@export var count: int = 5
@export var delay: float = 0.5

@export var pattern: Pattern = Pattern.LINE
@export var enemy_scene: PackedScene

enum Pattern {
	LINE,
	WIDE,
	CENTER,
	V
}

@export var formation_speed: float = 100.0
@export var formation_offset: Vector2 = Vector2.ZERO

@export var spacing: float = 80.0

# NEW
@export var dive_speed: float = 300.0

@export_range(0.0, 1.0)
var dive_chance: float = 0.25
