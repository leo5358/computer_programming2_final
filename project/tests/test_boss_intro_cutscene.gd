extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main := scene.instantiate()
	if not main.has_method("_play_boss_intro_cutscene"):
		push_error("Main should expose boss intro cutscene playback")
		quit(1)
		return
	if main.get("BOSS_INTRO_DURATION") == null or not is_equal_approx(float(main.get("BOSS_INTRO_DURATION")), 6.0):
		push_error("Boss intro duration should be 6 seconds")
		quit(1)
		return
	if main.get("BOSS_INTRO_ZOOM_OUT_TIME") == null or not is_equal_approx(float(main.get("BOSS_INTRO_ZOOM_OUT_TIME")), 3.0):
		push_error("Boss intro zoom-out duration should be 3 seconds")
		quit(1)
		return
	if main.get("BOSS_INTRO_SHAKE_TIMES") == null:
		push_error("Boss intro should expose BOSS_INTRO_SHAKE_TIMES for BGM alignment")
		quit(1)
		return
	var shake_times: PackedFloat32Array = main.get("BOSS_INTRO_SHAKE_TIMES")
	if shake_times.size() != 6:
		push_error("Boss intro should schedule exactly 6 camera shakes")
		quit(1)
		return
	var previous_time := -0.001
	for shake_time in shake_times:
		if shake_time < 0.0 or shake_time > float(main.get("BOSS_INTRO_DURATION")) or shake_time <= previous_time:
			push_error("Boss intro shake timings should be increasing values within the intro duration")
			quit(1)
			return
		previous_time = shake_time

	var top_bar := main.get_node_or_null("MapTransitionUI/BossIntroOverlay/TopLetterbox") as ColorRect
	var bottom_bar := main.get_node_or_null("MapTransitionUI/BossIntroOverlay/BottomLetterbox") as ColorRect
	if top_bar == null or bottom_bar == null:
		push_error("Main scene should provide cinematic boss intro letterbox bars")
		quit(1)
		return
	if top_bar.visible or bottom_bar.visible:
		push_error("Boss intro letterbox bars should start hidden")
		quit(1)
		return

	var camera := main.get_node_or_null("Chapter1Map/Camera")
	if camera == null:
		push_error("Main scene should provide an active map camera")
		quit(1)
		return
	for method_name in ["begin_cutscene_override", "set_cutscene_focus", "end_cutscene_override", "is_cutscene_override_active"]:
		if not camera.has_method(method_name):
			push_error("Camera should expose %s for boss intro cutscenes" % method_name)
			quit(1)
			return

	get_root().add_child(main)
	await process_frame
	var bgm := main.get_node_or_null("BgmPlayer") as AudioStreamPlayer
	if bgm == null or not bgm.has_method("get_bgm_path"):
		push_error("Main should expose BgmPlayer for boss intro music timing")
		quit(1)
		return
	main._switch_map(main.BOSS_INTERIOR_SCENE, "boss_interior", Vector2(220, 640.5), false)
	if bgm.get_bgm_path() != "res://assets/BGMs/general_music.mp3":
		push_error("Boss BGM should not start during the black map transition before intro")
		quit(1)
		return
	camera = main.get_node_or_null("Chapter1Map/Camera")
	if camera == null:
		push_error("Boss interior should provide an active camera for intro")
		quit(1)
		return
	var boss_spawn: Vector2 = main.BOSS_INTERIOR_BOSS_SPAWN
	var reference_boss := main._spawn_enemy(main.BOSS_SCENE, boss_spawn) as Node2D
	if reference_boss == null:
		push_error("Boss intro test should be able to spawn a reference boss")
		quit(1)
		return
	await physics_frame
	var combat_boss_y: float = reference_boss.global_position.y
	reference_boss.queue_free()
	await process_frame
	var boss := main._spawn_enemy(main.BOSS_SCENE, boss_spawn) as Node2D
	if boss == null:
		push_error("Boss intro test should be able to spawn a boss")
		quit(1)
		return
	var player := main.get_node_or_null("Player") as Node2D
	if player == null:
		push_error("Boss intro test should have a player")
		quit(1)
		return
	player.global_position = boss.global_position + Vector2(-240.0, 0.0)
	main._play_boss_intro_cutscene(boss)
	if not bool(main.get("is_boss_intro_playing")):
		push_error("Boss intro should enter playing state immediately")
		quit(1)
		return
	if bgm.get_bgm_path() != "res://assets/BGMs/boss_music.mp3":
		push_error("Boss BGM should start when the 6 second intro starts")
		quit(1)
		return
	if player.is_physics_processing():
		push_error("Boss intro should immediately lock player physics")
		quit(1)
		return
	if boss.is_physics_processing():
		push_error("Boss intro should immediately lock boss physics")
		quit(1)
		return
	if absf(boss.global_position.y - combat_boss_y) > 0.5:
		push_error("Boss intro y-position should match the settled combat y-position")
		quit(1)
		return
	if not top_bar.visible or not bottom_bar.visible:
		push_error("Boss intro should immediately show letterbox bars")
		quit(1)
		return
	if not camera.is_cutscene_override_active():
		push_error("Boss intro should immediately take over the camera")
		quit(1)
		return
	if float(boss.get("facing")) != -1.0:
		push_error("Boss should face the player during the intro")
		quit(1)
		return
	var boss_sprite := boss.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if boss_sprite == null:
		push_error("Boss should expose AnimatedSprite2D for intro pose")
		quit(1)
		return
	if not boss_sprite.flip_h:
		push_error("Boss intro should visually flip Boss toward a player on the left")
		quit(1)
		return
	if boss_sprite.animation != &"walk" or boss_sprite.frame != 0 or not is_zero_approx(boss_sprite.speed_scale):
		push_error("Boss intro should freeze Boss on walk frame 1")
		quit(1)
		return
	for hud_path in ["BossHud", "PlayerVitalsHud", "PlayerPostureHud", "ItemUI"]:
		var hud := main.get_node_or_null(hud_path) as CanvasLayer
		if hud == null:
			push_error("%s should exist for intro visibility" % hud_path)
			quit(1)
			return
		if hud.visible:
			push_error("%s should be hidden during the boss intro" % hud_path)
			quit(1)
			return

	main.queue_free()
	quit(0)
