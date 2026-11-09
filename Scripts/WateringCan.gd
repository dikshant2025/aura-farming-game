extends Node2D
@onready var soil_grid: Node = $"../SoilGrid"

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos := get_global_mouse_position()
		(soil_grid as Node).call("set_watered_at_world", world_pos)
