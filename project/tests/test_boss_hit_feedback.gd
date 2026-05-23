extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Boss.tscn")
	if scene == null:
		push_error("Boss scene should load")
		quit(1)
		return

	var boss = scene.instantiate()
	get_root().add_child(boss)
	await process_frame

	for node_name in ["HitSpark", "PostureBreakSpark", "EnemyHurtSfx"]:
		if not boss.has_node(node_name):
			push_error("Boss should have %s for hit feedback" % node_name)
			quit(1)
			return

	boss.facing = -1.0
	boss.guard_chance = 0.0
	boss.receive_player_attack(8.0, 12.0)
	if boss.hit_spark_timer <= 0.0:
		push_error("Boss should show hit spark after taking player attack")
		quit(1)
		return
	if boss.hit_flash_timer <= 0.0:
		push_error("Boss should flash after taking player attack")
		quit(1)
		return
	if boss.hit_recoil_timer <= 0.0:
		push_error("Boss should recoil after taking player attack")
		quit(1)
		return
	if absf(boss.velocity.x) < 90.0:
		push_error("Boss hit recoil should be visible")
		quit(1)
		return
	if boss.hitstop_timer <= 0.0:
		push_error("Boss should get local hitstop after taking player attack")
		quit(1)
		return

	boss.hitstop_timer = 0.0
	boss._physics_process(0.04)
	if boss.sprite.modulate == Color.WHITE:
		push_error("Boss sprite should visibly flash during hit feedback")
		quit(1)
		return

	boss.queue_free()
	await process_frame
	quit(0)
