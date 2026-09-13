class_name GlacierValleyPresenter
extends Node3D

const TEAM_A_COLOR := Color(0.86, 0.28, 0.15, 1.0)
const TEAM_B_COLOR := Color(0.16, 0.40, 0.82, 1.0)
const WOOD_COLOR := Color(0.25, 0.16, 0.11, 1.0)
const DARK_METAL_COLOR := Color(0.08, 0.11, 0.14, 1.0)

var _config: GlacierValleyConfig
var _snow_source_positions: Array[Vector3] = []

func configure(config: GlacierValleyConfig, snow_source_positions: Array[Vector3]) -> void:
	_config = config
	_snow_source_positions = snow_source_positions.duplicate()

func _ready() -> void:
	if _config == null or DisplayServer.get_name() == "headless":
		visible = false
		return
	_polish_existing_world()
	_build_environment()
	_build_backdrop()
	_build_wall_ice_facets()
	_build_arch_silhouette()
	_build_river_accents()
	_build_snow_drifts()
	_build_cave_lighting()
	_build_cave_crystals()
	_build_outpost_anchor(1.0, TEAM_A_COLOR, "TEAM A OUTPOST")
	_build_outpost_anchor(-1.0, TEAM_B_COLOR, "TEAM B OUTPOST")
	_build_snow_source_readability()

func _polish_existing_world() -> void:
	var world := get_parent()
	if world == null:
		return
	for node in world.get_children():
		if node is not StaticBody3D:
			continue
		var body := node as StaticBody3D
		var surface_material := _surface_material_for(String(body.name))
		if surface_material == null:
			continue
		for child in body.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).material_override = surface_material

	var sun := world.get_node_or_null("Sun") as DirectionalLight3D
	if sun != null:
		sun.rotation_degrees = Vector3(-47.0, -32.0, 0.0)
		sun.light_color = GlacierValleyVisualSpec.SUN_COLOR
		sun.light_energy = 1.72
		sun.shadow_enabled = true

	var fill := DirectionalLight3D.new()
	fill.name = "ColdSkyFill"
	fill.rotation_degrees = Vector3(-24.0, 150.0, 0.0)
	fill.light_color = Color(0.30, 0.50, 0.72, 1.0)
	fill.light_energy = 0.18
	fill.shadow_enabled = false
	add_child(fill)

func _surface_material_for(node_name: String) -> StandardMaterial3D:
	if node_name == "ValleyFloor" or node_name.contains("Snowbank") or node_name.contains("Ramp"):
		return _material(GlacierValleyVisualSpec.SNOW_SURFACE_COLOR, 0.91)
	if node_name == "FrozenRiver":
		return _material(GlacierValleyVisualSpec.ICE_SURFACE_COLOR, 0.11, 0.16, 0.055)
	if node_name.contains("TeamAOutpostSpawnShield"):
		return _material(TEAM_A_COLOR.darkened(0.12), 0.48, 0.03)
	if node_name.contains("TeamBOutpostSpawnShield"):
		return _material(TEAM_B_COLOR.darkened(0.10), 0.48, 0.03)
	if node_name.contains("Shelter"):
		return _material(GlacierValleyVisualSpec.WOOD_SURFACE_COLOR, 0.74)
	if node_name.contains("CaveOuter") or node_name.contains("CaveBend") or node_name.contains("HighShelf") or node_name.contains("Counter"):
		return _material(GlacierValleyVisualSpec.ROCK_SURFACE_COLOR, 0.84, 0.02)
	if node_name.contains("Glacier") or node_name.contains("CaveInner") or node_name.contains("CaveRoof") or node_name.contains("RiverCover") or node_name.contains("BrokenGlacier"):
		return _material(GlacierValleyVisualSpec.DEEP_ICE_SURFACE_COLOR, 0.23, 0.07, 0.025)
	if node_name.contains("Wall"):
		return _material(GlacierValleyVisualSpec.ROCK_SURFACE_COLOR, 0.82)
	return null

func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = GlacierValleyVisualSpec.SKY_TOP_COLOR
	sky_material.sky_horizon_color = GlacierValleyVisualSpec.SKY_HORIZON_COLOR
	sky_material.ground_horizon_color = GlacierValleyVisualSpec.GROUND_HORIZON_COLOR
	sky_material.ground_bottom_color = GlacierValleyVisualSpec.GROUND_BOTTOM_COLOR

	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_color = GlacierValleyVisualSpec.AMBIENT_COLOR
	environment.ambient_light_energy = 0.78
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.08
	environment.fog_enabled = true
	environment.fog_light_color = GlacierValleyVisualSpec.FOG_COLOR
	environment.fog_light_energy = 0.75
	environment.fog_density = 0.0065
	environment.fog_sky_affect = 0.52

	var world_environment := WorldEnvironment.new()
	world_environment.name = "GlacierValleyEnvironment"
	world_environment.environment = environment
	add_child(world_environment)

