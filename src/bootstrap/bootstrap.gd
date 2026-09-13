extends Node

const TEST_ARENA := preload("res://scenes/world/test_arena.tscn")
const GLACIER_VALLEY := preload("res://scenes/world/glacier_valley.tscn")
const NETWORK_SESSION := preload("res://scenes/network/network_session.tscn")
const DEBUG_OVERLAY := preload("res://scenes/ui/debug_overlay.tscn")
const PROTOTYPE_HUD := preload("res://scenes/ui/prototype_hud.tscn")
const SESSION_MENU := preload("res://scenes/ui/session_menu.tscn")

var _host_process := LocalHostProcess.new()
var _menu: SessionMenu
var _runtime_started: bool = false

func _ready() -> void:
	App.configure_from_command_line(OS.get_cmdline_user_args())
	if _should_show_session_menu():
		_show_session_menu()
	else:
		_start_configured_runtime()

func _exit_tree() -> void:
	_host_process.stop()

func _should_show_session_menu() -> bool:
	return DisplayServer.get_name() != "headless" and not App.has_explicit_launch_arguments()

func _show_session_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_menu = SESSION_MENU.instantiate() as SessionMenu
	add_child(_menu)
	_menu.host_requested.connect(_on_host_requested)
	_menu.join_requested.connect(_on_join_requested)
	_menu.offline_requested.connect(_on_offline_requested)
	_menu.quit_requested.connect(func() -> void: get_tree().quit(0))

func _start_configured_runtime() -> void:
	if _runtime_started:
		return
	_runtime_started = true
	if _menu != null:
		_menu.queue_free()
		_menu = null

	var world_scene: PackedScene = GLACIER_VALLEY if App.active_world == &"glacier_valley" else TEST_ARENA
	add_child(world_scene.instantiate())

	if App.is_network_runtime():
		add_child(NETWORK_SESSION.instantiate())

	if not App.is_server_runtime():
		add_child(PROTOTYPE_HUD.instantiate())
		add_child(FirstPersonArmsPresenter.new())
		add_child(DEBUG_OVERLAY.instantiate())

func _on_host_requested(port: int) -> void:
	if _menu == null:
		return
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
	App.configure_for_join("127.0.0.1", port)
	_start_configured_runtime()

func _on_join_requested(host: String, port: int) -> void:
	App.configure_for_join(host, port)
	_start_configured_runtime()

func _on_offline_requested() -> void:
	App.configure_for_offline_glacier_valley()
	_start_configured_runtime()
