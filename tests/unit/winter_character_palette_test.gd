extends SceneTree

func _init() -> void:
	var team_a := WinterCharacterPalette.palette(0)
	var team_b := WinterCharacterPalette.palette(1)
	var neutral := WinterCharacterPalette.palette(-1)

	_assert_true(Color(team_a["jacket"]) != Color(team_b["jacket"]), "teams use distinct jacket blocks")
	_assert_true(Color(team_a["accent"]) != Color(team_b["accent"]), "teams use distinct accent blocks")
	_assert_equal(Color(team_a["glove"]), Color(team_b["glove"]), "gloves stay materially consistent across teams")
	_assert_equal(Color(team_a["pants"]), Color(team_b["pants"]), "pants stay neutral across teams")
	_assert_equal(Color(team_a["boot"]), Color(team_b["boot"]), "boots stay neutral across teams")
	_assert_equal(Color(neutral["jacket"]), WinterCharacterPalette.NEUTRAL_JACKET, "offline character uses neutral jacket")

	_assert_true(WinterCharacterPalette.TEAM_A_JACKET.r > WinterCharacterPalette.TEAM_A_JACKET.b, "team A jacket reads warm")
	_assert_true(WinterCharacterPalette.TEAM_B_JACKET.b > WinterCharacterPalette.TEAM_B_JACKET.r, "team B jacket reads cool")
	_assert_true(WinterCharacterPalette.GLOVE.get_luminance() < 0.15, "gloves remain dark against snow")
	_assert_true(WinterCharacterPalette.PANTS.get_luminance() < 0.20, "pants preserve silhouette against snow")

	print("SNOWDOWN_WINTER_CHARACTER_PALETTE_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)
