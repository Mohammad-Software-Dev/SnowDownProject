class_name SnowdownPlayer
extends CharacterBody3D

const STANDING_HEIGHT := 1.80
const CROUCHED_HEIGHT := 1.20
const STANDING_CAMERA_Y := 1.62
const CROUCHED_CAMERA_Y := 1.05
const STANCE_LERP_SPEED := 8.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual_mesh: MeshInstance3D = $VisualRoot/PlaceholderBody
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var local_input: LocalPlayerInput = $Components/LocalPlayerInput
@onready var movement: PlayerMovementComponent = $Components/Movement

var _pitch_radians: float = 0.0

func _ready() -> void:
	add_to_group("local_player")
	camera.current = true

func _physics_process(delta: float) -> void:
	var command := local_input.consume_command()
	_apply_look(command.look_delta)
	movement.simulate(command, delta)
	_update_stance(command.crouch_held or movement.is_sliding(), delta)

func teleport_to(world_position: Vector3) -> void:
	global_position = world_position
	velocity = Vector3.ZERO
	movement.reset()

func get_debug_snapshot() -> Dictionary:
	return {
		"position": global_position,
		"velocity": velocity,
		"speed": movement.horizontal_speed(),
		"locomotion": movement.locomotion_state,
		"on_floor": is_on_floor(),
	}

func _apply_look(relative: Vector2) -> void:
	if relative.is_zero_approx():
		return
	var config := GameConfig.player_movement
	rotate_y(-relative.x * config.mouse_sensitivity)
	_pitch_radians = clampf(
		_pitch_radians - relative.y * config.mouse_sensitivity,
		deg_to_rad(config.pitch_min_degrees),
		deg_to_rad(config.pitch_max_degrees)
	)
	camera_pivot.rotation.x = _pitch_radians

func _update_stance(crouched: bool, delta: float) -> void:
	var target_height := CROUCHED_HEIGHT if crouched else STANDING_HEIGHT
	var target_camera_y := CROUCHED_CAMERA_Y if crouched else STANDING_CAMERA_Y
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule != null:
		capsule.height = move_toward(capsule.height, target_height, STANCE_LERP_SPEED * delta)
		collision_shape.position.y = capsule.height * 0.5
		visual_mesh.position.y = capsule.height * 0.5
	camera_pivot.position.y = move_toward(camera_pivot.position.y, target_camera_y, STANCE_LERP_SPEED * delta)
