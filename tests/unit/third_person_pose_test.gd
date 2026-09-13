extends SceneTree

func _init() -> void:
	var idle := ThirdPersonPose.resolve(0.0, 0.0, false, ThirdPersonPose.STATE_HANDS_FREE, 0.0, 0.0, 0.0)
	var moving := ThirdPersonPose.resolve(7.5, 0.0, false, ThirdPersonPose.STATE_HANDS_FREE, 0.0, 1.0, 0.0)
	_assert_true(Vector3(moving["left_leg_rotation"]).x > 0.4, "locomotion drives left leg")
	_assert_true(Vector3(moving["right_leg_rotation"]).x < -0.4, "locomotion drives opposite leg")
	_assert_true(Vector3(idle["left_leg_rotation"]).is_zero_approx(), "idle legs remain neutral")

	var crouched := ThirdPersonPose.resolve(0.0, 0.0, true, ThirdPersonPose.STATE_HANDS_FREE, 0.0, 0.0, 0.0)
	_assert_true(Vector3(crouched["torso_position"]).y < Vector3(idle["torso_position"]).y, "crouch lowers torso")
	_assert_true(Vector3(crouched["torso_scale"]).y < 0.9, "crouch compresses torso")
	_assert_true(Vector3(crouched["head_offset"]).y < 0.0, "crouch lowers head")

	var airborne := ThirdPersonPose.resolve(5.0, 3.0, false, ThirdPersonPose.STATE_HANDS_FREE, 0.0, 1.0, 0.0)
	_assert_true(Vector3(airborne["left_leg_rotation"]).x < 0.0, "airborne overrides gait pose")
	_assert_true(Vector3(airborne["right_leg_rotation"]).x > 0.0, "airborne separates legs")

	var packing := ThirdPersonPose.resolve(0.0, 0.0, false, ThirdPersonPose.STATE_PACKING, 0.0, 0.0, 0.0)
	_assert_true(Vector3(packing["left_arm_rotation"]).x < -0.9, "packing raises left arm")
	_assert_true(Vector3(packing["right_arm_rotation"]).x < -0.9, "packing raises right arm")

	var charge_low := ThirdPersonPose.resolve(0.0, 0.0, false, ThirdPersonPose.STATE_THROW_CHARGING, 0.0, 0.0, 0.0)
	var charge_high := ThirdPersonPose.resolve(0.0, 0.0, false, ThirdPersonPose.STATE_THROW_CHARGING, 1.0, 0.0, 0.0)
	_assert_true(Vector3(charge_high["right_arm_rotation"]).distance_to(Vector3(charge_low["right_arm_rotation"])) > 0.8, "charge visibly changes throwing arm")

	var recovering := ThirdPersonPose.resolve(0.0, 0.0, false, ThirdPersonPose.STATE_THROW_RECOVERING, 0.0, 0.0, 0.0)
	_assert_true(Vector3(recovering["right_arm_rotation"]).x < -1.2, "throw recovery follows through")

	var catching := ThirdPersonPose.resolve(0.0, 0.0, false, ThirdPersonPose.STATE_CATCHING, 0.0, 0.0, 0.0)
	_assert_true(Vector3(catching["left_arm_rotation"]).x < -1.2, "catch raises left arm")
	_assert_true(Vector3(catching["right_arm_rotation"]).x < -1.2, "catch raises right arm")

	var reaction := ThirdPersonPose.resolve(0.0, 0.0, false, ThirdPersonPose.STATE_HANDS_FREE, 0.0, 0.0, 1.0)
	_assert_true(absf(Vector3(reaction["torso_rotation"]).x) > 0.05, "confirmed hit reaction moves torso")

	print("SNOWDOWN_TP_POSE_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)
