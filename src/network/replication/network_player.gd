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
@onready var body_hitbox: Area3D = $BodyHitbox
@onready var head_hitbox: Area3D = $HeadHitbox
@onready var snow_source_detector: Area3D = $SnowSourceDetector
@onready var movement: PlayerMovementComponent = $Components/Movement
@onready var inventory: SnowballInventoryComponent = $Components/Inventory
@onready var snowball_action: SnowballActionComponent = $Components/SnowballAction

var network_peer_id: int = 0
var team_index: int = 0
var locally_controlled: bool = false
var server_authoritative: bool = false
var reconciliation_count: int = 0
var server_rejected_inputs: int = 0

var _spawn_position: Vector3 = Vector3.ZERO
var _spawn_yaw: float = 0.0
var _latest_server_command := PlayerInputCommand.new()
var _latest_aim_direction: Vector3 = Vector3(0.0, 0.0, -1.0)
var _last_received_sequence: int = 0
var _next_sequence: int = 1
var _pending_commands: Array[Dictionary] = []
var _network_send_queue: Array[Dictionary] = []
var _catch_send_queue: Array[Dictionary] = []
var _state_history: Array[Dictionary] = []
var _catch_compensation_server_msec: int = 0
var _last_catch_rewind_ms: float = 0.0
var _snapshot_elapsed: float = 0.0
var _look_accumulator: Vector2 = Vector2.ZERO
var _pitch_radians: float = 0.0
var _camera_pivot: Node3D
var _remote_target_position: Vector3 = Vector3.ZERO
var _remote_target_yaw: float = 0.0
var _remote_crouched: bool = false
var _authoritative_inventory: int = 0
var _predicted_inventory: int = 0
var _authoritative_hand_state: StringName = SnowballActionComponent.HANDS_FREE
var _authoritative_pack_progress: float = 0.0
var _authoritative_charge: float = 0.0
var _authoritative_last_catch_succeeded: bool = false
var _local_charge_seconds: float = 0.0
var _local_charging: bool = false
var _predicted_catch_remaining: float = 0.0
var _smoke_elapsed: float = 0.0
var _smoke_throw_started: bool = false
var _smoke_throw_released: bool = false
var _smoke_catch_sent: bool = false

func _ready() -> void:
	snowball_action.configure(inventory)
	snowball_action.throw_requested.connect(_on_server_throw_requested)

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
	if server_authoritative:
		add_to_group("network_server_player")
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

func get_collision_exclusion_rids() -> Array[RID]:
	return [get_rid(), body_hitbox.get_rid(), head_hitbox.get_rid()]

func get_network_debug_snapshot() -> Dictionary:
	var shown_hand_state := _authoritative_hand_state if not server_authoritative else snowball_action.state
	if _predicted_catch_remaining > 0.0 and locally_controlled:
		shown_hand_state = SnowballActionComponent.CATCHING
	return {
		"peer_id": network_peer_id,
		"team": team_index,
		"reconciliations": reconciliation_count,
		"server_rejected_inputs": server_rejected_inputs,
		"pending_inputs": _pending_commands.size(),
		"surface": movement.current_surface,
		"inventory": _authoritative_inventory if not server_authoritative else inventory.current,
		"predicted_inventory": _predicted_inventory,
		"hand_state": shown_hand_state,
		"pack_progress": _authoritative_pack_progress,
		"charge": _authoritative_charge,
		"last_catch_succeeded": _authoritative_last_catch_succeeded if not server_authoritative else snowball_action.last_catch_succeeded,
		"last_catch_rewind_ms": _last_catch_rewind_ms,
	}

func server_validate_catch_segment(segment_from: Vector3, segment_to: Vector3, projectile_velocity: Vector3) -> bool:
	if not server_authoritative or not snowball_action.is_catch_active():
		return false
	var sample := _history_sample_at(_catch_compensation_server_msec)
	if sample.is_empty():
		return false
	var position: Vector3 = sample["position"]
	var yaw := float(sample["yaw"])
	var catch_origin := position + Vector3.UP * 1.25
	var forward := -(Basis(Vector3.UP, yaw).z).normalized()
	return CatchValidation.is_swept_valid(catch_origin, forward, segment_from, segment_to, projectile_velocity, GameConfig.snowball.catch_range, GameConfig.snowball.catch_half_angle_degrees)

