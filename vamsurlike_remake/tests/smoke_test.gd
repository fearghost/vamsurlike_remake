extends SceneTree
## Headless smoke test — reproduces the on-device "Start button" flow.
##
## Run (CI): godot --headless --path . -s tests/smoke_test.gd
##
## Phases:
##   1. Compile every .gd script in the project (catches parse errors).
##   2. Load + instantiate every .tscn scene, run _ready (catches scene/script
##      load failures — this is what blocks change_scene_to_packed on device).
##   3. Simulate the Start button press exactly as main_menu.gd does it and
##      verify the current scene actually changes to the combat scene.
##   4. Inject synthetic touch+drag events through the real input pipeline and
##      verify the VirtualJoystick actually moves the Player (the on-device
##      "character doesn't move / joystick invisible" bug).
##   5. Verify the Spawner put at least one enemy into the scene tree
##      (validates spawner + EnemyData .tres + enemy scene chain).
##
## Exit code: 0 = all pass, 1 = at least one failure.

var failures: Array[String] = []
var passes: Array[String] = []
var _added_nodes: Array[Node] = []
var _start_ms := 0
var _summary_printed := false
const WATCHDOG_MS := 30000


func _initialize() -> void:
	_start_ms = Time.get_ticks_msec()
	print("=== SMOKE TEST START (Godot %s) ===" % Engine.get_version_info().string)
	_run_tests()


func _process(_delta: float) -> bool:
	if not _summary_printed and Time.get_ticks_msec() - _start_ms > WATCHDOG_MS:
		failures.append("watchdog timeout — test did not finish in %d ms" % WATCHDOG_MS)
		_print_summary()
	return false


func _run_tests() -> void:
	await _ensure_autoloads()
	await _test_all_scripts_compile()
	# In -s mode there is no current scene; game code (e.g. Spawner) calls
	# get_tree().get_current_scene().add_child(...), so give it a container.
	if current_scene == null and has_method("set_current_scene"):
		var container := Node.new()
		container.name = "SmokeTestRoot"
		root.add_child(container)
		call("set_current_scene", container)
	await _test_all_scenes_load()
	await _test_start_button_flow()
	await _test_joystick_movement()
	await _test_enemy_spawning()
	_print_summary()


func _any_node_has_script(node: Node) -> bool:
	if node.get_script() != null:
		return true
	for child in node.get_children():
		if _any_node_has_script(child):
			return true
	return false


## In -s (script) mode autoloads may or may not be registered.
## Make sure the singletons the game code expects exist under /root.
func _ensure_autoloads() -> void:
	var needed := {
		"GameManager": "res://scripts/autoload/game_manager.gd",
		"SaveManager": "res://scripts/autoload/save_manager.gd",
		"PoolManager": "res://scripts/autoload/pool_manager.gd",
	}
	for name in needed:
		if root.get_node_or_null(name) != null:
			continue
		var script := load(needed[name])
		if script == null:
			failures.append("autoload %s: failed to load script %s" % [name, needed[name]])
			continue
		var node := Node.new()
		node.name = name
		node.set_script(script)
		root.add_child(node)
		_added_nodes.append(node)
		print("[autoloader] manually added /root/%s (not present in -s mode)" % name)
	await process_frame


func _test_all_scripts_compile() -> void:
	print("--- Phase 1: compile all .gd scripts ---")
	var gd_files := _list_files("res://", ".gd")
	var bad := 0
	for path in gd_files:
		if load(path) == null:
			bad += 1
			failures.append("script compile failed: %s" % path)
			printerr("[FAIL] script compile: %s" % path)
	if bad == 0:
		passes.append("all %d scripts compiled without errors" % gd_files.size())
	await process_frame


