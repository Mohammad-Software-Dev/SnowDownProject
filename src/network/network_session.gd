class_name NetworkSession
extends Node

const SERVER_PEER_ID := 1
const MAX_CLIENTS := 8
const NETWORK_PLAYER_SCENE := preload("res://scenes/network/network_player.tscn")
const SERVER_PROJECTILE_SCENE := preload("res://scenes/network/network_snowball_projectile.tscn")
const CLIENT_PROJECTILE_SCENE := preload("res://scenes/network/network_snowball_replica.tscn")
const MAP01_LAYOUT := preload("res://src/world/glacier_valley_layout.gd")

var state: StringName = &"starting"
var local_peer_id: int = 0
var rtt_ms: float = 0.0
var clock_offset_ms: float = 0.0
var projectile_prediction_merges: int = 0
var team_a_score: int = 0
var team_b_score: int = 0
var last_network_event: String = ""

var _peer: ENetMultiplayerPeer
var _players_root: Node3D
var _projectiles_root: Node3D
var _roster: Dictionary = {}
var _server_projectiles: Dictionary = {}
var _client_projectiles: Dictionary = {}
var _predicted_projectiles: Dictionary = {}
var _next_projectile_id: int = 1
var _ping_elapsed: float = 0.0
var _smoke_ready_elapsed: float = 0.0

func _ready() -> void:
	add_to_group("network_session")
	_players_root = Node3D.new()
	_players_root.name = "Players"
	add_child(_players_root)
	_projectiles_root = Node3D.new()
	_projectiles_root.name = "Projectiles"
	add_child(_projectiles_root)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	if App.is_server_runtime():
		_start_server()
	else:
		_start_client()

func _process(delta: float) -> void:
	if not App.is_server_runtime() and state == &"connected":
		_ping_elapsed += delta
		if _ping_elapsed >= 1.0:
			_ping_elapsed = 0.0
			request_ping.rpc_id(SERVER_PEER_ID, Time.get_ticks_msec())
		_update_network_smoke(delta)

func _exit_tree() -> void:
	if _peer != null:
		_peer.close()

func estimated_server_time_msec() -> int:
	return int(round(float(Time.get_ticks_msec()) + clock_offset_ms))

func get_debug_snapshot() -> Dictionary:
	var reconciliation_count := 0
	var rejected_inputs := 0
	var inventory := 0
	var hand_state: StringName = &""
	var catch_rewind_ms := 0.0
	var catch_succeeded := false
	var local_player := get_tree().get_first_node_in_group("network_local_player") as NetworkPlayer
	if local_player != null:
		var local_snapshot := local_player.get_network_debug_snapshot()
		reconciliation_count = int(local_snapshot["reconciliations"])
		rejected_inputs = int(local_snapshot["server_rejected_inputs"])
		inventory = int(local_snapshot["inventory"])
		hand_state = local_snapshot["hand_state"]
		catch_rewind_ms = float(local_snapshot["last_catch_rewind_ms"])
		catch_succeeded = bool(local_snapshot["last_catch_succeeded"])
	return {
		"state": state, "peer_id": local_peer_id, "roster": _roster.size(), "rtt_ms": rtt_ms, "clock_offset_ms": clock_offset_ms,
		"reconciliations": reconciliation_count, "server_rejected_inputs": rejected_inputs, "inventory": inventory, "hand_state": hand_state,
		"projectiles": _server_projectiles.size() if App.is_server_runtime() else _client_projectiles.size(), "predicted_projectiles": _predicted_projectiles.size(),
		"prediction_merges": projectile_prediction_merges, "team_a_score": team_a_score, "team_b_score": team_b_score, "last_event": last_network_event,
		"catch_rewind_ms": catch_rewind_ms, "catch_succeeded": catch_succeeded,
		"sim_latency_ms": App.net_sim_latency_ms, "sim_jitter_ms": App.net_sim_jitter_ms, "sim_loss_percent": App.net_sim_loss_percent,
	}

