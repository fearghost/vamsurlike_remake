class_name MapCamera
extends Camera2D

# Viewport size (1280x720) and map size (2560x1440) mirror project.godot / MapConfig.
const VW := 1280.0
const VH := 720.0
const MW := 2560.0
const MH := 1440.0

var player: Node2D = null

func _ready() -> void:
	player = _find_player()

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = _find_player()
		if player == null:
			return
	var hw := VW * 0.5
	var hh := VH * 0.5
	var mx := MW - hw
	var my := MH - hh
	var pos := player.global_position
	if MW <= VW:
		pos.x = MW * 0.5
	else:
		pos.x = clampf(pos.x, hw, mx)
	if MH <= VH:
		pos.y = MH * 0.5
	else:
		pos.y = clampf(pos.y, hh, my)
	global_position = pos

func _find_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("player"):
		if node is Node2D:
			return node as Node2D
	return null
