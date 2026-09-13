class_name SessionMenu
extends CanvasLayer

signal host_requested(port: int)
signal join_requested(host: String, port: int)
signal offline_requested
signal quit_requested
signal recovery_retry_requested
signal return_to_menu_requested

@onready var normal_controls: VBoxContainer = $Backdrop/Center/Panel/Margin/Content/NormalControls
@onready var recovery_controls: VBoxContainer = $Backdrop/Center/Panel/Margin/Content/RecoveryControls
@onready var address_edit: LineEdit = $Backdrop/Center/Panel/Margin/Content/NormalControls/JoinAddress
@onready var host_port: SpinBox = $Backdrop/Center/Panel/Margin/Content/NormalControls/HostRow/HostPort
@onready var status_label: Label = $Backdrop/Center/Panel/Margin/Content/NormalControls/Status
@onready var host_button: Button = $Backdrop/Center/Panel/Margin/Content/NormalControls/HostRow/HostButton
@onready var join_button: Button = $Backdrop/Center/Panel/Margin/Content/NormalControls/JoinButton
@onready var offline_button: Button = $Backdrop/Center/Panel/Margin/Content/NormalControls/OfflineButton
@onready var quit_button: Button = $Backdrop/Center/Panel/Margin/Content/NormalControls/QuitButton
@onready var recovery_title: Label = $Backdrop/Center/Panel/Margin/Content/RecoveryControls/RecoveryTitle
@onready var recovery_message: Label = $Backdrop/Center/Panel/Margin/Content/RecoveryControls/RecoveryMessage
@onready var retry_button: Button = $Backdrop/Center/Panel/Margin/Content/RecoveryControls/RecoveryButtons/RetryButton
@onready var return_button: Button = $Backdrop/Center/Panel/Margin/Content/RecoveryControls/RecoveryButtons/ReturnButton

func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	offline_button.pressed.connect(func() -> void: offline_requested.emit())
	quit_button.pressed.connect(func() -> void: quit_requested.emit())
	retry_button.pressed.connect(func() -> void: recovery_retry_requested.emit())
	return_button.pressed.connect(_on_return_to_menu_pressed)
	address_edit.text_submitted.connect(func(_value: String) -> void: _on_join_pressed())
	show_standard()

func show_standard(message: String = "", join_endpoint: String = "") -> void:
	normal_controls.visible = true
	recovery_controls.visible = false
	set_busy(false)
	if not join_endpoint.is_empty():
		address_edit.text = join_endpoint
	if not message.is_empty():
		show_status(message)
	address_edit.grab_focus()

func show_recovery(title: String, message: String, retry_label: String, can_retry: bool = true) -> void:
	normal_controls.visible = false
	recovery_controls.visible = true
	recovery_title.text = title
	recovery_message.text = message
	retry_button.text = retry_label
	retry_button.disabled = not can_retry
	if can_retry:
		retry_button.grab_focus()
	else:
		return_button.grab_focus()

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

func _on_return_to_menu_pressed() -> void:
	show_standard("Ready for another match.")
	return_to_menu_requested.emit()
