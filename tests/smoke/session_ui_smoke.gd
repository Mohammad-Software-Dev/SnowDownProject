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

	menu.show_standard("", "192.0.2.10:7000")
	_assert_equal(menu.address_edit.text, "192.0.2.10:7000", "standard mode can preserve retry endpoint")
	menu.show_recovery("CONNECTION LOST", "Server disconnected.", "RETRY CONNECTION", true)
	_assert_true(not menu.normal_controls.visible and menu.recovery_controls.visible, "recovery mode replaces normal controls")
	_assert_equal(menu.recovery_title.text, "CONNECTION LOST", "recovery title")
	_assert_equal(menu.retry_button.text, "RETRY CONNECTION", "recovery retry label")
	_assert_true(not menu.retry_button.disabled, "retry remains actionable")
	menu.show_standard("READY AGAIN")
	_assert_true(menu.normal_controls.visible and not menu.recovery_controls.visible, "return restores normal controls")
	_assert_equal(menu.status_label.text, "READY AGAIN", "return status")

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
