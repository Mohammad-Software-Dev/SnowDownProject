class_name CatchValidation
extends RefCounted

static func is_valid(
	catch_origin: Vector3,
	forward: Vector3,
	projectile_position: Vector3,
	projectile_velocity: Vector3,
	catch_range: float,
	half_angle_degrees: float
) -> bool:
	var offset := projectile_position - catch_origin
	var distance := offset.length()
	if distance <= 0.0001 or distance > catch_range:
		return false

	var direction_to_projectile := offset / distance
	var normalized_forward := forward.normalized()
	var minimum_dot := cos(deg_to_rad(half_angle_degrees))
	if normalized_forward.dot(direction_to_projectile) < minimum_dot:
		return false

	var direction_to_catcher := -direction_to_projectile
	if projectile_velocity.dot(direction_to_catcher) <= 0.0:
		return false

	return true
