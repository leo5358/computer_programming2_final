extends AudioStreamPlayer

const BGM_PATH := "res://assets/audio/bgm.mp3"

var bgm_loop_enabled := true

func _ready() -> void:
	if ResourceLoader.exists(BGM_PATH):
		stream = load(BGM_PATH)
		if stream != null and "loop" in stream:
			stream.loop = bgm_loop_enabled
		play()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("toggle_bgm_mute"):
		toggle_mute()
		get_viewport().set_input_as_handled()

func get_bgm_path() -> String:
	return BGM_PATH

func is_bgm_loop_enabled() -> bool:
	if stream != null and "loop" in stream:
		return bool(stream.loop)
	return bgm_loop_enabled

func toggle_mute() -> void:
	stream_paused = not stream_paused
