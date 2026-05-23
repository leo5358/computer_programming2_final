extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossGapCloseThrustTest"
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
	player.global_position = boss.global_position + Vector2(-165.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)

	if not boss.is_attack_winding_up:
		push_error("Boss should start a gap-close attack when the player is outside normal attack range")
		quit(1)
		return
	if boss.current_attack_animation != "thrust":
		push_error("Boss gap-close attack should use thrust, got %s" % boss.current_attack_animation)
		quit(1)
		return
	if not boss.is_current_attack_perilous():
		push_error("Boss gap-close thrust should be perilous")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-230.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	boss._physics_process(1.0 / 60.0)

	if boss.is_attack_winding_up:
		push_error("Boss should chase instead of thrusting from too far away")
		quit(1)
		return
	if boss.velocity.x * boss.facing <= 0.0:
		push_error("Boss should chase toward the player from outside thrust range")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
