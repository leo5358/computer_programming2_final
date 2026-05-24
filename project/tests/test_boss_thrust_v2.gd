extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossThrustV2Test"
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
	player.global_position = boss.global_position + Vector2(-260.0, 0.0)
	boss.facing = -1.0
	boss._start_normal_attack("thrust")
	await physics_frame

	var attack_area := boss.get_node_or_null("AttackArea") as Area2D
	var attack_shape_node := boss.get_node_or_null("AttackArea/CollisionShape2D") as CollisionShape2D
	var attack_shape := attack_shape_node.shape as RectangleShape2D if attack_shape_node != null else null
	if attack_area == null or attack_shape == null:
		push_error("Boss should expose thrust hitbox")
		quit(1)
		return
	if attack_shape.size.x < 130.0:
		push_error("Boss thrust should use a longer spear hitbox than normal attack")
		quit(1)
		return
	if absf(attack_area.position.x) < 58.0:
		push_error("Boss thrust hitbox should be placed far forward")
		quit(1)
		return

	var boss_x_before_thrust: float = boss.global_position.x
	boss.hitstop_timer = 0.0
	boss.attack_elapsed = 0.760
	boss._physics_process(0.050)
	if absf(boss.global_position.x - boss_x_before_thrust) < 5.0:
		push_error("Boss thrust should visibly lunge forward before the hit frame")
		quit(1)
		return

	boss.reset_combat_state()
	for index in 3:
		boss.receive_block_feedback(true)
		boss.hitstop_timer = 0.0
		boss.feedback_timer = 0.0
	if boss.posture >= boss.max_posture:
		push_error("Boss should not be posture-broken by only three perfect parries")
		quit(1)
		return
	if boss.max_posture < 150.0:
		push_error("Boss should have boss-level posture durability")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
