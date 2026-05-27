extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Enemy.tscn")
	if scene == null:
		push_error("Enemy scene should load")
		quit(1)
		return

	var enemy: Node = scene.instantiate()
	get_root().add_child(enemy)
	await process_frame

	enemy.receive_block_feedback(true)
	enemy.receive_block_feedback(true)
	enemy.receive_block_feedback(true)
	if enemy.defeated_flag:
		push_error("Enemy should not be defeated immediately when posture breaks")
		quit(1)
		return
	if not enemy.can_be_executed():
		push_error("Enemy should become executable when posture breaks")
		quit(1)
		return
	if enemy.health <= 0.0:
		push_error("Enemy should keep health until execution")
		quit(1)
		return

	enemy.execute()
	if not enemy.defeated_flag:
		push_error("Execution should defeat enemy")
		quit(1)
		return

	enemy.queue_free()
	await process_frame
	quit(0)
