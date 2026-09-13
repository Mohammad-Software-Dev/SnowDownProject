extends SceneTree

func _initialize() -> void:
	var config := GlacierValleyConfig.new()
	var presenter := GlacierValleyPresenter.new()
	presenter.configure(config, [Vector3.ZERO])
	root.add_child(presenter)

	presenter._build_environment()
	presenter._build_arch_silhouette()
	presenter._build_river_accents()
	presenter._build_snow_drifts()
	presenter._build_cave_lighting()
	presenter._build_cave_crystals()
	presenter._build_outpost_anchor(1.0, Color(0.74, 0.18, 0.105, 1.0), "TEAM A OUTPOST")
	presenter._build_snow_source_readability()
	presenter._build_blowing_snow()

	var world_environment := presenter.get_node_or_null("GlacierValleyEnvironment") as WorldEnvironment
	_assert_true(world_environment != null, "visual pass creates WorldEnvironment")
	_assert_true(world_environment.environment != null, "WorldEnvironment owns Environment resource")
	_assert_true(world_environment.environment.background_mode == Environment.BG_SKY, "visual pass uses sky background")
	_assert_true(world_environment.environment.fog_enabled, "distance fog is enabled")
	_assert_true(world_environment.environment.tonemap_mode == Environment.TONE_MAPPER_ACES, "ACES tonemapping is enabled")
	_assert_true(world_environment.environment.ssao_enabled, "SSAO contact shading is enabled")
	_assert_true(world_environment.environment.ssil_enabled, "SSIL indirect light is enabled")
	_assert_true(world_environment.environment.ssr_enabled, "SSR ice reflections are enabled")
	_assert_true(presenter.get_node_or_null("ArchFacetWest") != null, "arch receives faceted visual shell")
	_assert_true(presenter.get_node_or_null("ArchFractureSlab00") != null, "arch receives fracture breakup")
	_assert_true(presenter.get_node_or_null("RiverGlint00") != null, "river receives glossy crack accent")
	_assert_true(presenter.get_node_or_null("RiverFrostPatch00") != null, "river receives frost breakup")
	_assert_true(presenter.get_node_or_null("SnowSourcePowderBase00") != null, "snow source receives powder base")
	_assert_true(presenter.get_node_or_null("TeamAWarmLight00") != null, "outpost receives warm anchor light")
	_assert_true(presenter.get_node_or_null("TeamASupplyCrate00") != null, "outpost receives practical prop detail")
	_assert_true(presenter.get_node_or_null("WindDrivenSnow") != null, "world receives sparse wind-driven snow")

	var snow_material := presenter._surface_material_for("ValleyFloor")
	var river_material := presenter._surface_material_for("FrozenRiver")
	var rock_material := presenter._surface_material_for("HighShelf")
	_assert_true(snow_material != null and snow_material.roughness > 0.8, "snow remains matte")
	_assert_true(snow_material.normal_enabled, "snow has micro-normal detail")
	_assert_true(snow_material.uv1_triplanar and snow_material.uv1_world_triplanar, "snow uses world triplanar mapping")
	_assert_true(river_material != null and river_material.roughness < 0.25, "fast ice reads glossy")
	_assert_true(river_material.clearcoat_enabled, "ice uses clearcoat response")
	_assert_true(river_material.normal_enabled, "ice has micro-normal breakup")
	_assert_true(rock_material != null and rock_material.roughness > 0.7, "rock remains rough")
	_assert_true(rock_material.normal_enabled, "rock has surface microdetail")

	var glove := RealisticMaterialFactory.glove_surface(Color(0.08, 0.09, 0.10, 1.0))
	var snowball := RealisticMaterialFactory.snowball_surface()
	_assert_true(glove.normal_enabled and glove.roughness > 0.6, "glove material reads textured and matte")
	_assert_true(snowball.normal_enabled and snowball.roughness > 0.85, "packed snowball reads rough and granular")

	presenter.free()
	print("SNOWDOWN_VISUAL_RUNTIME_SMOKE_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)
