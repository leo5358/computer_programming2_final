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

	var boss: Node2D = main.get_node_or_null("Boss") as Node2D
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	if boss == null or player == null:
		push_error("Main scene should contain boss and player")
		quit(1)
		return

	boss.global_position = player.global_position + Vector2(90.0, 0.0)
	boss.current_boss_attack = boss.BossAttack.CHOP
	boss._start_attack_windup()
	for frame in 180:
		await physics_frame

	main.queue_free()
	await process_frame
	quit(0)
