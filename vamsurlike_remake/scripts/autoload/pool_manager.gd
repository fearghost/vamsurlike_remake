class_name ObjectPool
extends Node


## Reusable pool of inactive objects.
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
	return obj


## Returns an [param obj] to the pool, marking it as inactive and hiding it.
func release_object(obj: Node2D) -> void:
	if active_objects.has(obj):
		active_objects.erase(obj)

	obj.visible = false
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


class_name PoolManager
extends Node

## Initialize the group registration so other nodes can find this singleton.
func _ready() -> void:
	add_to_group("pool_manager")


## Dictionary mapping pool names to their ObjectPool instances.
var pools: Dictionary = {}


## Registers a new named object pool with [param template] and pre-allocates
## [param size] inactive instances.
func register_pool(name: String, template: PackedScene, size: int) -> void:
	var pool := ObjectPool.new()
	pool.init(template, size)
	pools[name] = pool


## Acquires (borrows) an object from the named pool.
func acquire(name: String) -> Node2D:
	if pools.has(name):
		return pools[name].get_object()

	push_error("PoolManager: no pool registered with name '%s'" % name)
	return null


## Returns an [param obj] to the named pool.
func release(name: String, obj: Node2D) -> void:
	if pools.has(name):
		pools[name].release_object(obj)
	else:
		push_error("PoolManager: no pool registered with name '%s'" % name)
