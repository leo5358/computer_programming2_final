extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	get_root().add_child(main)
	var boss = boss_scene.instantiate()
	var player = player_scene.instantiate()
	main.add_child(boss)
	main.add_child(player)
	await process_frame

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-88.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	await physics_frame

	if boss.get("attack_pressure_timer") == null:
		push_error("Boss should expose an attack pressure timer before attacking")
		quit(1)
		return
	if boss.get("attack_pressure_commit_time") == null:
		push_error("Boss should expose attack pressure commit duration")
		quit(1)
		return

	boss._physics_process(0.016)
	if boss.is_attack_winding_up:
		push_error("Boss should not start attacking immediately when entering range")
		quit(1)
		return
	if float(boss.get("attack_pressure_timer")) <= 0.0:
		push_error("Boss should enter a pressure pause before committing to an attack")
		quit(1)
		return

	boss._physics_process(float(boss.get("attack_pressure_commit_time")) + 0.05)
	if not boss.is_attack_winding_up:
		push_error("Boss should commit to an attack after the pressure pause")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-60.0, 0.0)
	boss.posture = boss.max_posture
	boss._break_posture_boss_internal()
	if not boss.can_be_executed():
		push_error("Boss should be executable after posture break")
		quit(1)
		return

	var health_before_followup: float = boss.health
	var result: Variant = boss.receive_player_attack(16.0, 18.0)
	if result != true:
		push_error("Player attack should still connect during boss posture broken state")
		quit(1)
		return
	if boss.defeated_flag:
		push_error("Boss should not die from a weak follow-up hit during posture break")
		quit(1)
		return
	if boss.health >= health_before_followup:
		push_error("Broken boss should take direct health damage from follow-up hits")
		quit(1)
		return
	if not bool(boss.get("posture_break_took_followup_hit_boss")):
		push_error("Broken boss should shorten its reset timer after a follow-up hit")
		quit(1)
		return

	boss.health = 12.0
	result = boss.receive_player_attack(16.0, 18.0)
	if result != true or not bool(boss.defeated_flag) or boss.health > 0.0:
		push_error("Boss should die once a posture-break follow-up fully depletes health")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
