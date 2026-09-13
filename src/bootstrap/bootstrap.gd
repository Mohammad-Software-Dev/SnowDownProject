extends Node

const TEST_ARENA := preload("res://scenes/world/test_arena.tscn")
const GLACIER_VALLEY := preload("res://scenes/world/glacier_valley.tscn")
const NETWORK_SESSION := preload("res://scenes/network/network_session.tscn")
const DEBUG_OVERLAY := preload("res://scenes/ui/debug_overlay.tscn")
const PROTOTYPE_HUD := preload("res://scenes/ui/prototype_hud.tscn")
const SESSION_MENU := preload("res://scenes/ui/session_menu.tscn")

var _host_process := LocalHostProcess.new()
var _menu: SessionMenu
var _network_session: NetworkSession
var _pause_menu: PauseMenu
var _runtime_nodes: Array[Node] = []
var _runtime_started: bool = false
var _recovery_in_progress: bool = false
var _last_session_kind: StringName = &""
var _last_host: String = ""
var _last_port: int = App.DEFAULT_NETWORK_PORT

func _ready() -> void:
	App.configure_from_command_line(OS.get_cmdline_user_args())
	if _should_show_session_menu():
		_show_session_menu()
	else:
		_start_configured_runtime()

func _process(_delta: float) -> void:
	if _recovery_in_progress or _network_session == null or not is_instance_valid(_network_session):
		return
	if DisplayServer.get_name() == "headless" or not App.network_smoke_name.is_empty():
		return
	if _network_session.state == SessionRecovery.STATE_CONNECTION_FAILED or _network_session.state == SessionRecovery.STATE_SERVER_DISCONNECTED:
		_recovery_in_progress = true
		call_deferred("_recover_from_network_failure", _network_session.state)

func _exit_tree() -> void:
	_host_process.stop()

func _should_show_session_menu() -> bool:
	return DisplayServer.get_name() != "headless" and not App.has_explicit_launch_arguments()

func _show_session_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _menu != null and is_instance_valid(_menu):
		return
	_menu = SESSION_MENU.instantiate() as SessionMenu
	add_child(_menu)
	_menu.host_requested.connect(_on_host_requested)
	_menu.join_requested.connect(_on_join_requested)
	_menu.offline_requested.connect(_on_offline_requested)
	_menu.recovery_retry_requested.connect(_on_recovery_retry_requested)
	_menu.return_to_menu_requested.connect(_on_return_to_menu_requested)
	_menu.quit_requested.connect(func() -> void: get_tree().quit(0))

func _start_configured_runtime() -> void:
	if _runtime_started:
		return
	_runtime_started = true
	_recovery_in_progress = false
	if _menu != null:
		_menu.queue_free()
		_menu = null

	var world_scene: PackedScene = GLACIER_VALLEY if App.active_world == &"glacier_valley" else TEST_ARENA
	_add_runtime_node(world_scene.instantiate())

	if App.is_network_runtime():
		_network_session = NETWORK_SESSION.instantiate() as NetworkSession
		_add_runtime_node(_network_session)

	if not App.is_server_runtime():
		_add_runtime_node(ControllerLookBridge.new())
		_add_runtime_node(PROTOTYPE_HUD.instantiate())
		_add_runtime_node(FirstPersonArmsPresenter.new())
		_add_runtime_node(DEBUG_OVERLAY.instantiate())
		if DisplayServer.get_name() != "headless":
			_pause_menu = PauseMenu.new()
			_pause_menu.return_to_menu_requested.connect(_on_pause_return_to_menu_requested)
			_add_runtime_node(_pause_menu)

func _add_runtime_node(node: Node) -> void:
	add_child(node)
	_runtime_nodes.append(node)

func _teardown_runtime() -> void:
	_runtime_started = false
	_network_session = null
	if _pause_menu != null and is_instance_valid(_pause_menu) and _pause_menu.is_open():
		_pause_menu.close_menu()
	_pause_menu = null
	get_tree().paused = false
	_host_process.stop()
	for node in _runtime_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_runtime_nodes.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _recover_from_network_failure(failure_state: StringName) -> void:
	var endpoint := SessionAddress.format_endpoint(_last_host, _last_port)
	var recovery := SessionRecovery.describe(failure_state, _last_session_kind, endpoint)
	_teardown_runtime()
	App.configure_for_menu()
	_show_session_menu()
	_menu.show_standard("", endpoint)
	_menu.show_recovery(
		String(recovery["title"]),
		String(recovery["message"]),
		String(recovery["retry_label"]),
		bool(recovery["can_retry"])
	)

func _on_host_requested(port: int) -> void:
	if _menu == null:
		return
	_last_session_kind = SessionRecovery.KIND_HOST
	_last_host = "127.0.0.1"
	_last_port = port
	_menu.set_busy(true)
	_menu.show_status("Starting authoritative server on UDP %d…" % port)
	var error := _host_process.start(port)
	if error != OK:
		_menu.set_busy(false)
		_menu.show_status("Could not start the local server: %s" % error_string(error), true)
		return
	# The server is the same project in headless authoritative mode. A short startup grace
	# keeps the client from racing Godot project initialization on slower machines.
	await get_tree().create_timer(0.75).timeout
	if not _host_process.is_running():
		_menu.set_busy(false)
		_menu.show_status("The local server exited during startup.", true)
		return
	App.configure_for_join(_last_host, port)
	_start_configured_runtime()

func _on_join_requested(host: String, port: int) -> void:
	_last_session_kind = SessionRecovery.KIND_JOIN
	_last_host = host.strip_edges()
	_last_port = port
	App.configure_for_join(_last_host, port)
	_start_configured_runtime()

func _on_offline_requested() -> void:
	_last_session_kind = &""
	_last_host = ""
	_last_port = App.DEFAULT_NETWORK_PORT
	App.configure_for_offline_glacier_valley()
	_start_configured_runtime()

func _on_recovery_retry_requested() -> void:
	if _menu == null:
		return
	var endpoint := SessionAddress.format_endpoint(_last_host, _last_port)
	_menu.show_standard("Retrying %s…" % endpoint, endpoint)
	if _last_session_kind == SessionRecovery.KIND_HOST:
		_on_host_requested(_last_port)
	elif _last_session_kind == SessionRecovery.KIND_JOIN:
		_on_join_requested(_last_host, _last_port)

func _on_return_to_menu_requested() -> void:
	_last_session_kind = &""
	_last_host = ""
	_last_port = App.DEFAULT_NETWORK_PORT
	_recovery_in_progress = false
	App.configure_for_menu()

func _on_pause_return_to_menu_requested() -> void:
	_teardown_runtime()
	_last_session_kind = &""
	_last_host = ""
	_last_port = App.DEFAULT_NETWORK_PORT
	_recovery_in_progress = false
	App.configure_for_menu()
	_show_session_menu()
