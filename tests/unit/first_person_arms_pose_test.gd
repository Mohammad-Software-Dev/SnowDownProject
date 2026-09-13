extends SceneTree

func _init() -> void:
	var idle := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_HANDS_FREE, 0.0, 0.0, 0, 0.0, 0.0)
	_assert_true(not bool(idle["ball_visible"]), "idle without inventory hides ball")

	var hold := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_HANDS_FREE, 0.0, 0.0, 2, 0.0, 0.0)
	_assert_true(bool(hold["ball_visible"]), "inventory exposes hold ball")

	var packing_early := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_PACKING, 0.2, 0.0, 0, 0.0, 0.0)
	var packing_late := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_PACKING, 0.9, 0.0, 0, 0.0, 0.0)
	_assert_true(not bool(packing_early["ball_visible"]), "early packing has not formed ball")
	_assert_true(bool(packing_late["ball_visible"]), "late packing forms ball")
	_assert_true(float(packing_late["ball_scale"]) > float(packing_early["ball_scale"]), "packing grows visible ball")

	var charge_low := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_THROW_CHARGING, 0.0, 0.1, 1, 0.0, 0.0)
	var charge_high := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_THROW_CHARGING, 0.0, 1.0, 1, 0.0, 0.0)
	_assert_true(Vector3(charge_high["right_position"]).distance_to(Vector3(charge_low["right_position"])) > 0.08, "charge visibly changes wind-up")

	var catch_pose := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_CATCHING, 0.0, 0.0, 1, 0.0, 0.0)
	_assert_true(not bool(catch_pose["ball_visible"]), "catch pose opens hands")
	_assert_true(absf(Vector3(catch_pose["left_position"]).x) < absf(FirstPersonArmsPose.IDLE_LEFT.x), "catch hands converge")

	var reaction := FirstPersonArmsPose.resolve(FirstPersonArmsPose.STATE_HANDS_FREE, 0.0, 0.0, 0, 0.0, 1.0)
	_assert_true(Vector3(reaction["right_position"]).z > FirstPersonArmsPose.IDLE_RIGHT.z, "reaction pushes hands toward camera")

	print("SNOWDOWN_FP_ARMS_POSE_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)
