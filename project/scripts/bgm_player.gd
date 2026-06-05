extends AudioStreamPlayer

const GENERAL_BGM_PATH := "res://assets/BGMs/general_music.mp3"
const BOSS_BGM_PATH := "res://assets/BGMs/boss_music.mp3"
const BOSS_LOOP_START := 6.0

var bgm_loop_enabled := true
var current_bgm_path := ""
var current_loop_start := 0.0
var fade_tween: Tween = null

func _ready() -> void:
	add_to_group("bgm_player")
	set_map_bgm("ab_foothill")

func stop_bgm() -> void:
	stop()

func play_bgm() -> void:
	_cancel_fade_out()
	volume_db = -10.0
	if not playing:
		play()

func fade_out_bgm(duration: float = 1.0) -> void:
	_cancel_fade_out()
	fade_tween = create_tween()
	fade_tween.tween_property(self, "volume_db", -80.0, duration)
	fade_tween.finished.connect(_on_fade_out_finished)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("toggle_bgm_mute"):
		toggle_mute()
		get_viewport().set_input_as_handled()

func get_bgm_path() -> String:
	return current_bgm_path

func get_current_loop_start() -> float:
	return current_loop_start

func is_bgm_loop_enabled() -> bool:
	if stream != null and "loop" in stream:
		return bool(stream.loop)
	return bgm_loop_enabled

func toggle_mute() -> void:
	stream_paused = not stream_paused

func set_map_bgm(map_id: String) -> void:
	var next_path := BOSS_BGM_PATH if map_id == "boss_interior" else GENERAL_BGM_PATH
	var next_loop_start := BOSS_LOOP_START if map_id == "boss_interior" else 0.0
	if current_bgm_path == next_path and stream != null:
		play_bgm()
		return
	_load_and_play_bgm(next_path, next_loop_start)

func restart_map_bgm(map_id: String) -> void:
	var next_path := BOSS_BGM_PATH if map_id == "boss_interior" else GENERAL_BGM_PATH
	var next_loop_start := BOSS_LOOP_START if map_id == "boss_interior" else 0.0
	_load_and_play_bgm(next_path, next_loop_start)

func _load_and_play_bgm(path: String, loop_start: float) -> void:
	_cancel_fade_out()
	current_bgm_path = path
	current_loop_start = loop_start
	if not ResourceLoader.exists(path):
		stream = null
		return
	stream = load(path)
	_configure_stream_loop(loop_start)
	volume_db = -10.0
	stream_paused = false
	play(0.0)

func _cancel_fade_out() -> void:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = null

func _on_fade_out_finished() -> void:
	fade_tween = null
	stop()

func _configure_stream_loop(loop_start: float) -> void:
	if stream == null:
		return
	if "loop" in stream:
		stream.loop = bgm_loop_enabled
	if "loop_offset" in stream:
		stream.loop_offset = loop_start
