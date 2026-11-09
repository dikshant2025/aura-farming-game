extends Node2D
class_name SoilGrid

@export var soil_tile_scene: PackedScene
@export var columns: int = 10
@export var rows: int = 10
@export var cell_size: Vector2i = Vector2i(16, 16)
@export var anchor: NodePath        # optional Marker2D at top-left of the bed

var tiles: Dictionary = {}          # Dictionary[Vector2i] -> SoilTile

func _ready() -> void:
	# lock the grid onto cell multiples so clicks line up perfectly
	if anchor != NodePath():
		global_position = (get_node(anchor) as Node2D).global_position
	position = position.snapped(Vector2(cell_size.x, cell_size.y))
	add_to_group("SoilGrid")

func _origin_px() -> Vector2:
	# GLOBAL origin in pixels (top-left of the grid)
	return global_position

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < columns and c.y < rows

func world_to_cell(pos: Vector2) -> Vector2i:
	# pos is GLOBAL (use get_global_mouse_position)
	var p := pos - _origin_px()
	return Vector2i(
		floori(p.x / float(cell_size.x)),
		floori(p.y / float(cell_size.y))
	)

func _get_or_create(c: Vector2i) -> SoilTile:
	var t: SoilTile = tiles.get(c, null)
	if t: return t

	# center of the cell in LOCAL grid units
	var cx := float(c.x) * float(cell_size.x) + float(cell_size.x) * 0.5
	var cy := float(c.y) * float(cell_size.y) + float(cell_size.y) * 0.5

	t = soil_tile_scene.instantiate() as SoilTile
	add_child(t)

	# ✅ Place in GLOBAL space (do NOT add the grid origin to a local position)
	t.global_position = _origin_px() + Vector2(cx, cy)

	tiles[c] = t
	return t

# ----- stamp helpers stay the same (they call world_to_cell(p) with GLOBAL p)
# Create-if-missing helper (used by HOE only)
func _apply_stamp(c0: Vector2i, size: Vector2i, cb: Callable) -> void:
	for dy in size.y:
		for dx in size.x:
			var c: Vector2i = Vector2i(c0.x + dx, c0.y + dy)
			if not in_bounds(c):
				continue
			var t: SoilTile = _get_or_create(c)   # create tile if needed
			cb.call(t)

func _apply_stamp_existing(c0: Vector2i, size: Vector2i, cb: Callable) -> void:
	for dy in size.y:
		for dx in size.x:
			var c: Vector2i = Vector2i(c0.x + dx, c0.y + dy)
			if not in_bounds(c):
				continue
			var t: SoilTile = tiles.get(c, null)
			if t:                     # skip if there is no tile yet
				cb.call(t)


# HOE: create tiles if missing, then hoe them
func set_hoed_stamp_at_world(p: Vector2) -> void:
	var c := world_to_cell(p)
	if not in_bounds(c): return
	_apply_stamp(c, GameDB.SOIL_STAMP, func(t: SoilTile): t.hoe())

# WATER: only water tiles that already exist
func set_watered_stamp_at_world(p: Vector2) -> void:
	var c := world_to_cell(p)
	if not in_bounds(c): return
	_apply_stamp_existing(c, GameDB.SOIL_STAMP, func(t: SoilTile): t.water())

# PLANT: only plant on tiles that already exist
func set_planted_stamp_at_world(p: Vector2, crop_id: String) -> void:
	var c := world_to_cell(p)
	if not in_bounds(c): return
	_apply_stamp_existing(c, GameDB.SOIL_STAMP, func(t: SoilTile): t.plant(crop_id))

# HARVEST: only harvest existing matured tiles
func try_harvest_items_stamp_at_world(p: Vector2) -> Dictionary[String, int]:
	var c := world_to_cell(p)
	if not in_bounds(c): return {} as Dictionary[String, int]

	var bag: Dictionary[String, int] = {}
	_apply_stamp_existing(c, GameDB.SOIL_STAMP, func(t: SoilTile) -> void:
		var got_id: String = t.harvest()
		if got_id != "":
			bag[got_id] = (bag.get(got_id, 0) as int) + 1
	)
	return bag

	
# SoilGrid.gd
func _make_tile(c: Vector2i) -> SoilTile:
	var t: SoilTile = soil_tile_scene.instantiate()
	add_child(t)  # local to SoilGrid
	# local center of the cell (NO global/top-left added here)
	var cx := (float(c.x) + 0.5) * float(cell_size.x)
	var cy := (float(c.y) + 0.5) * float(cell_size.y)
	t.position = Vector2(cx, cy)
	tiles[c] = t
	return t
	
# Add at bottom of SoilGrid.gd
func for_each_tile(cb: Callable) -> void:
	for t in tiles.values():
		cb.call(t)


	
