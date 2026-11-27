## PoolManager handles object pooling for projectiles, enemies, and effects.
## Reduces instantiation overhead and improves performance.
extends Node

## Initialize the group registration so other nodes can find this singleton.
func _ready() -> void:
	add_to_group("pool_manager")


## Dictionary mapping pool names to their ObjectPool instances.
var pools: Dictionary = {}


## Registers a new named object pool with [param template] and pre-allocates
## [param size] inactive instances.
func register_pool(name: String, template: PackedScene, size: int) -> void:
	# Global-class .new() is broken in Godot 4 (godotengine/godot#62360) — load the script and attach it instead.
	var pool_script := load("res://scripts/autoload/object_pool.gd") as Script
	if pool_script == null:
		push_error("PoolManager: failed to load object_pool.gd — pool '%s' not registered" % name)
		return
	var p: Variant  # explicit Variant — dynamic dispatch to the attached ObjectPool script
	p = Node.new()
	p.set_script(pool_script)
	# Keep the pool in the tree so get_object() can attach instances to it.
	add_child(p)
	p.init(template, size)
	pools[name] = p


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
