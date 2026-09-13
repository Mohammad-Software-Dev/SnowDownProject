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
var network_smoke_action: StringName = &""
var network_smoke_layout: StringName = &""
var network_smoke_expected_peers: int = 0
var match_smoke_enabled: bool = false
var net_sim_latency_ms: int = 0
var net_sim_jitter_ms: int = 0
var net_sim_loss_percent: float = 0.0

func configure_from_command_line(arguments: PackedStringArray) -> void:
	INPUT_DEFAULTS.install_if_missing()
	launch_arguments = arguments
	runtime_role = &"server" if arguments.has("--server") else &"client"
	active_world = _read_named_argument(arguments, "--world", DEFAULT_WORLD)
	active_scenario = _read_named_argument(arguments, "--scenario", DEFAULT_SCENARIO)
	connect_host = String(_read_named_argument(arguments, "--connect", ""))
	network_port = _read_int_argument(arguments, "--port", DEFAULT_NETWORK_PORT)
	network_smoke_name = String(_read_named_argument(arguments, "--network-smoke-name", ""))
	network_smoke_action = _read_named_argument(arguments, "--network-smoke-action", "")
	network_smoke_layout = _read_named_argument(arguments, "--network-smoke-layout", "")
	network_smoke_expected_peers = _read_int_argument(arguments, "--network-smoke-expected", 0)
	match_smoke_enabled = arguments.has("--match-smoke")
	net_sim_latency_ms = maxi(0, _read_int_argument(arguments, "--net-sim-latency-ms", 0))
	net_sim_jitter_ms = maxi(0, _read_int_argument(arguments, "--net-sim-jitter-ms", 0))
	net_sim_loss_percent = clampf(_read_float_argument(arguments, "--net-sim-loss-percent", 0.0), 0.0, 25.0)

	if is_network_runtime() and active_world == StringName(DEFAULT_WORLD) and active_scenario == StringName(DEFAULT_SCENARIO):
		active_world = &"glacier_valley"
		active_scenario = &"map01_spawn_team_a"
	elif String(active_scenario).begins_with("map01_"):
		active_world = &"glacier_valley"
	elif active_world == &"glacier_valley" and active_scenario == StringName(DEFAULT_SCENARIO):
		active_scenario = &"map01_spawn_team_a"

	print("[Snowdown] role=%s world=%s scenario=%s network=%s:%d sim=%dms/%dms/%.1f%% match_smoke=%s" % [runtime_role, active_world, active_scenario, connect_host if not connect_host.is_empty() else "off", network_port, net_sim_latency_ms, net_sim_jitter_ms, net_sim_loss_percent, match_smoke_enabled])

func configure_for_join(host: String, port: int) -> void:
	runtime_role = &"client"
	active_world = &"glacier_valley"
	active_scenario = &"map01_spawn_team_a"
	connect_host = host.strip_edges()
	network_port = clampi(port, SessionAddress.MIN_PORT, SessionAddress.MAX_PORT)
	_reset_test_runtime_flags()
	print("[Snowdown] menu join endpoint=%s" % SessionAddress.format_endpoint(connect_host, network_port))

func configure_for_offline_glacier_valley() -> void:
	runtime_role = &"client"
	active_world = &"glacier_valley"
	active_scenario = &"map01_spawn_team_a"
	connect_host = ""
	network_port = DEFAULT_NETWORK_PORT
	_reset_test_runtime_flags()
	print("[Snowdown] menu offline practice")

func configure_for_menu() -> void:
	runtime_role = &"client"
	active_world = StringName(DEFAULT_WORLD)
	active_scenario = StringName(DEFAULT_SCENARIO)
	connect_host = ""
	network_port = DEFAULT_NETWORK_PORT
	launch_arguments = PackedStringArray()
	_reset_test_runtime_flags()
	print("[Snowdown] returned to interactive session menu")

func is_server_runtime() -> bool:
	return runtime_role == &"server"

func is_network_runtime() -> bool:
	return is_server_runtime() or not connect_host.is_empty()

func has_explicit_launch_arguments() -> bool:
	return not launch_arguments.is_empty()

func _reset_test_runtime_flags() -> void:
	network_smoke_name = ""
	network_smoke_action = &""
	network_smoke_layout = &""
	network_smoke_expected_peers = 0
	match_smoke_enabled = false
	net_sim_latency_ms = 0
	net_sim_jitter_ms = 0
	net_sim_loss_percent = 0.0

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

func _read_float_argument(arguments: PackedStringArray, key: String, fallback: float) -> float:
	var value := String(_read_named_argument(arguments, key, str(fallback)))
	return value.to_float() if value.is_valid_float() else fallback