func server_spawn_snowball(owner: NetworkPlayer, normalized_charge: float, input_sequence: int, aim_direction: Vector3) -> void:
	if not App.is_server_runtime() or owner == null:
		return
	var direction := aim_direction.normalized()
	if direction.is_zero_approx():
		direction = -owner.global_transform.basis.z.normalized()
	var chest_origin := owner.global_position + Vector3.UP * 1.30
	var desired_origin := chest_origin + direction * 0.48
	var query := PhysicsRayQueryParameters3D.create(chest_origin, desired_origin, 1, owner.get_collision_exclusion_rids())
	var hit := owner.get_world_3d().direct_space_state.intersect_ray(query)
	var spawn_position := desired_origin
	if not hit.is_empty():
		spawn_position = Vector3(hit["position"]) + Vector3(hit["normal"]) * (GameConfig.snowball.projectile_radius + 0.02)
	var speed := GameConfig.snowball.charge_to_speed(normalized_charge)
	var inherited := Vector3(owner.velocity.x, 0.0, owner.velocity.z) * GameConfig.snowball.horizontal_velocity_inheritance
	var projectile_velocity := direction * speed + inherited
	var projectile_id := _next_projectile_id
	_next_projectile_id += 1
	var projectile := SERVER_PROJECTILE_SCENE.instantiate() as NetworkSnowballProjectile
	projectile.name = "Projectile_%d" % projectile_id
	_projectiles_root.add_child(projectile)
	projectile.setup(owner, projectile_id, spawn_position, projectile_velocity)
	projectile.state_updated.connect(_on_server_projectile_state)
	projectile.terminal_resolved.connect(_on_server_projectile_terminal)
	_server_projectiles[projectile_id] = projectile
	client_spawn_snowball.rpc(projectile_id, owner.network_peer_id, input_sequence, spawn_position, projectile_velocity)
	print("SNOWDOWN_NETWORK_THROW_ACCEPTED owner=%d projectile=%d input=%d" % [owner.network_peer_id, projectile_id, input_sequence])

func spawn_predicted_throw(input_sequence: int, spawn_position: Vector3, projectile_velocity: Vector3) -> void:
	if App.is_server_runtime() or _predicted_projectiles.has(input_sequence):
		return
	var replica := CLIENT_PROJECTILE_SCENE.instantiate() as NetworkSnowballReplica
	replica.name = "Predicted_%d" % input_sequence
	_projectiles_root.add_child(replica)
	replica.setup_predicted(input_sequence, local_peer_id, spawn_position, projectile_velocity)
	replica.prediction_expired.connect(_on_prediction_expired)
	_predicted_projectiles[input_sequence] = replica

func _start_server() -> void:
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_server(App.network_port, MAX_CLIENTS)
	if error != OK:
		push_error("Snowdown server failed to listen on port %d: %s" % [App.network_port, error_string(error)])
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = _peer
	state = &"listening"
	local_peer_id = SERVER_PEER_ID
	print("SNOWDOWN_NETWORK_SERVER_READY port=%d" % App.network_port)

func _start_client() -> void:
	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_client(App.connect_host, App.network_port)
	if error != OK:
		push_error("Snowdown client failed to start connection: %s" % error_string(error))
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer = _peer
	state = &"connecting"

func _on_peer_connected(peer_id: int) -> void:
	if not App.is_server_runtime():
		return
	var team := _roster.size() % 2
	var slot := _count_team_members(team)
	var spawn := _spawn_for_team(team, slot)
	var yaw := 0.0 if team == 0 else 180.0
	_roster[peer_id] = {"team": team, "position": spawn, "yaw": yaw}
	_spawn_avatar(peer_id, team, spawn, yaw, false, true)
	for existing_peer_id in _roster.keys():
		if int(existing_peer_id) == peer_id:
			continue
		var existing: Dictionary = _roster[existing_peer_id]
		client_spawn_player.rpc_id(peer_id, int(existing_peer_id), int(existing["team"]), Vector3(existing["position"]), float(existing["yaw"]))
	client_spawn_player.rpc(peer_id, team, spawn, yaw)
	client_sync_scores.rpc_id(peer_id, team_a_score, team_b_score)
	for projectile in _server_projectiles.values():
		if is_instance_valid(projectile):
			var snapshot: Dictionary = projectile.get_authoritative_snapshot()
			client_spawn_snowball.rpc_id(peer_id, int(snapshot["projectile_id"]), int(snapshot["owner_peer_id"]), 0, Vector3(snapshot["position"]), Vector3(snapshot["velocity"]))
	print("[Snowdown][net] peer joined id=%d team=%d roster=%d" % [peer_id, team, _roster.size()])

func _on_peer_disconnected(peer_id: int) -> void:
	if App.is_server_runtime():
		_roster.erase(peer_id)
		_despawn_avatar(peer_id)
		client_despawn_player.rpc(peer_id)
		print("[Snowdown][net] peer left id=%d roster=%d" % [peer_id, _roster.size()])
	else:
		_roster.erase(peer_id)
		_despawn_avatar(peer_id)

