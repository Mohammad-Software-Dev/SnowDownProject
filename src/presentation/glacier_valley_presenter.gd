class_name GlacierValleyPresenter
extends Node3D

const TEAM_A_COLOR := Color(0.88, 0.36, 0.20, 1.0)
const TEAM_B_COLOR := Color(0.20, 0.48, 0.90, 1.0)
const WOOD_COLOR := Color(0.34, 0.22, 0.15, 1.0)
const ARCH_COLOR := Color(0.24, 0.61, 0.80, 1.0)

var _config: GlacierValleyConfig
var _snow_source_positions: Array[Vector3] = []

func configure(config: GlacierValleyConfig, snow_source_positions: Array[Vector3]) -> void:
	_config = config
	_snow_source_positions = snow_source_positions.duplicate()

func _ready() -> void:
	if _config == null or DisplayServer.get_name() == "headless":
		visible = false
		return
	_build_environment()
	_build_backdrop()
	_build_arch_silhouette()
	_build_cave_lighting()
	_build_outpost_anchor(1.0, TEAM_A_COLOR, "TEAM A OUTPOST")
	_build_outpost_anchor(-1.0, TEAM_B_COLOR, "TEAM B OUTPOST")
	_build_snow_source_readability()

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = GlacierValleyVisualSpec.SKY_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = GlacierValleyVisualSpec.AMBIENT_COLOR
	environment.ambient_light_energy = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.name = "GlacierValleyEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

func _build_backdrop() -> void:
	for spire in GlacierValleyVisualSpec.backdrop_spires(_config):
		_add_spire(
			String(spire["name"]),
			Vector3(spire["position"]),
			float(spire["height"]),
			float(spire["radius"]),
			GlacierValleyVisualSpec.BACKDROP_ICE_COLOR,
			0.72
		)

func _build_arch_silhouette() -> void:
	for spire in GlacierValleyVisualSpec.arch_spires():
		_add_spire(
			String(spire["name"]),
			Vector3(spire["position"]),
			float(spire["height"]),
			float(spire["radius"]),
			ARCH_COLOR,
			0.48
		)

func _build_cave_lighting() -> void:
	var index := 0
	for light_position in GlacierValleyVisualSpec.cave_light_positions(_config):
		var light := OmniLight3D.new()
		light.name = "CaveCyanLight%02d" % index
		light.position = light_position
		light.light_color = GlacierValleyVisualSpec.CAVE_LIGHT_COLOR
		light.light_energy = 1.55
		light.omni_range = 11.0
		light.shadow_enabled = false
		add_child(light)
		index += 1

func _build_outpost_anchor(side: float, team_color: Color, label_text: String) -> void:
	var spawn_z := (_config.playable_half_length - _config.team_spawn_inset) * side
	var prefix := "TeamA" if side > 0.0 else "TeamB"
	var index := 0
	for light_position in GlacierValleyVisualSpec.outpost_light_positions(_config, side):
		var light := OmniLight3D.new()
		light.name = "%sWarmLight%02d" % [prefix, index]
		light.position = light_position
		light.light_color = GlacierValleyVisualSpec.WARM_LIGHT_COLOR
		light.light_energy = 2.0
		light.omni_range = 8.5
		light.shadow_enabled = false
		add_child(light)
		index += 1

	var pole := MeshInstance3D.new()
	pole.name = prefix + "BannerPole"
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.055
	pole_mesh.bottom_radius = 0.07
	pole_mesh.height = 3.4
	pole_mesh.radial_segments = 12
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, 2.0, spawn_z + 4.2 * side)
	pole.material_override = _material(WOOD_COLOR, 0.82)
	add_child(pole)

	var banner := MeshInstance3D.new()
	banner.name = prefix + "Banner"
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(2.1, 0.95, 0.08)
	banner.mesh = banner_mesh
	banner.position = Vector3(1.05, 3.05, spawn_z + 4.2 * side)
	banner.material_override = _material(team_color, 0.78)
	add_child(banner)

	var label := Label3D.new()
	label.name = prefix + "OutpostLabel"
	label.text = label_text
	label.position = Vector3(0.0, 4.15, spawn_z + 3.6 * side)
	label.billboard = 1
	label.font_size = 24
	label.outline_size = 7
	add_child(label)

func _build_snow_source_readability() -> void:
	var material := _material(GlacierValleyVisualSpec.POWDER_COLOR, 1.0)
	var source_index := 0
	for source_position in _snow_source_positions:
		var mound_index := 0
		for offset in GlacierValleyVisualSpec.snow_mound_offsets():
			var mound := MeshInstance3D.new()
			mound.name = "SnowReadability%02d_%02d" % [source_index, mound_index]
			var sphere := SphereMesh.new()
			sphere.radius = 0.62
			sphere.height = 0.32
			sphere.radial_segments = 12
			sphere.rings = 6
			mound.mesh = sphere
			mound.position = source_position + offset
			mound.material_override = material
			add_child(mound)
			mound_index += 1
		source_index += 1

func _add_spire(node_name: String, position: Vector3, height: float, radius: float, color: Color, roughness: float) -> void:
	var spire := MeshInstance3D.new()
	spire.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 9
	spire.mesh = mesh
	spire.position = position
	spire.material_override = _material(color, roughness)
	add_child(spire)

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
