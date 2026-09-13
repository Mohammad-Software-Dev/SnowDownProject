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

static func is_swept_valid(
	catch_origin: Vector3,
	forward: Vector3,
	segment_from: Vector3,
	segment_to: Vector3,
	projectile_velocity: Vector3,
	catch_range: float,
	half_angle_degrees: float
) -> bool:
	var segment := segment_to - segment_from
	var closest := segment_from
	if segment.length_squared() > 0.000001:
		var t := clampf((catch_origin - segment_from).dot(segment) / segment.length_squared(), 0.0, 1.0)
		closest = segment_from + segment * t
	return is_valid(catch_origin, forward, closest, projectile_velocity, catch_range, half_angle_degrees)