func _test_all_scenes_load() -> void:
	print("--- Phase 2: load + instantiate all .tscn scenes ---")
	var tscn_files := _list_files("res://", ".tscn")
	var bad := 0
	for path in tscn_files:
		var scene := load(path) as PackedScene
		if scene == null:
			bad += 1
			failures.append("scene load failed: %s" % path)
			printerr("[FAIL] scene load: %s" % path)
			continue
		var inst := scene.instantiate()
		if inst == null:
			bad += 1
			failures.append("scene instantiate failed: %s" % path)
			printerr("[FAIL] scene instantiate: %s" % path)
			continue
		root.add_child(inst)
		_added_nodes.append(inst)
		await process_frame
		await process_frame

		# Regression check: if the .tscn declares scripts, at least one node in
		# the instantiated tree must actually have a script attached. Godot 4
		# loads Godot-3-format (format=2) node trees but silently drops scripts —
		# that was the root cause of the dead Start button on device.
		var declares_script := FileAccess.get_file_as_string(path).find("script") >= 0
		if declares_script and not _any_node_has_script(inst):
			bad += 1
			failures.append("scene %s: scripts declared but NONE attached (wrong .tscn format?)" % path)
			printerr("[FAIL] script attachment: %s" % path)
			continue

		print("[PASS] scene load+instantiate+_ready: %s" % path)
	if bad == 0:
		passes.append("all %d scenes loaded and instantiated" % tscn_files.size())
	await process_frame


## The actual bug reproduction: press Start, verify the scene changes.
func _test_start_button_flow() -> void:
	print("--- Phase 3: simulate Start button press ---")
	# Clean slate so leftover test nodes don't interfere.
	for n in _added_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_added_nodes.clear()
	await process_frame

	var menu_scene := load("res://scenes/ui/main_menu.tscn") as PackedScene
	if menu_scene == null:
		failures.append("Start flow: cannot load main_menu.tscn")
		printerr("[FAIL] Start flow: main_menu.tscn load returned null")
		return

	var menu := menu_scene.instantiate()
	root.add_child(menu)
	_added_nodes.append(menu)
	await process_frame

	if not menu.has_method("_on_start_pressed"):
		failures.append("Start flow: main_menu.gd script is NOT attached (parse error?) — button has no handler")
		printerr("[FAIL] Start flow: _on_start_pressed() does not exist on the menu node")
		return

	var sb := menu.get_node_or_null("StartButton") as Button
	if sb == null:
		failures.append("Start flow: StartButton node missing from scene")
		return
	var conns := sb.pressed.get_connections().size()
	print("[info] StartButton.pressed connections: %d" % conns)
	if conns == 0:
		failures.append("Start flow: no handler connected to StartButton.pressed (menu _ready failed?)")

	# Call the handler exactly as a button press would.
	menu._on_start_pressed()
	await process_frame
	await process_frame
	await process_frame

	var cs := current_scene
	if cs == null:
		failures.append("Start flow: current_scene is null after _on_start_pressed() — scene change did not happen")
		printerr("[FAIL] Start flow: scene change did not happen (combat_demo.tscn load or change_scene_to_packed failed)")
		return

	print("[info] current_scene after Start press: %s" % cs.name)
	if not cs.name.to_lower().contains("combat"):
		failures.append("Start flow: current_scene is '%s', expected the combat scene" % cs.name)
	else:
		passes.append("Start button transitions to combat scene (%s)" % cs.name)

	# Let the combat scene run a few frames to surface runtime errors in _ready.
	await process_frame
	await process_frame
	await process_frame


