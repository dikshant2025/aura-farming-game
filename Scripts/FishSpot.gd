extends Area2D
class_name FishSpot

# --- Setup ---
@export var fish_scene: PackedScene                 # assign res://Scenes/Fish.tscn
@export var max_fish: int = 4
@export var spawn_interval_sec: float = 10.0
@export var click_radius: float = 20.0              # click distance to select a fish

# NEW: hook tuning
@export var hook_damage: int = 1                    # damage dealt per hook
@export var hook_energy_cost: int = 4               # cost per attempt (matches GameDB.ACTION_COST["fish"])

# Runtime
var _rng := RandomNumberGenerator.new()
var _spawn_timer: Timer
var _fish: Array[Node] = []                         # active fish

# Signals for UI / SFX
signal fish_hit(fish: Node, hp_left: int)
signal fish_caught(item_id: String, qty: int)

func _ready() -> void:
	add_to_group("FishSpot")
	_rng.randomize()

	# spawn timer
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval_sec
	_spawn_timer.autostart = true
	_spawn_timer.one_shot = false
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_tick)

func _on_spawn_tick() -> void:
	# prune freed
	_fish = _fish.filter(func(f): return is_instance_valid(f))
	if _fish.size() >= max_fish: return
	if fish_scene == null: return

	var f: Node2D = fish_scene.instantiate()
	add_child(f)
	f.global_position = _random_point_inside()
	_fish.append(f)

	# when a fish gets caught, remove from list
	if f.has_signal("caught"):
		f.caught.connect(func():
			_fish.erase(f)
		)

# Works with RectangleShape2D or CircleShape2D on the first CollisionShape2D child
func _random_point_inside() -> Vector2:
	var cs := $CollisionShape2D
	var shape = cs.shape
	var local := Vector2.ZERO
	if shape is RectangleShape2D:
		var ext: Vector2 = (shape as RectangleShape2D).size * 0.5
		local.x = _rng.randf_range(-ext.x, ext.x)
		local.y = _rng.randf_range(-ext.y, ext.y)
	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		# uniform disk sample
		var t := 2.0 * PI * _rng.randf()
		var u := _rng.randf()
		var rr := r * sqrt(u)
		local = Vector2(rr * cos(t), rr * sin(t))
	return cs.global_transform * local

# Called by Player on click with the mouse position in world space.
# Returns:
#   - {"id": "fish", "qty": 1} if a fish was caught
#   - {"hit": true, "hp": <int>} if you hit but didn't catch
#   - null if nothing was close, or not enough energy
func try_fish(world_pos: Vector2) -> Variant:
	# pick closest fish within click_radius
	_fish = _fish.filter(func(f): return is_instance_valid(f))
	var best: Node2D = null
	var best_d2 := click_radius * click_radius
	for f in _fish:
		var d2 = f.global_position.distance_squared_to(world_pos)
		if d2 <= best_d2:
			best = f
			best_d2 = d2

	if best == null:
		return null

	# energy gate
	if not PlayerState.spend_energy(hook_energy_cost):
		return null

	# apply hook damage
	if best.has_method("try_hook"):
		var ok: bool = best.try_hook(hook_damage)    # uses your Fish.gd
		if ok:
			_fish.erase(best)
			emit_signal("fish_caught", "fish", 1)
			return {"id": "fish", "qty": 1}
		else:
			# optional: if Fish.gd emits "damaged(hp)", connect it on spawn and cache hp there.
			# If not, you can expose a read-only 'hp' in Fish.gd and read it here:
			if "hp" in best:
				emit_signal("fish_hit", best, best.hp)
				return {"hit": true, "hp": int(best.hp)}
			else:
				return {"hit": true}


	return null
