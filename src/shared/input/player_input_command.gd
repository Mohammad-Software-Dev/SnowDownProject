class_name PlayerInputCommand
extends RefCounted

var move: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var sprint_held: bool = false
var crouch_pressed: bool = false
var crouch_held: bool = false
var pack_held: bool = false
var throw_pressed: bool = false
var throw_held: bool = false
var throw_released: bool = false
var catch_pressed: bool = false
