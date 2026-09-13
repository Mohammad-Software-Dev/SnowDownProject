class_name PauseMenu
extends CanvasLayer

signal return_to_menu_requested

var resume_button: Button
var return_button: Button
var mouse_slider: HSlider
var controller_slider: HSlider
var render_scale_slider: HSlider
var vsync_toggle: CheckButton
var mouse_value_label: Label
var controller_value_label: Label
var render_scale_value_label: Label
var mode_label: Label

var _input_snapshot: Dictionary = {}
var _open: bool = false
var _paused_offline_tree: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	_restore_runtime_state(false)

func toggle() -> void:
	if _open:
		close_menu()
	else:
		open_menu()

func open_menu() -> void:
	if _open:
		return
	_open = true
	_input_snapshot = GameplayInputGate.suppress()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_offline_tree = not App.is_network_runtime()
	if _paused_offline_tree:
		get_tree().paused = true
	mode_label.text = "NETWORK SESSION CONTINUES" if App.is_network_runtime() else "OFFLINE PRACTICE PAUSED"
	_sync_setting_controls()
	visible = true
	resume_button.grab_focus()

func close_menu() -> void:
	if not _open:
		return
	_restore_runtime_state(true)

func is_open() -> bool:
	return _open

func _restore_runtime_state(capture_mouse: bool) -> void:
	if _paused_offline_tree and get_tree() != null:
		get_tree().paused = false
	_paused_offline_tree = false
	if not _input_snapshot.is_empty():
		GameplayInputGate.restore(_input_snapshot)
		_input_snapshot.clear()
	_open = false
	visible = false
	if capture_mouse and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_return_to_menu() -> void:
	_restore_runtime_state(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return_to_menu_requested.emit()

func _sync_setting_controls() -> void:
	var config := GameConfig.player_movement
	mouse_slider.set_value_no_signal(config.mouse_sensitivity)
	controller_slider.set_value_no_signal(config.controller_look_radians_per_second)
	render_scale_slider.set_value_no_signal(get_viewport().scaling_3d_scale)
	vsync_toggle.set_pressed_no_signal(DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED)
	_update_mouse_value(config.mouse_sensitivity)
	_update_controller_value(config.controller_look_radians_per_second)
	_update_render_scale_value(get_viewport().scaling_3d_scale)

func _on_mouse_sensitivity_changed(value: float) -> void:
	GameConfig.player_movement.mouse_sensitivity = clampf(value, mouse_slider.min_value, mouse_slider.max_value)
	_update_mouse_value(GameConfig.player_movement.mouse_sensitivity)

func _on_controller_sensitivity_changed(value: float) -> void:
	GameConfig.player_movement.controller_look_radians_per_second = clampf(value, controller_slider.min_value, controller_slider.max_value)
	_update_controller_value(GameConfig.player_movement.controller_look_radians_per_second)

func _on_render_scale_changed(value: float) -> void:
	var scale := clampf(value, render_scale_slider.min_value, render_scale_slider.max_value)
	get_viewport().scaling_3d_scale = scale
	_update_render_scale_value(scale)

func _on_vsync_toggled(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED)

func _update_mouse_value(value: float) -> void:
	mouse_value_label.text = "%.1f mrad / pixel" % (value * 1000.0)

func _update_controller_value(value: float) -> void:
	controller_value_label.text = "%d° / sec" % int(round(rad_to_deg(value)))

func _update_render_scale_value(value: float) -> void:
	render_scale_value_label.text = "%d%% 3D resolution" % int(round(value * 100.0))

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.03, 0.05, 0.78)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.10, 0.15, 0.98)
	panel_style.border_color = Color(0.30, 0.54, 0.70, 0.85)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	content.add_child(title)

	mode_label = Label.new()
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.modulate = Color(0.72, 0.88, 1.0)
	content.add_child(mode_label)

	content.add_child(_separator())
	content.add_child(_setting_label("MOUSE LOOK SENSITIVITY"))
	mouse_slider = HSlider.new()
	mouse_slider.min_value = 0.0006
	mouse_slider.max_value = 0.0040
	mouse_slider.step = 0.0001
	mouse_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	content.add_child(mouse_slider)
	mouse_value_label = Label.new()
	mouse_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(mouse_value_label)

	content.add_child(_setting_label("CONTROLLER LOOK SENSITIVITY"))
	controller_slider = HSlider.new()
	controller_slider.min_value = 1.2
	controller_slider.max_value = 5.0
	controller_slider.step = 0.05
	controller_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controller_slider.value_changed.connect(_on_controller_sensitivity_changed)
	content.add_child(controller_slider)
	controller_value_label = Label.new()
	controller_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(controller_value_label)

	content.add_child(_separator())
	content.add_child(_setting_label("3D RENDER SCALE"))
	render_scale_slider = HSlider.new()
	render_scale_slider.min_value = 0.60
	render_scale_slider.max_value = 1.00
	render_scale_slider.step = 0.05
	render_scale_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	render_scale_slider.value_changed.connect(_on_render_scale_changed)
	content.add_child(render_scale_slider)
	render_scale_value_label = Label.new()
	render_scale_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(render_scale_value_label)

	vsync_toggle = CheckButton.new()
	vsync_toggle.text = "VSync"
	vsync_toggle.toggled.connect(_on_vsync_toggled)
	content.add_child(vsync_toggle)

	content.add_child(_separator())
	resume_button = Button.new()
	resume_button.text = "RESUME"
	resume_button.pressed.connect(close_menu)
	content.add_child(resume_button)

	return_button = Button.new()
	return_button.text = "RETURN TO SESSION MENU"
	return_button.pressed.connect(_on_return_to_menu)
	content.add_child(return_button)

	var hint := Label.new()
	hint.text = "Esc / Menu resumes • network matches are not server-paused"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(0.62, 0.72, 0.80)
	content.add_child(hint)

func _setting_label(text_value: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 13)
	return label

func _separator() -> HSeparator:
	var separator := HSeparator.new()
	separator.custom_minimum_size.y = 8.0
	return separator
