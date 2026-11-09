extends CanvasLayer

@onready var bar      : ProgressBar = $"TopBar/EnergyBar"
@onready var tool_lbl : Label       = $"TopBar/ToolLabel"
@onready var wood_lbl : Label       = $"TopBar/WoodLabel"
@onready var fish_lbl : Label       = $"TopBar/FishLabel"
@onready var meat_lbl : Label       = $"TopBar/MeatLabel"
@onready var crop_lbl : Label       = $"TopBar/CropLabel"

func _ready() -> void:
	set_process(true)
	var cb := Callable(self, "_refresh")
	if not PlayerState.stats_changed.is_connected(cb):
		PlayerState.stats_changed.connect(cb)
	_refresh()

func _process(_d: float) -> void:
	_refresh()

func _refresh() -> void:
	if bar == null:
		push_error("HUD: EnergyBar path is wrong. Expected TopBar/EnergyBar")
		return

	# energy
	bar.max_value = PlayerState.max_energy
	bar.value     = PlayerState.energy

	# tool
	tool_lbl.text = "Tool: %s" % PlayerState.get_tool()

	# items
	wood_lbl.text = "Wood: %d" % PlayerState.get_item_qty("wood")
	meat_lbl.text = "Meat: %d" % PlayerState.get_item_qty("meat")
	fish_lbl.text = "Fish: %d" % PlayerState.get_item_qty("fish")

	# crops (sum of your produce IDs)
	var crops := 0
	crops += PlayerState.get_item_qty("turnip")
	crops += PlayerState.get_item_qty("potato")
	crops += PlayerState.get_item_qty("bean")
	crop_lbl.text = "Crops: %d" % crops
