extends SceneTree
## CI probe — focused diagnostics for the two reported on-device bugs:
##   P1. Virtual joystick layout (parent type + full-viewport rect).
##   P2. Real input pipeline (Input.parse_input_event) actually moves the player.
##   P3. Enemy contact damages the player (body_entered -> take_damage).
##
## Run (CI): godot --headless --path . -s tests/_probe.gd
## Exit code: 0 = all probes pass, 1 = at least one probe failed.
##
## This probe runs BEFORE the full smoke test so a failure points straight at
## the reported symptom instead of getting buried in phase output.

var _failures: Array[String] = []
var _start_ms := 0
var _finished := false
const WATCHDOG_MS := 30000


func _initialize() -> void:
	_start_ms = Time.get_ticks_msec()
	print("=== PROBE START (Godot %s) ===" % Engine.get_version_info().string)
	_run_probes()


func _process(_delta: float) -> bool:
	if not _finished and Time.get_ticks_msec() - _start_ms > WATCHDOG_MS:
		_failures.append("watchdog timeout — probe did not finish in %d ms" % WATCHDOG_MS)
		_finish()
	return false


func _run_probes() -> void:
	await _ensure_autoloads()

	var scene := load("res://scenes/game/combat_demo.tscn") as PackedScene
	if scene == null:
		_failures.append("P0: cannot load combat_demo.tscn")
		_finish()
		return
	var cs := scene.instantiate()
	# Game code (Spawner) calls get_tree().get_current_scene(); give it a valid one
	# BEFORE _ready runs (add_child triggers _ready).
	if has_method("set_current_scene"):
		call("set_current_scene", cs)
	root.add_child(cs)
	await process_frame
	await process_frame

	var joystick := cs.find_child("VirtualJoystick", true, false)
	var player := cs.get_node_or_null("Player")
	if joystick == null or player == null:
		_failures.append("P0: VirtualJoystick (found=%s) or Player (found=%s) missing from combat scene" % [str(joystick != null), str(player != null)])
		_finish()
		return

	# --- P1: joystick layout (parent type + rect must cover the viewport) ---
	var parent := joystick.get_parent()
	print("[P1] joystick parent: %s (type %s)" % [parent.name, parent.get_class()])
	print("[P1] joystick rect: %s | visible_in_tree: %s | mouse_filter: %d" % [str(joystick.get_rect()), str(joystick.is_visible_in_tree()), joystick.mouse_filter])
	if not (parent is CanvasLayer):
		_failures.append("P1: joystick parent is '%s' — expected CanvasLayer (on-device touch routing only works with the proven CanvasLayer pattern)" % parent.get_class())
	var rs: Vector2 = joystick.get_rect().size
	if rs.x < 640.0 or rs.y < 360.0:
		_failures.append("P1: joystick rect too small to cover the viewport: %s" % str(joystick.get_rect()))

	# --- P2: real input pipeline moves the player ---
	var start_pos: Vector2 = player.global_position
	var moved := await _touch_drag_moves_player(player, start_pos)
	print("[P2] real input pipeline (Input.parse_input_event) moved player: %s" % str(moved))
	if not moved:
		_failures.append("P2: synthetic touch+drag did NOT move the player via the real input pipeline")

	# --- P3: enemy contact damages the player ---
	var stats := cs.get_node_or_null("Player/PlayerStats")
	if stats == null:
		_failures.append("P3: PlayerStats missing under Player")
	else:
		var hp_before: int = stats.current_hp
		var enemy_data_res := load("res://data/enemies/chase_01.tres") as EnemyData
		var enemy_scene := load("res://scenes/game/enemy_ai.tscn") as PackedScene
		if enemy_data_res == null or enemy_scene == null:
			_failures.append("P3: cannot load chase_01.tres / enemy_ai.tscn")
		else:
			var enemy := enemy_scene.instantiate() as EnemyAI
			if enemy == null:
				_failures.append("P3: enemy_ai.tscn instantiate failed (EnemyAI class unavailable — check enemy_ai.gd for parse errors)")
			else:
				enemy.enemy_data = enemy_data_res
				# Spawn a few pixels away so body_entered fires on overlap.
				enemy.global_position = player.global_position + Vector2(20, 0)
				cs.add_child(enemy)
				var hp_after: int = hp_before
				for i in range(30):
					await process_frame
					hp_after = stats.current_hp
					if hp_after < hp_before:
						break
				print("[P3] player HP before contact: %d, after: %d" % [hp_before, hp_after])
				if hp_after >= hp_before:
					_failures.append("P3: enemy contact did NOT reduce player HP (stayed at %d)" % hp_before)

	_finish()


func _touch_drag_moves_player(player: Node, start_pos: Vector2) -> bool:
	Input.parse_input_event(_make_touch(300.0, 500.0, true))
	await process_frame
	Input.parse_input_event(_make_drag(380.0, 500.0))
	for i in range(20):
		await process_frame
		if player.global_position != start_pos:
			Input.parse_input_event(_make_touch(380.0, 500.0, false))
			return true
	Input.parse_input_event(_make_touch(380.0, 500.0, false))
	await process_frame
	return false


func _make_touch(x: float, y: float, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = Vector2(x, y)
	e.pressed = pressed
	return e


func _make_drag(x: float, y: float) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = Vector2(x, y)
	return e


## In -s (script) mode autoloads may or may not be registered.
## Make sure the singletons the game code expects exist under /root.
func _ensure_autoloads() -> void:
	var needed := {
		"GameManager": "res://scripts/autoload/game_manager.gd",
		"SaveManager": "res://scripts/autoload/save_manager.gd",
		"PoolManager": "res://scripts/autoload/pool_manager.gd",
	}
	for name in needed:
		if root.get_node_or_null(name) == null:
			var script := load(needed[name])
			if script != null:
				var node := Node.new()
				node.name = name
				node.set_script(script)
				root.add_child(node)
	await process_frame


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("=== PROBE RESULT: PASS ===")
	else:
		print("=== PROBE RESULT: FAIL (%d) ===" % _failures.size())
		for f in _failures:
			printerr("[PROBE FAIL] %s" % f)
	quit(1 if not _failures.is_empty() else 0)
