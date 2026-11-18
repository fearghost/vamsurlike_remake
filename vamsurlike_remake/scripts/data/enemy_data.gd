class_name EnemyData
extends Resource

@export var enemy_id: String = "dummy_enemy_01"
@export var enemy_name: String = "Dummy Enemy"
@export var hp: int = 50
@export var attack: int = 5
@export var defense: int = 2
@export var speed: float = 80.0
@export var ai_pattern: String = "chase"  # "chase", "ranged", "charge"
@export var drop_table: Array[Dictionary] = []
@export var sprite_path: String = ""
