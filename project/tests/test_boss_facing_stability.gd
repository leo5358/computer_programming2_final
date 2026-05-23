extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossFacingStabilityTest"
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
	player.global_position = boss.global_position + Vector2(-82.0, 0.0)
	boss.attack_cooldown = 0.8
	boss.facing = -1.0

	var previous_facing: float = boss.facing
	var flips := 0
	for frame in 60:
		await physics_frame
		if boss.facing != previous_facing:
			flips += 1
			previous_facing = boss.facing

	if flips > 0:
		push_error("Boss should hold a stable facing during close-range cooldown instead of flickering")
		quit(1)
		return
	if absf(boss.velocity.x) > 1.0:
		push_error("Boss should hold position near the player during cooldown")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
