extends CharacterBody2D

@onready var tool_anim: AnimatedSprite2D = get_node_or_null("ToolAnim")

const SPEED := 100.0

func _ready() -> void:
	if tool_anim: tool_anim.visible = false

func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized() 
	velocity = dir * SPEED
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("tool_1"): PlayerState.set_tool("hoe")
	if event.is_action_pressed("tool_2"): PlayerState.set_tool("seeds")
	if event.is_action_pressed("tool_3"): PlayerState.set_tool("watering")
	if event.is_action_pressed("tool_4"): PlayerState.set_tool("scythe")
	if event.is_action_pressed("tool_5"): PlayerState.set_tool("axe")
	if event.is_action_pressed("tool_6"): PlayerState.set_tool("rod")
	if event.is_action_pressed("tool_7"): PlayerState.set_tool("bow")
	if event.is_action_pressed("attack"):
		_use_tool()

func _use_tool() -> void:
	var pos := get_global_mouse_position()
	Audio.play_sfx_section(Audio.sfx_hoeing, 0.0, 0.5)      # ~120 ms click
	Audio.play_sfx_section(Audio.sfx_planting, 0.0, 0.5)
	Audio.play_sfx_section(Audio.sfx_watering, 0.0, 0.5)
	Audio.play_sfx_section(Audio.sfx_harvesting, 0.0, 0.5)
	Audio.play_sfx_section(Audio.sfx_cutting, 0.0, 0.5)
	Audio.play_sfx_section(Audio.sfx_fishing, 0.0, 0.5)
	Audio.play_sfx_section(Audio.sfx_hunting, 0.0, 0.5)
	#soil.set_hoed_stamp_at_world(pos)

	match String(PlayerState.selected_tool):
		"hoe":
			var soil := _find_singleton_in_group("SoilGrid")
			if soil and _near_target(pos, GameDB.TOOL_RANGE.soil) and PlayerState.spend_energy(GameDB.action_cost("hoe")):
				soil.set_hoed_stamp_at_world(pos)
				Audio.play_sfx(Audio.sfx_hoeing)
				_show_tool("hoe")
			else:
				Audio.error()
			return
				
		"seeds":
			var soil := _find_singleton_in_group("SoilGrid")
			if soil and _near_target(pos, GameDB.TOOL_RANGE.soil) and PlayerState.take_seed_if_available(PlayerState.selected_seed):  
				if PlayerState.spend_energy(GameDB.action_cost("seeds")):
					soil.set_planted_stamp_at_world(pos, PlayerState.selected_seed)
					Audio.play_sfx(Audio.sfx_planting)
					_show_tool("seeds")
				else:
					Audio.error()
			else:
					Audio.error()
			return

		"watering":
			var soil := _find_singleton_in_group("SoilGrid")
			if soil and _near_target(pos, GameDB.TOOL_RANGE.soil) and PlayerState.spend_energy(GameDB.action_cost("watering")):
				soil.set_watered_stamp_at_world(pos)
				Audio.play_sfx(Audio.sfx_watering)
				_show_tool("watering")
			else:
				Audio.error()
			return


		"scythe":
			var soil := _find_singleton_in_group("SoilGrid")
			if soil and _near_target(pos, GameDB.TOOL_RANGE.soil) and PlayerState.spend_energy(GameDB.action_cost("scythe")):
				var items: Dictionary[String, int] = soil.try_harvest_items_stamp_at_world(pos)
				if items.size() > 0:
					Audio.play_sfx(Audio.sfx_harvesting)
					for id in items.keys():
						PlayerState.add_item(id, items[id])
					_show_tool("scythe")
				else:
					Audio.error()
			else:
				Audio.error()      # no water/fish in range
			return

# --- AXE: trees only ---
		"axe":
			var forest := _find_nearest_in_radius("TreeSpot", pos, GameDB.TOOL_RANGE.tree)
			if forest and PlayerState.spend_energy(GameDB.action_cost("axe")):
				if forest.try_chop(get_global_mouse_position()):
					Audio.play_sfx(Audio.sfx_cutting)
					_show_tool("axe")
				else:
					Audio.error()
			else:
					Audio.error()
			return

# --- SPEAR: animals only ---
		"bow":
			var hunt := _find_nearest_in_radius("HuntSpot", pos, GameDB.TOOL_RANGE.hunt)
			if hunt and PlayerState.spend_energy(GameDB.action_cost("bow")):
		# OLD: if hunt.try_hunt(get_global_mouse_position()):
				if hunt.try_hunt(get_global_mouse_position(), global_position):
					Audio.play_sfx(Audio.sfx_hunting)
					_show_tool("bow")
				else:
					Audio.error()
			else:
				Audio.error()
			return	


# --- ROD: fishing ---
		"rod":
			var spot := _find_nearest_in_radius("FishSpot", pos, GameDB.TOOL_RANGE.fish)
			if not spot:
				Audio.error()      # no water/fish in range
				return
			if spot:
				var res = spot.try_fish(get_global_mouse_position())
				if typeof(res) == TYPE_DICTIONARY:
					if res.has("id"):
						Audio.play_sfx(Audio.sfx_fishing)
						PlayerState.add_item(String(res["id"]), int(res.get("qty", 1)))
						_show_tool("rod") # optional: success feedback
					elif res.get("hit", false):
						Audio.error()      # no water/fish in range
						_show_tool("rod")  # or a different “hit” flash if you want
				else:
					Audio.error()		
				return


func _near_target(pos: Vector2, r: float) -> bool:
	return global_position.distance_to(pos) <= r

func _find_singleton_in_group(g: String) -> Node:
	var arr := get_tree().get_nodes_in_group(g)
	return arr[0] if not arr.is_empty() else null

func _find_nearest_in_radius(group_name: String, pos: Vector2, r: float) -> Node:
	var best: Node = null
	var best_d2 := r * r
	for n in get_tree().get_nodes_in_group(group_name):
		if n is Node2D:
			var d2: float = (n.global_position - pos).length_squared()
			if d2 <= best_d2:
				best = n
				best_d2 = d2
	return best

func _show_tool(_name: String) -> void:
	if not tool_anim: return
	if not tool_anim.sprite_frames or not tool_anim.sprite_frames.has_animation(_name): return
	tool_anim.visible = true
	tool_anim.play(_name)
	await get_tree().create_timer(0.15).timeout
	tool_anim.visible = false
