class_name LocalHostProcess
extends RefCounted

var pid: int = 0

func start(port: int) -> Error:
	stop()
	var executable: String = OS.get_executable_path()
	var arguments: PackedStringArray = build_arguments(port)
	pid = OS.create_process(executable, arguments, false)
	if pid <= 0:
		pid = 0
		return ERR_CANT_FORK
	return OK

func stop() -> void:
	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)
	pid = 0

func is_running() -> bool:
	return pid > 0 and OS.is_process_running(pid)

static func build_arguments(port: int) -> PackedStringArray:
	var arguments := PackedStringArray()
	arguments.append("--headless")
	if not OS.has_feature("standalone"):
		arguments.append("--path")
		arguments.append(ProjectSettings.globalize_path("res://"))
	arguments.append("--")
	arguments.append("--server")
	arguments.append("--world=glacier_valley")
	arguments.append("--scenario=map01_spawn_team_a")
	arguments.append("--port=%d" % port)
	return arguments