func server_compensated_catch_origin() -> Vector3:
	var sample := _history_sample_at(_catch_compensation_server_msec)
	return Vector3(sample.get("position", global_position)) + Vector3.UP * 1.25

func server_confirm_catch(projectile_id: int) -> void:
	if not server_authoritative:
		return
	inventory.try_add()
	snowball_action.confirm_catch_success()
	print("SNOWDOWN_NETWORK_CATCH_ACCEPTED catcher=%d projectile=%d rewind_ms=%.1f" % [network_peer_id, projectile_id, _last_catch_rewind_ms])

func _server_tick(delta: float) -> void:
	snowball_action.simulate(_latest_server_command, delta, _has_packable_snow(), movement.is_sliding())
	movement.simulate(_latest_server_command, delta, snowball_action.movement_multiplier())
	_update_stance(_latest_server_command.crouch_held or movement.is_sliding(), delta)
	_latest_server_command.jump_pressed = false
	_latest_server_command.crouch_pressed = false
	_latest_server_command.throw_pressed = false
	_latest_server_command.throw_released = false
	_latest_server_command.catch_pressed = false

	if MAP01_LAYOUT.is_out_of_bounds(GameConfig.glacier_valley, global_position):
		global_position = _spawn_position
		velocity = Vector3.ZERO
		rotation.y = _spawn_yaw
		movement.reset()
		snowball_action.reset()
	_record_history()

	_snapshot_elapsed += delta
	if _snapshot_elapsed >= SNAPSHOT_INTERVAL:
		_snapshot_elapsed = 0.0
		receive_state.rpc(
			_last_received_sequence,
			global_position,
			velocity,
			rotation.y,
			_latest_server_command.crouch_held or movement.is_sliding(),
			server_rejected_inputs,
			inventory.current,
			snowball_action.state,
			snowball_action.pack_progress,
			snowball_action.normalized_charge(),
			snowball_action.last_catch_succeeded,
			_last_catch_rewind_ms
		)

func _client_prediction_tick(delta: float) -> void:
	var command := _read_local_command(delta)
	_apply_local_look()
	var sequence := _next_sequence
	_next_sequence += 1
	_predicted_catch_remaining = maxf(0.0, _predicted_catch_remaining - delta)
	if command.catch_pressed:
		_local_charging = false
		_local_charge_seconds = 0.0
		_predicted_catch_remaining = GameConfig.snowball.catch_active_seconds + GameConfig.snowball.catch_recovery_seconds
		_queue_catch_request(sequence)
	_simulate_local_snowball_prediction(command, delta, sequence)
	var predicted_speed_multiplier := GameConfig.snowball.pack_movement_multiplier if command.pack_held and _predicted_inventory < GameConfig.snowball.inventory_capacity else 1.0
	if _predicted_catch_remaining > 0.0:
		predicted_speed_multiplier = minf(predicted_speed_multiplier, GameConfig.snowball.catch_movement_multiplier)
	movement.simulate(command, delta, predicted_speed_multiplier)
	_update_stance(command.crouch_held or movement.is_sliding(), delta)

	_pending_commands.append(_serialize_command(sequence, command, delta, rotation.y))
	if _pending_commands.size() > 180:
		_pending_commands.pop_front()
	_queue_input_packet(sequence, command, rotation.y, _current_aim_direction())
	_flush_simulated_network()

func _remote_interpolation_tick(delta: float) -> void:
	var weight := minf(1.0, delta * 12.0)
	global_position = global_position.lerp(_remote_target_position, weight)
	rotation.y = lerp_angle(rotation.y, _remote_target_yaw, weight)
	_update_stance(_remote_crouched, delta)

