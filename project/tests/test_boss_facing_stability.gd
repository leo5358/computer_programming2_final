extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main: Node = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	var boss = main.get_node_or_null("Boss")
	var player = main.get_node_or_null("Player")
	if boss == null or player == null:
		push_error("Main scene should contain boss and player")
		quit(1)
		return

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
