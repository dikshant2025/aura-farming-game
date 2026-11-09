extends Node2D
class_name SoilTile

@onready var spr: AnimatedSprite2D = $Spr

enum State { EMPTY, HOED, PLANTED, WATERED, MATURED }

var state: State = State.HOED
var crop_id: String = ""
var grow_timer: float = 0.0

@export var grow_days: int = 1        # used by daily model
@export var grow_seconds: float = 15.0 # used by real-time model

func _ready() -> void:
	spr.speed_scale = 0.0
	_refresh()

func _refresh() -> void:
	match state:
		State.EMPTY:		spr.frame = 0
		State.HOED:     spr.frame = 1
		State.PLANTED:  spr.frame = 2
		State.WATERED:  spr.frame = 3
		State.MATURED:  spr.frame = 4

func set_state(s: int) -> void:
	state = s
	_refresh()

func hoe() -> void:
	if state == State.EMPTY:
		crop_id = ""
		state = State.HOED
		grow_timer = 0.0
		_refresh()

func plant(id: String) -> void:
	if state == State.HOED:
		crop_id = id
		state = State.PLANTED
		grow_timer = 0.0
		_refresh()

func water() -> void:
	if state == State.PLANTED:
		state = State.WATERED
		grow_timer = 0.0
		_refresh()

# ---- growth models ----

# REAL-TIME: call every frame with delta if you prefer seconds instead of days
func advance_time(dt: float) -> void:
	if state == State.WATERED:
		grow_timer += dt
		if grow_timer >= grow_seconds:
			state = State.MATURED
			_refresh()

func harvest() -> String:
	if state == State.MATURED:
		var id := crop_id
		state = State.HOED
		crop_id = ""
		grow_timer = 0.0
		state = State.EMPTY
		_refresh()
		return id
	return ""
