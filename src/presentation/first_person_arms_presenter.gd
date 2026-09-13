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
var _current_team_index: int = -99

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
	_apply_team_palette(int(snapshot.get("team", -1)))
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
	_current_team_index = -99
	_rig_root = Node3D.new()
	_rig_root.name = "ProceduralFirstPersonArms"
	_camera.add_child(_rig_root)
	_left_root = _build_hand("LeftHand", -1.0)
	_right_root = _build_hand("RightHand", 1.0)
	_rig_root.add_child(_left_root)
	_rig_root.add_child(_right_root)
	_snowball = MeshInstance3D.new()
	_snowball.name = "HeldSnowball"
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.18
	sphere.radial_segments = 16
	sphere.rings = 8
	_snowball.mesh = sphere
	var snow_material := StandardMaterial3D.new()
	snow_material.albedo_color = Color(0.95, 0.98, 1.0, 1.0)
	snow_material.roughness = 0.97
	_snowball.material_override = snow_material
	_snowball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rig_root.add_child(_snowball)

func _build_hand(node_name: String, side: float) -> Node3D:
	var root := Node3D.new()
	root.name = node_name

	var forearm := MeshInstance3D.new()
	forearm.name = "Forearm"
	var forearm_mesh := CapsuleMesh.new()
	forearm_mesh.radius = 0.055
	forearm_mesh.height = 0.40
	forearm.mesh = forearm_mesh
	forearm.position = Vector3(0.0, -0.17, 0.07)
	forearm.material_override = _material(WinterCharacterPalette.NEUTRAL_JACKET, 0.82)
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(forearm)

	var cuff := MeshInstance3D.new()
	cuff.name = "TeamCuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.067
	cuff_mesh.bottom_radius = 0.071
	cuff_mesh.height = 0.065
	cuff_mesh.radial_segments = 14
	cuff.mesh = cuff_mesh
	cuff.position = Vector3(0.0, -0.045, 0.015)
	cuff.material_override = _material(WinterCharacterPalette.NEUTRAL_ACCENT, 0.80)
	cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cuff)

	var glove := MeshInstance3D.new()
	glove.name = "Glove"
	var glove_mesh := SphereMesh.new()
	glove_mesh.radius = 0.073
	glove_mesh.height = 0.145
	glove_mesh.radial_segments = 14
	glove_mesh.rings = 7
	glove.mesh = glove_mesh
	glove.scale = Vector3(1.08, 0.96, 0.92)
	glove.material_override = _material(WinterCharacterPalette.GLOVE, 0.94)
	glove.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glove)

	var thumb := MeshInstance3D.new()
	thumb.name = "Thumb"
	var thumb_mesh := CapsuleMesh.new()
	thumb_mesh.radius = 0.025
	thumb_mesh.height = 0.085
	thumb.mesh = thumb_mesh
	thumb.position = Vector3(0.058 * side, -0.006, -0.004)
	thumb.rotation_degrees = Vector3(0.0, 0.0, -48.0 * side)
	thumb.material_override = _material(WinterCharacterPalette.GLOVE, 0.94)
	thumb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(thumb)
	return root

func _apply_team_palette(team_index: int) -> void:
	if team_index == _current_team_index:
		return
	_current_team_index = team_index
	var jacket := WinterCharacterPalette.jacket_color(team_index)
	var accent := WinterCharacterPalette.accent_color(team_index)
	for hand_root in [_left_root, _right_root]:
		if hand_root == null:
			continue
		var forearm := hand_root.get_node_or_null("Forearm") as MeshInstance3D
		var cuff := hand_root.get_node_or_null("TeamCuff") as MeshInstance3D
		if forearm != null:
			forearm.material_override = _material(jacket, 0.82)
		if cuff != null:
			cuff.material_override = _material(accent, 0.80)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

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
	var target_scale := Vector3(1.0, 0.94, 1.04) * float(pose["ball_scale"])
	_snowball.scale = _snowball.scale.lerp(target_scale, weight)
	_snowball.visible = bool(pose["ball_visible"])
