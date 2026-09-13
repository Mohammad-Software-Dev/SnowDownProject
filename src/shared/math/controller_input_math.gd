class_name ControllerInputMath
extends RefCounted

static func shape_stick(raw: Vector2, deadzone: float) -> Vector2:
	var clamped_deadzone := clampf(deadzone, 0.0, 0.95)
	var magnitude := minf(raw.length(), 1.0)
	if magnitude <= clamped_deadzone:
		return Vector2.ZERO
	var normalized := (magnitude - clamped_deadzone) / (1.0 - clamped_deadzone)
	var curved := normalized * normalized * (3.0 - 2.0 * normalized)
	return raw.normalized() * curved
