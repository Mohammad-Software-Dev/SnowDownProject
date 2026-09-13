class_name SessionMenu
extends CanvasLayer

signal host_requested(port: int)
signal join_requested(host: String, port: int)
signal offline_requested
signal quit_requested

@onready var address_edit: LineEdit = $Backdrop/Center/Panel/Margin/Content/JoinAddress
@onready var host_port: SpinBox = $Backdrop/Center/Panel/Margin/Content/HostRow/HostPort
@onready var status_label: Label = $Backdrop/Center/Panel/Margin/Content/Status
@onready var host_button: Button = $Backdrop/Center/Panel/Margin/Content/HostRow/HostButton
@onready var join_button: Button = $Backdrop/Center/Panel/Margin/Content/JoinButton
@onready var offline_button: Button = $Backdrop/Center/Panel/Margin/Content/OfflineButton
@onready var quit_button: Button = $Backdrop/Center/Panel/Margin/Content/QuitButton

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	offline_button.pressed.connect(func() -> void: offline_requested.emit())
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	address_edit.text_submitted.connect(func(_value: String) -> void: _on_join_pressed())
	address_edit.grab_focus()

func show_status(message: String, is_error: bool = false) -> void:
	status_label.text = message
	status_label.modulate = Color(1.0, 0.55, 0.55) if is_error else Color(0.78, 0.9, 1.0)

func set_busy(busy: bool) -> void:
	host_button.disabled = busy
	join_button.disabled = busy
	offline_button.disabled = busy
	address_edit.editable = not busy
	host_port.editable = not busy

func _on_host_pressed() -> void:
	var port := int(host_port.value)
	if port < SessionAddress.MIN_PORT or port > SessionAddress.MAX_PORT:
		show_status("Choose a port between %d and %d." % [SessionAddress.MIN_PORT, SessionAddress.MAX_PORT], true)
		return
	host_requested.emit(port)

func _on_join_pressed() -> void:
	var parsed := SessionAddress.parse(address_edit.text, int(host_port.value))
	if not bool(parsed["valid"]):
		show_status(String(parsed["error"]), true)
		return
	join_requested.emit(String(parsed["host"]), int(parsed["port"]))
