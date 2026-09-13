extends Node

const DEFAULT_SCENARIO := "test_arena_origin"
const INPUT_DEFAULTS := preload("res://src/bootstrap/input_defaults.gd")

var runtime_role: StringName = &"client"
var active_scenario: StringName = DEFAULT_SCENARIO
var launch_arguments: PackedStringArray = []

func configure_from_command_line(arguments: PackedStringArray) -> void:
	INPUT_DEFAULTS.install_if_missing()
	launch_arguments = arguments
	runtime_role = &"server" if arguments.has("--server") else &"client"
	active_scenario = _read_named_argument(arguments, "--scenario", DEFAULT_SCENARIO)
	print("[Snowdown] role=%s scenario=%s" % [runtime_role, active_scenario])

func is_server_runtime() -> bool:
	return runtime_role == &"server"

func _read_named_argument(arguments: PackedStringArray, key: String, fallback: String) -> StringName:
	for index in range(arguments.size()):
		var value := arguments[index]
		if value.begins_with(key + "="):
			return StringName(value.trim_prefix(key + "="))
		if value == key and index + 1 < arguments.size():
			return StringName(arguments[index + 1])
	return StringName(fallback)
