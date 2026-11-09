extends Node

signal stats_changed

var selected_tool: StringName = "hoe"
var selected_seed: StringName = "potato"

var energy: int = 1000
var max_energy: int = 1000

var seeds: Dictionary = {"potato": 1000}
var items: Dictionary = {}   # { "wood":3, "meat":1, "fish":2, ... }

func set_tool(name: StringName) -> void:
	selected_tool = name
	stats_changed.emit()

func spend_energy(cost: int) -> bool:
	if cost <= 0: return true
	if energy < cost: return false
	energy -= cost
	stats_changed.emit()
	return true

func gain_energy(n: int) -> void:
	energy = min(max_energy, energy + n)
	stats_changed.emit()

func add_item(id: String, qty: int = 1) -> void:
	if qty <= 0: return
	items[id] = int(items.get(id, 0)) + qty
	stats_changed.emit()

func take_item(id: String, qty: int = 1) -> bool:
	if not items.has(id): return false
	items[id] = int(items.get(id, 0)) - qty
	if items[id] <= 0: items.erase(id)
	stats_changed.emit()
	return true

# convenience getters for HUD
func get_item_qty(id: String) -> int:
	return int(items.get(id, 0))

func get_tool() -> String:
	return String(selected_tool)

# seeds helpers
func add_seed(id: String, qty := 1) -> void:
	if qty <= 0: return
	seeds[id] = int(seeds.get(id, 0)) + qty
	stats_changed.emit()

func take_seed_if_available(id: String) -> bool:
	var have := int(seeds.get(id, 0))
	if have <= 0: return false
	seeds[id] = have - 1
	stats_changed.emit()
	return true
	
