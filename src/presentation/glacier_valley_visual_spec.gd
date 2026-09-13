class_name GlacierValleyVisualSpec
extends RefCounted

const SKY_COLOR := Color(0.62, 0.78, 0.90, 1.0)
const AMBIENT_COLOR := Color(0.63, 0.75, 0.86, 1.0)
const WARM_LIGHT_COLOR := Color(1.0, 0.58, 0.24, 1.0)
const CAVE_LIGHT_COLOR := Color(0.18, 0.68, 0.92, 1.0)
const BACKDROP_ICE_COLOR := Color(0.22, 0.53, 0.72, 1.0)
const POWDER_COLOR := Color(0.96, 0.985, 1.0, 1.0)

static func outpost_light_positions(config: GlacierValleyConfig, side: float) -> Array[Vector3]:
	var spawn_z := (config.playable_half_length - config.team_spawn_inset) * side
	return [
		Vector3(-4.2, 2.5, spawn_z + 1.8 * side),
		Vector3(4.2, 2.5, spawn_z + 1.8 * side),
	]

static func cave_light_positions(config: GlacierValleyConfig) -> Array[Vector3]:
	return [
		Vector3(config.cave_center_x, 3.2, -16.0),
		Vector3(config.cave_center_x, 3.5, 0.0),
		Vector3(config.cave_center_x, 3.2, 16.0),
	]

static func snow_mound_offsets() -> Array[Vector3]:
	return [
		Vector3(-1.55, 0.16, -1.15),
		Vector3(0.10, 0.20, -1.55),
		Vector3(1.55, 0.14, -0.75),
		Vector3(-1.30, 0.12, 1.20),
		Vector3(0.45, 0.18, 1.45),
		Vector3(1.60, 0.10, 0.85),
	]

static func arch_spires() -> Array[Dictionary]:
	return [
		{"name": "ArchSpireWest", "position": Vector3(-7.2, 13.0, 0.6), "height": 6.0, "radius": 1.15},
		{"name": "ArchSpireCenter", "position": Vector3(0.0, 14.3, -0.5), "height": 7.5, "radius": 1.35},
		{"name": "ArchSpireEast", "position": Vector3(7.0, 12.8, 0.8), "height": 5.6, "radius": 1.05},
	]

static func backdrop_spires(config: GlacierValleyConfig) -> Array[Dictionary]:
	var x := config.playable_half_width
	var z := config.playable_half_length
	return [
		{"name": "BackdropNorthWest", "position": Vector3(-x - 20.0, 14.0, z + 18.0), "height": 30.0, "radius": 11.0},
		{"name": "BackdropNorth", "position": Vector3(4.0, 18.0, z + 28.0), "height": 38.0, "radius": 14.0},
		{"name": "BackdropNorthEast", "position": Vector3(x + 17.0, 13.0, z + 15.0), "height": 28.0, "radius": 10.0},
		{"name": "BackdropSouthWest", "position": Vector3(-x - 18.0, 12.0, -z - 17.0), "height": 26.0, "radius": 10.0},
		{"name": "BackdropSouth", "position": Vector3(-6.0, 16.0, -z - 27.0), "height": 34.0, "radius": 13.0},
		{"name": "BackdropSouthEast", "position": Vector3(x + 19.0, 15.0, -z - 20.0), "height": 32.0, "radius": 11.5},
	]
