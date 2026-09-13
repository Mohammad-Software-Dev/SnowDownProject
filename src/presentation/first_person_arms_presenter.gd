class_name FirstPersonArmsPresenter
extends Node

var _camera: Camera3D
var _rig_root: Node3D
var _left_root: Node3D
var _right_root: Node3D
var _snowball: MeshInstance3D
var _motion_phase: float = 0.0
var _last_network_event: String = ""
var _reaction_strength: float = 0.0

func _process(delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_ensure_rig()
	if _rig_root == null:
		return
	var snapshot := _local_snapshot()
	if snapshot.is_empty():
		_rig_root.visible = false
		return
	_rig_root.visible = true
	var speed := float(snapshot.get("speed", 0.0))
	_motion_phase += delta * (1.8 + minf(speed, 8.0) * 0.35)
	_reaction_strength = move_toward(_reaction_strength, 0.0, delta * 4.5)
	_update_confirmed_reaction()
	var pose := FirstPersonArmsPose.resolve(
		StringName(snapshot.get("hand_state", SnowballActionComponent.HANDS_FREE)),
		float(snapshot.get("pack_progress", 0.0)),
		float(snapshot.get("charge", 0.0)),
		int(snapshot.get("inventory", 0)),
		sin(_motion_phase) * clampf(speed / 8.0, 0.0, 1.0),
		_reaction_strength
	)
	_apply_pose(pose, delta)

func _ensure_rig() -> void:
	var active_camera := get_viewport().get_camera_3d()
	if active_camera == null:
		return
	if _camera == active_camera and _rig_root != null:
		return
	if _rig_root != null and is_instance_valid(_rig_root):
		_rig_root.queue_free()
	_camera = active_camera
	_rig_root = Node3D.new()
	_rig_root.name = "ProceduralFirstPersonArms"
	_camera.add_child(_rig_root)
	_left_root = _build_hand("LeftHand", Color(0.14, 0.32, 0.46, 1.0))
	_right_root = _build_hand("RightHand", Color(0.14, 0.32, 0.46, 1.0))
	_rig_root.add_child(_left_root)
	_rig_root.add_child(_right_root)
	_snowball = MeshInstance3D.new()
	_snowball.name = "HeldSnowball"
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	_snowball.mesh = sphere
	var snow_material := StandardMaterial3D.new()
	snow_material.albedo_color = Color(0.95, 0.98, 1.0, 1.0)
	snow_material.roughness = 0.95
	_snowball.material_override = snow_material
	_snowball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rig_root.add_child(_snowball)

func _build_hand(node_name: String, sleeve_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = node_name
	var forearm := MeshInstance3D.new()
	forearm.name = "Forearm"
	var forearm_mesh := CapsuleMesh.new()
	forearm_mesh.radius = 0.055
	forearm_mesh.height = 0.40
	forearm.mesh = forearm_mesh
	forearm.position = Vector3(0.0, -0.17, 0.07)
	var sleeve := StandardMaterial3D.new()
	sleeve.albedo_color = sleeve_color
	sleeve.roughness = 0.8
	forearm.material_override = sleeve
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(forearm)
	var glove := MeshInstance3D.new()
	glove.name = "Glove"
	var glove_mesh := SphereMesh.new()
	glove_mesh.radius = 0.075
	glove_mesh.height = 0.15
	glove.mesh = glove_mesh
	var glove_material := StandardMaterial3D.new()
	glove_material.albedo_color = Color(0.06, 0.08, 0.10, 1.0)
	glove_material.roughness = 0.92
	glove.material_override = glove_material
	glove.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glove)
	return root

func _local_snapshot() -> Dictionary:
	var offline := get_tree().get_first_node_in_group("local_player") as SnowdownPlayer
	if offline != null:
		return offline.get_debug_snapshot()
	var networked := get_tree().get_first_node_in_group("network_local_player") as NetworkPlayer
	if networked != null:
		var snapshot := networked.get_network_debug_snapshot()
		snapshot["speed"] = Vector3(networked.velocity.x, 0.0, networked.velocity.z).length()
		return snapshot
	return {}

func _update_confirmed_reaction() -> void:
	var session := get_tree().get_first_node_in_group("network_session") as NetworkSession
	if session == null:
		return
	var snapshot := session.get_debug_snapshot()
	var event_text := String(snapshot.get("last_event", ""))
	if event_text == _last_network_event:
		return
	_last_network_event = event_text
	var profile := SnowballPresentation.feedback_for_event(event_text, int(snapshot.get("peer_id", 0)))
	if bool(profile["local_reaction"]):
		_reaction_strength = 1.0 if int(profile["emphasis"]) >= 2 else 0.65

func _apply_pose(pose: Dictionary, delta: float) -> void:
	var weight := minf(1.0, delta * 18.0)
	_left_root.position = _left_root.position.lerp(Vector3(pose["left_position"]), weight)
	_right_root.position = _right_root.position.lerp(Vector3(pose["right_position"]), weight)
	_left_root.rotation = _left_root.rotation.lerp(Vector3(pose["left_rotation"]), weight)
	_right_root.rotation = _right_root.rotation.lerp(Vector3(pose["right_rotation"]), weight)
	_snowball.position = _snowball.position.lerp(Vector3(pose["ball_position"]), weight)
	var target_scale := Vector3.ONE * float(pose["ball_scale"])
	_snowball.scale = _snowball.scale.lerp(target_scale, weight)
	_snowball.visible = bool(pose["ball_visible"])
