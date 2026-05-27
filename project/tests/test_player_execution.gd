extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var enemy_scene: PackedScene = load("res://scenes/Enemy.tscn")
	if player_scene == null or enemy_scene == null:
		push_error("Player and enemy scenes should load")
		quit(1)
		return

	var player: Node2D = player_scene.instantiate()
	var enemy: Node2D = enemy_scene.instantiate()
	get_root().add_child(player)
	get_root().add_child(enemy)
	player.global_position = Vector2.ZERO
	enemy.global_position = Vector2(34.0, 0.0)
	await process_frame
	await physics_frame

	enemy.receive_block_feedback(true)
	enemy.receive_block_feedback(true)
	enemy.receive_block_feedback(true)
	if not enemy.can_be_executed():
		push_error("Enemy should be executable before player attack")
		quit(1)
		return

	player._apply_attack_hit()
	if not enemy.defeated_flag:
		push_error("Player attack should execute broken enemy in attack range")
		quit(1)
		return

	player.set_physics_process(false)
	enemy.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	enemy.queue_free()
	await process_frame
	quit(0)
