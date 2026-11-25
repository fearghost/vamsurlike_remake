## Reusable pool of inactive objects.
class_name ObjectPool
extends Node

## The underlying storage for pooled objects.
var pool: Array = []

## The PackedScene template used to instantiate new objects when the pool is empty.
var template: PackedScene

## Currently active (in-use) objects tracked for convenience.
var active_objects: Array = []

## Whether this pool has been initialized with a valid template.
var is_active: bool = false


## Initializes the object pool with a [param template_scene] and pre-allocates
## [param initial_size] inactive instances.
func init(template_scene: PackedScene, initial_size: int) -> void:
	template = template_scene
	is_active = true

	for i in initial_size:
		var instance: Node2D = template.instantiate()
		instance.visible = false
		pool.append(instance)


## Retrieves an available object from the pool, or instantiates a new one if empty.
## The returned object is moved to [param active_objects] and made visible.
func get_object() -> Node2D:
	var obj: Node2D

	if pool.size() > 0:
		obj = pool.pop_back()
	else:
		if template != null:
			obj = template.instantiate()
		else:
			push_error("ObjectPool: no template set; cannot instantiate.")
			return null

	active_objects.append(obj)
	obj.visible = true
	# A node outside the tree never runs _process and its Area2D signals never
	# fire — it must be in the tree before use, or it is invisible, immobile,
	# and deals no damage.
	if obj.get_parent() == null:
		var tree := get_tree()
		if tree != null:
			var container := tree.current_scene
			if container == null:
				container = tree.root
			container.add_child(obj)
	return obj


## Returns an [param obj] to the pool, marking it as inactive and hiding it.
func release_object(obj: Node2D) -> void:
	if active_objects.has(obj):
		active_objects.erase(obj)

	obj.visible = false
	# Remove from the tree so a hidden (pooled) object stops monitoring —
	# visible=false does NOT disable Area2D collision detection.
	if obj.get_parent() != null:
		# Godot 4 has no remove_from_scene()/remove_from_parent() — the parent
		# must remove the child. (Both "convenient" names are Godot 3 / non-API
		# and raise a script error, silently leaving the node in the tree.)
		obj.get_parent().remove_child(obj)
	pool.append(obj)


## Empties the pool and clears all active object references.
func clear_pool() -> void:
	for obj in pool:
		obj.queue_free()
	pool.clear()
	active_objects.clear()


## Frees all remaining objects and resets the pool to its uninitialized state.
func reset() -> void:
	clear_pool()
	template = null
	is_active = false
