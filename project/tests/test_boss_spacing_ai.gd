extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossSpacingAiTest"
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
	player.global_position = boss.global_position + Vector2(-38.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	var boss_x_before_spacing: float = boss.global_position.x
	boss._physics_process(1.0 / 60.0)

	if boss.is_attack_winding_up:
		push_error("Boss should not start a long-weapon attack while the player is face-hugging")
		quit(1)
		return
	if (boss.global_position.x - boss_x_before_spacing) * boss.facing >= 0.0:
		push_error("Boss should step backward when the player is too close, moved %.2f facing=%.1f distance=%.2f" % [boss.global_position.x - boss_x_before_spacing, boss.facing, absf(player.global_position.x - boss.global_position.x)])
		quit(1)
		return
	if boss.current_animation != "walk":
		push_error("Boss close-range spacing step should use walk animation")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-104.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)

	if boss.is_attack_winding_up:
		push_error("Boss should pause before attacking from long-weapon sweet spot distance")
		quit(1)
		return
	if float(boss.get("attack_pressure_timer")) <= 0.0:
		push_error("Boss should show attack pressure before committing from sweet spot distance")
		quit(1)
		return
	boss._physics_process(float(boss.get("attack_pressure_commit_time")) + 0.001)
	if not boss.is_attack_winding_up:
		push_error("Boss should attack after pressure pause at long-weapon sweet spot distance")
		quit(1)
		return
	if boss.current_attack_animation != "attack":
		push_error("Boss first sweet-spot attack should use the standard attack profile")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
