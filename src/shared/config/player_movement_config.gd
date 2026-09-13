class_name PlayerMovementConfig
extends Resource

@export_category("Ground Movement")
@export var walk_speed: float = 6.0
@export var sprint_speed: float = 9.0
@export var ground_acceleration: float = 28.0
@export var ground_deceleration: float = 34.0
@export var air_acceleration: float = 8.0
@export var air_speed_cap: float = 7.0

@export_category("Jump / Gravity")
@export var jump_velocity: float = 6.5
@export var gravity: float = 18.0
@export var jump_buffer_seconds: float = 0.10
@export var coyote_time_seconds: float = 0.08

@export_category("Crouch / Slide")
@export var crouch_speed: float = 3.5
@export var slide_entry_speed: float = 7.0
@export var slide_min_speed: float = 3.5
@export var slide_initial_boost: float = 0.75
@export var slide_friction: float = 5.0
@export var slide_max_seconds: float = 1.15

@export_category("Fast Ice Surface")
@export var ice_ground_speed_multiplier: float = 1.08
@export var ice_slide_friction_multiplier: float = 0.45

@export_category("Camera")
@export var mouse_sensitivity: float = 0.0018
@export var pitch_min_degrees: float = -85.0
@export var pitch_max_degrees: float = 85.0
