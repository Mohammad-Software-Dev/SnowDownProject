class_name PlayerInputCommand
extends RefCounted

var move: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var sprint_held: bool = false
var crouch_pressed: bool = false
var crouch_held: bool = false

func clear_transients() -> void:
	look_delta = Vector2.ZERO
	jump_pressed = false
	crouch_pressed = false
