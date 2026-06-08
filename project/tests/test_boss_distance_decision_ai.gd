extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossDistanceDecisionAiTest"
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
	player.global_position = boss.global_position + Vector2(-126.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)
	if boss.is_attack_winding_up:
		push_error("Boss should chase at 126px instead of converting the distance into chop")
		quit(1)
		return
	if not boss.is_chasing:
		push_error("Boss should keep closing distance at 126px")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-165.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)
	if boss.is_attack_winding_up:
		push_error("Boss first engagement should chase at 165px instead of opening with a special attack")
		quit(1)
		return
	boss.has_engaged_player = true
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)
	if not boss.is_attack_winding_up or boss.current_attack_animation != "thrust":
		push_error("Boss should use perilous thrust when an engaged player backs out to 165px")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-310.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	if not boss._should_start_attack():
		push_error("Boss should allow chop gap-close only from far mid-range")
		quit(1)
		return
	boss._start_normal_attack()
	if boss.current_attack_animation != "chop":
		push_error("Boss far mid-range gap closer should be chop")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
