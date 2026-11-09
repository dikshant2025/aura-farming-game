extends Area2D
class_name HuntSpot

@export var critter_scene: PackedScene
@export var max_critters: int = 3
@export var spawn_interval_sec: float = 3.0
@export var click_radius: float = 60.0        # how close the CLICK must be to a critter
@export var bow_min_radius: float = 20.0    # too close? no hit
@export var bow_max_radius: float = 120.0   # too far?  no hit
@export var aim_cone_deg: float = 35.0          # optional: how tightly you must aim (0..90)

var _rng := RandomNumberGenerator.new()
var _spawn_timer: Timer
var _critters: Array[Node2D] = []

func _ready() -> void:
	add_to_group("HuntSpot")
	_rng.randomize()
	_spawn_timer = Timer.new()
	_spawn_timer.wait_time = spawn_interval_sec
	_spawn_timer.autostart = true
	_spawn_timer.one_shot = false
	add_child(_spawn_timer)
	_spawn_timer.timeout.connect(_on_spawn_tick)


func _on_spawn_tick() -> void:
	_critters = _critters.filter(func(c): return is_instance_valid(c))
	if _critters.size() >= max_critters or critter_scene == null:
		return
	var c: Node2D = critter_scene.instantiate()
	add_child(c)
	c.tree_exited.connect(_remove_critter.bind(c))  # auto-clean when freed
	c.global_position = _random_point_inside()
	_critters.append(c)
	# Give the critter patrol bounds inside this Area (rectangle shapes only)
	if c.has_method("set_patrol_bounds"):
		var rect := _area_rect()
		# Small “margin” so they don’t stick to edges
		var margin := 8.0
		c.set_patrol_bounds(rect.position.x + margin, rect.position.x + rect.size.x - margin)

func _random_point_inside() -> Vector2:
	var cs := $CollisionShape2D
	var shape: Shape2D = cs.shape
	var local := Vector2.ZERO

	if shape is RectangleShape2D:
		var ext := (shape as RectangleShape2D).size * 0.5
		# guard against 0-height/width rectangles
		if ext.x < 1.0: ext.x = 1.0
		if ext.y < 1.0: ext.y = 1.0
		local.x = _rng.randf_range(-ext.x, ext.x)
		local.y = _rng.randf_range(-ext.y, ext.y)

	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		if r < 1.0: r = 1.0
		var t := TAU * _rng.randf()
		var rr := r * sqrt(_rng.randf())   # uniform disk
		local = Vector2(rr * cos(t), rr * sin(t))

	# convert local (shape space) to world
	return cs.global_transform * local


# NEW: Return area rect in global coords (for patrol limits)
func _area_rect() -> Rect2:
	var cs: CollisionShape2D = $CollisionShape2D
	if cs.shape is RectangleShape2D:
		var size: Vector2 = (cs.shape as RectangleShape2D).size
		var center: Vector2 = cs.global_transform.origin
		return Rect2(center - size * 0.5, size)
	# Fallback: small rect around center (for non-rect shapes)
	return Rect2(cs.global_transform.origin - Vector2(64, 32), Vector2(128, 64))

func try_hunt(world_pos: Vector2, player_pos: Vector2) -> bool:
	# 1) pick clicked-nearest critter within click_radius
	_critters = _critters.filter(func(c): return is_instance_valid(c))
	var best: Node2D = null
	var best_d2_click: float = click_radius * click_radius

	for c in _critters:
		var d2 := c.global_position.distance_squared_to(world_pos)
		if d2 <= best_d2_click:
			best_d2_click = d2
			best = c

	if best == null or not best.has_method("hit_with_bow"):
		return false

	# 2) distance from PLAYER must be in a sweet spot (not too close / far)
	var d2_player := player_pos.distance_squared_to(best.global_position)
	var min2 := bow_min_radius * bow_min_radius
	var max2 := bow_max_radius * bow_max_radius
	if d2_player < min2 or d2_player > max2:
		return false

	# 3) optional: require click direction to roughly face the critter
	if aim_cone_deg > 0.0:
		var aim_dir := (world_pos - player_pos).normalized()
		var to_critter := (best.global_position - player_pos).normalized()
		var cos_limit := cos(deg_to_rad(clamp(aim_cone_deg, 0.0, 89.0)))
		if aim_dir.dot(to_critter) < cos_limit:
			return false

	# 4) apply the hit; if the critter dies, it queues free
	var died: bool = best.hit_with_bow(world_pos)

	# Remove it from our list now as well (immediate clean-up).
	# (Also covered by tree_exited connection, but immediate feels snappier.)
	if died:
		_remove_critter(best)

	return died

	
	# top-level in HuntSpot.gd
func _remove_critter(c: Node) -> void:
	var i := _critters.find(c)
	if i != -1:
		_critters.remove_at(i)
