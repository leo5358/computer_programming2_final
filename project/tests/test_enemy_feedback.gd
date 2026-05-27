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
	if enemy.hit_recoil_timer <= 0.0:
		push_error("Enemy should briefly recoil after taking player attack")
		quit(1)
		return
	if abs(enemy.velocity.x) < 80.0:
		push_error("Enemy hit recoil should be visible")
		quit(1)
		return
	if enemy.hit_flash_timer <= 0.0:
		push_error("Enemy should flash bright when player attack lands")
		quit(1)
		return
	if enemy.hit_freeze_timer <= 0.0:
		push_error("Enemy should briefly freeze when player attack lands")
		quit(1)
		return

	enemy.reset_combat_state()
	enemy.is_winding_up = true
	enemy.is_attack_cue_active = true
	enemy.is_attack_active = true
	enemy.attack_visual.visible = true
	enemy.receive_block_feedback(true)
	if enemy.parry_spark_timer <= 0.0:
		push_error("Enemy should show a distinct spark after being parried")
		quit(1)
		return
	if enemy.hit_recoil_timer <= 0.0:
		push_error("Enemy should recoil when its attack is parried")
		quit(1)
		return
	if enemy.is_winding_up or enemy.is_attack_cue_active or enemy.is_attack_active:
		push_error("Perfect parry should interrupt enemy attack state")
		quit(1)
		return
	if enemy.attack_visual.visible:
		push_error("Perfect parry should hide enemy attack visual immediately")
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
