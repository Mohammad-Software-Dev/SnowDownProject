class_name NetworkPlayer
extends CharacterBody3D

const MAP01_LAYOUT := preload("res://src/world/glacier_valley_layout.gd")
const SNAPSHOT_INTERVAL := 1.0 / 20.0
const RECONCILE_THRESHOLD := 0.05
const STANDING_HEIGHT := 1.80
const CROUCHED_HEIGHT := 1.20
const STANDING_CAMERA_Y := 1.62
const CROUCHED_CAMERA_Y := 1.05
const STANCE_LERP_SPEED := 8.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var movement: PlayerMovementComponent = $Components/Movement

var network_peer_id: int = 0
var team_index: int = 0
var locally_controlled: bool = false
var server_authoritative: bool = false
var reconciliation_count: int = 0
var server_rejected_inputs: int = 0

var _spawn_position: Vector3 = Vector3.ZERO
var _spawn_yaw: float = 0.0
var _latest_server_command := PlayerInputCommand.new()
var _last_received_sequence: int = 0
var _next_sequence: int = 1
var _pending_commands: Array[Dictionary] = []
var _snapshot_elapsed: float = 0.0
var _look_accumulator: Vector2 = Vector2.ZERO
var _pitch_radians: float = 0.0
var _camera_pivot: Node3D
var _remote_target_position: Vector3 = Vector3.ZERO
var _remote_target_yaw: float = 0.0
var _remote_crouched: bool = false

func configure(peer_id: int, team: int, spawn: Vector3, yaw_degrees: float, is_local: bool, is_server: bool) -> void:
	network_peer_id = peer_id
	team_index = team
	locally_controlled = is_local
	server_authoritative = is_server
	_spawn_position = spawn
	_spawn_yaw = deg_to_rad(yaw_degrees)
	global_position = spawn
	rotation.y = _spawn_yaw
	_remote_target_position = spawn
	_remote_target_yaw = _spawn_yaw
	set_multiplayer_authority(1)
	if locally_controlled:
		add_to_group("network_local_player")
	_build_client_presentation()

func _physics_process(delta: float) -> void:
	if server_authoritative:
		_server_tick(delta)
	elif locally_controlled:
		_client_prediction_tick(delta)
	else:
		_remote_interpolation_tick(delta)

func _unhandled_input(event: InputEvent) -> void:
	if not locally_controlled or server_authoritative or _is_headless():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_accumulator += event.relative
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func get_network_debug_snapshot() -> Dictionary:
	return {
		"peer_id": network_peer_id,
		"team": team_index,
		"reconciliations": reconciliation_count,
		"server_rejected_inputs": server_rejected_inputs,
		"pending_inputs": _pending_commands.size(),
		"surface": movement.current_surface,
	}

func _server_tick(delta: float) -> void:
	rotation.y = wrapf(rotation.y, -PI, PI)
	movement.simulate(_latest_server_command, delta)
	_update_stance(_latest_server_command.crouch_held or movement.is_sliding(), delta)
	_latest_server_command.jump_pressed = false
	_latest_server_command.crouch_pressed = false

	if MAP01_LAYOUT.is_out_of_bounds(GameConfig.glacier_valley, global_position):
		global_position = _spawn_position
		velocity = Vector3.ZERO
		rotation.y = _spawn_yaw
		movement.reset()

	_snapshot_elapsed += delta
	if _snapshot_elapsed >= SNAPSHOT_INTERVAL:
		_snapshot_elapsed = 0.0
		receive_state.rpc(
			_last_received_sequence,
			global_position,
			velocity,
			rotation.y,
			_latest_server_command.crouch_held or movement.is_sliding(),
			server_rejected_inputs
		)

func _client_prediction_tick(delta: float) -> void:
	var command := _read_local_command()
	_apply_local_look()
	movement.simulate(command, delta)
	_update_stance(command.crouch_held or movement.is_sliding(), delta)

	var sequence := _next_sequence
	_next_sequence += 1
	_pending_commands.append(_serialize_command(sequence, command, delta, rotation.y))
	if _pending_commands.size() > 180:
		_pending_commands.pop_front()
	submit_input.rpc_id(1, sequence, command.move, command.sprint_held, command.crouch_pressed, command.crouch_held, command.jump_pressed, rotation.y)

func _remote_interpolation_tick(delta: float) -> void:
	var weight := minf(1.0, delta * 12.0)
	global_position = global_position.lerp(_remote_target_position, weight)
	rotation.y = lerp_angle(rotation.y, _remote_target_yaw, weight)
	_update_stance(_remote_crouched, delta)

