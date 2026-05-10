extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main := scene.instantiate()
	get_root().add_child(main)
	await process_frame

	if not main.has_node("BgmPlayer"):
		push_error("Main scene should include a BgmPlayer")
		quit(1)
		return

	var bgm := main.get_node("BgmPlayer") as AudioStreamPlayer
	if bgm == null:
		push_error("BgmPlayer should be an AudioStreamPlayer")
		quit(1)
		return
	if not bgm.has_method("get_bgm_path"):
		push_error("BgmPlayer script should expose its configured bgm path")
		quit(1)
		return
	if bgm.get_bgm_path() != "res://assets/audio/bgm.mp3":
		push_error("BgmPlayer should load bgm from assets/audio/bgm.mp3")
		quit(1)
		return
	if not bgm.autoplay:
		push_error("BgmPlayer should autoplay when the scene starts")
		quit(1)
		return
	if not bgm.has_method("is_bgm_loop_enabled"):
		push_error("BgmPlayer script should expose whether looping is enabled")
		quit(1)
		return
	if not bgm.is_bgm_loop_enabled():
		push_error("BgmPlayer should configure BGM to loop")
		quit(1)
		return
	if not InputMap.has_action("toggle_bgm_mute"):
		push_error("Project input map should include toggle_bgm_mute")
		quit(1)
		return
	var has_m_key := false
	for event in InputMap.action_get_events("toggle_bgm_mute"):
		if event is InputEventKey and event.keycode == KEY_M:
			has_m_key = true
	if not has_m_key:
		push_error("toggle_bgm_mute should be bound to M")
		quit(1)
		return
	if not bgm.has_method("toggle_mute"):
		push_error("BgmPlayer should expose toggle_mute")
		quit(1)
		return
	bgm.stream_paused = false
	bgm.toggle_mute()
	if not bgm.stream_paused:
		push_error("toggle_mute should pause BGM playback")
		quit(1)
		return
	bgm.toggle_mute()
	if bgm.stream_paused:
		push_error("toggle_mute should resume BGM playback")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