func _on_connected_to_server() -> void:
	state = &"connected"
	local_peer_id = multiplayer.get_unique_id()
	print("[Snowdown][net] connected peer=%d" % local_peer_id)

func _on_connection_failed() -> void:
	state = &"connection_failed"
	push_error("Snowdown client connection failed to %s:%d" % [App.connect_host, App.network_port])
	if not App.network_smoke_name.is_empty():
		get_tree().quit(1)

func _on_server_disconnected() -> void:
	state = &"server_disconnected"
	_roster.clear()
	for child in _players_root.get_children(): child.queue_free()
	for child in _projectiles_root.get_children(): child.queue_free()
	_client_projectiles.clear()
	_predicted_projectiles.clear()
	if not App.network_smoke_name.is_empty(): get_tree().quit(1)

@rpc("authority", "call_remote", "reliable")
func client_spawn_player(peer_id: int, team: int, spawn: Vector3, yaw: float) -> void:
	if App.is_server_runtime() or _roster.has(peer_id): return
	_roster[peer_id] = {"team": team, "position": spawn, "yaw": yaw}
	_spawn_avatar(peer_id, team, spawn, yaw, peer_id == multiplayer.get_unique_id(), false)

@rpc("authority", "call_remote", "reliable")
func client_despawn_player(peer_id: int) -> void:
	if App.is_server_runtime(): return
	_roster.erase(peer_id)
	_despawn_avatar(peer_id)

@rpc("authority", "call_remote", "reliable")
func client_spawn_snowball(projectile_id: int, owner_peer_id: int, input_sequence: int, spawn_position: Vector3, projectile_velocity: Vector3) -> void:
	if App.is_server_runtime() or _client_projectiles.has(projectile_id): return
	var replica: NetworkSnowballReplica
	if owner_peer_id == local_peer_id and input_sequence > 0 and _predicted_projectiles.has(input_sequence):
		replica = _predicted_projectiles[input_sequence] as NetworkSnowballReplica
		_predicted_projectiles.erase(input_sequence)
		replica.promote_to_authoritative(projectile_id, spawn_position, projectile_velocity)
		projectile_prediction_merges += 1
	else:
		replica = CLIENT_PROJECTILE_SCENE.instantiate() as NetworkSnowballReplica
		replica.name = "Projectile_%d" % projectile_id
		_projectiles_root.add_child(replica)
		replica.setup_authoritative(projectile_id, owner_peer_id, spawn_position, projectile_velocity)
	_client_projectiles[projectile_id] = replica

@rpc("authority", "call_remote", "unreliable")
func client_update_snowball(projectile_id: int, position: Vector3, projectile_velocity: Vector3) -> void:
	if App.is_server_runtime(): return
	var replica := _client_projectiles.get(projectile_id) as NetworkSnowballReplica
	if replica != null and is_instance_valid(replica): replica.apply_authoritative(position, projectile_velocity)

@rpc("authority", "call_remote", "reliable")
func client_resolve_snowball(projectile_id: int, kind: StringName, target_peer_id: int, world_position: Vector3, score_a: int, score_b: int) -> void:
	if App.is_server_runtime(): return
	team_a_score = score_a
	team_b_score = score_b
	last_network_event = "%s projectile=%d target=%d at=(%.1f,%.1f,%.1f)" % [kind, projectile_id, target_peer_id, world_position.x, world_position.y, world_position.z]
	var replica := _client_projectiles.get(projectile_id) as NetworkSnowballReplica
	if replica != null and is_instance_valid(replica): replica.queue_free()
	_client_projectiles.erase(projectile_id)

@rpc("authority", "call_remote", "reliable")
func client_sync_scores(score_a: int, score_b: int) -> void:
	if App.is_server_runtime(): return
	team_a_score = score_a
	team_b_score = score_b

@rpc("any_peer", "call_remote", "unreliable")
func request_ping(client_msec: int) -> void:
	if not App.is_server_runtime(): return
	var sender := multiplayer.get_remote_sender_id()
	reply_ping.rpc_id(sender, client_msec, Time.get_ticks_msec())

@rpc("authority", "call_remote", "unreliable")
func reply_ping(client_msec: int, server_msec: int) -> void:
	if App.is_server_runtime(): return
	var now := Time.get_ticks_msec()
	rtt_ms = float(now - client_msec)
	clock_offset_ms = float(server_msec) - (float(client_msec) + rtt_ms * 0.5)

