extends Area2D
class_name CookStation

const ENERGY_PER: Dictionary[String, int] = {
	"fish": 50, "meat": 100, "potato": 10
}

const WOOD_COST: Dictionary[String, int] = {
	"meat": 3, "fish": 2,  "potato": 1, 
}

var _player_inside: bool = false

func _ready() -> void:
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("PlayerGroup"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("PlayerGroup"):
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("fire"):
		_cook_all_items()

func _cook_all_items() -> void:
	var wood_available: int = PlayerState.get_item_qty("wood")
	if wood_available <= 0:
		print("You need wood to cook!")
		return

	var wood_used: int = 0
	var energy_gained: int = 0

	for id in ENERGY_PER.keys():
		var have: int = PlayerState.get_item_qty(id)
		if have <= 0:
			continue

		var cost_per: int = int(WOOD_COST.get(id, 1))
		if cost_per <= 0:
			cost_per = 1

		# integer math so types stay int
		var can_cook: int = int((wood_available - wood_used) / cost_per)
		if can_cook <= 0:
			continue

		var cook_qty: int = min(have, can_cook)

		if cook_qty > 0:
			PlayerState.take_item(id, cook_qty)
			wood_used += cook_qty * cost_per
			energy_gained += int(ENERGY_PER[id]) * cook_qty

	if wood_used > 0:
		PlayerState.take_item("wood", wood_used)
		PlayerState.gain_energy(energy_gained)
		Audio.play_sfx(Audio.sfx_powerup)
		print("Cooked: used %d wood, gained +%d energy." % [wood_used, energy_gained])
	else:
		Audio.play_sfx(Audio.sfx_error)
		print("No items cooked (not enough wood or no items).")
