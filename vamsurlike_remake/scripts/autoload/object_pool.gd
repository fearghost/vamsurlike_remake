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
	var parent := obj.get_parent()
	if parent != null:
		# Still in the tree because a previous release's deferred remove_child
		# has not run yet. Cancel it — this object is active again, and the
		# pending removal would yank it out of the tree at end of frame.
		parent.remove_call_deferred("remove_child", [obj])
	else:
		# A node outside the tree never runs _process and its Area2D signals
		# never fire — it must be in the tree before use, or it is invisible,
		# immobile, and deals no damage.
		var tree := get_tree()
		if tree != null:
			var container := tree.current_scene
			if container == null:
				container = tree.root
			container.add_child(obj)
	return obj


## Returns an [param obj] to the pool, marking it as inactive and hiding it.
func release_object(obj: Node2D) -> void:
	# Double-release guard: _on_destroyed can fire twice for one shot (e.g.
	# body_entered and lifetime expiry in the same frame). Without this the
	# object would be appended to the pool twice and two deferred removals
	# would be scheduled for it.
	if pool.has(obj):
		return
	if active_objects.has(obj):
		active_objects.erase(obj)

	obj.visible = false
	# Remove from the tree so a hidden (pooled) object stops monitoring —
	# visible=false does NOT disable Area2D collision detection.
	if obj.get_parent() != null:
		# Godot 4 has no remove_from_scene()/remove_from_parent() — the parent
		# must remove the child. And release_object is often called from a
		# physics callback (Area2D body_entered / _physics_process lifetime),
		# where removing a CollisionObject immediately is NOT allowed — it
		# corrupts physics server state. call_deferred defers the removal to
		# end of frame, after the physics step completes.
		obj.get_parent().call_deferred("remove_child", obj)
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
