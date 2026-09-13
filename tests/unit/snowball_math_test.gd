extends SceneTree

func _initialize() -> void:
	var result := SnowballMath.simulate_step(
		Vector3.ZERO,
		Vector3(0.0, 10.0, 0.0),
		0.5,
		10.0,
		1.0,
		0.0
	)
	var position: Vector3 = result["position"]
	var velocity: Vector3 = result["velocity"]
	if not is_equal_approx(velocity.y, 5.0):
		push_error("expected vertical velocity 5.0, got %f" % velocity.y)
		quit(1)
		return
	if not is_equal_approx(position.y, 3.75):
		push_error("expected vertical position 3.75, got %f" % position.y)
		quit(1)
		return
	print("SNOWDOWN_SNOWBALL_MATH_OK")
	quit(0)