## The on-device bug: "blue square won't move, joystick doesn't appear".
## Inject touch+drag through the real input pipeline and require the player
## to actually change position. If the pipeline path fails, we still probe
## the direct _gui_input path — but ONLY as a diagnostic to tell CI whether
## input ROUTING is broken (direct works) or the joystick logic itself is
## broken (direct also fails). The test FAILS either way: if real touch
## routing doesn't work in CI, it won't work on device.
func _test_joystick_movement() -> void:
	print("--- Phase 4: virtual joystick drives player movement ---")
	var cs := current_scene
	if cs == null or not cs.name.to_lower().contains("combat"):
		failures.append("joystick: combat scene not active (Phase 3 failed) — skipped")
		return

	var player := cs.get_node_or_null("Player")
	var joystick := cs.get_node_or_null("VirtualJoystick")
	if player == null or joystick == null:
		failures.append("joystick: Player or VirtualJoystick missing from combat scene")
		printerr("[FAIL] joystick: nodes missing (player=%s, joystick=%s)" % [str(player), str(joystick)])
		return

	# Layout diagnostics — a zero/empty rect means the control can never be
	# hit-tested (the on-device "joystick invisible / no response" symptom).
	print("[DIAG] joystick parent: %s (type %s)" % [joystick.get_parent().name, joystick.get_parent().get_class()])
	print("[DIAG] joystick rect: %s | visible_in_tree: %s | mouse_filter: %d" % [str(joystick.get_rect()), str(joystick.is_visible_in_tree()), joystick.mouse_filter])

	var start_pos: Vector2 = player.global_position
	var moved := await _touch_drag_and_check_movement(player, start_pos, 300.0, 500.0, 80.0)
	_touch(380.0, 500.0, false)
	await process_frame

	if moved:
		passes.append("virtual joystick touch+drag moves the player (via real input pipeline)")
	else:
		# Diagnostic only — proves whether the joystick logic works when the
		# event is delivered by hand (bypassing GUI hit-testing/routing).
		var direct_works := await _direct_gui_input_check(player, start_pos)
		failures.append("joystick: synthetic touch never reached the joystick via the real input pipeline (direct-drive worked=%s)" % str(direct_works))
		printerr("[FAIL] joystick movement: real input pipeline did not deliver the touch (player stayed at %s; direct _gui_input drive worked=%s)" % [str(start_pos), str(direct_works)])
		if direct_works:
			printerr("[DIAG] => input ROUTING is broken (control logic is fine). Check joystick rect/parent type and GUI hit-testing.")
		else:
			printerr("[DIAG] => joystick LOGIC itself is broken (even direct _gui_input does nothing).")


func _direct_gui_input_check(player: Node, start_pos: Vector2) -> bool:
	var joystick := current_scene.get_node_or_null("VirtualJoystick")
	if joystick == null:
		return false
	joystick._gui_input(_make_touch(300.0, 500.0, true))
	await process_frame
	joystick._gui_input(_make_drag(380.0, 500.0))
	for i in range(10):
		await process_frame
		if player.global_position != start_pos:
			return true
	_touch(380.0, 500.0, false)
	await process_frame
	return false


func _touch_drag_and_check_movement(player: Node, start_pos: Vector2, x: float, y: float, drag_dx: float) -> bool:
	_touch(x, y, true)
	await process_frame
	_drag(x + drag_dx, y)
	for i in range(20):
		await process_frame
		if player.global_position != start_pos:
			return true
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


func _touch(x: float, y: float, pressed: bool) -> void:
	Input.parse_input_event(_make_touch(x, y, pressed))


func _drag(x: float, y: float) -> void:
	Input.parse_input_event(_make_drag(x, y))


## The spawner spawns enemy #1 immediately in start_wave(); verify an enemy
## really exists in the tree (validates spawner + EnemyData .tres + enemy scene).
func _test_enemy_spawning() -> void:
	print("--- Phase 5: spawner spawns enemies into the scene tree ---")
	var cs := current_scene
	if cs == null or not cs.name.to_lower().contains("combat"):
		failures.append("spawning: combat scene not active (Phase 3 failed) — skipped")
		return
	await process_frame
	await process_frame
	var enemies := get_nodes_in_group("enemies")
	if enemies.size() > 0:
		passes.append("spawner spawned %d enemy(ies) into the scene tree" % enemies.size())
	else:
		failures.append("spawning: no enemies in group 'enemies' after combat start (spawner or EnemyData load broken?)")
		printerr("[FAIL] spawning: 0 enemies in tree")


func _print_summary() -> void:
	if _summary_printed:
		return
	_summary_printed = true
	print("=== SMOKE TEST SUMMARY ===")
	for p in passes:
		print("[PASS] " + p)
	for f in failures:
		print("[FAIL] " + f)
	if failures.is_empty():
		print("RESULT: PASS")
		quit(0)
	else:
		print("RESULT: FAIL (%d failure(s))" % failures.size())
		quit(1)


func _list_files(dir_path: String, ext: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full := dir_path.path_join(file_name)
		if dir.current_is_dir():
			if file_name != "." and file_name != ".." and not file_name.begins_with("."):
				result.append_array(_list_files(full, ext))
		elif file_name.ends_with(ext):
			result.append(full)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result
