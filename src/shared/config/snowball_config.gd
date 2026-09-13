class_name SnowballConfig
extends Resource

@export_category("Inventory / Pack")
@export var inventory_capacity: int = 3
@export var pack_duration_seconds: float = 0.85
@export var pack_movement_multiplier: float = 0.55

@export_category("Throw")
@export var minimum_release_seconds: float = 0.08
@export var normal_charge_seconds: float = 0.65
@export var maximum_charge_seconds: float = 1.25
@export var throw_recovery_seconds: float = 0.35
@export var minimum_launch_speed: float = 14.0
@export var maximum_launch_speed: float = 26.0
@export var gravity_scale: float = 1.0
@export var drag: float = 0.0
@export var projectile_radius: float = 0.10
@export var projectile_lifetime_seconds: float = 5.0
@export var horizontal_velocity_inheritance: float = 0.75

@export_category("Catch")
@export var catch_active_seconds: float = 0.18
@export var catch_recovery_seconds: float = 0.32
@export var catch_movement_multiplier: float = 0.80
@export var catch_half_angle_degrees: float = 55.0
@export var catch_range: float = 1.35

func charge_to_speed(normalized_charge: float) -> float:
	var t := clampf(normalized_charge, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	return lerpf(minimum_launch_speed, maximum_launch_speed, eased)
