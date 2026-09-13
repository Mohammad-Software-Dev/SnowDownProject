class_name SnowballActionComponent
extends Node

signal throw_requested(normalized_charge: float)
signal action_state_changed(state: StringName)
signal snowball_packed

const HANDS_FREE := &"hands_free"
const PACKING := &"packing"
const THROW_CHARGING := &"throw_charging"
const THROW_RECOVERING := &"throw_recovering"

var state: StringName = HANDS_FREE
var pack_progress: float = 0.0
var charge_seconds: float = 0.0
var recovery_remaining: float = 0.0
var _inventory: SnowballInventoryComponent

func configure(inventory: SnowballInventoryComponent) -> void:
	_inventory = inventory

func simulate(command: PlayerInputCommand, delta: float, can_pack_here: bool, sliding: bool) -> void:
	assert(_inventory != null, "SnowballActionComponent requires an inventory")
	match state:
		HANDS_FREE:
			_simulate_hands_free(command, can_pack_here, sliding)
		PACKING:
			_simulate_packing(command, delta, can_pack_here, sliding)
		THROW_CHARGING:
			_simulate_charging(command, delta)
		THROW_RECOVERING:
			_simulate_recovery(delta)

func movement_multiplier() -> float:
	return GameConfig.snowball.pack_movement_multiplier if state == PACKING else 1.0

func normalized_charge() -> float:
	return clampf(charge_seconds / GameConfig.snowball.maximum_charge_seconds, 0.0, 1.0)

func reset() -> void:
	pack_progress = 0.0
	charge_seconds = 0.0
	recovery_remaining = 0.0
	_set_state(HANDS_FREE)

func _simulate_hands_free(command: PlayerInputCommand, can_pack_here: bool, sliding: bool) -> void:
	if command.pack_held and can_pack_here and not sliding and not _inventory.is_full():
		pack_progress = 0.0
		_set_state(PACKING)
		return
	if command.throw_pressed and _inventory.has_snowball():
		charge_seconds = 0.0
		_set_state(THROW_CHARGING)

func _simulate_packing(command: PlayerInputCommand, delta: float, can_pack_here: bool, sliding: bool) -> void:
	if command.jump_pressed or not command.pack_held or not can_pack_here or sliding:
		pack_progress = 0.0
		_set_state(HANDS_FREE)
		return

	pack_progress += delta
	if pack_progress < GameConfig.snowball.pack_duration_seconds:
		return

	if _inventory.try_add():
		snowball_packed.emit()
	pack_progress = 0.0
	if _inventory.is_full() or not command.pack_held:
		_set_state(HANDS_FREE)

func _simulate_charging(command: PlayerInputCommand, delta: float) -> void:
	charge_seconds = minf(charge_seconds + delta, GameConfig.snowball.maximum_charge_seconds)
	if not command.throw_released:
		return

	if charge_seconds >= GameConfig.snowball.minimum_release_seconds and _inventory.try_consume():
		throw_requested.emit(normalized_charge())
		recovery_remaining = GameConfig.snowball.throw_recovery_seconds
		_set_state(THROW_RECOVERING)
	else:
		charge_seconds = 0.0
		_set_state(HANDS_FREE)

func _simulate_recovery(delta: float) -> void:
	recovery_remaining = maxf(0.0, recovery_remaining - delta)
	if recovery_remaining <= 0.0:
		charge_seconds = 0.0
		_set_state(HANDS_FREE)

func _set_state(next_state: StringName) -> void:
	if state == next_state:
		return
	state = next_state
	action_state_changed.emit(state)
