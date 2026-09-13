class_name LocalPlayerInput
extends Node

var _look_accumulator: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look_accumulator += event.relative
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func consume_command() -> PlayerInputCommand:
	var command := PlayerInputCommand.new()
	command.move = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	command.look_delta = _look_accumulator
	command.jump_pressed = Input.is_action_just_pressed("jump")
	command.sprint_held = Input.is_action_pressed("sprint")
	command.crouch_pressed = Input.is_action_just_pressed("crouch_slide")
	command.crouch_held = Input.is_action_pressed("crouch_slide")
	command.pack_held = Input.is_action_pressed("pack_interact")
	command.throw_pressed = Input.is_action_just_pressed("throw_primary")
	command.throw_held = Input.is_action_pressed("throw_primary")
	command.throw_released = Input.is_action_just_released("throw_primary")
	command.catch_pressed = Input.is_action_just_pressed("catch")
	_look_accumulator = Vector2.ZERO
	return command
