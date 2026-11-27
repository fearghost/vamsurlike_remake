class_name CharacterBody
extends Node2D

## Builds the quarter-view knight figure (shadow + cape + armored body + head/helmet
## + held sword) from a CharacterData resource. Used by PlayerController in combat
## and by the character select screen previews — one drawing path for both.

@export var character: CharacterData = null


func setup(data: CharacterData) -> void:
	character = data


static func load_character(id: String) -> CharacterData:
	var path := "res://data/characters/%s.tres" % id
	if ResourceLoader.exists(path):
		var data := load(path) as CharacterData
		if data != null:
			return data
	printerr("[CharacterBody] character '%s' not found at %s — falling back to female_knight" % [id, path])
	if ResourceLoader.exists("res://data/characters/female_knight.tres"):
		var f := load("res://data/characters/female_knight.tres") as CharacterData
		if f != null:
			return f
	# Last resort — create via a fresh Resource with the script attached (global-class .new() is broken in Godot 4)
	var data_script := load("res://scripts/data/character_data.gd") as Script
	if data_script == null:
		return null
	var fallback := Resource.new()
	fallback.set_script(data_script)
	return fallback as CharacterData


func _ready() -> void:
	if child_count > 0:
		return  # already built (e.g. declared in a .tscn) — do not duplicate
	var data := character if character != null else load_character("female_knight")
	_build(data)


func _ellipse_polygon(rx: float, ry: float, segments: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(segments):
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _add_poly(parent: Node2D, polygon: PackedVector2Array, color: Color, pos: Vector2 = Vector2.ZERO) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = polygon
	p.color = color
	if pos != Vector2.ZERO:
		p.position = pos
	parent.add_child(p)
	return p


func _build(data: CharacterData) -> void:
	# Ground shadow — light from upper-left, so the shadow falls lower-right and peeks out below the base
	var shadow := Polygon2D.new()
	shadow.polygon = _ellipse_polygon(15.0, 6.0)
	shadow.color = Color(0, 0, 0, 0.30)
	shadow.position = Vector2(4, 9)
	add_child(shadow)

	# Cloak/cape — flows behind the figure down past the feet (drawn first so it sits under everything else)
	var cape := PackedVector2Array([
		Vector2(-8.0, -12.0), Vector2(8.0, -12.0),
		Vector2(13.5, 6.0), Vector2(9.0, 16.0),
		Vector2(-9.0, 16.0), Vector2(-13.5, 6.0),
	])
	_add_poly(self, cape, data.cape_color)
	var cape_shade := PackedVector2Array([
		Vector2(-6.5, -10.0), Vector2(6.5, -10.0),
		Vector2(9.5, 4.0), Vector2(6.0, 12.5),
		Vector2(-6.0, 12.5), Vector2(-9.5, 4.0),
	])
	_add_poly(self, cape_shade, data.cape_color.darkened(0.35))

	# Armored body — slightly flattened ellipse reads as viewed from above at an angle
	var circle := Polygon2D.new()
	circle.polygon = _ellipse_polygon(13.5, 11.0)
	circle.color = data.armor_color
	circle.position = Vector2(0, -3)
	add_child(circle)

	# Highlight — upper-left light source (brighter than the armor)
	var hi := Polygon2D.new()
	hi.polygon = _ellipse_polygon(6.0, 4.5)
	hi.color = data.armor_color.lightened(0.35) if not data.has_helmet else Color(1.00, 1.00, 1.00, 1)
	hi.position = Vector2(-4.5, -7.5)
	add_child(hi)

	if data.has_helmet:
		# Full black helmet — covers the whole head ellipse (no skin/hair visible)
		var helm := Polygon2D.new()
		helm.polygon = _ellipse_polygon(6.5, 6.0)
		helm.color = data.helmet_color
		helm.position = Vector2(0, -14.5)
		add_child(helm)
		# Visor slit — horizontal dark band across the face area
		var visor := PackedVector2Array([
			Vector2(-4.6, -14.8), Vector2(4.6, -14.8), Vector2(3.8, -12.9), Vector2(-3.8, -12.9),
		])
		_add_poly(self, visor, Color(0.02, 0.02, 0.03, 1))
		# Helmet sheen — small bright arc upper-left of the dome
		var sheen := Polygon2D.new()
		sheen.polygon = _ellipse_polygon(2.6, 1.8)
		sheen.color = Color(0.55, 0.56, 0.62, 1)
		sheen.position = Vector2(-2.4, -17.3)
		add_child(sheen)
	else:
		# Head — skin tone with hair (female look: visible locks past the shoulders)
		var head := Polygon2D.new()
		head.polygon = _ellipse_polygon(6.0, 5.5)
		head.color = data.skin_color
		head.position = Vector2(0, -14.5)
		add_child(head)

		var hair := PackedVector2Array([
			Vector2(-6.0, -15.5), Vector2(-4.5, -20.5), Vector2(0, -21.5),
			Vector2(4.5, -20.5), Vector2(6.0, -15.5), Vector2(3.5, -17.5),
			Vector2(-3.5, -17.5),
		])
		_add_poly(self, hair, data.hair_color)

		if data.side_locks:
			# Side locks — two strands hanging down past the shoulders (in front of the cape edges)
			for side in [-1, 1]:
				var lock := PackedVector2Array([
					Vector2(side * 5.0, -15.0), Vector2(side * 8.5, -13.0),
					Vector2(side * 7.0, -3.0), Vector2(side * 4.5, -6.0),
				])
				_add_poly(self, lock, data.hair_color)

		# Headband across the forehead — reads as a knight's headband over the hairline
		var band := PackedVector2Array([
			Vector2(-5.0, -18.5), Vector2(5.0, -18.5), Vector2(4.2, -16.8), Vector2(-4.2, -16.8),
		])
		_add_poly(self, band, data.band_color)

	# Sword held at the figure's right edge — handle near the hand, guard, then blade down past the feet
	var grip := PackedVector2Array([
		Vector2(11.5, -3.0), Vector2(17.0, -3.0), Vector2(16.6, 5.5), Vector2(12.0, 5.5),
	])
	_add_poly(self, grip, Color(0.24, 0.18, 0.14, 1))
	var guard := PackedVector2Array([
		Vector2(8.5, 5.0), Vector2(19.5, 5.0), Vector2(19.5, 9.0), Vector2(8.5, 9.0),
	])
	_add_poly(self, guard, data.sword_guard_color)
	var blade := PackedVector2Array([
		Vector2(10.6, 9.0), Vector2(17.4, 9.0), Vector2(15.7, 33.5),
		Vector2(14.0, 38.5), Vector2(12.3, 33.5),
	])
	_add_poly(self, blade, data.sword_blade_color)
	# Center ridge — thin lighter stripe down the blade (reads as a polished edge)
	var ridge := PackedVector2Array([
		Vector2(13.4, 10.0), Vector2(14.6, 10.0), Vector2(14.3, 32.5), Vector2(13.7, 32.5),
	])
	_add_poly(self, ridge, data.sword_blade_color.lightened(0.30))
