class_name WinterCharacterPalette
extends RefCounted

const TEAM_A_JACKET := Color(0.68, 0.20, 0.12, 1.0)
const TEAM_A_ACCENT := Color(0.96, 0.56, 0.24, 1.0)
const TEAM_B_JACKET := Color(0.10, 0.30, 0.61, 1.0)
const TEAM_B_ACCENT := Color(0.31, 0.68, 0.94, 1.0)
const NEUTRAL_JACKET := Color(0.16, 0.35, 0.43, 1.0)
const NEUTRAL_ACCENT := Color(0.48, 0.72, 0.76, 1.0)
const PANTS := Color(0.075, 0.095, 0.125, 1.0)
const GLOVE := Color(0.045, 0.055, 0.068, 1.0)
const BOOT := Color(0.055, 0.050, 0.050, 1.0)
const SKIN := Color(0.64, 0.47, 0.36, 1.0)
const BEANIE := Color(0.095, 0.115, 0.14, 1.0)
const SCARF := Color(0.18, 0.20, 0.22, 1.0)

static func jacket_color(team_index: int) -> Color:
	if team_index == 0:
		return TEAM_A_JACKET
	if team_index == 1:
		return TEAM_B_JACKET
	return NEUTRAL_JACKET

static func accent_color(team_index: int) -> Color:
	if team_index == 0:
		return TEAM_A_ACCENT
	if team_index == 1:
		return TEAM_B_ACCENT
	return NEUTRAL_ACCENT

static func palette(team_index: int) -> Dictionary:
	return {
		"jacket": jacket_color(team_index),
		"accent": accent_color(team_index),
		"pants": PANTS,
		"glove": GLOVE,
		"boot": BOOT,
		"skin": SKIN,
		"beanie": BEANIE,
		"scarf": SCARF,
	}