func _build_backdrop() -> void:
	var index := 0
	for spire in GlacierValleyVisualSpec.backdrop_spires(_config):
		var shade := GlacierValleyVisualSpec.BACKDROP_ICE_COLOR.lerp(
			GlacierValleyVisualSpec.BACKDROP_SHADOW_COLOR,
			0.18 if index % 2 == 0 else 0.36
		)
		_add_spire(
			String(spire["name"]),
			Vector3(spire["position"]),
			float(spire["height"]),
			float(spire["radius"]),
			shade,
			0.58,
			true
		)
		index += 1

func _build_wall_ice_facets() -> void:
	for shard in GlacierValleyVisualSpec.wall_ice_shards(_config):
		var shard_node := _add_spire(
			String(shard["name"]),
			Vector3(shard["position"]),
			float(shard["height"]),
			float(shard["radius"]),
			GlacierValleyVisualSpec.BACKDROP_ICE_COLOR,
			0.30,
			true
		)
		shard_node.rotation_degrees.z = float(shard["tilt"])

func _build_arch_silhouette() -> void:
	for spire in GlacierValleyVisualSpec.arch_spires():
		_add_spire(
			String(spire["name"]),
			Vector3(spire["position"]),
			float(spire["height"]),
			float(spire["radius"]),
			GlacierValleyVisualSpec.ARCH_ICE_COLOR,
			0.22,
			false
		)

	_add_visual_box(
		"ArchFacetWest",
		Vector3(11.8, 1.15, 6.4),
		Vector3(-5.2, 10.55, 0.0),
		Vector3(0.0, 0.0, -8.0),
		GlacierValleyVisualSpec.ARCH_HIGHLIGHT_COLOR,
		0.17
	)
	_add_visual_box(
		"ArchFacetEast",
		Vector3(11.8, 1.15, 6.4),
		Vector3(5.2, 10.55, 0.0),
		Vector3(0.0, 0.0, 8.0),
		GlacierValleyVisualSpec.ARCH_ICE_COLOR,
		0.20
	)

func _build_river_accents() -> void:
	var material := _material(GlacierValleyVisualSpec.RIVER_GLINT_COLOR, 0.06, 0.10, 0.14)
	var glints := GlacierValleyVisualSpec.river_glint_positions(_config)
	for index in range(glints.size()):
		var glint: Dictionary = glints[index]
		var crack := MeshInstance3D.new()
		crack.name = "RiverGlint%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.055, 0.018, float(glint["length"]))
		crack.mesh = mesh
		crack.position = Vector3(glint["position"])
		crack.rotation_degrees.y = float(glint["yaw"])
		crack.material_override = material
		crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(crack)

func _build_snow_drifts() -> void:
	var drift_material := _material(GlacierValleyVisualSpec.POWDER_COLOR, 0.96)
	var index := 0
	for drift_position in GlacierValleyVisualSpec.snow_drift_positions(_config):
		var drift := MeshInstance3D.new()
		drift.name = "SnowDrift%02d" % index
		var sphere := SphereMesh.new()
		sphere.radius = 2.15 + float(index % 3) * 0.30
		sphere.height = 0.55 + float(index % 2) * 0.12
		sphere.radial_segments = 20
		sphere.rings = 8
		drift.mesh = sphere
		drift.position = drift_position
		drift.rotation_degrees.y = float(index * 23)
		drift.material_override = drift_material
		drift.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(drift)
		index += 1

func _build_cave_lighting() -> void:
	var index := 0
	for light_position in GlacierValleyVisualSpec.cave_light_positions(_config):
		var light := OmniLight3D.new()
		light.name = "CaveCyanLight%02d" % index
		light.position = light_position
		light.light_color = GlacierValleyVisualSpec.CAVE_LIGHT_COLOR
		light.light_energy = 2.2
		light.omni_range = 12.5
		light.shadow_enabled = index == 1
		add_child(light)
		index += 1

func _build_cave_crystals() -> void:
	var x := _config.cave_center_x
	var positions := [
		Vector3(x - 2.5, 1.6, -20.0), Vector3(x + 2.1, 1.2, -7.5),
		Vector3(x - 2.0, 1.8, 7.0), Vector3(x + 2.5, 1.4, 20.5),
	]
	for index in range(positions.size()):
		var crystal := _add_spire(
			"CaveCrystal%02d" % index,
			positions[index],
			2.4 + float(index % 2) * 0.8,
			0.35 + float(index % 3) * 0.08,
			GlacierValleyVisualSpec.CAVE_LIGHT_COLOR,
			0.12,
			false
		)
		crystal.rotation_degrees.z = -9.0 + float(index) * 6.0

