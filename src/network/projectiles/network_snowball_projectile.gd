class_name NetworkSnowballProjectile
extends Node3D

signal state_updated(projectile_id: int, position: Vector3, velocity: Vector3)
signal terminal_resolved(projectile_id: int, kind: StringName, target_peer_id: int, world_position: Vector3)

const RESULT_HEAD := &"head_hit"
const RESULT_BODY := &"body_hit"
const RESULT_WORLD := &"world_impact"
const SNAPSHOT_INTERVAL := 1.0 / 20.0

var projectile_id: int = 0
var owner_peer_id: int = 0
var velocity: Vector3 = Vector3.ZERO
var active: bool = true
var lifetime: float = 0.0
var owner_player: NetworkPlayer
var _shape := SphereShape3D.new()
var _snapshot_elapsed: float = 0.0

func setup(owner: NetworkPlayer, id: int, spawn_position: Vector3, initial_velocity: Vector3) -> void:
	owner_player = owner
	owner_peer_id = owner.network_peer_id
	projectile_id = id
	global_position = spawn_position
	velocity = initial_velocity
	_shape.radius = GameConfig.snowball.projectile_radius

func get_authoritative_snapshot() -> Dictionary:
	return {
		"projectile_id": projectile_id,
		"owner_peer_id": owner_peer_id,
		"position": global_position,
		"velocity": velocity,
	}

func _physics_process(delta: float) -> void:
	if not active:
		return
	lifetime += delta
	if lifetime >= GameConfig.snowball.projectile_lifetime_seconds or global_position.y < -20.0:
		_finish(RESULT_WORLD, 0, global_position)
		return

	var step := SnowballMath.simulate_step(
		global_position,
		velocity,
		delta,
		GameConfig.player_movement.gravity,
		GameConfig.snowball.gravity_scale,
		GameConfig.snowball.drag
	)
	var next_position: Vector3 = step["position"]
	var displacement := next_position - global_position
	if _sweep_and_resolve(displacement):
		return
	global_position = next_position
	velocity = step["velocity"]

	_snapshot_elapsed += delta
	if _snapshot_elapsed >= SNAPSHOT_INTERVAL:
		_snapshot_elapsed = 0.0
		state_updated.emit(projectile_id, global_position, velocity)

func _sweep_and_resolve(displacement: Vector3) -> bool:
	if displacement.is_zero_approx():
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.motion = displacement
	query.collision_mask = 7
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if owner_player != null:
		query.exclude = owner_player.get_collision_exclusion_rids()

	var space := get_world_3d().direct_space_state
	var cast := space.cast_motion(query)
	if cast.is_empty() or cast[0] >= 1.0:
		return false

	var unsafe_fraction := cast[1]
	var impact_position := global_position + displacement * clampf(unsafe_fraction + 0.002, 0.0, 1.0)
	query.transform = Transform3D(Basis.IDENTITY, impact_position)
	query.motion = Vector3.ZERO
	var hits := space.intersect_shape(query, 24)
	var classified := _classify_collision(hits)
	global_position = impact_position
	_finish(classified["kind"], classified["target_peer_id"], impact_position)
	return true

func _classify_collision(hits: Array[Dictionary]) -> Dictionary:
	var body_target: int = 0
	var world_found: bool = false
	for hit in hits:
		var collider := hit.get("collider") as Node
		if collider == null:
			continue
		var target_player := _target_player_for(collider)
		if target_player == owner_player:
			continue
		if collider.is_in_group("network_target_head") and target_player != null:
			return {"kind": RESULT_HEAD, "target_peer_id": target_player.network_peer_id}
		if collider.is_in_group("network_target_body") and target_player != null:
			body_target = target_player.network_peer_id
		elif collider is NetworkPlayer and collider != owner_player:
			body_target = (collider as NetworkPlayer).network_peer_id
		else:
			world_found = true
	if body_target != 0:
		return {"kind": RESULT_BODY, "target_peer_id": body_target}
	return {"kind": RESULT_WORLD, "target_peer_id": 0 if world_found else 0}

func _target_player_for(collider: Node) -> NetworkPlayer:
	if collider is NetworkPlayer:
		return collider as NetworkPlayer
	var parent := collider.get_parent()
	return parent as NetworkPlayer if parent is NetworkPlayer else null

func _finish(kind: StringName, target_peer_id: int, point: Vector3) -> void:
	if not active:
		return
	active = false
	terminal_resolved.emit(projectile_id, kind, target_peer_id, point)
	queue_free()