@rpc("any_peer", "call_remote", "unreliable_ordered", 0)
func submit_input(sequence: int, move: Vector2, sprint_held: bool, crouch_held: bool, jump_pressed: bool, pack_held: bool, throw_held: bool, yaw: float, aim_direction: Vector3) -> void:
	if not server_authoritative:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != network_peer_id or sequence <= _last_received_sequence:
		server_rejected_inputs += 1
		return
	if not _valid_finite_vector2(move) or move.length() > 1.05 or is_nan(yaw) or is_inf(yaw) or not _valid_aim_direction(aim_direction):
		server_rejected_inputs += 1
		return
	var previous_crouch := _latest_server_command.crouch_held
	var previous_throw := _latest_server_command.throw_held
	_last_received_sequence = sequence
	_latest_server_command.move = move.limit_length(1.0)
	_latest_server_command.sprint_held = sprint_held
	_latest_server_command.crouch_pressed = _latest_server_command.crouch_pressed or (crouch_held and not previous_crouch)
	_latest_server_command.crouch_held = crouch_held
	_latest_server_command.jump_pressed = _latest_server_command.jump_pressed or jump_pressed
	_latest_server_command.pack_held = pack_held
	_latest_server_command.throw_pressed = _latest_server_command.throw_pressed or (throw_held and not previous_throw)
	_latest_server_command.throw_released = _latest_server_command.throw_released or (not throw_held and previous_throw)
	_latest_server_command.throw_held = throw_held
	rotation.y = wrapf(yaw, -PI, PI)
	_latest_aim_direction = aim_direction.normalized()

@rpc("any_peer", "call_remote", "reliable", 1)
func request_catch(input_sequence: int, estimated_server_msec: int) -> void:
	if not server_authoritative:
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != network_peer_id or input_sequence <= 0:
		server_rejected_inputs += 1
		return
	var now := Time.get_ticks_msec()
	var max_rewind_ms := int(GameConfig.snowball.max_lag_rewind_seconds * 1000.0)
	_catch_compensation_server_msec = clampi(estimated_server_msec, now - max_rewind_ms, now)
	_last_catch_rewind_ms = float(now - _catch_compensation_server_msec)
	_latest_server_command.catch_pressed = true

@rpc("authority", "call_remote", "unreliable")
func receive_state(ack_sequence: int, server_position: Vector3, server_velocity: Vector3, server_yaw: float, crouched: bool, rejected_inputs: int, authoritative_inventory: int, hand_state: StringName, pack_progress: float, charge: float, last_catch_succeeded: bool, last_catch_rewind_ms: float) -> void:
	if server_authoritative:
		return
	server_rejected_inputs = rejected_inputs
	_authoritative_inventory = clampi(authoritative_inventory, 0, GameConfig.snowball.inventory_capacity)
	_authoritative_hand_state = hand_state
	_authoritative_pack_progress = pack_progress
	_authoritative_charge = charge
	_authoritative_last_catch_succeeded = last_catch_succeeded
	_last_catch_rewind_ms = last_catch_rewind_ms
	if not _local_charging:
		_predicted_inventory = _authoritative_inventory
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
		var replay_multiplier := GameConfig.snowball.pack_movement_multiplier if replay_command.pack_held and _predicted_inventory < GameConfig.snowball.inventory_capacity else 1.0
		movement.simulate(replay_command, float(record["delta"]), replay_multiplier)
		_update_stance(replay_command.crouch_held or movement.is_sliding(), float(record["delta"]))
	if error_distance >= RECONCILE_THRESHOLD:
		reconciliation_count += 1

func _read_local_command(delta: float) -> PlayerInputCommand:
	if _is_headless() and not App.network_smoke_action.is_empty():
		return _read_smoke_command(delta)
	var command := PlayerInputCommand.new()
	command.move = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	command.jump_pressed = Input.is_action_just_pressed("jump")
	command.sprint_held = Input.is_action_pressed("sprint")
	command.crouch_pressed = Input.is_action_just_pressed("crouch_slide")
	command.crouch_held = Input.is_action_pressed("crouch_slide")
	command.pack_held = Input.is_action_pressed("pack_interact")
	command.throw_pressed = Input.is_action_just_pressed("throw_primary")
	command.throw_held = Input.is_action_pressed("throw_primary")
	command.throw_released = Input.is_action_just_released("throw_primary")
	command.catch_pressed = Input.is_action_just_pressed("catch")
	return command

