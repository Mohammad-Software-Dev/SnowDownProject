extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu_scene := load("res://scenes/ui/session_menu.tscn") as PackedScene
	var menu := menu_scene.instantiate() as SessionMenu
	root.add_child(menu)
	await process_frame
	_assert_true(menu.address_edit != null, "session address field exists")
	_assert_true(menu.host_button != null and menu.join_button != null, "session buttons exist")
	menu.set_busy(true)
	_assert_true(menu.host_button.disabled and menu.join_button.disabled, "busy state disables network actions")
	menu.set_busy(false)
	menu.show_status("READY")
	_assert_equal(menu.status_label.text, "READY", "menu status")

	menu.queue_free()
	await process_frame
	print("SNOWDOWN_SESSION_UI_OK")
	quit(0)

func _assert_true(value: bool, label: String) -> void:
	if not value:
		push_error(label)
		quit(1)

func _assert_equal(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		push_error("%s expected=%s actual=%s" % [label, str(expected), str(actual)])
		quit(1)
