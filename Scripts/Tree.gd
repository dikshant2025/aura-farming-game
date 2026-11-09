# Tree.gd (script on Tree.tscn root)
extends Node2D
class_name GameTree

var hp := 1
func hit_with_axe(_pos: Vector2) -> bool:
	hp -= 1
	if hp <= 0:
		PlayerState.add_item("wood", 1)
		queue_free()
		return true
	return false
