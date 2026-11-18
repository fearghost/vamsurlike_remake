class_name Spawner
extends Node2D


@export var wave_data: Array[Dictionary] = []
var current_wave: int = 0
var is_waving_active: bool = false
var _enemies_alive: int = 0

var spawn_timer: Timer
var wave_delay_timer: Timer
signal all_waves_cleared


func _ready() -> void:
	# Timer for staggered enemy spawning within a wave
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0
	spawn_timer.autostart = false
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	# Timer for delay between waves
	wave_delay_timer = Timer.new()
	wave_delay_timer.wait_time = 2.0
	wave_delay_timer.autostart = false
	wave_delay_timer.one_shot = true
	wave_delay_timer.timeout.connect(_on_wave_delay_timeout)
	add_child(wave_delay_timer)


func start_wave(wave_index: int) -> void:
	if wave_index >= wave_data.size():
		all_waves_cleared.emit()
		return

	current_wave = wave_index
	var wave := wave_data[wave_index]
	_enemies_alive = wave["enemies"].size()
	is_waving_active = true

	_spawn_next_enemy(wave)


func _spawn_next_enemy(wave: Dictionary) -> void:
	if not is_waving_active or wave["enemies"].is_empty():
		# No more enemies to spawn in this wave — wait for remaining to die
		return

	var enemy_entry := wave["enemies"].pop_front() as String
	var spawn_position := _get_random_spawn_position()

	# Load enemy data from resources
	var enemy_data_resource := _load_enemy_by_id(enemy_entry)

	spawn_enemy(enemy_data_resource, spawn_position)


func _load_enemy_by_id(enemy_id: String) -> EnemyData:
	# Search for the EnemyData resource by enemy_id
	for file in ["chase_01", "ranged_01", "charge_01"]:
		var path := "res://data/enemies/%s.tres" % file
		var res := load(path) as EnemyData
		if res != null and res.enemy_id == enemy_id:
			return res

	printerr("Spawner: No EnemyData found for ID '%s'" % enemy_id)
	return null


func _get_random_spawn_position() -> Vector2:
	# Spawn enemies at random positions around the edges of the screen
	var edge := randi() % 4
	match edge:
		0: return Vector2(randf_range(100, 300), 50)       # top-left
		1: return Vector2(randf_range(980, 1180), 50)      # top-right
		2: return Vector2(50, randf_range(100, 620))        # left
		_: return Vector2(1230, randf_range(100, 620))      # right


func spawn_enemy(enemy_data: EnemyData, position: Vector2) -> void:
	if enemy_data == null:
		return

	var enemy_scene_path := "res://scenes/game/enemy_ai.tscn"

	var enemy_scene := load(enemy_scene_path) as PackedScene
	if enemy_scene == null:
		printerr("Spawner: Failed to load enemy scene at ", enemy_scene_path)
		return

	var enemy := enemy_scene.instantiate() as EnemyAI
	if enemy == null:
		printerr("Spawner: Failed to instantiate enemy")
		return

	enemy.enemy_data = enemy_data
	enemy.global_position = position

	# Connect enemy death signal to track remaining enemies
	enemy.died.connect(_on_enemy_died)

	get_tree().current_scene.add_child(enemy)


func _on_spawn_timer_timeout() -> void:
	var wave := wave_data[current_wave]

	if wave["enemies"].is_empty():
		# All enemies queued, wait for them to die
		is_waving_active = false
		return

	# Wait for the configured interval before spawning next enemy
	var spawn_interval := wave.get("spawn_interval", 1.0) as float
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()


func _on_enemy_died() -> void:
	_enemies_alive -= 1

	if _enemies_alive <= 0:
		# Current wave cleared
		if current_wave + 1 < wave_data.size():
			# Start next wave after a delay
			wave_delay_timer.wait_time = 2.0
			wave_delay_timer.start()
		else:
			# All waves cleared
			is_waving_active = false
			all_waves_cleared.emit()


func _on_wave_delay_timeout() -> void:
	start_wave(current_wave + 1)


func all_waves_cleared() -> bool:
	return not is_waving_active and current_wave >= wave_data.size()
