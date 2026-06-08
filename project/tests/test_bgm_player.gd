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
	if bgm.get_bgm_path() != "res://assets/BGMs/general_music.mp3":
		push_error("BgmPlayer should load general BGM by default")
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
	if not bgm.has_method("set_map_bgm"):
		push_error("BgmPlayer should switch BGM by map id")
		quit(1)
		return
	bgm.set_map_bgm("h_stone_plaza")
	if bgm.get_bgm_path() != "res://assets/BGMs/general_music.mp3":
		push_error("H stone plaza should keep general BGM")
		quit(1)
		return
	bgm.set_map_bgm("boss_interior")
	if bgm.get_bgm_path() != "res://assets/BGMs/boss_music.mp3":
		push_error("Boss interior should use boss BGM")
		quit(1)
		return
	if not bgm.has_method("get_current_loop_start"):
		push_error("BgmPlayer should expose the current loop start")
		quit(1)
		return
	if not is_equal_approx(bgm.get_current_loop_start(), 6.0):
		push_error("Boss BGM should loop from 6 seconds after the first playback")
		quit(1)
		return
	bgm.set_map_bgm("ab_foothill")
	if bgm.get_bgm_path() != "res://assets/BGMs/general_music.mp3":
		push_error("AB foothill should use general BGM")
		quit(1)
		return
	bgm.stop()
	bgm.volume_db = -80.0
	bgm.set_map_bgm("ab_foothill")
	if not bgm.playing:
		push_error("Setting the same map BGM after death fade-out should restart playback")
		quit(1)
		return
	if bgm.volume_db < -20.0:
		push_error("Restarting the same map BGM should restore audible volume")
		quit(1)
		return
	bgm.fade_out_bgm(0.2)
	await process_frame
	bgm.restart_map_bgm("ab_foothill")
	await create_timer(0.25).timeout
	if not bgm.playing:
		push_error("Restarting map BGM should cancel the pending death fade-out stop")
		quit(1)
		return
	if bgm.volume_db < -20.0:
		push_error("Restarting map BGM should stay audible after the old death fade-out would have finished")
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
