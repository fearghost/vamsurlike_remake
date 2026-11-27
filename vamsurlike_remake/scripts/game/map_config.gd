class_name MapConfig
extends RefCounted


## Shared map-wide constants for the combat scene.
## The playable area is larger than the viewport (1280x720) so the camera
## follows the player and clamps at the edges instead of showing void.

const MAP_SIZE := Vector2(2560, 1440)

# Obstacles (trees/rocks) live on this layer; the player and enemies detect it
# via collision_mask so they cannot walk through them. Kept out of layers 1-2
# (player/enemy) so physical contact between those two stays distance-based.
const OBSTACLE_LAYER := 4
const OBSTACLE_MASK := 1 << (OBSTACLE_LAYER - 1)
