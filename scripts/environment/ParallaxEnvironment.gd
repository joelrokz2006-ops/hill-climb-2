class_name ParallaxEnvironment
extends ParallaxBackground

## ParallaxEnvironment: Multi-layered 2D parallax environment system.
## Provides sky, animated clouds, distant mountains, mid hills, and near scenery
## with accurate depth scaling and optional gentle atmospheric drift.

@export var enable_cloud_drift: bool = true
@export var cloud_drift_speed: float = 12.0 # Pixels per second horizontal drift

@onready var clouds_layer: ParallaxLayer = get_node_or_null("CloudsLayer")
@onready var distant_clouds_layer: ParallaxLayer = get_node_or_null("DistantCloudsLayer")

func _process(delta: float) -> void:
	if enable_cloud_drift:
		if clouds_layer:
			clouds_layer.motion_offset.x += cloud_drift_speed * delta
		if distant_clouds_layer:
			distant_clouds_layer.motion_offset.x += (cloud_drift_speed * 0.4) * delta