func _read_smoke_command(delta: float) -> PlayerInputCommand:
	_smoke_elapsed += delta
	var command := PlayerInputCommand.new()
	if App.network_smoke_action == &"pack_throw":
		var pack_end := GameConfig.snowball.pack_duration_seconds + 0.30
		var throw_start := pack_end + 0.15
		var throw_end := throw_start + GameConfig.snowball.normal_charge_seconds + 0.15
		if _smoke_elapsed < pack_end:
			command.pack_held = true
		elif _smoke_elapsed >= throw_start and _smoke_elapsed < throw_end:
			command.throw_held = true
			if not _smoke_throw_started:
				command.throw_pressed = true
				_smoke_throw_started = true
		elif _smoke_elapsed >= throw_end and not _smoke_throw_released:
			command.throw_released = true
			_smoke_throw_released = true
	elif App.network_smoke_action == &"catch" and _smoke_elapsed >= 2.50 and not _smoke_catch_sent:
		command.catch_pressed = true
		_smoke_catch_sent = true
	return command

func _simulate_local_snowball_prediction(command: PlayerInputCommand, delta: float, sequence: int) -> void:
	if command.throw_pressed and _predicted_inventory > 0:
		_local_charging = true
		_local_charge_seconds = 0.0
	if _local_charging and command.throw_held:
		_local_charge_seconds = minf(_local_charge_seconds + delta, GameConfig.snowball.maximum_charge_seconds)
	if not _local_charging or not command.throw_released:
		return
	if _local_charge_seconds >= GameConfig.snowball.minimum_release_seconds and _predicted_inventory > 0:
		var normalized_charge := clampf(_local_charge_seconds / GameConfig.snowball.maximum_charge_seconds, 0.0, 1.0)
		_spawn_predicted_throw(sequence, normalized_charge)
		_predicted_inventory = maxi(0, _predicted_inventory - 1)
	_local_charging = false
	_local_charge_seconds = 0.0

func _spawn_predicted_throw(sequence: int, normalized_charge: float) -> void:
	var direction := _current_aim_direction()
	var origin := global_position + Vector3.UP * 1.30 + direction * 0.48
	var speed := GameConfig.snowball.charge_to_speed(normalized_charge)
	var inherited := Vector3(velocity.x, 0.0, velocity.z) * GameConfig.snowball.horizontal_velocity_inheritance
	var session := get_tree().get_first_node_in_group("network_session") as NetworkSession
	if session != null:
		session.spawn_predicted_throw(sequence, origin, direction * speed + inherited)

func _on_server_throw_requested(normalized_charge: float) -> void:
	if not server_authoritative:
		return
	var session := get_tree().get_first_node_in_group("network_session") as NetworkSession
	if session != null:
		session.server_spawn_snowball(self, normalized_charge, _last_received_sequence, _latest_aim_direction)

func _queue_input_packet(sequence: int, command: PlayerInputCommand, yaw: float, aim_direction: Vector3) -> void:
	if _should_drop_input(sequence):
		return
	var delay_ms := _simulated_one_way_delay_ms(sequence)
	_network_send_queue.append({
		"deliver_at": Time.get_ticks_msec() + delay_ms,
		"sequence": sequence,
		"move": command.move,
		"sprint": command.sprint_held,
		"crouch": command.crouch_held,
		"jump": command.jump_pressed,
		"pack": command.pack_held,
		"throw": command.throw_held,
		"yaw": yaw,
		"aim": aim_direction,
	})

func _queue_catch_request(sequence: int) -> void:
	var session := get_tree().get_first_node_in_group("network_session") as NetworkSession
	var estimated_server_msec := Time.get_ticks_msec()
	if session != null:
		estimated_server_msec = session.estimated_server_time_msec()
	_catch_send_queue.append({
		"deliver_at": Time.get_ticks_msec() + _simulated_one_way_delay_ms(sequence),
		"sequence": sequence,
		"server_msec": estimated_server_msec,
	})

