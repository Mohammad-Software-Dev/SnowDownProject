class_name ThirdPersonPose
extends RefCounted

static func resolve(
	speed: float,
	vertical_velocity: float,
	crouched: bool,
	hand_state: StringName,
	charge: float,
	gait_wave: float,
	reaction_strength: float
) -> Dictionary:
	var move_amount := clampf(speed / 7.5, 0.0, 1.0)
	var gait := clampf(gait_wave, -1.0, 1.0) * move_amount
	var reaction := clampf(reaction_strength, 0.0, 1.0)
	var torso_position := Vector3(0.0, 1.18 if not crouched else 0.92, 0.0)
	var torso_rotation := Vector3(reaction * -0.10, 0.0, reaction * 0.08)
	var torso_scale := Vector3(1.0, 0.78 if crouched else 1.0, 1.0)
	var left_leg_rotation := Vector3(gait * 0.55, 0.0, 0.0)
	var right_leg_rotation := Vector3(-gait * 0.55, 0.0, 0.0)
	var left_arm_rotation := Vector3(-gait * 0.42, 0.0, -0.08)
	var right_arm_rotation := Vector3(gait * 0.42, 0.0, 0.08)
	var head_offset := Vector3(0.0, -0.18 if crouched else 0.0, 0.0)

	if absf(vertical_velocity) > 0.8:
		left_leg_rotation.x = -0.18
		right_leg_rotation.x = 0.22
		left_arm_rotation.x = -0.20
		right_arm_rotation.x = -0.20

	match hand_state:
		SnowballActionComponent.PACKING:
			left_arm_rotation = Vector3(-1.05, 0.0, -0.42)
			right_arm_rotation = Vector3(-1.05, 0.0, 0.42)
		SnowballActionComponent.THROW_CHARGING:
			var windup := clampf(charge, 0.0, 1.0)
			left_arm_rotation = Vector3(-0.45, 0.0, -0.22)
			right_arm_rotation = Vector3(lerpf(-0.55, 0.35, windup), -0.35 * windup, lerpf(0.18, 0.78, windup))
		SnowballActionComponent.THROW_RECOVERING:
			left_arm_rotation = Vector3(-0.20, 0.0, -0.10)
			right_arm_rotation = Vector3(-1.38, 0.0, 0.08)
		SnowballActionComponent.CATCHING:
			left_arm_rotation = Vector3(-1.28, 0.0, -0.34)
			right_arm_rotation = Vector3(-1.28, 0.0, 0.34)

	return {
		"torso_position": torso_position,
		"torso_rotation": torso_rotation,
		"torso_scale": torso_scale,
		"head_offset": head_offset,
		"left_leg_rotation": left_leg_rotation,
		"right_leg_rotation": right_leg_rotation,
		"left_arm_rotation": left_arm_rotation,
		"right_arm_rotation": right_arm_rotation,
	}
