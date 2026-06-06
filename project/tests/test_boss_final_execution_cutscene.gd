extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	if boss_scene == null or warrior_scene == null:
		push_error("Boss and warrior scenes should load")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)
	var warrior = warrior_scene.instantiate()
	var boss = boss_scene.instantiate()
	root.add_child(warrior)
	root.add_child(boss)
	await process_frame

	warrior.reset_combat_state()
	warrior.guard_chance = 0.0
	warrior.posture = warrior.max_posture - 1.0
	warrior.receive_player_attack(1.0, 999.0)
	var warrior_execute_label := warrior.get_node_or_null("ExecuteLabel") as Label
	if warrior_execute_label != null and warrior_execute_label.visible:
		push_error("Minor enemy execute text should stay hidden when posture is full")
		quit(1)
		return

	boss.reset_combat_state()
	boss.guard_chance = 0.0
	boss.posture = boss.max_posture
	boss._break_posture_boss_internal()
	if not boss.can_be_executed():
		push_error("Boss should be executable after posture break")
		quit(1)
		return

	var execute_label := boss.get_node_or_null("ExecuteLabel") as Label
	if execute_label != null and execute_label.visible:
		push_error("Boss execute text should stay hidden when posture is full")
		quit(1)
		return

	var requested := [false]
	if not boss.has_signal("final_execution_requested"):
		push_error("Boss should expose a final_execution_requested signal")
		quit(1)
		return
	boss.final_execution_requested.connect(func(_boss: Node2D) -> void:
		requested[0] = true
	)

	var result: Variant = boss.receive_player_attack(16.0, 18.0)
	if result != true:
		push_error("Follow-up attack should connect when boss is executable")
		quit(1)
		return
	if not bool(requested[0]):
		push_error("Follow-up attack should request the final execution cutscene")
		quit(1)
		return
	if boss.defeated_flag:
		push_error("Boss should wait for the final execution cutscene before being marked defeated")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
