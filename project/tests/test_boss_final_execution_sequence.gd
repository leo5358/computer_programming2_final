extends SceneTree

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	if main_scene == null or boss_scene == null:
		push_error("Main and Boss scenes should load")
		quit(1)
		return

	var main = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	await physics_frame

	if not main.has_method("_play_boss_final_execution_cutscene"):
		push_error("Main should expose the boss final execution cutscene")
		quit(1)
		return

	var boss := boss_scene.instantiate() as Node2D
	main.add_child(boss)
	boss.global_position = Vector2(760.0, 529.0)
	var player := main.get_node_or_null("Player") as Node2D
	if player != null:
		player.global_position = boss.global_position + Vector2(-96.0, 0.0)
	await process_frame

	var bgm := main.get_node_or_null("BgmPlayer") as AudioStreamPlayer
	var bgm_before := bgm.volume_db if bgm != null else 0.0
	var camera := main.get_node_or_null("Chapter1Map/Camera") as Camera2D
	var top_bar := main.get_node_or_null("MapTransitionUI/BossIntroOverlay/TopLetterbox") as ColorRect
	var bottom_bar := main.get_node_or_null("MapTransitionUI/BossIntroOverlay/BottomLetterbox") as ColorRect

	main._play_boss_final_execution_cutscene(boss)
	await process_frame
	if not bool(main.get("is_boss_final_execution_playing")):
		push_error("Final execution cutscene should mark itself active immediately")
		quit(1)
		return
	if top_bar == null or bottom_bar == null or not top_bar.visible or not bottom_bar.visible:
		push_error("Final execution should show letterbox bars")
		quit(1)
		return
	if camera == null or not camera.has_method("is_cutscene_override_active") or not camera.is_cutscene_override_active():
		push_error("Final execution should take over the camera")
		quit(1)
		return
	if bgm != null and bgm.volume_db >= bgm_before:
		push_error("Final execution should duck the BGM for the hollow hit moment")
		quit(1)
		return
	if player != null and player.is_physics_processing():
		push_error("Final execution should lock player control")
		quit(1)
		return
	if boss.is_physics_processing():
		push_error("Final execution should freeze boss AI")
		quit(1)
		return

	while bool(main.get("is_boss_final_execution_playing")):
		await process_frame

	if not bool(boss.get("defeated_flag")):
		push_error("Boss should be defeated after the final execution cutscene finishes")
		quit(1)
		return
	if top_bar.visible or bottom_bar.visible:
		push_error("Final execution should hide letterbox bars after zooming out")
		quit(1)
		return
	if bgm != null and bgm.volume_db >= bgm_before:
		push_error("Final execution should start fading out BGM after the ritual")
		quit(1)
		return
	if player != null and not player.is_physics_processing():
		push_error("Final execution should unlock player control")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
