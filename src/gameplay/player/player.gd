class_name SnowdownPlayer
extends CharacterBody3D

signal projectile_spawned(projectile: SnowballProjectile)

const SNOWBALL_SCENE := preload("res://scenes/projectiles/snowball.tscn")
const STANDING_HEIGHT := 1.80
const CROUCHED_HEIGHT := 1.20
const STANDING_CAMERA_Y := 1.62
const CROUCHED_CAMERA_Y := 1.05
const STANCE_LERP_SPEED := 8.0
const AIM_DISTANCE := 100.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual_mesh: MeshInstance3D = $VisualRoot/PlaceholderBody
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var throw_origin: Marker3D = $CameraPivot/ThrowOrigin
@onready var snow_source_detector: Area3D = $SnowSourceDetector
@onready var local_input: LocalPlayerInput = $Components/LocalPlayerInput
@onready var movement: PlayerMovementComponent = $Components/Movement
@onready var inventory: SnowballInventoryComponent = $Components/Inventory
@onready var snowball_action: SnowballActionComponent = $Components/SnowballAction

var _pitch_radians: float = 0.0
var _next_projectile_id: int = 1

func _ready() -> void:
	add_to_group("local_player")
	camera.current = true
	snowball_action.configure(inventory)
	snowball_action.throw_requested.connect(_on_throw_requested)

func _physics_process(delta: float) -> void:
	var command := local_input.consume_command()
	_apply_look(command.look_delta)
	snowball_action.simulate(command, delta, _has_packable_snow(), movement.is_sliding())
	_attempt_catch()
	movement.simulate(command, delta, snowball_action.movement_multiplier())
	_update_stance(command.crouch_held or movement.is_sliding(), delta)

func teleport_to(world_position: Vector3) -> void:
	global_position = world_position
	velocity = Vector3.ZERO
	movement.reset()
	snowball_action.reset()
	inventory.reset(0)

func get_debug_snapshot() -> Dictionary:
	return {
		"position": global_position,
		"velocity": velocity,
		"speed": movement.horizontal_speed(),
		"locomotion": movement.locomotion_state,
		"on_floor": is_on_floor(),
		"inventory": inventory.current,
		"inventory_capacity": inventory.capacity(),
		"hand_state": snowball_action.state,
		"pack_progress": snowball_action.pack_progress,
		"charge": snowball_action.normalized_charge(),
		"catch_active": snowball_action.is_catch_active(),
		"last_catch_succeeded": snowball_action.last_catch_succeeded,
		"can_pack": _has_packable_snow(),
	}

func _has_packable_snow() -> bool:
	for area in snow_source_detector.get_overlapping_areas():
		if area.is_in_group("snow_source"):
			return true
	return false

func _attempt_catch() -> void:
	if not snowball_action.is_catch_active():
		return
	var catch_origin := global_position + Vector3.UP * 1.25
	var forward := -global_transform.basis.z
	for node in get_tree().get_nodes_in_group("snowball_projectile"):
		var projectile := node as SnowballProjectile
		if projectile == null or not projectile.active or projectile.owner_player == self:
			continue
		if not CatchValidation.is_valid(
			catch_origin,
			forward,
			projectile.global_position,
			projectile.velocity,
			GameConfig.snowball.catch_range,
			GameConfig.snowball.catch_half_angle_degrees
		):
			continue
		if projectile.try_catch(self):
			inventory.try_add()
			snowball_action.confirm_catch_success()
			break

func _on_throw_requested(normalized_charge: float) -> void:
	var aim_target := _resolve_aim_target()
	var origin := _resolve_safe_throw_origin(throw_origin.global_position)
	var direction := (aim_target - origin).normalized()
	if direction.is_zero_approx():
		direction = -camera.global_transform.basis.z.normalized()
	var speed := GameConfig.snowball.charge_to_speed(normalized_charge)
	var inherited_velocity := Vector3(velocity.x, 0.0, velocity.z) * GameConfig.snowball.horizontal_velocity_inheritance
	var projectile_velocity := direction * speed + inherited_velocity

	var projectile := SNOWBALL_SCENE.instantiate() as SnowballProjectile
	projectile.setup(self, origin, projectile_velocity, _next_projectile_id)
	_next_projectile_id += 1
	get_parent().add_child(projectile)
	projectile_spawned.emit(projectile)

func _resolve_aim_target() -> Vector3:
	var from := camera.global_position
	var to := from - camera.global_transform.basis.z * AIM_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("position", to)

func _resolve_safe_throw_origin(desired_origin: Vector3) -> Vector3:
	var chest_origin := global_position + Vector3.UP * 1.25
	var query := PhysicsRayQueryParameters3D.create(chest_origin, desired_origin, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return desired_origin
	var point: Vector3 = hit["position"]
	var normal: Vector3 = hit["normal"]
	return point + normal * (GameConfig.snowball.projectile_radius + 0.02)

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
