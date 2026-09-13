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
	sphere.radius = 0.095
	sphere.height = 0.19
	sphere.radial_segments = 28
	sphere.rings = 14
	_snowball.mesh = sphere
	_snowball.material_override = RealisticMaterialFactory.snowball_surface()
	_snowball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rig_root.add_child(_snowball)
	_add_snowball_clump(Vector3(0.048, 0.014, -0.040), 0.040)
	_add_snowball_clump(Vector3(-0.035, 0.046, 0.018), 0.032)
	_add_snowball_clump(Vector3(-0.018, -0.045, -0.026), 0.027)
	_add_snowball_clump(Vector3(0.012, 0.052, 0.050), 0.022)

func _add_snowball_clump(offset: Vector3, radius: float) -> void:
	var clump := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 14
	mesh.rings = 7
	clump.mesh = mesh
	clump.position = offset
	clump.material_override = RealisticMaterialFactory.snowball_surface()
	clump.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_snowball.add_child(clump)

func _build_hand(node_name: String, side: float) -> Node3D:
	var root := Node3D.new()
	root.name = node_name

	var forearm := MeshInstance3D.new()
	forearm.name = "Forearm"
	var forearm_mesh := CylinderMesh.new()
	forearm_mesh.top_radius = 0.052
	forearm_mesh.bottom_radius = 0.078
	forearm_mesh.height = 0.42
	forearm_mesh.radial_segments = 24
	forearm.mesh = forearm_mesh
	forearm.position = Vector3(0.0, -0.18, 0.075)
	forearm.material_override = RealisticMaterialFactory.fabric_surface(WinterCharacterPalette.NEUTRAL_JACKET, 0.80)
	forearm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(forearm)

	var sleeve_panel := MeshInstance3D.new()
	sleeve_panel.name = "SleevePanel"
	var sleeve_mesh := BoxMesh.new()
	sleeve_mesh.size = Vector3(0.075, 0.18, 0.018)
	sleeve_panel.mesh = sleeve_mesh
	sleeve_panel.position = Vector3(0.0, -0.18, -0.005)
	sleeve_panel.material_override = RealisticMaterialFactory.fabric_surface(WinterCharacterPalette.NEUTRAL_ACCENT, 0.72)
	sleeve_panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(sleeve_panel)

	var cuff := MeshInstance3D.new()
	cuff.name = "TeamCuff"
	var cuff_mesh := CylinderMesh.new()
	cuff_mesh.top_radius = 0.068
	cuff_mesh.bottom_radius = 0.075
	cuff_mesh.height = 0.072
	cuff_mesh.radial_segments = 20
	cuff.mesh = cuff_mesh
	cuff.position = Vector3(0.0, -0.045, 0.018)
	cuff.material_override = RealisticMaterialFactory.fabric_surface(WinterCharacterPalette.NEUTRAL_ACCENT, 0.70)
	cuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cuff)

	var palm := MeshInstance3D.new()
	palm.name = "Glove"
	var palm_mesh := SphereMesh.new()
	palm_mesh.radius = 0.071
	palm_mesh.height = 0.13
	palm_mesh.radial_segments = 22
	palm_mesh.rings = 11
	palm.mesh = palm_mesh
	palm.scale = Vector3(1.02, 0.76, 1.10)
	palm.position = Vector3(0.0, 0.015, -0.018)
	palm.material_override = RealisticMaterialFactory.glove_surface(WinterCharacterPalette.GLOVE)
	palm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(palm)

	var knuckle_pad := MeshInstance3D.new()
	knuckle_pad.name = "KnucklePad"
	var knuckle_mesh := BoxMesh.new()
	knuckle_mesh.size = Vector3(0.112, 0.034, 0.070)
	knuckle_pad.mesh = knuckle_mesh
	knuckle_pad.position = Vector3(0.0, 0.032, -0.058)
	knuckle_pad.material_override = RealisticMaterialFactory.glove_surface(WinterCharacterPalette.GLOVE.lightened(0.03))
	knuckle_pad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(knuckle_pad)

	for finger_index in range(4):
		var finger := MeshInstance3D.new()
		finger.name = "Finger%d" % finger_index
		var finger_mesh := CapsuleMesh.new()
		finger_mesh.radius = 0.0145
		finger_mesh.height = 0.078 + float(finger_index == 1 or finger_index == 2) * 0.008
		finger.mesh = finger_mesh
		finger.position = Vector3((-0.041 + finger_index * 0.027) * side, 0.018, -0.091)
		finger.rotation_degrees.x = 78.0
		finger.material_override = RealisticMaterialFactory.glove_surface(WinterCharacterPalette.GLOVE)
		finger.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(finger)

	var thumb := MeshInstance3D.new()
	thumb.name = "Thumb"
	var thumb_mesh := CapsuleMesh.new()
	thumb_mesh.radius = 0.024
	thumb_mesh.height = 0.090
	thumb.mesh = thumb_mesh
	thumb.position = Vector3(0.060 * side, 0.005, -0.020)
	thumb.rotation_degrees = Vector3(18.0, 0.0, -50.0 * side)
	thumb.material_override = RealisticMaterialFactory.glove_surface(WinterCharacterPalette.GLOVE)
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
		var sleeve_panel := hand_root.get_node_or_null("SleevePanel") as MeshInstance3D
		var cuff := hand_root.get_node_or_null("TeamCuff") as MeshInstance3D
		if forearm != null:
			forearm.material_override = RealisticMaterialFactory.fabric_surface(jacket, 0.80)
		if sleeve_panel != null:
			sleeve_panel.material_override = RealisticMaterialFactory.fabric_surface(accent.darkened(0.10), 0.74)
		if cuff != null:
			cuff.material_override = RealisticMaterialFactory.fabric_surface(accent, 0.70)

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
