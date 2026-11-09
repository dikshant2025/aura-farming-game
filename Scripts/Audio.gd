extends Node
# optional if you aren't autoloading the scene:
# class_name Audio

# --- exported streams (already in your file, adding BGM + background) ---
@export var sfx_hoeing:     AudioStream
@export var sfx_planting:   AudioStream
@export var sfx_watering:   AudioStream
@export var sfx_harvesting: AudioStream
@export var sfx_cutting:    AudioStream
@export var sfx_fishing:    AudioStream
@export var sfx_hunting:    AudioStream
@export var sfx_powerup:    AudioStream
@export var sfx_error:      AudioStream
@export var bgm_track:      AudioStream     # <-- add this (your BackGround.mp3)

var p_ui:  AudioStreamPlayer
var p_sfx: AudioStreamPlayer
var p_bgm: AudioStreamPlayer                 # <-- add this

func _ready() -> void:
	p_ui  = AudioStreamPlayer.new()
	p_sfx = AudioStreamPlayer.new()
	p_bgm = AudioStreamPlayer.new()
	add_child(p_ui)
	add_child(p_sfx)
	add_child(p_bgm)

	p_ui.bus  = "UI"
	p_sfx.bus = "SFX"
	p_bgm.bus = "Music"
	
	p_bgm.stream = bgm_track
	p_bgm.volume_db = linear_to_db(0.15)
	

# ---------- Simple helpers ----------
func play_ui(stream: AudioStream) -> void:
	if stream:
		p_ui.stream = stream
		p_ui.play()

func play_sfx(stream: AudioStream) -> void:
	if not stream: return
	_force_loop(stream, false)       # <-- force OFF for one-shots
	p_sfx.stream = stream
	p_sfx.play(0.0)

func error() -> void:
	play_sfx(sfx_error)

# ---------- Play only a section of a clip ----------
# start_sec: where to begin; length_sec: how long to play before we stop

func play_sfx_section(stream: AudioStream, start_sec: float, length_sec: float) -> void:
	if not stream or length_sec <= 0.0: return
	_force_loop(stream, false)       # <-- force OFF for one-shots
	p_sfx.stream = stream
	p_sfx.play(max(0.0, start_sec))
	var t := get_tree().create_timer(length_sec) # one-shot
	t.timeout.connect(func(): p_sfx.stop())

# ---------- Background music ----------
func play_bgm(stream: AudioStream = bgm_track, from_sec: float = 0.0, loop: bool = true) -> void:
	if not stream: return
	_force_loop(stream, loop)     # <— allow loop for BGM only
	p_bgm.stream = stream
	p_bgm.play(max(0.0, from_sec))

func stop_bgm() -> void:
	p_bgm.stop()

# ---------- Volumes (per bus or per player) ----------
# volume: 0.0..1.0 (linear). Use negative dB if you prefer.
func set_bus_volume(bus_name: String, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		var db := linear_to_db(clamp(volume, 0.0, 1.0))
		AudioServer.set_bus_volume_db(idx, db)

func set_music_volume(volume: float) -> void:
	# set both player and bus for robustness
	p_bgm.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	set_bus_volume("Music", volume)

func set_sfx_volume(volume: float) -> void:
	p_sfx.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	set_bus_volume("SFX", volume)

func set_ui_volume(volume: float) -> void:
	p_ui.volume_db = linear_to_db(clamp(volume, 0.0, 1.0))
	set_bus_volume("UI", volume)

# Per-clip quick trims without timers (optional utility):
func play_click_short() -> void:
	# e.g., play only first 0.12s of hoeing click
	play_sfx_section(sfx_hoeing, 0.0, 0.12)
	

func _force_loop(stream: AudioStream, should_loop: bool) -> void:
	# Some stream types expose a `loop` property (Ogg, WAV, MP3).
	# Touch it defensively only if it exists.
	if stream and "loop" in stream:
		stream.loop = should_loop
