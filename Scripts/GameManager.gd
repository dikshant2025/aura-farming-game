extends Node
class_name GameManager

@onready var hud: CanvasLayer = get_tree().get_first_node_in_group("HUDGroup")
@onready var player: Node = get_tree().get_first_node_in_group("PlayerGroup")

func _ready() -> void:
	# Load crop data (works with either name)
	if FileAccess.file_exists("res://Data/crops.json"):
		GameDB.load_crops_from_json("res://Data/crops.json")
	elif FileAccess.file_exists("res://Data/crop.json"):
		GameDB.load_crops_from_json("res://Data/crop.json")
	else:
		print("⚠️ No crop.json found — using built-in defaults.")

	# Connect HUD refresh
	if not PlayerState.stats_changed.is_connected(_on_stats_changed):
		PlayerState.stats_changed.connect(_on_stats_changed)
	_on_stats_changed()
	print("🌾 GameManager initialized.")
	
	var drain := Timer.new()
	drain.wait_time = 5.0
	drain.one_shot = false
	drain.autostart = true
	add_child(drain)
	drain.timeout.connect(func ():
		PlayerState.spend_energy(1) # costs 1 every 5 seconds
	)
	Audio.play_bgm()
	Audio.set_music_volume(0.05)  # lower background music (0.3 = 30%)
	Audio.set_sfx_volume(1.0)    # boost tool and action sounds to full

func _on_stats_changed() -> void:
	if hud and hud.has_method("_refresh"):
		hud._refresh()

func reset_game() -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		get_tree().reload_current_scene()
