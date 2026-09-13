extends SceneTree

func _initialize() -> void:
	var origin := Vector3.ZERO
	var forward := Vector3(0.0, 0.0, -1.0)
	var valid := CatchValidation.is_valid(origin, forward, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, 6.0), 1.35, 55.0)
	var rear := CatchValidation.is_valid(origin, forward, Vector3(0.0, 0.0, 1.0), Vector3(0.0, 0.0, -6.0), 1.35, 55.0)
	var moving_away := CatchValidation.is_valid(origin, forward, Vector3(0.0, 0.0, -1.0), Vector3(0.0, 0.0, -6.0), 1.35, 55.0)
	if not valid:
		push_error("frontal approaching catch should be valid")
		quit(1)
		return
	if rear:
		push_error("rear catch should be invalid")
		quit(1)
		return
	if moving_away:
		push_error("projectile moving away should be invalid")
		quit(1)
		return
	print("SNOWDOWN_CATCH_VALIDATION_OK")
	quit(0)