@rpc("any_peer", "call_remote", "unreliable")
func submit_input(sequence: int, move: Vector2, sprint_held: bool, crouch_pressed: bool, crouch_held: bool, jump_pressed: bool, yaw: float) -> void:
	if not server_authoritative:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != network_peer_id or sequence <= _last_received_sequence:
		server_rejected_inputs += 1
		return
	if is_nan(move.x) or is_nan(move.y) or is_inf(move.x) or is_inf(move.y) or move.length() > 1.05 or is_nan(yaw) or is_inf(yaw):
		server_rejected_inputs += 1
		return

	_last_received_sequence = sequence
	_latest_server_command.move = move.limit_length(1.0)
	_latest_server_command.sprint_held = sprint_held
	_latest_server_command.crouch_pressed = crouch_pressed
	_latest_server_command.crouch_held = crouch_held
	_latest_server_command.jump_pressed = jump_pressed
	rotation.y = wrapf(yaw, -PI, PI)

@rpc("authority", "call_remote", "unreliable")
func receive_state(ack_sequence: int, server_position: Vector3, server_velocity: Vector3, server_yaw: float, crouched: bool, rejected_inputs: int) -> void:
	if server_authoritative:
		return
	server_rejected_inputs = rejected_inputs
	if not locally_controlled:
		_remote_target_position = server_position
		_remote_target_yaw = server_yaw
		_remote_crouched = crouched
		velocity = server_velocity
		return

	var error_distance := global_position.distance_to(server_position)
	var remaining: Array[Dictionary] = []
	for record in _pending_commands:
		if int(record["sequence"]) > ack_sequence:
			remaining.append(record)
	_pending_commands = remaining

	global_position = server_position
	velocity = server_velocity
	rotation.y = server_yaw
	movement.reset()
	for record in _pending_commands:
		rotation.y = float(record["yaw"])
		var replay_command := _deserialize_command(record)
		movement.simulate(replay_command, float(record["delta"]))
		_update_stance(replay_command.crouch_held or movement.is_sliding(), float(record["delta"]))
	if error_distance >= RECONCILE_THRESHOLD:
		reconciliation_count += 1

func _read_local_command() -> PlayerInputCommand:
	var command := PlayerInputCommand.new()
	command.move = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	command.jump_pressed = Input.is_action_just_pressed("jump")
	command.sprint_held = Input.is_action_pressed("sprint")
	command.crouch_pressed = Input.is_action_just_pressed("crouch_slide")
	command.crouch_held = Input.is_action_pressed("crouch_slide")
	return command

func _apply_local_look() -> void:
	if _look_accumulator.is_zero_approx():
		return
	var config := GameConfig.player_movement
	rotation.y -= _look_accumulator.x * config.mouse_sensitivity
	_pitch_radians = clampf(
		_pitch_radians - _look_accumulator.y * config.mouse_sensitivity,
		deg_to_rad(config.pitch_min_degrees),
		deg_to_rad(config.pitch_max_degrees)
	)
	if _camera_pivot != null:
		_camera_pivot.rotation.x = _pitch_radians
	_look_accumulator = Vector2.ZERO

func _serialize_command(sequence: int, command: PlayerInputCommand, delta: float, yaw: float) -> Dictionary:
	return {
		"sequence": sequence,
		"move": command.move,
		"sprint": command.sprint_held,
		"crouch_pressed": command.crouch_pressed,
		"crouch_held": command.crouch_held,
		"jump": command.jump_pressed,
		"delta": delta,
		"yaw": yaw,
	}

func _deserialize_command(record: Dictionary) -> PlayerInputCommand:
	var command := PlayerInputCommand.new()
	command.move = Vector2(record["move"])
	command.sprint_held = bool(record["sprint"])
	command.crouch_pressed = bool(record["crouch_pressed"])
	command.crouch_held = bool(record["crouch_held"])
	command.jump_pressed = bool(record["jump"])
	return command

func _update_stance(crouched: bool, delta: float) -> void:
	var target_height := CROUCHED_HEIGHT if crouched else STANDING_HEIGHT
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule != null:
		capsule.height = move_toward(capsule.height, target_height, STANCE_LERP_SPEED * delta)
		collision_shape.position.y = capsule.height * 0.5
	if _camera_pivot != null:
		var target_camera_y := CROUCHED_CAMERA_Y if crouched else STANDING_CAMERA_Y
		_camera_pivot.position.y = move_toward(_camera_pivot.position.y, target_camera_y, STANCE_LERP_SPEED * delta)

func _build_client_presentation() -> void:
	if server_authoritative or _is_headless():
		return
	if not locally_controlled:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "RemoteBody"
		mesh_instance.position = Vector3(0.0, 0.9, 0.0)
		var capsule_mesh := CapsuleMesh.new()
		capsule_mesh.radius = 0.42
		capsule_mesh.height = 1.8
		mesh_instance.mesh = capsule_mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.90, 0.34, 0.18, 1.0) if team_index == 0 else Color(0.20, 0.48, 0.90, 1.0)
		mesh_instance.material_override = material
		add_child(mesh_instance)
		return

	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_camera_pivot.position = Vector3(0.0, STANDING_CAMERA_Y, 0.0)
	add_child(_camera_pivot)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.current = true
	camera.fov = 80.0
	camera.near = 0.05
	_camera_pivot.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
