class_name NetworkSession
extends Node

const SERVER_PEER_ID := 1
const MAX_CLIENTS := 8
const NETWORK_PLAYER_SCENE := preload("res://scenes/network/network_player.tscn")
const MAP01_LAYOUT := preload("res://src/world/glacier_valley_layout.gd")

var state: StringName = &"starting"
var local_peer_id: int = 0
var rtt_ms: float = 0.0
var clock_offset_ms: float = 0.0
var _peer: ENetMultiplayerPeer
var _players_root: Node3D
var _roster: Dictionary = {}
var _ping_elapsed: float = 0.0
var _smoke_ready_elapsed: float = 0.0

func _ready() -> void:
	add_to_group("network_session")
	_players_root = Node3D.new()
	_players_root.name = "Players"
	add_child(_players_root)

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

func get_debug_snapshot() -> Dictionary:
	var reconciliation_count := 0
	var rejected_inputs := 0
	var local_player := get_tree().get_first_node_in_group("network_local_player") as NetworkPlayer
	if local_player != null:
		var local_snapshot := local_player.get_network_debug_snapshot()
		reconciliation_count = int(local_snapshot["reconciliations"])
		rejected_inputs = int(local_snapshot["server_rejected_inputs"])
	return {
		"state": state,
		"peer_id": local_peer_id,
		"roster": _roster.size(),
		"rtt_ms": rtt_ms,
		"clock_offset_ms": clock_offset_ms,
		"reconciliations": reconciliation_count,
		"server_rejected_inputs": rejected_inputs,
	}

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
	var state_data := {"team": team, "position": spawn, "yaw": yaw}
	_roster[peer_id] = state_data
	_spawn_avatar(peer_id, team, spawn, yaw, false, true)

	for existing_peer_id in _roster.keys():
		if int(existing_peer_id) == peer_id:
			continue
		var existing: Dictionary = _roster[existing_peer_id]
		client_spawn_player.rpc_id(peer_id, int(existing_peer_id), int(existing["team"]), Vector3(existing["position"]), float(existing["yaw"]))
	client_spawn_player.rpc(peer_id, team, spawn, yaw)
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
	for child in _players_root.get_children():
		child.queue_free()
	if not App.network_smoke_name.is_empty():
		get_tree().quit(1)

@rpc("authority", "call_remote", "reliable")
func client_spawn_player(peer_id: int, team: int, spawn: Vector3, yaw: float) -> void:
	if App.is_server_runtime() or _roster.has(peer_id):
		return
	_roster[peer_id] = {"team": team, "position": spawn, "yaw": yaw}
	_spawn_avatar(peer_id, team, spawn, yaw, peer_id == multiplayer.get_unique_id(), false)

@rpc("authority", "call_remote", "reliable")
func client_despawn_player(peer_id: int) -> void:
	if App.is_server_runtime():
		return
	_roster.erase(peer_id)
	_despawn_avatar(peer_id)

@rpc("any_peer", "call_remote", "unreliable")
func request_ping(client_msec: int) -> void:
	if not App.is_server_runtime():
		return
	var sender := multiplayer.get_remote_sender_id()
	reply_ping.rpc_id(sender, client_msec, Time.get_ticks_msec())

@rpc("authority", "call_remote", "unreliable")
func reply_ping(client_msec: int, server_msec: int) -> void:
	if App.is_server_runtime():
		return
	var now := Time.get_ticks_msec()
	rtt_ms = float(now - client_msec)
	clock_offset_ms = float(server_msec) - (float(client_msec) + rtt_ms * 0.5)

func _spawn_avatar(peer_id: int, team: int, spawn: Vector3, yaw: float, local_controlled: bool, server_authoritative: bool) -> void:
	if _players_root.has_node("Player_%d" % peer_id):
		return
	var avatar := NETWORK_PLAYER_SCENE.instantiate() as NetworkPlayer
	avatar.name = "Player_%d" % peer_id
	_players_root.add_child(avatar)
	avatar.configure(peer_id, team, spawn, yaw, local_controlled, server_authoritative)

func _despawn_avatar(peer_id: int) -> void:
	var avatar := _players_root.get_node_or_null("Player_%d" % peer_id)
	if avatar != null:
		avatar.queue_free()

func _count_team_members(team: int) -> int:
	var count := 0
	for state_data in _roster.values():
		if int(state_data["team"]) == team:
			count += 1
	return count

func _spawn_for_team(team: int, slot: int) -> Vector3:
	var scenario := &"map01_spawn_team_a" if team == 0 else &"map01_spawn_team_b"
	var spawn := MAP01_LAYOUT.spawn_for(GameConfig.glacier_valley, scenario)
	var lateral_offsets := [-4.5, -1.5, 1.5, 4.5]
	spawn.x += float(lateral_offsets[mini(slot, lateral_offsets.size() - 1)])
	return spawn

func _update_network_smoke(delta: float) -> void:
	if App.network_smoke_expected_peers <= 0 or App.network_smoke_name.is_empty():
		return
	if _roster.size() < App.network_smoke_expected_peers:
		_smoke_ready_elapsed = 0.0
		return
	_smoke_ready_elapsed += delta
	if _smoke_ready_elapsed < 0.35:
		return
	print("SNOWDOWN_NETWORK_CLIENT_READY name=%s peer=%d roster=%d rtt_ms=%.1f" % [App.network_smoke_name, local_peer_id, _roster.size(), rtt_ms])
	get_tree().quit(0)
