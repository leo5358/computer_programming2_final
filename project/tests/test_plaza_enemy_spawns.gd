extends SceneTree

func _initialize() -> void:
	var plaza_scene: PackedScene = load("res://scenes/maps/chapter1_h_stone_plaza.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if plaza_scene == null or player_scene == null:
		push_error("Plaza map and player scenes should load")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)
	var player: Node2D = player_scene.instantiate()
	player.global_position = Vector2(220, 530.5)
	root.add_child(player)
	var plaza: Node = plaza_scene.instantiate()
	root.add_child(plaza)
	await process_frame
	await process_frame

	var spawn_root: Node = plaza.get_node_or_null("EnemySpawns")
	if spawn_root == null:
		push_error("H stone plaza should own EnemySpawns")
		quit(1)
		return
	var spawn_points := get_nodes_in_group("enemy_spawn_point")
	if spawn_points.size() != 3:
		push_error("H stone plaza should place a Torchman, Warrior, and Archer combo")
		quit(1)
		return
	spawn_points.sort_custom(func(a: Node, b: Node) -> bool:
		return (a as Node2D).global_position.x < (b as Node2D).global_position.x
	)

	var expected_types := ["torchman", "warrior", "archer"]
	for index in expected_types.size():
		if spawn_points[index].get("enemy_type") != expected_types[index]:
			push_error("Plaza spawn point %d should be %s" % [index, expected_types[index]])
			quit(1)
			return
		if not is_equal_approx((spawn_points[index] as Node2D).global_position.y, 530.5):
			push_error("Plaza enemies should spawn on the floor line for horizontal arrows")
			quit(1)
			return

	var torchman := get_first_node_in_group("map_spawned_enemy") as Node
	for enemy in get_nodes_in_group("map_spawned_enemy"):
		if enemy.get("display_name") == "Torchman":
			torchman = enemy
			break
	if torchman == null or not torchman.has_method("can_see_player") or not torchman.can_see_player():
		push_error("Plaza Torchman should see the player immediately on entry")
		quit(1)
		return

	torchman.receive_alert()
	torchman.set("target", player)
	torchman.set("attack_cooldown", 0.0)
	torchman.call("_update_combat_movement")
	if torchman.get("state") != torchman.EnemyState.FLEE:
		push_error("Plaza Torchman should flee first and pull the combo encounter")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
