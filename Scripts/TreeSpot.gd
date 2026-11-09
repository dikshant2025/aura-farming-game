extends Area2D
class_name TreeSpot

@export var tree_scene: PackedScene          # set to Tree.tscn
@export var max_trees: int = 6
@export var respawn_interval_sec: float = 8.0
@export var click_radius: float = 28.0

var _rng := RandomNumberGenerator.new()
var _trees: Array[Node2D] = []
var _timer: Timer

func _ready() -> void:
	add_to_group("TreeSpot")
	_rng.randomize()

	# timer that does the regrow / cleanup tick
	_timer = Timer.new()
	_timer.wait_time = respawn_interval_sec
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_tick)
	_timer.start()

	# seed the area to max at start
	for i in range(max_trees):
		_spawn_one()

func _on_tick() -> void:
	# purge freed trees
	_trees = _trees.filter(func(t): return is_instance_valid(t))
	# fill back up to max (spawn as many as needed this tick)
	while _trees.size() < max_trees:
		_spawn_one()

func _spawn_one() -> void:
	if tree_scene == null:
		return
	var t := tree_scene.instantiate() as Node2D
	add_child(t)
	t.global_position = _random_point_inside()
	_trees.append(t)

func _random_point_inside() -> Vector2:
	var cs := $CollisionShape2D
	var shape: Shape2D = cs.shape
	var local := Vector2.ZERO

	if shape is RectangleShape2D:
		var ext := (shape as RectangleShape2D).size * 0.5
		local.x = _rng.randf_range(-ext.x, ext.x)
		local.y = _rng.randf_range(-ext.y, ext.y)
	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		# uniform disk sample
		var t := 2.0 * PI * _rng.randf()
		var u := _rng.randf()
		var rr := r * sqrt(u)
		local = Vector2(rr * cos(t), rr * sin(t))
	else:
		local = Vector2.ZERO

	return cs.global_transform * local

# Called by Player.gd when using the axe
func try_chop(world_pos: Vector2) -> bool:
	# keep list clean
	_trees = _trees.filter(func(t): return is_instance_valid(t))

	var best: Node2D = null
	var best_d2: float = click_radius * click_radius
	for t in _trees:
		var d2: float = t.global_position.distance_squared_to(world_pos)
		if d2 <= best_d2:
			best = t
			best_d2 = d2

	if best and best.has_method("hit_with_axe"):
		var died: bool = best.hit_with_axe(world_pos)
		if died == true or not is_instance_valid(best):
			_trees.erase(best) # remove from our list so future chops work
		return died

	return false
