class_name GlacierValleyPresenter
extends Node3D

const TEAM_A_COLOR := Color(0.74, 0.18, 0.105, 1.0)
const TEAM_B_COLOR := Color(0.11, 0.30, 0.66, 1.0)
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
	_build_blowing_snow()

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
		sun.rotation_degrees = Vector3(-43.0, -31.0, 0.0)
		sun.light_color = GlacierValleyVisualSpec.SUN_COLOR
		sun.light_energy = 1.58
		sun.shadow_enabled = true

	var fill := DirectionalLight3D.new()
	fill.name = "ColdSkyFill"
	fill.rotation_degrees = Vector3(-24.0, 150.0, 0.0)
	fill.light_color = Color(0.27, 0.43, 0.62, 1.0)
	fill.light_energy = 0.14
	fill.shadow_enabled = false
	add_child(fill)

func _surface_material_for(node_name: String) -> StandardMaterial3D:
	if node_name == "ValleyFloor" or node_name.contains("Snowbank") or node_name.contains("Ramp"):
		return RealisticMaterialFactory.snow_surface()
	if node_name == "FrozenRiver":
		return RealisticMaterialFactory.ice_surface(false)
	if node_name.contains("TeamAOutpostSpawnShield"):
		return RealisticMaterialFactory.team_structure_surface(TEAM_A_COLOR)
	if node_name.contains("TeamBOutpostSpawnShield"):
		return RealisticMaterialFactory.team_structure_surface(TEAM_B_COLOR)
	if node_name.contains("Shelter"):
		return RealisticMaterialFactory.weathered_wood_surface()
	if node_name.contains("CaveOuter") or node_name.contains("CaveBend") or node_name.contains("HighShelf") or node_name.contains("Counter"):
		return RealisticMaterialFactory.rock_surface()
	if node_name.contains("Glacier") or node_name.contains("CaveInner") or node_name.contains("CaveRoof") or node_name.contains("RiverCover") or node_name.contains("BrokenGlacier"):
		return RealisticMaterialFactory.ice_surface(true)
	if node_name.contains("Wall"):
		return RealisticMaterialFactory.rock_surface()
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
	environment.ambient_light_energy = 0.70
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.03
	environment.fog_enabled = true
	environment.fog_light_color = GlacierValleyVisualSpec.FOG_COLOR
	environment.fog_light_energy = 0.70
	environment.fog_density = 0.0052
	environment.fog_sky_affect = 0.48
	environment.fog_height = -0.5
	environment.fog_height_density = 0.012
	environment.ssao_enabled = true
	environment.ssao_radius = 1.45
	environment.ssao_intensity = 1.35
	environment.ssao_power = 1.25
	environment.ssil_enabled = true
	environment.ssil_radius = 4.2
	environment.ssil_intensity = 0.52
	environment.ssr_enabled = true
	environment.ssr_max_steps = 64
	environment.glow_enabled = true

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

	for index in range(5):
		var slab := MeshInstance3D.new()
		slab.name = "ArchFractureSlab%02d" % index
		var slab_mesh := BoxMesh.new()
		slab_mesh.size = Vector3(1.1 + index * 0.13, 3.4 + (index % 2) * 0.8, 3.3)
		slab.mesh = slab_mesh
		slab.position = Vector3(-5.8 + index * 2.9, 7.9 + (index % 3) * 0.35, 0.25 * (index - 2))
		slab.rotation_degrees = Vector3(float(index % 2) * 3.0, -10.0 + index * 5.0, -11.0 + index * 5.5)
		slab.material_override = RealisticMaterialFactory.ice_surface(index % 2 == 0)
		add_child(slab)

func _build_river_accents() -> void:
	var material := _material(GlacierValleyVisualSpec.RIVER_GLINT_COLOR, 0.05, 0.08, 0.08)
	var glints := GlacierValleyVisualSpec.river_glint_positions(_config)
	for index in range(glints.size()):
		var glint: Dictionary = glints[index]
		var crack := MeshInstance3D.new()
		crack.name = "RiverGlint%02d" % index
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.035, 0.014, float(glint["length"]))
		crack.mesh = mesh
		crack.position = Vector3(glint["position"])
		crack.rotation_degrees.y = float(glint["yaw"])
		crack.material_override = material
		crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(crack)

	for index in range(7):
		var frost_patch := MeshInstance3D.new()
		frost_patch.name = "RiverFrostPatch%02d" % index
		var patch_mesh := CylinderMesh.new()
		patch_mesh.top_radius = 0.9 + float(index % 3) * 0.35
		patch_mesh.bottom_radius = patch_mesh.top_radius * 1.06
		patch_mesh.height = 0.012
		patch_mesh.radial_segments = 18
		frost_patch.mesh = patch_mesh
		frost_patch.position = Vector3(-1.8 + float(index % 4) * 1.2, 0.352, 33.0 - float(index) * 10.5)
		frost_patch.scale.z = 0.42 + float(index % 2) * 0.20
		frost_patch.material_override = RealisticMaterialFactory.packed_snow_surface()
		frost_patch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(frost_patch)