func _build_outpost_anchor(side: float, team_color: Color, label_text: String) -> void:
	var spawn_z := (_config.playable_half_length - _config.team_spawn_inset) * side
	var prefix := "TeamA" if side > 0.0 else "TeamB"
	var index := 0
	for light_position in GlacierValleyVisualSpec.outpost_light_positions(_config, side):
		var light := OmniLight3D.new()
		light.name = "%sWarmLight%02d" % [prefix, index]
		light.position = light_position
		light.light_color = GlacierValleyVisualSpec.WARM_LIGHT_COLOR
		light.light_energy = 2.8
		light.omni_range = 10.0
		light.shadow_enabled = false
		add_child(light)

		var lantern := MeshInstance3D.new()
		lantern.name = "%sLantern%02d" % [prefix, index]
		var lantern_mesh := SphereMesh.new()
		lantern_mesh.radius = 0.12
		lantern_mesh.height = 0.24
		lantern_mesh.radial_segments = 12
		lantern_mesh.rings = 6
		lantern.mesh = lantern_mesh
		lantern.position = light_position
		lantern.material_override = _material(GlacierValleyVisualSpec.WARM_LIGHT_COLOR, 0.25, 0.0, 1.8)
		lantern.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lantern)
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
	pole.material_override = _material(DARK_METAL_COLOR, 0.42, 0.55)
	add_child(pole)

	var banner := MeshInstance3D.new()
	banner.name = prefix + "Banner"
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(2.1, 0.95, 0.08)
	banner.mesh = banner_mesh
	banner.position = Vector3(1.05, 3.05, spawn_z + 4.2 * side)
	banner.material_override = _material(team_color, 0.48)
	add_child(banner)

	var roof_material := _material(WOOD_COLOR, 0.70)
	for roof_side in [-1.0, 1.0]:
		var roof := MeshInstance3D.new()
		roof.name = "%sRoof%s" % [prefix, "Left" if roof_side < 0.0 else "Right"]
		var roof_mesh := BoxMesh.new()
		roof_mesh.size = Vector3(6.4, 0.20, 5.8)
		roof.mesh = roof_mesh
		roof.position = Vector3(roof_side * 2.75, 3.45, spawn_z + 1.0 * side)
		roof.rotation_degrees.z = roof_side * -15.0
		roof.material_override = roof_material
		add_child(roof)

	var label := Label3D.new()
	label.name = prefix + "OutpostLabel"
	label.text = label_text
	label.position = Vector3(0.0, 4.7, spawn_z + 3.6 * side)
	label.billboard = 1
	label.font_size = 24
	label.outline_size = 7
	label.modulate = team_color.lightened(0.25)
	add_child(label)

func _build_snow_source_readability() -> void:
	var mound_material := _material(GlacierValleyVisualSpec.POWDER_COLOR, 0.98)
	var base_material := _material(GlacierValleyVisualSpec.POWDER_SHADOW_COLOR, 0.90)
	var source_index := 0
	for source_position in _snow_source_positions:
		var base := MeshInstance3D.new()
		base.name = "SnowSourcePowderBase%02d" % source_index
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 2.55
		base_mesh.bottom_radius = 2.70
		base_mesh.height = 0.06
		base_mesh.radial_segments = 28
		base.mesh = base_mesh
		base.position = source_position + Vector3(0.0, 0.15, 0.0)
		base.material_override = base_material
		base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(base)

		var mound_index := 0
		for offset in GlacierValleyVisualSpec.snow_mound_offsets():
			var mound := MeshInstance3D.new()
			mound.name = "SnowReadability%02d_%02d" % [source_index, mound_index]
			var sphere := SphereMesh.new()
			sphere.radius = 0.62 + float(mound_index % 3) * 0.08
			sphere.height = 0.32 + float(mound_index % 2) * 0.08
			sphere.radial_segments = 16
			sphere.rings = 7
			mound.mesh = sphere
			mound.position = source_position + offset
			mound.material_override = mound_material
			mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mound)
			mound_index += 1
		source_index += 1

func _add_spire(node_name: String, position: Vector3, height: float, radius: float, color: Color, roughness: float, snow_cap: bool) -> MeshInstance3D:
	var spire := MeshInstance3D.new()
	spire.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	spire.mesh = mesh
	spire.position = position
	spire.material_override = _material(color, roughness, 0.04)
	add_child(spire)

	if snow_cap:
		var cap := MeshInstance3D.new()
		cap.name = node_name + "SnowCap"
		var cap_mesh := CylinderMesh.new()
		cap_mesh.top_radius = 0.0
		cap_mesh.bottom_radius = radius * 0.56
		cap_mesh.height = height * 0.27
		cap_mesh.radial_segments = 10
		cap.mesh = cap_mesh
		cap.position = Vector3(0.0, height * 0.365, 0.0)
		cap.material_override = _material(GlacierValleyVisualSpec.POWDER_COLOR, 0.94)
		cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spire.add_child(cap)
	return spire

func _add_visual_box(node_name: String, size: Vector3, position: Vector3, rotation_degrees: Vector3, color: Color, roughness: float) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.position = position
	visual.rotation_degrees = rotation_degrees
	visual.material_override = _material(color, roughness, 0.05)
	add_child(visual)
	return visual

func _material(color: Color, roughness: float, metallic: float = 0.0, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
