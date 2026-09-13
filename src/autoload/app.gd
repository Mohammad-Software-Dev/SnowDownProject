extends Node

const DEFAULT_SCENARIO := "test_arena_origin"
const DEFAULT_WORLD := "test_arena"
const DEFAULT_NETWORK_PORT := 7000
const INPUT_DEFAULTS := preload("res://src/bootstrap/input_defaults.gd")

var runtime_role: StringName = &"client"
var active_world: StringName = DEFAULT_WORLD
var active_scenario: StringName = DEFAULT_SCENARIO
var launch_arguments: PackedStringArray = []
var connect_host: String = ""
var network_port: int = DEFAULT_NETWORK_PORT
var network_smoke_name: String = ""
var network_smoke_expected_peers: int = 0

func configure_from_command_line(arguments: PackedStringArray) -> void:
	INPUT_DEFAULTS.install_if_missing()
	launch_arguments = arguments
	runtime_role = &"server" if arguments.has("--server") else &"client"
	active_world = _read_named_argument(arguments, "--world", DEFAULT_WORLD)
	active_scenario = _read_named_argument(arguments, "--scenario", DEFAULT_SCENARIO)
	connect_host = String(_read_named_argument(arguments, "--connect", ""))
	network_port = _read_int_argument(arguments, "--port", DEFAULT_NETWORK_PORT)
	network_smoke_name = String(_read_named_argument(arguments, "--network-smoke-name", ""))
	network_smoke_expected_peers = _read_int_argument(arguments, "--network-smoke-expected", 0)

	if is_network_runtime() and active_world == StringName(DEFAULT_WORLD) and active_scenario == StringName(DEFAULT_SCENARIO):
		active_world = &"glacier_valley"
		active_scenario = &"map01_spawn_team_a"
	elif String(active_scenario).begins_with("map01_"):
		active_world = &"glacier_valley"
	elif active_world == &"glacier_valley" and active_scenario == StringName(DEFAULT_SCENARIO):
		active_scenario = &"map01_spawn_team_a"

	print("[Snowdown] role=%s world=%s scenario=%s network=%s:%d" % [runtime_role, active_world, active_scenario, connect_host if not connect_host.is_empty() else "off", network_port])

func is_server_runtime() -> bool:
	return runtime_role == &"server"

func is_network_runtime() -> bool:
	return is_server_runtime() or not connect_host.is_empty()

func _read_named_argument(arguments: PackedStringArray, key: String, fallback: String) -> StringName:
	for index in range(arguments.size()):
		var value := arguments[index]
		if value.begins_with(key + "="):
			return StringName(value.trim_prefix(key + "="))
		if value == key and index + 1 < arguments.size():
			return StringName(arguments[index + 1])
	return StringName(fallback)

func _read_int_argument(arguments: PackedStringArray, key: String, fallback: int) -> int:
	var value := String(_read_named_argument(arguments, key, str(fallback)))
	return value.to_int() if value.is_valid_int() else fallback
