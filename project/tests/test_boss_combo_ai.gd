extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossComboAiTest"
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
	player.global_position = boss.global_position + Vector2(-104.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)
	if boss.current_attack_animation != "attack":
		push_error("Boss should open with standard attack at sweet-spot range")
		quit(1)
		return

	boss.attack_elapsed = boss.attack_animation_total_time - 0.001
	boss._update_attack_state(0.002)
	if boss.get("pending_combo_followup") == null:
		push_error("Boss should expose pending_combo_followup for combo AI")
		quit(1)
		return
	if boss.get("combo_link_delay") == null:
		push_error("Boss should expose combo_link_delay for combo AI")
		quit(1)
		return
	if boss.get("attack_chain_count") == null:
		push_error("Boss should expose attack_chain_count for combo AI")
		quit(1)
		return
	if not boss.is_attack_recovering:
		push_error("Boss should enter a brief combo link recovery after first attack")
		quit(1)
		return
	if not bool(boss.get("pending_combo_followup")):
		push_error("Boss should queue a second swing when player remains in sweet-spot range")
		quit(1)
		return

	boss._update_attack_state(float(boss.get("combo_link_delay")) + 0.001)
	if not boss.is_attack_winding_up:
		push_error("Boss should start the queued second swing after combo link delay")
		quit(1)
		return
	if int(boss.get("attack_chain_count")) != 2:
		push_error("Boss second swing should increment attack_chain_count to 2")
		quit(1)
		return

	boss.attack_elapsed = boss.attack_animation_total_time - 0.001
	boss._update_attack_state(0.002)
	if bool(boss.get("pending_combo_followup")):
		push_error("Boss should not queue a third normal swing")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-104.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss._start_normal_attack("attack")
	boss.receive_block_feedback(true)
	if bool(boss.get("pending_combo_followup")) or int(boss.get("attack_chain_count")) != 0:
		push_error("Perfect parry should cancel Boss combo pressure")
		quit(1)
		return
	if boss.get("perfect_parry_cooldown") == null:
		push_error("Boss should expose perfect_parry_cooldown for parry reward AI")
		quit(1)
		return
	if boss.attack_cooldown < float(boss.get("perfect_parry_cooldown")) - 0.001:
		push_error("Perfect parry should force a longer Boss cooldown window")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-104.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss.receive_block_feedback(false)
	boss.receive_block_feedback(false)
	boss.feedback_timer = 0.0
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)
	if boss.current_attack_animation != "chop":
		push_error("Repeated non-perfect guard should make Boss answer with chop, got %s" % boss.current_attack_animation)
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
