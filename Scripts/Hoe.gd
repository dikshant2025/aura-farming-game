extends Node2D
@onready var soil_grid: Node = $"../SoilGrid"

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos := get_global_mouse_position()
		(soil_grid as Node).call("set_hoed_at_world", world_pos)
		# if SoilGrid.gd is class_name SoilGrid, this also works:
		# (soil_grid as SoilGrid).set_hoed_at_world(world_pos)
