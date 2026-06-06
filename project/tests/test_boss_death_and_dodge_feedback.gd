extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	if boss_scene == null:
		push_error("Boss scene should load")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)
	var boss = boss_scene.instantiate()
	root.add_child(boss)
	await process_frame

	boss.reset_combat_state()
	boss.posture = boss.max_posture
	boss.execute()
	var executed_y: float = boss.global_position.y
	boss._physics_process(0.25)
	if int(boss.collision_layer) != 0 or int(boss.collision_mask) != 0:
		push_error("Executed boss corpse should not collide or be pushable")
		quit(1)
		return
	if absf(boss.global_position.y - executed_y) > 0.01:
		push_error("Executed boss corpse should stay fixed instead of falling")
		quit(1)
		return

	boss.reset_combat_state()
	boss.complete_final_execution_death()
	var final_executed_y: float = boss.global_position.y
	boss._physics_process(0.25)
	if int(boss.collision_layer) != 0 or int(boss.collision_mask) != 0:
		push_error("Final-executed boss corpse should not collide or be pushable")
		quit(1)
		return
	if absf(boss.global_position.y - final_executed_y) > 0.01:
		push_error("Final-executed boss corpse should stay fixed instead of falling")
		quit(1)
		return

	boss.reset_combat_state()
	boss.posture = boss.max_posture - boss.dodge_posture_damage
	boss.receive_dodge_feedback()
	if not boss.posture_broken:
		push_error("Perfect dodge feedback should posture-break the boss through boss-specific logic")
		quit(1)
		return
	if float(boss.get("posture_break_reset_timer_boss")) <= 0.0:
		push_error("Boss dodge posture break should set the boss reset timer")
		quit(1)
		return
	boss._physics_process(0.016)
	if not boss.posture_broken or boss.posture <= 0.0:
		push_error("Boss posture should not immediately reset after dodge-triggered posture break")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
