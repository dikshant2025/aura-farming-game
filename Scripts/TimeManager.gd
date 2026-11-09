extends Node
class_name TimeManager

@export var day_seconds: float = 4.0
var _acc: float = 0.0

@export var energy_tick_sec: float = 2.0   # lose 1 energy per 5s
var _energy_acc: float = 0.0

var soil_grid: Node = null

func _process(delta: float) -> void:
	# crops growth (you already have this)
	if soil_grid == null or not is_instance_valid(soil_grid):
		soil_grid = get_tree().get_first_node_in_group("SoilGrid")
	if soil_grid:
		soil_grid.for_each_tile(func(t): t.advance_time(delta))

	# passive energy drain
	_energy_acc += delta
	if _energy_acc >= energy_tick_sec:
		_energy_acc -= energy_tick_sec
		PlayerState.spend_energy(1)  # will no-op if already 0 (returns false)
