extends CharacterBody2D
signal caught
signal damaged

var _t := 0.0
var _amp := 3.0
var _spd := 3.0
var _home := Vector2.ZERO

# --- NEW ---
@export var max_hp: int = 3
var hp: int = max_hp
var is_dead := false

func _ready() -> void:
	_home = position
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if is_dead: return
	_t += delta * _spd
	# gentle wobble around home
	var off := Vector2(cos(_t), sin(_t)) * _amp
	position = _home + off

# Try to catch the fish: returns true if killed/caught
func try_hook(damage: int = 1) -> bool:
	if is_dead: 
		return false
	hp -= damage
	emit_signal("damaged", hp)
	if hp <= 0:
		is_dead = true
		emit_signal("caught")
		queue_free()
		return true
	return false
