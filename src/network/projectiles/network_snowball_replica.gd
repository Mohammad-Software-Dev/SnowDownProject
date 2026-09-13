class_name NetworkSnowballReplica
extends Node3D

signal prediction_expired(prediction_key: int)

var projectile_id: int = 0
var owner_peer_id: int = 0
var prediction_key: int = 0
var predicted: bool = false
var velocity: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3.ZERO
var _target_velocity: Vector3 = Vector3.ZERO
var _age: float = 0.0
var _streak: SnowballStreak3D

func setup_authoritative(id: int, owner_id: int, spawn_position: Vector3, initial_velocity: Vector3) -> void:
	projectile_id = id
	owner_peer_id = owner_id
	predicted = false
	global_position = spawn_position
	_target_position = spawn_position
	velocity = initial_velocity
	_target_velocity = initial_velocity
	_build_visual()

func setup_predicted(key: int, owner_id: int, spawn_position: Vector3, initial_velocity: Vector3) -> void:
	prediction_key = key
	owner_peer_id = owner_id
	predicted = true
	global_position = spawn_position
	_target_position = spawn_position
	velocity = initial_velocity
	_target_velocity = initial_velocity
	_build_visual()

func promote_to_authoritative(id: int, authoritative_position: Vector3, authoritative_velocity: Vector3) -> void:
	projectile_id = id
	prediction_key = 0
	predicted = false
	_target_position = authoritative_position
	_target_velocity = authoritative_velocity

func apply_authoritative(position: Vector3, authoritative_velocity: Vector3) -> void:
	_target_position = position
	_target_velocity = authoritative_velocity

func _physics_process(delta: float) -> void:
	_age += delta
	if predicted:
		var step := SnowballMath.simulate_step(
			global_position,
			velocity,
			delta,
			GameConfig.player_movement.gravity,
			GameConfig.snowball.gravity_scale,
			GameConfig.snowball.drag
		)
		global_position = step["position"]
		velocity = step["velocity"]
		_update_streak()
		if _age >= 1.5:
			prediction_expired.emit(prediction_key)
			queue_free()
		return
	var weight := minf(1.0, delta * 18.0)
	global_position = global_position.lerp(_target_position, weight)
	velocity = velocity.lerp(_target_velocity, weight)
	_update_streak()

func _build_visual() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if get_node_or_null("SnowballMesh") == null:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "SnowballMesh"
		var sphere := SphereMesh.new()
		sphere.radius = GameConfig.snowball.projectile_radius
		sphere.height = GameConfig.snowball.projectile_radius * 2.0
		mesh_instance.mesh = sphere
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.96, 0.98, 1.0, 1.0)
		material.roughness = 0.85
		mesh_instance.material_override = material
		add_child(mesh_instance)
	if _streak == null:
		_streak = SnowballStreak3D.new()
		_streak.name = "VelocityStreak"
		add_child(_streak)
	_update_streak()

func _update_streak() -> void:
	if _streak != null:
		_streak.update_from_velocity(velocity)