func _spawn_avatar(peer_id: int, team: int, spawn: Vector3, yaw: float, local_controlled: bool, server_authoritative: bool) -> void:
	if _players_root.has_node("Player_%d" % peer_id): return
	var avatar := NETWORK_PLAYER_SCENE.instantiate() as NetworkPlayer
	avatar.name = "Player_%d" % peer_id
	_players_root.add_child(avatar)
	avatar.configure(peer_id, team, spawn, yaw, local_controlled, server_authoritative)

func _despawn_avatar(peer_id: int) -> void:
	var avatar := _players_root.get_node_or_null("Player_%d" % peer_id)
	if avatar != null: avatar.queue_free()

func _count_team_members(team: int) -> int:
	var count := 0
	for state_data in _roster.values():
		if int(state_data["team"]) == team: count += 1
	return count

func _spawn_for_team(team: int, slot: int) -> Vector3:
	if App.network_smoke_layout == &"catch_lane":
		return Vector3(0.0, 1.15, 14.0) if team == 0 else Vector3(0.0, 1.15, -1.0)
	var scenario := &"map01_spawn_team_a" if team == 0 else &"map01_spawn_team_b"
	var spawn := MAP01_LAYOUT.spawn_for(GameConfig.glacier_valley, scenario)
	var lateral_offsets := [-9.0, -3.0, 3.0, 9.0]
	spawn.x += float(lateral_offsets[mini(slot, lateral_offsets.size() - 1)])
	return spawn

func _on_server_projectile_state(projectile_id: int, position: Vector3, projectile_velocity: Vector3) -> void:
	if App.is_server_runtime(): client_update_snowball.rpc(projectile_id, position, projectile_velocity)

func _on_server_projectile_terminal(projectile_id: int, kind: StringName, target_peer_id: int, world_position: Vector3) -> void:
	if not App.is_server_runtime(): return
	var projectile := _server_projectiles.get(projectile_id) as NetworkSnowballProjectile
	var owner_peer_id := projectile.owner_peer_id if projectile != null else 0
	var owner_state: Dictionary = _roster.get(owner_peer_id, {})
	var target_state: Dictionary = _roster.get(target_peer_id, {})
	if not owner_state.is_empty() and not target_state.is_empty() and int(owner_state["team"]) != int(target_state["team"]) and (kind == NetworkSnowballProjectile.RESULT_BODY or kind == NetworkSnowballProjectile.RESULT_HEAD):
		var points := GameConfig.match_rules.head_hit_score if kind == NetworkSnowballProjectile.RESULT_HEAD else GameConfig.match_rules.body_hit_score
		if int(owner_state["team"]) == 0: team_a_score += points
		else: team_b_score += points
	_server_projectiles.erase(projectile_id)
	client_resolve_snowball.rpc(projectile_id, kind, target_peer_id, world_position, team_a_score, team_b_score)

func _on_prediction_expired(prediction_key: int) -> void:
	_predicted_projectiles.erase(prediction_key)

func _update_network_smoke(delta: float) -> void:
	if App.network_smoke_expected_peers <= 0 or App.network_smoke_name.is_empty(): return
	if _roster.size() < App.network_smoke_expected_peers:
		_smoke_ready_elapsed = 0.0
		return
	_smoke_ready_elapsed += delta
	if _smoke_ready_elapsed < 4.5: return
	var local_player := get_tree().get_first_node_in_group("network_local_player") as NetworkPlayer
	if App.network_smoke_action == &"pack_throw" and projectile_prediction_merges < 1: return
	if App.network_smoke_action == &"catch" and (local_player == null or not bool(local_player.get_network_debug_snapshot()["last_catch_succeeded"])): return
	if App.network_smoke_action == &"pack_throw": print("SNOWDOWN_NETWORK_SNOWBALL_OK name=%s merges=%d" % [App.network_smoke_name, projectile_prediction_merges])
	if App.network_smoke_action == &"catch":
		var snapshot := local_player.get_network_debug_snapshot()
		print("SNOWDOWN_NETWORK_CATCH_OK name=%s rewind_ms=%.1f score_a=%d score_b=%d" % [App.network_smoke_name, snapshot["last_catch_rewind_ms"], team_a_score, team_b_score])
	print("SNOWDOWN_NETWORK_CLIENT_READY name=%s peer=%d roster=%d rtt_ms=%.1f" % [App.network_smoke_name, local_peer_id, _roster.size(), rtt_ms])
	get_tree().quit(0)
