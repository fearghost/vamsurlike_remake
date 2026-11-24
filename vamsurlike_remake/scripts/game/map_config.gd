class_name MapConfig
extends RefCounted


## Shared map-wide constants for the combat scene.
## The playable area is larger than the viewport (1280x720) so the camera
## follows the player and clamps at the edges instead of showing void.

const MAP_SIZE := Vector2(2560, 1440)
