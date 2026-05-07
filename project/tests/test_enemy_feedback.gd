extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Enemy.tscn")
	if scene == null:
		push_error("Enemy scene should load")
		quit(1)
		return

	var enemy = scene.instantiate()
	get_root().add_child(enemy)
	await process_frame

	for node_name in ["HitSpark", "PostureBreakSpark", "EnemyHurtSfx", "PostureBreakSfx", "ExecutionSfx"]:
		if not enemy.has_node(node_name):
			push_error("Enemy should have %s" % node_name)
			quit(1)
			return

	enemy.receive_player_attack(1.0, 1.0)
	if enemy.hit_spark_timer <= 0.0:
		push_error("Enemy should show hit spark after taking player attack")
		quit(1)
		return

	enemy.posture = 99.0
	enemy.receive_player_attack(0.0, 1.0)
	if enemy.posture_break_spark_timer <= 0.0:
		push_error("Enemy should show posture break spark when posture breaks")
		quit(1)
		return

	enemy.execute()
	if not enemy.defeated_flag:
		push_error("Enemy should be defeated by execution")
		quit(1)
		return

	enemy.set_physics_process(false)
	enemy.get_node("AnimatedSprite2D").sprite_frames = null
	enemy.queue_free()
	await process_frame
	quit(0)
