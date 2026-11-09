extends Node
class_name GameDB

# ------------------------------
# TOOL SETTINGS
# ------------------------------

# Energy cost for each action
const ACTION_COST = {
	"hoe": 2,
	"seeds": 2,
	"watering": 2,
	"scythe": 2,
	"axe": 5,      # trees
	"bow": 10,    # hunting
	"rod": 5,
}

static func action_cost(name: String) -> int:
	return int(ACTION_COST.get(name, 1))

# Range (pixels) for tool interactions
const TOOL_RANGE := {
	"soil": 56.0,
	"tree": 604.0,
	"fish": 64.0,
	"hunt": 64.0,
	"cook": 48.0,
}

const SOIL_STAMP = Vector2i(1, 1)  # not 2x2


# ------------------------------
# CROPS DATABASE
# ------------------------------

static var CROPS: Dictionary = {
	"turnip": {
		"stages": 2,
		"days_per_stage": [1, 1],
		"energy_cost": 2,
		"harvest_yield": 1
	},
}

# ------------------------------
# LOAD CROP DATA FROM JSON
# ------------------------------

static func set_crops(data: Dictionary) -> void:
	CROPS = data

static func load_crops_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("⚠️ Missing crop data file: ", path)
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Failed to open file: " + path)
		return
	var txt := f.get_as_text()
	var data = JSON.parse_string(txt)
	if typeof(data) == TYPE_DICTIONARY:
		CROPS = data
		print("✅ Crops loaded successfully from JSON!")
	else:
		push_error("Invalid crop JSON format.")
