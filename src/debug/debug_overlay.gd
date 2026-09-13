class_name DebugOverlay
extends CanvasLayer

@onready var panel: PanelContainer = $Margin/Panel
@onready var label: Label = $Margin/Panel/Padding/Label

var scenario_registry: TestScenarioRegistry

func _ready() -> void:
	visible = not App.is_server_runtime()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_overlay"):
		panel.visible = not panel.visible
	if not panel.visible:
		return

	var movement := GameConfig.player_movement
	var snowball := GameConfig.snowball
	var match_rules := GameConfig.match_rules
	label.text = "Snowdown DEV\nrole: %s\nscenario: %s\nfps: %d\n\nmovement walk/sprint: %.1f / %.1f\nsnowballs: %d capacity\nthrow speed: %.1f -> %.1f m/s\nmatch: %dv%d / %.0fs" % [
		App.runtime_role,
		App.active_scenario,
		Engine.get_frames_per_second(),
		movement.walk_speed,
		movement.sprint_speed,
		snowball.inventory_capacity,
		snowball.minimum_launch_speed,
		snowball.maximum_launch_speed,
		match_rules.team_size,
		match_rules.team_size,
		match_rules.regulation_seconds,
	]
