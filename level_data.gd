extends Resource
class_name LevelData

enum LevelType {
	ARCADE,
	FREE_ROAM,
	BOSS,
	SHOP
}

@export var level_name: String = "Level"

@export var scene: PackedScene

@export var level_type: LevelType = LevelType.ARCADE

@export var music_id: String = ""

@export var difficulty: int = 1

@export var has_shop_after: bool = false

@export var score_multiplier: float = 1.0

@export var intro_text: String = ""
