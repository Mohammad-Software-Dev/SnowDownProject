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
	_visual_root.name = "WinterCharacterVisual"
	add_child(_visual_root)

	var palette := WinterCharacterPalette.palette(_player.team_index)
	var jacket := Color(palette["jacket"])
	var accent := Color(palette["accent"])
	var pants := Color(palette["pants"])

	_torso = _build_box_part("Torso", Vector3(0.47, 0.60, 0.25), jacket)
	_head = _build_sphere_part("Head", 0.155, Color(palette["skin"]))
	_left_arm = _build_limb("LeftArm", 0.37, 0.068, jacket)
	_right_arm = _build_limb("RightArm", 0.37, 0.068, jacket)
	_left_leg = _build_limb("LeftLeg", 0.59, 0.082, pants)
	_right_leg = _build_limb("RightLeg", 0.59, 0.082, pants)
	for part in [_torso, _head, _left_arm, _right_arm, _left_leg, _right_leg]:
		_visual_root.add_child(part)

	_torso.position = Vector3(0.0, 1.18, 0.0)
	_head.position = Vector3(0.0, 1.63, 0.0)
	_left_arm.position = Vector3(-0.31, 1.37, 0.0)
	_right_arm.position = Vector3(0.31, 1.37, 0.0)
	_left_leg.position = Vector3(-0.14, 0.78, 0.0)
	_right_leg.position = Vector3(0.14, 0.78, 0.0)

	_add_jacket_detail(_torso, accent, Color(palette["scarf"]))
	_add_headwear(_head, Color(palette["beanie"]), Color(palette["scarf"]))
	_add_glove(_left_arm, Color(palette["glove"]))
	_add_glove(_right_arm, Color(palette["glove"]))
	_add_boot(_left_leg, Color(palette["boot"]))
	_add_boot(_right_leg, Color(palette["boot"]))

func _add_jacket_detail(torso_root: Node3D, accent: Color, scarf_color: Color) -> void:
	var zipper := MeshInstance3D.new()
	zipper.name = "JacketZipper"
	var zipper_mesh := BoxMesh.new()
	zipper_mesh.size = Vector3(0.025, 0.43, 0.018)
	zipper.mesh = zipper_mesh
	zipper.position = Vector3(0.0, 0.015, -0.134)
	zipper.material_override = RealisticMaterialFactory.dark_metal_surface()
	torso_root.add_child(zipper)

	var badge := MeshInstance3D.new()
	badge.name = "TeamChestPanel"
	var badge_mesh := BoxMesh.new()
	badge_mesh.size = Vector3(0.12, 0.075, 0.02)
	badge.mesh = badge_mesh
	badge.position = Vector3(0.115, 0.13, -0.137)
	badge.material_override = RealisticMaterialFactory.fabric_surface(accent, 0.74)
	torso_root.add_child(badge)

	var scarf := MeshInstance3D.new()
	scarf.name = "Scarf"
	var scarf_mesh := CylinderMesh.new()
	scarf_mesh.top_radius = 0.16
	scarf_mesh.bottom_radius = 0.17
	scarf_mesh.height = 0.09
	scarf_mesh.radial_segments = 18
	scarf.mesh = scarf_mesh
	scarf.position = Vector3(0.0, 0.34, 0.0)
	scarf.material_override = RealisticMaterialFactory.fabric_surface(scarf_color, 0.86)
	torso_root.add_child(scarf)

func _add_headwear(head_root: Node3D, beanie_color: Color, hood_color: Color) -> void:
	var hood := MeshInstance3D.new()
	hood.name = "Hood"
	var hood_mesh := SphereMesh.new()
	hood_mesh.radius = 0.182
	hood_mesh.height = 0.30
	hood_mesh.radial_segments = 18
	hood_mesh.rings = 9
	hood.mesh = hood_mesh
	hood.position = Vector3(0.0, -0.005, 0.045)
	hood.scale = Vector3(1.06, 1.0, 0.92)
	hood.material_override = RealisticMaterialFactory.fabric_surface(hood_color, 0.84)
	head_root.add_child(hood)

	var beanie := MeshInstance3D.new()
	beanie.name = "Beanie"
	var beanie_mesh := SphereMesh.new()
	beanie_mesh.radius = 0.17
	beanie_mesh.height = 0.13
	beanie_mesh.radial_segments = 18
	beanie_mesh.rings = 7
	beanie.mesh = beanie_mesh
	beanie.position = Vector3(0.0, 0.11, -0.005)
	beanie.material_override = RealisticMaterialFactory.fabric_surface(beanie_color, 0.88)
	head_root.add_child(beanie)

func _add_glove(arm_root: Node3D, glove_color: Color) -> void:
	var glove := MeshInstance3D.new()
	glove.name = "Glove"
	var mesh := SphereMesh.new()
	mesh.radius = 0.075
	mesh.height = 0.14
	mesh.radial_segments = 16
	mesh.rings = 8
	glove.mesh = mesh
	glove.position = Vector3(0.0, -0.36, 0.0)
	glove.material_override = RealisticMaterialFactory.glove_surface(glove_color)
	arm_root.add_child(glove)

func _add_boot(leg_root: Node3D, boot_color: Color) -> void:
	var boot := MeshInstance3D.new()
	boot.name = "Boot"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.17, 0.14, 0.28)
	boot.mesh = mesh
	boot.position = Vector3(0.0, -0.57, -0.06)
	boot.material_override = RealisticMaterialFactory.glove_surface(boot_color)
	leg_root.add_child(boot)

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
	sphere.radial_segments = 18
	sphere.rings = 9
	mesh_instance.mesh = sphere
	mesh_instance.material_override = _skin_material(color)
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
	return RealisticMaterialFactory.fabric_surface(color, 0.82)

func _skin_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.63
	material.subsurf_scatter_enabled = true
	material.subsurf_scatter_strength = 0.08
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
