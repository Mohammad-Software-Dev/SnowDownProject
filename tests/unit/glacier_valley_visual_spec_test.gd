extends SceneTree

func _init() -> void:
	var config := GlacierValleyConfig.new()

	_assert_true(GlacierValleyVisualSpec.WARM_LIGHT_COLOR.r > GlacierValleyVisualSpec.WARM_LIGHT_COLOR.b, "outpost light is warm")
	_assert_true(GlacierValleyVisualSpec.CAVE_LIGHT_COLOR.b > GlacierValleyVisualSpec.CAVE_LIGHT_COLOR.r, "cave light is cyan/cold")

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

	print("SNOWDOWN_GLACIER_VISUAL_SPEC_OK")
	quit(0)

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
