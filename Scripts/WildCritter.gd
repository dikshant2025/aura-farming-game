extends CharacterBody2D

@export var hp: int = 1
@export var speed: float = 20.0
@export var left_limit: float = -INF
@export var right_limit: float = INF

var _dir := 1

func _ready() -> void:
	add_to_group("Critters")
	# If limits were not set by HuntSpot, give a small local patrol span:
	if left_limit == -INF or right_limit == INF:
		left_limit = global_position.x - 64.0
		right_limit = global_position.x + 64.0
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	velocity = Vector2(_dir * speed, 0)
	move_and_slide()
	if global_position.x <= left_limit:
		global_position.x = left_limit
		_dir = 1
	elif global_position.x >= right_limit:
		global_position.x = right_limit
		_dir = -1

# Called from HuntSpot on click when player is close enough
func hit_with_bow(_pos: Vector2) -> bool:
	hp -= 1
	if hp <= 0:
		PlayerState.add_item("meat", 1)
		queue_free()
		return true
	return false

# Optional helper so HuntSpot can set patrol bounds from its Area shape
func set_patrol_bounds(min_x: float, max_x: float) -> void:
	left_limit = min_x
	right_limit = max_x