func _flush_simulated_network() -> void:
	var now := Time.get_ticks_msec()
	for index in range(_network_send_queue.size() - 1, -1, -1):
		var record := _network_send_queue[index]
		if int(record["deliver_at"]) > now:
			continue
		submit_input.rpc_id(1, int(record["sequence"]), Vector2(record["move"]), bool(record["sprint"]), bool(record["crouch"]), bool(record["jump"]), bool(record["pack"]), bool(record["throw"]), float(record["yaw"]), Vector3(record["aim"]))
		_network_send_queue.remove_at(index)
	for index in range(_catch_send_queue.size() - 1, -1, -1):
		var record := _catch_send_queue[index]
		if int(record["deliver_at"]) > now:
			continue
		request_catch.rpc_id(1, int(record["sequence"]), int(record["server_msec"]))
		_catch_send_queue.remove_at(index)

func _simulated_one_way_delay_ms(sequence: int) -> int:
	var base := App.net_sim_latency_ms / 2
	if App.net_sim_jitter_ms <= 0:
		return base
	var direction := (sequence % 3) - 1
	return maxi(0, base + int(float(direction * App.net_sim_jitter_ms) * 0.5))

func _should_drop_input(sequence: int) -> bool:
	if App.net_sim_loss_percent <= 0.0:
		return false
	var drop_every := maxi(2, int(round(100.0 / App.net_sim_loss_percent)))
	return sequence % drop_every == 0

func _record_history() -> void:
	var now := Time.get_ticks_msec()
	_state_history.append({"msec": now, "position": global_position, "yaw": rotation.y})
	var oldest_allowed := now - int(GameConfig.snowball.state_history_seconds * 1000.0)
	while not _state_history.is_empty() and int(_state_history[0]["msec"]) < oldest_allowed:
		_state_history.pop_front()

func _history_sample_at(target_msec: int) -> Dictionary:
	if _state_history.is_empty():
		return {"msec": Time.get_ticks_msec(), "position": global_position, "yaw": rotation.y}
	var best: Dictionary = _state_history[0]
	var best_delta := absi(int(best["msec"]) - target_msec)
	for sample in _state_history:
		var delta := absi(int(sample["msec"]) - target_msec)
		if delta < best_delta:
			best = sample
			best_delta = delta
	return best

func _has_packable_snow() -> bool:
	for area in snow_source_detector.get_overlapping_areas():
		if area.is_in_group("snow_source"):
			return true
	return false

func _current_aim_direction() -> Vector3:
	if _camera_pivot != null:
		return -_camera_pivot.global_transform.basis.z.normalized()
	return -global_transform.basis.z.normalized()

func _apply_local_look() -> void:
	if _look_accumulator.is_zero_approx():
		return
	var config := GameConfig.player_movement
	rotation.y -= _look_accumulator.x * config.mouse_sensitivity
	_pitch_radians = clampf(_pitch_radians - _look_accumulator.y * config.mouse_sensitivity, deg_to_rad(config.pitch_min_degrees), deg_to_rad(config.pitch_max_degrees))
	if _camera_pivot != null:
		_camera_pivot.rotation.x = _pitch_radians
	_look_accumulator = Vector2.ZERO

func _serialize_command(sequence: int, command: PlayerInputCommand, delta: float, yaw: float) -> Dictionary:
	return {"sequence": sequence, "move": command.move, "sprint": command.sprint_held, "crouch_pressed": command.crouch_pressed, "crouch_held": command.crouch_held, "jump": command.jump_pressed, "pack": command.pack_held, "delta": delta, "yaw": yaw}

func _deserialize_command(record: Dictionary) -> PlayerInputCommand:
	var command := PlayerInputCommand.new()
	command.move = Vector2(record["move"])
	command.sprint_held = bool(record["sprint"])
	command.crouch_pressed = bool(record["crouch_pressed"])
	command.crouch_held = bool(record["crouch_held"])
	command.jump_pressed = bool(record["jump"])
	command.pack_held = bool(record["pack"])
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

func _valid_finite_vector2(value: Vector2) -> bool:
	return not is_nan(value.x) and not is_nan(value.y) and not is_inf(value.x) and not is_inf(value.y)

func _valid_aim_direction(value: Vector3) -> bool:
	if is_nan(value.x) or is_nan(value.y) or is_nan(value.z) or is_inf(value.x) or is_inf(value.y) or is_inf(value.z):
		return false
	var length := value.length()
	return length >= 0.5 and length <= 1.5

func _is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
