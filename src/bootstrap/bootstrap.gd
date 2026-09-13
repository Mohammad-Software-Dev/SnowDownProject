extends Node

const TEST_ARENA := preload("res://scenes/world/test_arena.tscn")
const DEBUG_OVERLAY := preload("res://scenes/ui/debug_overlay.tscn")

func _ready() -> void:
	App.configure_from_command_line(OS.get_cmdline_user_args())
	var arena := TEST_ARENA.instantiate()
	add_child(arena)

	if not App.is_server_runtime():
		var overlay := DEBUG_OVERLAY.instantiate()
		add_child(overlay)
	else:
		print("[Snowdown] Server runtime foundation active; networking will be introduced in the network milestone.")
