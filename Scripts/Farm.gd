extends Node2D

@onready var grid: Node = %SoilGrid
@onready var hud: Node = get_node_or_null(^"HUD")  # ← no syntax error

func _ready() -> void:
	# No day system. Just make sure visuals/HUD are sane at start.

	if hud and hud.has_method("update_display"):
		hud.update_display()
