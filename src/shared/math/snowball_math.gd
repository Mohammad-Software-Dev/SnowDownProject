class_name SnowballMath
extends RefCounted

static func integrate_velocity(current_velocity: Vector3, delta: float, gravity: float, gravity_scale: float, drag: float) -> Vector3:
	var next_velocity := current_velocity
	next_velocity.y -= gravity * gravity_scale * delta
	if drag > 0.0:
		next_velocity *= maxf(0.0, 1.0 - drag * delta)
	return next_velocity

static func simulate_step(position: Vector3, velocity: Vector3, delta: float, gravity: float, gravity_scale: float, drag: float) -> Dictionary:
	var next_velocity := integrate_velocity(velocity, delta, gravity, gravity_scale, drag)
	var next_position := position + (velocity + next_velocity) * 0.5 * delta
	return {
		"position": next_position,
		"velocity": next_velocity,
	}