func _build_snow_drifts() -> void:
	var drift_material := RealisticMaterialFactory.powder_surface()
	var index := 0
	for drift_position in GlacierValleyVisualSpec.snow_drift_positions(_config):
		var drift := MeshInstance3D.new()
		drift.name = "SnowDrift%02d" % index
		var sphere := SphereMesh.new()
		sphere.radius = 2.15 + float(index % 3) * 0.30
		sphere.height = 0.55 + float(index % 2) * 0.12
		sphere.radial_segments = 24
		sphere.rings = 10
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
		light.light_energy = 1.75
		light.omni_range = 11.5
		light.shadow_enabled = index == 1
		add_child(light)
		index += 1

func _build_cave_crystals() -> void:
	var x := _config.cave_center_x
	var positions := [
		Vector3(x - 2.6, 5.2, -18.0), Vector3(x + 2.2, 5.1, -7.0),
		Vector3(x - 2.1, 5.3, 6.5), Vector3(x + 2.5, 5.0, 18.5),
	]
	for index in range(positions.size()):
		var icicle := _add_spire(
			"CaveIcicle%02d" % index,
			positions[index],
			1.7 + float(index % 2) * 0.7,
			0.22 + float(index % 3) * 0.05,
			GlacierValleyVisualSpec.CAVE_LIGHT_COLOR.darkened(0.22),
			0.18,
			false
		)
		icicle.rotation_degrees.z = 180.0

func _build_outpost_anchor(side: float, team_color: Color, _label_text: String) -> void:
	var spawn_z := (_config.playable_half_length - _config.team_spawn_inset) * side
	var prefix := "TeamA" if side > 0.0 else "TeamB"
	var index := 0
	for light_position in GlacierValleyVisualSpec.outpost_light_positions(_config, side):
		var light := OmniLight3D.new()
		light.name = "%sWarmLight%02d" % [prefix, index]
		light.position = light_position
		light.light_color = GlacierValleyVisualSpec.WARM_LIGHT_COLOR
		light.light_energy = 2.35
		light.omni_range = 9.0
		light.shadow_enabled = false
		add_child(light)

		var lantern := MeshInstance3D.new()
		lantern.name = "%sLantern%02d" % [prefix, index]
		var lantern_mesh := SphereMesh.new()
		lantern_mesh.radius = 0.10
		lantern_mesh.height = 0.20
		lantern_mesh.radial_segments = 14
		lantern_mesh.rings = 7
		lantern.mesh = lantern_mesh
		lantern.position = light_position
		lantern.material_override = _material(GlacierValleyVisualSpec.WARM_LIGHT_COLOR, 0.25, 0.0, 1.25)
		lantern.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lantern)
		index += 1

	var pole := MeshInstance3D.new()
	pole.name = prefix + "BannerPole"
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.055
	pole_mesh.bottom_radius = 0.07
	pole_mesh.height = 3.4
	pole_mesh.radial_segments = 14
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, 2.0, spawn_z + 4.2 * side)
	pole.material_override = RealisticMaterialFactory.dark_metal_surface()
	add_child(pole)

	var banner := MeshInstance3D.new()
	banner.name = prefix + "Banner"
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(2.1, 0.95, 0.055)
	banner.mesh = banner_mesh
	banner.position = Vector3(1.05, 3.05, spawn_z + 4.2 * side)
	banner.material_override = RealisticMaterialFactory.fabric_surface(team_color, 0.78)
	add_child(banner)

	var roof_material := RealisticMaterialFactory.weathered_wood_surface()
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

		var snow_cap := MeshInstance3D.new()
		snow_cap.name = roof.name + "SnowCap"
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = Vector3(6.15, 0.08, 5.55)
		snow_cap.mesh = cap_mesh
		snow_cap.position = roof.position + Vector3(0.0, 0.15, 0.0)
		snow_cap.rotation_degrees = roof.rotation_degrees
		snow_cap.material_override = RealisticMaterialFactory.powder_surface()
		snow_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(snow_cap)

	_build_outpost_props(side, prefix, spawn_z, team_color)

