extends Resource
class_name WaveResource

enum Pattern {
	LINE,
	WIDE,
	CENTER,
	V,
	ARC
}

@export var count: int = 5
@export var delay: float = 0.5
@export var pattern: Pattern = Pattern.LINE
@export var enemy_scene: PackedScene

# Formation behavior
@export var formation_speed: float = 100.0

# Formation shaping (NEW)
@export var spacing: float = 80.0
@export var formation_offset: Vector2 = Vector2.ZERO
