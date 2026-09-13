extends SceneTree

func _init() -> void:
	var config := GlacierValleyConfig.new()

	_assert_true(GlacierValleyVisualSpec.WARM_LIGHT_COLOR.r > GlacierValleyVisualSpec.WARM_LIGHT_COLOR.b, "outpost light is warm")
	_assert_true(GlacierValleyVisualSpec.CAVE_LIGHT_COLOR.b > GlacierValleyVisualSpec.CAVE_LIGHT_COLOR.r, "cave light is cyan/cold")
	_assert_true(_luminance(GlacierValleyVisualSpec.SKY_HORIZON_COLOR) > _luminance(GlacierValleyVisualSpec.SKY_TOP_COLOR), "sky has a readable horizon gradient")
	_assert_true(_luminance(GlacierValleyVisualSpec.SNOW_SURFACE_COLOR) > _luminance(GlacierValleyVisualSpec.ROCK_SURFACE_COLOR) + 0.45, "snow and rock values are strongly separated")
	_assert_true(GlacierValleyVisualSpec.ICE_SURFACE_COLOR.b > GlacierValleyVisualSpec.ICE_SURFACE_COLOR.r, "ice stays cool/cyan")
	_assert_true(_luminance(GlacierValleyVisualSpec.POWDER_COLOR) > 0.92, "packable powder remains a bright readability anchor")

	var team_a_lights := GlacierValleyVisualSpec.outpost_light_positions(config, 1.0)
	var team_b_lights := GlacierValleyVisualSpec.outpost_light_positions(config, -1.0)
	_assert_equal(team_a_lights.size(), team_b_lights.size(), "outpost light count is symmetrical")
	for index in range(team_a_lights.size()):
		_assert_near(team_a_lights[index].x, team_b_lights[index].x, 0.001, "outpost light x symmetry")
		_assert_near(team_a_lights[index].z, -team_b_lights[index].z, 0.001, "outpost light z symmetry")

	var cave_lights := GlacierValleyVisualSpec.cave_light_positions(config)
	_assert_true(cave_lights.size() >= 3, "cave has multiple lighting anchors")
	for position in cave_lights:
		_assert_near(position.x, config.cave_center_x, 0.001, "cave light remains inside cave lane")
		_assert_true(absf(position.z) <= config.cave_half_length, "cave light remains within cave length")

	var mounds := GlacierValleyVisualSpec.snow_mound_offsets()
	_assert_true(mounds.size() >= 6, "snow source has readable powder breakup")
	for offset in mounds:
		_assert_true(absf(offset.x) <= 2.0 and absf(offset.z) <= 2.0, "snow mound remains inside source footprint")
		_assert_true(offset.y >= 0.0 and offset.y <= 0.3, "snow mound stays close to source surface")

	var arch := GlacierValleyVisualSpec.arch_spires()
	_assert_equal(arch.size(), 3, "arch silhouette uses restrained spire count")
	_assert_true(float(arch[1]["height"]) > float(arch[0]["height"]), "arch center remains dominant")
	_assert_true(float(arch[1]["height"]) > float(arch[2]["height"]), "arch center remains dominant over east")

	var backdrop := GlacierValleyVisualSpec.backdrop_spires(config)
	_assert_true(backdrop.size() >= 6, "backdrop frames both ends of valley")
	for spire in backdrop:
		var position := Vector3(spire["position"])
		_assert_true(absf(position.x) > config.playable_half_width or absf(position.z) > config.playable_half_length, "backdrop remains outside competitive footprint")

	var wall_shards := GlacierValleyVisualSpec.wall_ice_shards(config)
	_assert_true(wall_shards.size() >= 6, "side walls receive enough silhouette breakup")
	for shard in wall_shards:
		var shard_position := Vector3(shard["position"])
		_assert_true(absf(shard_position.x) > config.playable_half_width, "wall visual shards stay outside competitive footprint")

	var glints := GlacierValleyVisualSpec.river_glint_positions(config)
	_assert_true(glints.size() >= 5, "river gets repeated glossy crack accents")
	for glint in glints:
		var glint_position := Vector3(glint["position"])
		_assert_true(absf(glint_position.x) < config.river_half_width, "river glint remains inside fast-ice lane")

	print("SNOWDOWN_GLACIER_VISUAL_SPEC_OK")
	quit(0)

func _luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)

func _assert_near(actual: float, expected: float, tolerance: float, label: String) -> void:
	if absf(actual - expected) > tolerance:
		push_error("%s expected=%.4f actual=%.4f" % [label, expected, actual])
		quit(1)
