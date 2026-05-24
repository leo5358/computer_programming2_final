extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Boss.tscn")
	if scene == null:
		push_error("Boss scene should load")
		quit(1)
		return

	var boss = scene.instantiate()
	get_root().add_child(boss)
	await process_frame

	if boss.get("posture_recovery_rate") == null:
		push_error("Boss should expose posture_recovery_rate")
		quit(1)
		return
	if boss.get("posture_recovery_pause") == null:
		push_error("Boss should expose posture_recovery_pause")
		quit(1)
		return
	if boss.get("posture_broken") == null:
		push_error("Boss should expose posture_broken state")
		quit(1)
		return

	boss.guard_chance = 0.0
	boss.posture = 80.0
	boss.posture_recovery_pause_timer = 0.0
	boss.health = boss.max_health
	boss._physics_process(1.0)
	if boss.posture >= 80.0:
		push_error("Boss posture should recover over time when pressure has stopped")
		quit(1)
		return

	boss.reset_combat_state()
	boss.guard_chance = 0.0
	boss.receive_block_feedback(true)
	boss.receive_block_feedback(true)
	boss.receive_block_feedback(true)
	boss.receive_block_feedback(true)
	boss.receive_block_feedback(true)
	boss.receive_block_feedback(true)
	if not boss.posture_broken:
		push_error("Boss should enter posture-broken state when posture reaches max")
		quit(1)
		return
	if not boss.can_be_executed():
		push_error("Boss posture-broken state should make execution available")
		quit(1)
		return
	if boss.current_animation != "hurt" and boss.current_animation != "deflect1" and boss.current_animation != "deflect2":
		push_error("Boss posture break should leave a readable stunned/parried animation")
		quit(1)
		return

	boss.reset_combat_state()
	if boss.posture_broken or boss.can_be_executed():
		push_error("Boss reset should clear posture-broken execution state")
		quit(1)
		return

	boss.queue_free()
	await process_frame
	quit(0)
