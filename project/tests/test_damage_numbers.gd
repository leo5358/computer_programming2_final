extends SceneTree

func _initialize() -> void:
	var dummy_scene: PackedScene = load("res://scenes/TrainingDummy.tscn")
	var enemy_scene: PackedScene = load("res://scenes/Enemy.tscn")
	if dummy_scene == null or enemy_scene == null:
		push_error("Damage number test scenes should load")
		quit(1)
		return

	var dummy = dummy_scene.instantiate()
	var enemy = enemy_scene.instantiate()
	get_root().add_child(dummy)
	get_root().add_child(enemy)
	dummy.global_position = Vector2(100, 408)
	enemy.global_position = Vector2(220, 408)
	await process_frame

	dummy.receive_player_attack(16.4, 0.0)
	enemy.receive_player_attack(12.0, 0.0)
	await process_frame

	var damage_numbers := get_nodes_in_group("damage_number")
	if damage_numbers.size() < 2:
		push_error("Training dummy and enemy should spawn floating damage numbers")
		quit(1)
		return

	var saw_dummy_damage := false
	var saw_enemy_damage := false
	for node in damage_numbers:
		if node.has_method("get_text"):
			if node.get_text() == "16":
				saw_dummy_damage = true
			if node.get_text() == "12":
				saw_enemy_damage = true
	if not saw_dummy_damage:
		push_error("Training dummy damage number should show rounded damage")
		quit(1)
		return
	if not saw_enemy_damage:
		push_error("Enemy damage number should show rounded damage")
		quit(1)
		return

	for node in damage_numbers:
		node.queue_free()
	dummy.queue_free()
	enemy.queue_free()
	await process_frame
	quit(0)
