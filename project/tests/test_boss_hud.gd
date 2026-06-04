extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var hud_script: Script = load("res://scripts/boss_hud.gd")
	if boss_scene == null or hud_script == null:
		push_error("Boss scene and Boss HUD script should load")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)
	var boss = boss_scene.instantiate()
	root.add_child(boss)
	var hud: CanvasLayer = CanvasLayer.new()
	hud.set_script(hud_script)
	root.add_child(hud)
	await process_frame

	var hud_root := hud.get_node_or_null("BossHudRoot") as Control
	var health_fill := hud.get_node_or_null("BossHudRoot/HealthFill") as ColorRect
	var posture_fill := hud.get_node_or_null("BossHudRoot/PostureFill") as ColorRect
	var overhead_bars := boss.get_node_or_null("OverheadBars") as Node2D
	if hud_root == null or health_fill == null or posture_fill == null:
		push_error("Boss HUD should build health and posture bars")
		quit(1)
		return
	if overhead_bars != null and overhead_bars.visible:
		push_error("Boss should hide minor-enemy overhead health and posture bars")
		quit(1)
		return
	if hud.get_node_or_null("BossHudRoot/HealthValue") != null or hud.get_node_or_null("BossHudRoot/PostureValue") != null:
		push_error("Boss HUD should not show numeric health or posture values")
		quit(1)
		return

	boss.health = boss.max_health * 0.5
	boss.posture = boss.max_posture * 0.25
	hud._update_stats()
	if not is_equal_approx(health_fill.size.x, hud.current_bar_width * 0.5):
		push_error("Boss HUD health bar should scale by boss max_health")
		quit(1)
		return
	if not is_equal_approx(posture_fill.size.x, hud.current_bar_width * 0.25):
		push_error("Boss HUD posture bar should scale by boss max_posture")
		quit(1)
		return
	boss.defeated_flag = true
	hud._update_stats()
	if hud_root.visible:
		push_error("Boss HUD should hide after boss defeat")
		quit(1)
		return
	boss.defeated_flag = false
	hud._update_stats()
	if not hud_root.visible:
		push_error("Boss HUD should show again when boss state is reset")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
