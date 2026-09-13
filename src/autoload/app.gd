extends Node

const DEFAULT_SCENARIO := "test_arena_origin"
const DEFAULT_WORLD := "test_arena"
const INPUT_DEFAULTS := preload("res://src/bootstrap/input_defaults.gd")

var runtime_role: StringName = &"client"
var active_world: StringName = DEFAULT_WORLD
var active_scenario: StringName = DEFAULT_SCENARIO
var launch_arguments: PackedStringArray = []

func configure_from_command_line(arguments: PackedStringArray) -> void:
	INPUT_DEFAULTS.install_if_missing()
	launch_arguments = arguments
	runtime_role = &"server" if arguments.has("--server") else &"client"
	active_world = _read_named_argument(arguments, "--world", DEFAULT_WORLD)
	active_scenario = _read_named_argument(arguments, "--scenario", DEFAULT_SCENARIO)

	if String(active_scenario).begins_with("map01_"):
		active_world = &"glacier_valley"
	elif active_world == &"glacier_valley" and active_scenario == StringName(DEFAULT_SCENARIO):
		active_scenario = &"map01_spawn_team_a"

	print("[Snowdown] role=%s world=%s scenario=%s" % [runtime_role, active_world, active_scenario])

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
