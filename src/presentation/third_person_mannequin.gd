class_name ThirdPersonMannequin
extends Node3D

var _player: NetworkPlayer
var _visual_root: Node3D
var _torso: Node3D
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _gait_phase: float = 0.0
var _reaction_strength: float = 0.0
var _last_network_event: String = ""

func _ready() -> void:
	_player = get_parent() as NetworkPlayer
	if _player == null or _player.locally_controlled or _player.server_authoritative or DisplayServer.get_name() == "headless":
		visible = false
		return
	_build_visual()

func _process(delta: float) -> void:
	if _player == null or not visible:
		return
	var fallback := _player.get_node_or_null("RemoteBody") as GeometryInstance3D
	if fallback != null:
		fallback.visible = false
	var horizontal_speed := Vector3(_player.velocity.x, 0.0, _player.velocity.z).length()
	_gait_phase += delta * (3.0 + horizontal_speed * 1.05)
	_reaction_strength = move_toward(_reaction_strength, 0.0, delta * 3.8)
	_update_confirmed_reaction()
	var capsule := _player.collision_shape.shape as CapsuleShape3D
	var crouched := capsule != null and capsule.height < 1.5
	var snapshot := _player.get_network_debug_snapshot()
	var pose := ThirdPersonPose.resolve(
		horizontal_speed,
		_player.velocity.y,
		crouched,
		StringName(snapshot.get("hand_state", SnowballActionComponent.HANDS_FREE)),
		float(snapshot.get("charge", 0.0)),
		sin(_gait_phase),
		_reaction_strength
	)
	_apply_pose(pose, delta)

func _build_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "MannequinVisual"
	add_child(_visual_root)
	var team_color := Color(0.86, 0.28, 0.18, 1.0) if _player.team_index == 0 else Color(0.18, 0.42, 0.86, 1.0)
	_torso = _build_box_part("Torso", Vector3(0.46, 0.60, 0.24), team_color)
	_head = _build_sphere_part("Head", 0.16, Color(0.74, 0.56, 0.44, 1.0))
	_left_arm = _build_limb("LeftArm", 0.36, 0.07, team_color)
	_right_arm = _build_limb("RightArm", 0.36, 0.07, team_color)
	_left_leg = _build_limb("LeftLeg", 0.58, 0.085, Color(0.10, 0.13, 0.18, 1.0))
	_right_leg = _build_limb("RightLeg", 0.58, 0.085, Color(0.10, 0.13, 0.18, 1.0))
	for part in [_torso, _head, _left_arm, _right_arm, _left_leg, _right_leg]:
		_visual_root.add_child(part)
	_torso.position = Vector3(0.0, 1.18, 0.0)
	_head.position = Vector3(0.0, 1.63, 0.0)
	_left_arm.position = Vector3(-0.31, 1.37, 0.0)
	_right_arm.position = Vector3(0.31, 1.37, 0.0)
	_left_leg.position = Vector3(-0.14, 0.78, 0.0)
	_right_leg.position = Vector3(0.14, 0.78, 0.0)

func _build_box_part(node_name: String, size: Vector3, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = _material(color)
	root.add_child(mesh_instance)
	return root

func _build_sphere_part(node_name: String, radius: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh_instance.mesh = sphere
	mesh_instance.material_override = _material(color)
	root.add_child(mesh_instance)
	return root

func _build_limb(node_name: String, length: float, radius: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	var mesh_instance := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = length
	mesh_instance.mesh = capsule
	mesh_instance.position = Vector3(0.0, -length * 0.45, 0.0)
	mesh_instance.material_override = _material(color)
	root.add_child(mesh_instance)
	return root

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material

func _update_confirmed_reaction() -> void:
	var session := get_tree().get_first_node_in_group("network_session") as NetworkSession
	if session == null:
		return
	var snapshot := session.get_debug_snapshot()
	var event_text := String(snapshot.get("last_event", ""))
	if event_text == _last_network_event:
		return
	_last_network_event = event_text
	if not event_text.contains("target=%d" % _player.network_peer_id):
		return
	if event_text.begins_with("head_hit"):
		_reaction_strength = 1.0
	elif event_text.begins_with("body_hit"):
		_reaction_strength = 0.65

func _apply_pose(pose: Dictionary, delta: float) -> void:
	var weight := minf(1.0, delta * 15.0)
	_torso.position = _torso.position.lerp(Vector3(pose["torso_position"]), weight)
	_torso.rotation = _torso.rotation.lerp(Vector3(pose["torso_rotation"]), weight)
	_torso.scale = _torso.scale.lerp(Vector3(pose["torso_scale"]), weight)
	_head.position = _head.position.lerp(Vector3(0.0, 1.63, 0.0) + Vector3(pose["head_offset"]), weight)
	_left_arm.rotation = _left_arm.rotation.lerp(Vector3(pose["left_arm_rotation"]), weight)
	_right_arm.rotation = _right_arm.rotation.lerp(Vector3(pose["right_arm_rotation"]), weight)
	_left_leg.rotation = _left_leg.rotation.lerp(Vector3(pose["left_leg_rotation"]), weight)
	_right_leg.rotation = _right_leg.rotation.lerp(Vector3(pose["right_leg_rotation"]), weight)
