class_name PlayerStats
extends Node


## Player statistics and health management.
## All damage/healing flows through this node; the HUD subscribes to its signals.


@export var current_hp: int = 100
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 5

signal hp_changed(current: int, max_hp: int)
signal died


func _ready() -> void:
	# Clamp initial values
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)


func take_damage(amount: int) -> void:
	if current_hp <= 0:
		return

	var actual_damage: int = max(1, amount - defense)
	current_hp = maxi(0, current_hp - actual_damage)
	hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0:
		_on_died()


func heal(amount: int) -> void:
	if current_hp >= max_hp:
		return

	current_hp = mini(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)


func _on_died() -> void:
	died.emit()
