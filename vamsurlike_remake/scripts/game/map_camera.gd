class_name MapCamera
extends Camera2D

# Map size mirrors MapConfig.MAP_SIZE / project.godot.
const MW := 2560.0
const MH := 1440.0
# Design-time logical viewport (project.godot window size). Used only as a
# fallback when the viewport reports a degenerate size (e.g. headless -s mode
# before layout).
const DESIGN_VW := 1280.0
const DESIGN_VH := 720.0

var player: Node2D = null

func _ready() -> void:
	player = _find_player()

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = _find_player()
		if player == null:
			return

	# Read the ACTUAL viewport size instead of hardcoding 1280x720. If a device
	# ever runs with a different logical size (stretch not applied, different
	# aspect), hardcoded constants clamp the camera too early and the player
	# walks off-screen at the map edges — the on-device "blue box disappears"
	# bug.
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		vp_size = Vector2(DESIGN_VW, DESIGN_VH)
	var half := (vp_size * 0.5) / zoom

	var pos := player.global_position
	pos.x = _clamp_axis(pos.x, MW, half.x)
	pos.y = _clamp_axis(pos.y, MH, half.y)
	global_position = pos


## Clamp the camera so the viewport stays inside the map; center it on that
## axis when the map is smaller than the viewport.
func _clamp_axis(p: float, map_size: float, half_view: float) -> float:
	if half_view <= 0.0 or map_size <= half_view * 2.0:
		return map_size * 0.5
	return clampf(p, half_view, map_size - half_view)


func _find_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Node2D:
			return node as Node2D
	return null
