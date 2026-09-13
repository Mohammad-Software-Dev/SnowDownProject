class_name RealisticMaterialFactory
extends RefCounted

const TEXTURE_SIZE := 256

static func snow_surface() -> StandardMaterial3D:
	return _natural_material(
		Color(0.79, 0.86, 0.91, 1.0),
		Color(0.985, 0.995, 1.0, 1.0),
		0.88,
		0.10,
		0.22,
		101,
		0.055
	)

static func packed_snow_surface() -> StandardMaterial3D:
	return _natural_material(
		Color(0.66, 0.76, 0.83, 1.0),
		Color(0.91, 0.96, 0.985, 1.0),
		0.72,
		0.16,
		0.34,
		137,
		0.075
	)

static func powder_surface() -> StandardMaterial3D:
	return _natural_material(
		Color(0.86, 0.92, 0.96, 1.0),
		Color(1.0, 1.0, 1.0, 1.0),
		0.94,
		0.08,
		0.18,
		173,
		0.065
	)

static func ice_surface(deep: bool = false) -> StandardMaterial3D:
	var material := _natural_material(
		Color(0.035, 0.20, 0.30, 1.0) if deep else Color(0.16, 0.48, 0.62, 1.0),
		Color(0.22, 0.64, 0.76, 1.0) if deep else Color(0.58, 0.86, 0.93, 1.0),
		0.22 if deep else 0.14,
		0.22,
		0.52,
		211 if deep else 197,
		0.045 if deep else 0.060
	)
	material.clearcoat_enabled = true
	material.clearcoat = 0.72 if deep else 0.88
	material.clearcoat_roughness = 0.16 if deep else 0.10
	material.rim_enabled = true
	material.rim = 0.22 if deep else 0.34
	material.rim_tint = 0.68
	return material

static func rock_surface() -> StandardMaterial3D:
	return _natural_material(
		Color(0.075, 0.09, 0.105, 1.0),
		Color(0.27, 0.30, 0.32, 1.0),
		0.84,
		0.28,
		0.74,
		307,
		0.050
	)

static func weathered_wood_surface() -> StandardMaterial3D:
	return _natural_material(
		Color(0.12, 0.075, 0.045, 1.0),
		Color(0.39, 0.25, 0.15, 1.0),
		0.76,
		0.18,
		0.42,
		353,
		0.070
	)

static func dark_metal_surface() -> StandardMaterial3D:
	var material := _natural_material(
		Color(0.035, 0.045, 0.052, 1.0),
		Color(0.12, 0.14, 0.15, 1.0),
		0.46,
		0.20,
		0.38,
		401,
		0.10
	)
	material.metallic = 0.72
	return material

static func team_structure_surface(color: Color) -> StandardMaterial3D:
	var material := fabric_surface(color.darkened(0.12), 0.58)
	material.metallic = 0.03
	return material

static func fabric_surface(color: Color, roughness: float = 0.80) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.normal_enabled = true
	material.normal_texture = _normal_noise(463, 0.22, 4, 2.8)
	material.normal_scale = 0.16
	material.uv1_triplanar = true
	material.uv1_world_triplanar = false
	material.uv1_scale = Vector3(6.0, 6.0, 6.0)
	return material

static func glove_surface(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.69
	material.metallic = 0.015
	material.normal_enabled = true
	material.normal_texture = _normal_noise(509, 0.30, 4, 3.6)
	material.normal_scale = 0.22
	material.uv1_triplanar = true
	material.uv1_scale = Vector3(8.0, 8.0, 8.0)
	return material

static func snowball_surface() -> StandardMaterial3D:
	var material := _natural_material(
		Color(0.78, 0.86, 0.91, 1.0),
		Color(0.99, 1.0, 1.0, 1.0),
		0.92,
		0.20,
		0.48,
		557,
		0.18
	)
	material.uv1_world_triplanar = false
	material.uv1_scale = Vector3(7.0, 7.0, 7.0)
	return material

static func _natural_material(
	low_color: Color,
	high_color: Color,
	roughness: float,
	macro_frequency: float,
	normal_strength: float,
	seed: int,
	texture_scale: float
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.albedo_texture = _color_noise(seed, macro_frequency, 4, low_color, high_color)
	material.roughness = roughness
	material.normal_enabled = true
	material.normal_texture = _normal_noise(seed + 29, macro_frequency * 3.4, 5, 3.2)
	material.normal_scale = normal_strength
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_triplanar_sharpness = 5.5
	material.uv1_scale = Vector3(texture_scale, texture_scale, texture_scale)
	return material

static func _color_noise(
	seed: int,
	frequency: float,
	octaves: int,
	low_color: Color,
	high_color: Color
) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.fractal_gain = 0.48
	noise.fractal_lacunarity = 2.05

	var gradient := Gradient.new()
	gradient.set_color(0, low_color)
	gradient.set_color(1, high_color)
	gradient.add_point(0.42, low_color.lerp(high_color, 0.42))
	gradient.add_point(0.72, low_color.lerp(high_color, 0.74))

	var texture := NoiseTexture2D.new()
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	texture.generate_mipmaps = true
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = gradient
	return texture

static func _normal_noise(seed: int, frequency: float, octaves: int, bump_strength: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.fractal_gain = 0.52
	noise.fractal_lacunarity = 2.15

	var texture := NoiseTexture2D.new()
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	texture.generate_mipmaps = true
	texture.seamless = true
	texture.noise = noise
	texture.as_normal_map = true
	texture.bump_strength = bump_strength
	return texture
