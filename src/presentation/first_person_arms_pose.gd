class_name FirstPersonArmsPose
extends RefCounted

const STATE_HANDS_FREE := &"hands_free"
const STATE_PACKING := &"packing"
const STATE_THROW_CHARGING := &"throw_charging"
const STATE_THROW_RECOVERING := &"throw_recovering"
const STATE_CATCHING := &"catching"

const IDLE_LEFT := Vector3(-0.27, -0.27, -0.48)
const IDLE_RIGHT := Vector3(0.27, -0.27, -0.48)
const IDLE_LEFT_ROT := Vector3(-1.02, 0.08, -0.18)
const IDLE_RIGHT_ROT := Vector3(-1.02, -0.08, 0.18)

static func resolve(
	hand_state: StringName,
	pack_progress: float,
	charge: float,
	inventory: int,
	motion_wave: float,
	reaction_strength: float
) -> Dictionary:
	var pack := clampf(pack_progress, 0.0, 1.0)
	var normalized_charge := clampf(charge, 0.0, 1.0)
	var subtle_motion := clampf(motion_wave, -1.0, 1.0) * 0.008
	var reaction := clampf(reaction_strength, 0.0, 1.0)
	var left_position := IDLE_LEFT + Vector3(0.0, subtle_motion, reaction * 0.035)
	var right_position := IDLE_RIGHT + Vector3(0.0, -subtle_motion, reaction * 0.05)
	var left_rotation := IDLE_LEFT_ROT
	var right_rotation := IDLE_RIGHT_ROT
	var ball_position := Vector3(0.19, -0.19, -0.50)
	var ball_scale := 1.0
	var ball_visible := inventory > 0

	match hand_state:
		STATE_PACKING:
			var gather := smoothstep(0.0, 1.0, pack)
			left_position = IDLE_LEFT.lerp(Vector3(-0.105, -0.14, -0.47), gather)
			right_position = IDLE_RIGHT.lerp(Vector3(0.105, -0.14, -0.47), gather)
			left_rotation = IDLE_LEFT_ROT.lerp(Vector3(-1.32, 0.18, -0.48), gather)
			right_rotation = IDLE_RIGHT_ROT.lerp(Vector3(-1.32, -0.18, 0.48), gather)
			ball_position = Vector3(0.0, -0.11, -0.54)
			ball_scale = lerpf(0.35, 1.0, gather)
			ball_visible = pack >= 0.35
		STATE_THROW_CHARGING:
			left_position = Vector3(-0.25, -0.22, -0.48)
			right_position = Vector3(0.25 + normalized_charge * 0.13, -0.20 + normalized_charge * 0.10, -0.47 + normalized_charge * 0.10)
			left_rotation = Vector3(-1.08, 0.15, -0.25)
			right_rotation = IDLE_RIGHT_ROT.lerp(Vector3(-0.55, -0.38, 0.65), normalized_charge)
			ball_position = right_position + Vector3(-0.015, 0.065, -0.055)
			ball_visible = inventory > 0
		STATE_THROW_RECOVERING:
			left_position = Vector3(-0.28, -0.24, -0.48)
			right_position = Vector3(0.08, -0.03, -0.63)
			left_rotation = IDLE_LEFT_ROT
			right_rotation = Vector3(-1.46, -0.08, 0.18)
			ball_visible = false
		STATE_CATCHING:
			left_position = Vector3(-0.12, -0.08, -0.53)
			right_position = Vector3(0.12, -0.08, -0.53)
			left_rotation = Vector3(-1.36, 0.18, -0.30)
			right_rotation = Vector3(-1.36, -0.18, 0.30)
			ball_visible = false
		_:
			if inventory > 0:
				right_position = Vector3(0.22, -0.19, -0.50)
				right_rotation = Vector3(-1.12, -0.12, 0.22)
				ball_position = right_position + Vector3(-0.01, 0.065, -0.06)

	return {
		"left_position": left_position,
		"right_position": right_position,
		"left_rotation": left_rotation,
		"right_rotation": right_rotation,
		"ball_position": ball_position,
		"ball_scale": ball_scale,
		"ball_visible": ball_visible,
	}
