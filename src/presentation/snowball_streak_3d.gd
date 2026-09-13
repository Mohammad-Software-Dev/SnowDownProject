class_name SnowballStreak3D
extends MeshInstance3D

var _built: bool = false

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		visible = false
		return
	_build_visual()

func update_from_velocity(projectile_velocity: Vector3) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if not _built:
		_build_visual()
	var length := SnowballPresentation.streak_length_for_speed(projectile_velocity.length())
	visible = length > 0.0
	if not visible:
		return
	var direction := projectile_velocity.normalized()
	if direction.is_zero_approx():
		visible = false
		return
	var up := Vector3.RIGHT if absf(direction.dot(Vector3.UP)) > 0.96 else Vector3.UP
	look_at(direction, up)
	scale = Vector3(1.0, 1.0, length)
	position = -direction * length * 0.5

func _build_visual() -> void:
	if _built:
		return
	_built = true
	var streak_mesh := BoxMesh.new()
	streak_mesh.size = Vector3(0.032, 0.032, 1.0)
	mesh = streak_mesh
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.88, 0.96, 1.0, 0.48)
	material.no_depth_test = false
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