func _build_outpost_props(side: float, prefix: String, spawn_z: float, team_color: Color) -> void:
	var wood := RealisticMaterialFactory.weathered_wood_surface()
	var metal := RealisticMaterialFactory.dark_metal_surface()
	var accent := RealisticMaterialFactory.team_structure_surface(team_color)

	for brace_index in range(4):
		var brace := MeshInstance3D.new()
		brace.name = "%sBrace%02d" % [prefix, brace_index]
		var brace_mesh := BoxMesh.new()
		brace_mesh.size = Vector3(0.16, 2.8, 0.16)
		brace.mesh = brace_mesh
		var brace_side := -1.0 if brace_index % 2 == 0 else 1.0
		var brace_depth := -1.0 if brace_index < 2 else 1.0
		brace.position = Vector3(brace_side * 5.0, 1.45, spawn_z + brace_depth * 3.3 * side)
		brace.rotation_degrees.z = brace_side * 8.0
		brace.material_override = wood
		add_child(brace)

	for crate_index in range(3):
		var crate := MeshInstance3D.new()
		crate.name = "%sSupplyCrate%02d" % [prefix, crate_index]
		var crate_mesh := BoxMesh.new()
		crate_mesh.size = Vector3(0.9 + crate_index * 0.12, 0.62, 0.75)
		crate.mesh = crate_mesh
		crate.position = Vector3(-6.6 + crate_index * 1.15, 0.35, spawn_z + 2.6 * side)
		crate.rotation_degrees.y = -9.0 + crate_index * 7.0
		crate.material_override = wood if crate_index < 2 else metal
		add_child(crate)

	var marker := MeshInstance3D.new()
	marker.name = prefix + "TeamMarkerPanel"
	var marker_mesh := BoxMesh.new()
	marker_mesh.size = Vector3(1.35, 0.38, 0.06)
	marker.mesh = marker_mesh
	marker.position = Vector3(0.0, 2.55, spawn_z - 5.65 * side)
	marker.material_override = accent
	add_child(marker)

func _build_snow_source_readability() -> void:
	var mound_material := RealisticMaterialFactory.powder_surface()
	var base_material := RealisticMaterialFactory.packed_snow_surface()
	var source_index := 0
	for source_position in _snow_source_positions:
		var base := MeshInstance3D.new()
		base.name = "SnowSourcePowderBase%02d" % source_index
		var base_mesh := CylinderMesh.new()
		base_mesh.top_radius = 2.55
		base_mesh.bottom_radius = 2.70
		base_mesh.height = 0.055
		base_mesh.radial_segments = 32
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
			sphere.radial_segments = 20
			sphere.rings = 9
			mound.mesh = sphere
			mound.position = source_position + offset
			mound.scale.x = 1.15 + float(mound_index % 2) * 0.12
			mound.scale.z = 0.92 + float(mound_index % 3) * 0.08
			mound.material_override = mound_material
			mound.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mound)
			mound_index += 1
		source_index += 1

func _build_blowing_snow() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "WindDrivenSnow"
	particles.amount = 420
	particles.lifetime = 5.8
	particles.randomness = 0.42
	particles.visibility_aabb = AABB(Vector3(-58.0, -3.0, -78.0), Vector3(116.0, 28.0, 156.0))

	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(48.0, 11.0, 64.0)
	process.direction = Vector3(-0.62, -0.72, 0.18).normalized()
	process.spread = 20.0
	process.initial_velocity_min = 1.8
	process.initial_velocity_max = 4.6
	process.gravity = Vector3(-0.25, -0.65, 0.10)
	process.scale_min = 0.55
	process.scale_max = 1.35
	process.color = Color(0.92, 0.965, 1.0, 0.52)
	particles.process_material = process

	var flake := QuadMesh.new()
	flake.size = Vector2(0.045, 0.045)
	var flake_material := StandardMaterial3D.new()
	flake_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flake_material.albedo_color = Color(0.96, 0.985, 1.0, 0.62)
	flake_material.roughness = 1.0
	flake_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flake_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	flake.material = flake_material
	particles.draw_pass_1 = flake
	particles.position = Vector3(0.0, 8.0, 0.0)
	add_child(particles)

func _add_spire(node_name: String, position: Vector3, height: float, radius: float, color: Color, roughness: float, snow_cap: bool) -> MeshInstance3D:
	var spire := MeshInstance3D.new()
	spire.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	spire.mesh = mesh
	spire.position = position
	if roughness < 0.35:
		spire.material_override = RealisticMaterialFactory.ice_surface(roughness > 0.25)
	else:
		spire.material_override = _material(color, roughness, 0.04)
	add_child(spire)

	if snow_cap:
		var cap := MeshInstance3D.new()
		cap.name = node_name + "SnowCap"
		var cap_mesh := CylinderMesh.new()
		cap_mesh.top_radius = 0.0
		cap_mesh.bottom_radius = radius * 0.56
		cap_mesh.height = height * 0.27
		cap_mesh.radial_segments = 12
		cap.mesh = cap_mesh
		cap.position = Vector3(0.0, height * 0.365, 0.0)
		cap.material_override = RealisticMaterialFactory.powder_surface()
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
	visual.material_override = RealisticMaterialFactory.ice_surface(roughness > 0.18)
	add_child(visual)
	return visual

func _material(color: Color, roughness: float, metallic: float = 0.0, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if roughness < 0.25 and metallic < 0.2:
		material.clearcoat_enabled = true
		material.clearcoat = 0.65
		material.clearcoat_roughness = 0.12
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material
