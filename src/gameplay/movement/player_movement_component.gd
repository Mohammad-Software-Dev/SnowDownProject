class_name PlayerMovementComponent
extends Node

const STATE_GROUNDED := &"grounded"
const STATE_AIRBORNE := &"airborne"
const STATE_CROUCHED := &"crouched"
const STATE_SLIDING := &"sliding"
const SURFACE_SNOW := &"snow"
const SURFACE_ICE := &"ice"
const SURFACE_AIR := &"air"

var locomotion_state: StringName = STATE_AIRBORNE
var current_surface: StringName = SURFACE_AIR
var _body: CharacterBody3D
var _coyote_remaining: float = 0.0
var _jump_buffer_remaining: float = 0.0
var _slide_remaining: float = 0.0
var _slide_direction: Vector3 = Vector3.ZERO
var _sliding: bool = false

func _ready() -> void:
	_body = get_node("../..") as CharacterBody3D
	assert(_body != null, "PlayerMovementComponent must be two levels below CharacterBody3D")

func simulate(command: PlayerInputCommand, delta: float, speed_multiplier: float = 1.0) -> void:
	var config := GameConfig.player_movement
	_update_grace_windows(command, delta, config)

	if _should_begin_slide(command, config):
		_begin_slide(config)

	if _sliding:
		_simulate_slide(delta, config)
	else:
		_simulate_standard_movement(command, delta, config, speed_multiplier)

	_try_jump(config)
	_apply_gravity(delta, config)
	_body.move_and_slide()
	_update_surface_state()
	_update_locomotion_state(command)

func reset() -> void:
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_slide_remaining = 0.0
	_slide_direction = Vector3.ZERO
	_sliding = false
	current_surface = SURFACE_AIR
	locomotion_state = STATE_AIRBORNE

func is_sliding() -> bool:
	return _sliding

func horizontal_speed() -> float:
	return Vector2(_body.velocity.x, _body.velocity.z).length()

func _update_grace_windows(command: PlayerInputCommand, delta: float, config: PlayerMovementConfig) -> void:
	if _body.is_on_floor():
		_coyote_remaining = config.coyote_time_seconds
	else:
		_coyote_remaining = maxf(0.0, _coyote_remaining - delta)

	if command.jump_pressed:
		_jump_buffer_remaining = config.jump_buffer_seconds
	else:
		_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)

func _should_begin_slide(command: PlayerInputCommand, config: PlayerMovementConfig) -> bool:
	return command.crouch_pressed \
		and _body.is_on_floor() \
		and not _sliding \
		and horizontal_speed() >= config.slide_entry_speed

func _begin_slide(config: PlayerMovementConfig) -> void:
	_sliding = true
	_slide_remaining = config.slide_max_seconds
	var horizontal := Vector3(_body.velocity.x, 0.0, _body.velocity.z)
	_slide_direction = horizontal.normalized()
	if _slide_direction.is_zero_approx():
		_slide_direction = -_body.global_transform.basis.z.normalized()
	_body.velocity.x += _slide_direction.x * config.slide_initial_boost
	_body.velocity.z += _slide_direction.z * config.slide_initial_boost

func _simulate_slide(delta: float, config: PlayerMovementConfig) -> void:
	_slide_remaining = maxf(0.0, _slide_remaining - delta)
	var friction := config.slide_friction
	if current_surface == SURFACE_ICE:
		friction *= config.ice_slide_friction_multiplier
	var speed := horizontal_speed()
	speed = move_toward(speed, 0.0, friction * delta)
	_body.velocity.x = _slide_direction.x * speed
	_body.velocity.z = _slide_direction.z * speed

	if _slide_remaining <= 0.0 or speed < config.slide_min_speed or not _body.is_on_floor():
		_sliding = false

func _simulate_standard_movement(command: PlayerInputCommand, delta: float, config: PlayerMovementConfig, speed_multiplier: float) -> void:
	var local_wish := Vector3(command.move.x, 0.0, command.move.y)
	var world_wish := (_body.global_transform.basis * local_wish)
	world_wish.y = 0.0
	world_wish = world_wish.normalized() if world_wish.length_squared() > 0.0001 else Vector3.ZERO

	var target_speed := config.walk_speed
	if command.crouch_held and _body.is_on_floor():
		target_speed = config.crouch_speed
	elif command.sprint_held:
		target_speed = config.sprint_speed

	if _body.is_on_floor() and current_surface == SURFACE_ICE:
		target_speed *= config.ice_ground_speed_multiplier
	if not _body.is_on_floor():
		target_speed = minf(target_speed, config.air_speed_cap)
	target_speed *= clampf(speed_multiplier, 0.0, 1.0)

	var target_velocity := world_wish * target_speed
	var acceleration := config.air_acceleration
	if _body.is_on_floor():
		acceleration = config.ground_acceleration if not world_wish.is_zero_approx() else config.ground_deceleration

	_body.velocity.x = move_toward(_body.velocity.x, target_velocity.x, acceleration * delta)
	_body.velocity.z = move_toward(_body.velocity.z, target_velocity.z, acceleration * delta)

func _try_jump(config: PlayerMovementConfig) -> void:
	if _jump_buffer_remaining <= 0.0 or _coyote_remaining <= 0.0:
		return
	_body.velocity.y = config.jump_velocity
	_jump_buffer_remaining = 0.0
	_coyote_remaining = 0.0
	_sliding = false

func _apply_gravity(delta: float, config: PlayerMovementConfig) -> void:
	if not _body.is_on_floor():
		_body.velocity.y -= config.gravity * delta
	elif _body.velocity.y < 0.0:
		_body.velocity.y = 0.0

func _update_surface_state() -> void:
	if not _body.is_on_floor():
		current_surface = SURFACE_AIR
		return
	current_surface = SURFACE_SNOW
	for index in range(_body.get_slide_collision_count()):
		var collision := _body.get_slide_collision(index)
		if collision.get_normal().dot(_body.up_direction) < 0.65:
			continue
		var collider := collision.get_collider() as Node
		if collider != null and collider.is_in_group("fast_surface"):
			current_surface = SURFACE_ICE
			return

func _update_locomotion_state(command: PlayerInputCommand) -> void:
	if _sliding:
		locomotion_state = STATE_SLIDING
	elif not _body.is_on_floor():
		locomotion_state = STATE_AIRBORNE
	elif command.crouch_held:
		locomotion_state = STATE_CROUCHED
	else:
		locomotion_state = STATE_GROUNDED
