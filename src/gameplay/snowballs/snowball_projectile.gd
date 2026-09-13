class_name SnowballProjectile
extends Node3D

signal terminal_resolved(kind: StringName, collider: Node, world_position: Vector3)

const RESULT_HEAD := &"head_hit"
const RESULT_BODY := &"body_hit"
const RESULT_WORLD := &"world_impact"

var projectile_id: int = 0
var velocity: Vector3 = Vector3.ZERO
var active: bool = true
var lifetime: float = 0.0
var owner_player: CollisionObject3D
var _shape := SphereShape3D.new()

func setup(owner_node: CollisionObject3D, spawn_position: Vector3, initial_velocity: Vector3, id: int) -> void:
	owner_player = owner_node
	global_position = spawn_position
	velocity = initial_velocity
	projectile_id = id

func _ready() -> void:
	_shape.radius = GameConfig.snowball.projectile_radius
	var mesh := $Mesh as MeshInstance3D
	var sphere := mesh.mesh as SphereMesh
	if sphere != null:
		sphere.radius = GameConfig.snowball.projectile_radius
		sphere.height = GameConfig.snowball.projectile_radius * 2.0

func _physics_process(delta: float) -> void:
	if not active:
		return
	lifetime += delta
	if lifetime >= GameConfig.snowball.projectile_lifetime_seconds or global_position.y < -20.0:
		_finish(RESULT_WORLD, null, global_position)
		return

	var next_velocity := _integrate_velocity(velocity, delta)
	var displacement := (velocity + next_velocity) * 0.5 * delta
	if _sweep_and_resolve(displacement):
		return
	global_position += displacement
	velocity = next_velocity

func _integrate_velocity(current_velocity: Vector3, delta: float) -> Vector3:
	var next_velocity := current_velocity
	next_velocity.y -= GameConfig.player_movement.gravity * GameConfig.snowball.gravity_scale * delta
	var drag := GameConfig.snowball.drag
	if drag > 0.0:
		next_velocity *= maxf(0.0, 1.0 - drag * delta)
	return next_velocity

func _sweep_and_resolve(displacement: Vector3) -> bool:
	if displacement.is_zero_approx():
		return false
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.motion = displacement
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	if owner_player != null:
		query.exclude = [owner_player.get_rid()]

	var space := get_world_3d().direct_space_state
	var cast := space.cast_motion(query)
	if cast.is_empty() or cast[0] >= 1.0:
		return false

	var unsafe_fraction := cast[1]
	var impact_position := global_position + displacement * clampf(unsafe_fraction + 0.002, 0.0, 1.0)
	query.transform = Transform3D(Basis.IDENTITY, impact_position)
	query.motion = Vector3.ZERO
	var hits := space.intersect_shape(query, 16)
	var classified := _classify_collision(hits)
	global_position = impact_position
	_finish(classified[0], classified[1], impact_position)
	return true

func _classify_collision(hits: Array[Dictionary]) -> Array:
	var body_hit: Node = null
	var world_hit: Node = null
	for hit in hits:
		var collider := hit.get("collider") as Node
		if collider == null or collider == owner_player:
			continue
		if collider.is_in_group("target_head"):
			return [RESULT_HEAD, collider]
		if collider.is_in_group("target_body"):
			body_hit = collider
		elif world_hit == null:
			world_hit = collider
	if body_hit != null:
		return [RESULT_BODY, body_hit]
	return [RESULT_WORLD, world_hit]

func _finish(kind: StringName, collider: Node, point: Vector3) -> void:
	if not active:
		return
	active = false
	terminal_resolved.emit(kind, collider, point)
	queue_free()
