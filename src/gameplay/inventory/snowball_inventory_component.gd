class_name SnowballInventoryComponent
extends Node

signal inventory_changed(current: int, capacity: int)

var current: int = 0

func capacity() -> int:
	return GameConfig.snowball.inventory_capacity

func is_full() -> bool:
	return current >= capacity()

func has_snowball() -> bool:
	return current > 0

func try_add(amount: int = 1) -> bool:
	if amount <= 0 or is_full():
		return false
	var previous := current
	current = mini(capacity(), current + amount)
	if current != previous:
		inventory_changed.emit(current, capacity())
	return current != previous

func try_consume(amount: int = 1) -> bool:
	if amount <= 0 or current < amount:
		return false
	current -= amount
	inventory_changed.emit(current, capacity())
	return true

func reset(value: int = 0) -> void:
	current = clampi(value, 0, capacity())
	inventory_changed.emit(current, capacity())
