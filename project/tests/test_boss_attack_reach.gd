extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossAttackReachTest"
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
	player.global_position = boss.global_position + Vector2(-boss.attack_start_distance, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0

	for frame in 90:
		await physics_frame
		if boss.attack_has_connected:
			break

	if not boss.attack_has_connected:
		push_error("Boss standard attack should reach a stationary player at attack_start_distance %.1f" % boss.attack_start_distance)
		quit(1)
		return
	if player.health >= player.max_health:
		push_error("Boss standard attack connection should damage a stationary player")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
