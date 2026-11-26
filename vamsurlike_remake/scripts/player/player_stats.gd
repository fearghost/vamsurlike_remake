class_name PlayerStats
extends Node


## Player statistics, health management, and the XP/level system.
## All damage/healing flows through this node; the HUD subscribes to its signals.


@export var current_hp: int = 100
@export var max_hp: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var level: int = 1
var xp: int = 0

signal hp_changed(current: int, max_hp: int)
signal died
signal leveled_up(new_level: int)
signal xp_changed(current: int, needed: int, level: int)


func _ready() -> void:
	add_to_group("player_stats")

	# Clamp initial values
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp, max_hp)
	xp_changed.emit(xp, xp_to_next(), level)


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


func xp_to_next() -> int:
	# XP required to go from `level` to `level + 1`. Scales with level so each
	# stage grants a few levels instead of one big jump.
	return 25 + (level - 1) * 25


func gain_xp(amount: int) -> void:
	if amount <= 0 or level < 1:
		return

	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_next(), level)


func _on_died() -> void:
	died.emit()
