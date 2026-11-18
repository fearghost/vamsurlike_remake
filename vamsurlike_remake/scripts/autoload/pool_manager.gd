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
	var p := ObjectPool.new()
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
