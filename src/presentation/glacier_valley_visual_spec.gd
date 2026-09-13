class_name GlacierValleyVisualSpec
extends RefCounted

const SKY_TOP_COLOR := Color(0.055, 0.14, 0.25, 1.0)
const SKY_HORIZON_COLOR := Color(0.58, 0.76, 0.88, 1.0)
const SKY_COLOR := SKY_HORIZON_COLOR
const GROUND_HORIZON_COLOR := Color(0.36, 0.53, 0.65, 1.0)
const GROUND_BOTTOM_COLOR := Color(0.10, 0.19, 0.27, 1.0)
const AMBIENT_COLOR := Color(0.46, 0.61, 0.74, 1.0)
const FOG_COLOR := Color(0.58, 0.72, 0.81, 1.0)
const SUN_COLOR := Color(1.0, 0.95, 0.86, 1.0)
const WARM_LIGHT_COLOR := Color(1.0, 0.53, 0.20, 1.0)
const CAVE_LIGHT_COLOR := Color(0.08, 0.66, 0.92, 1.0)
const SNOW_SURFACE_COLOR := Color(0.91, 0.955, 0.985, 1.0)
const ICE_SURFACE_COLOR := Color(0.20, 0.68, 0.84, 1.0)
const DEEP_ICE_SURFACE_COLOR := Color(0.055, 0.29, 0.45, 1.0)
const ROCK_SURFACE_COLOR := Color(0.15, 0.19, 0.23, 1.0)
const WOOD_SURFACE_COLOR := Color(0.29, 0.20, 0.14, 1.0)
const BACKDROP_ICE_COLOR := Color(0.10, 0.36, 0.55, 1.0)
const BACKDROP_SHADOW_COLOR := Color(0.045, 0.17, 0.27, 1.0)
const ARCH_ICE_COLOR := Color(0.13, 0.58, 0.78, 1.0)
const ARCH_HIGHLIGHT_COLOR := Color(0.42, 0.82, 0.94, 1.0)
const POWDER_COLOR := Color(0.96, 0.985, 1.0, 1.0)
const POWDER_SHADOW_COLOR := Color(0.75, 0.88, 0.95, 1.0)
const RIVER_GLINT_COLOR := Color(0.50, 0.92, 1.0, 1.0)

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

static func wall_ice_shards(config: GlacierValleyConfig) -> Array[Dictionary]:
	var x := config.playable_half_width + 1.4
	return [
		{"name": "WestShardNorth", "position": Vector3(-x, 13.0, 31.0), "height": 16.0, "radius": 2.5, "tilt": -7.0},
		{"name": "WestShardMid", "position": Vector3(-x, 11.0, 5.0), "height": 12.0, "radius": 2.0, "tilt": 5.0},
		{"name": "WestShardSouth", "position": Vector3(-x, 14.0, -28.0), "height": 18.0, "radius": 2.8, "tilt": -5.0},
		{"name": "EastShardNorth", "position": Vector3(x, 12.0, 27.0), "height": 14.0, "radius": 2.2, "tilt": 6.0},
		{"name": "EastShardMid", "position": Vector3(x, 13.5, -3.0), "height": 17.0, "radius": 2.4, "tilt": -6.0},
		{"name": "EastShardSouth", "position": Vector3(x, 10.5, -32.0), "height": 11.0, "radius": 1.9, "tilt": 4.0},
	]

static func snow_drift_positions(config: GlacierValleyConfig) -> Array[Vector3]:
	var x := config.playable_half_width - 3.0
	var z := config.playable_half_length - 9.0
	return [
		Vector3(-x, 0.10, 28.0), Vector3(-x, 0.10, -24.0),
		Vector3(x, 0.10, 22.0), Vector3(x, 0.10, -30.0),
		Vector3(-15.0, 0.10, z), Vector3(16.0, 0.10, z),
		Vector3(-14.0, 0.10, -z), Vector3(15.0, 0.10, -z),
	]

static func river_glint_positions(_config: GlacierValleyConfig) -> Array[Dictionary]:
	return [
		{"position": Vector3(-1.4, 0.345, 34.0), "length": 7.5, "yaw": -14.0},
		{"position": Vector3(1.1, 0.345, 20.0), "length": 5.5, "yaw": 18.0},
		{"position": Vector3(-0.8, 0.345, 5.0), "length": 8.5, "yaw": -9.0},
		{"position": Vector3(1.5, 0.345, -11.0), "length": 6.5, "yaw": 16.0},
		{"position": Vector3(-1.1, 0.345, -28.0), "length": 7.0, "yaw": -12.0},
	]
