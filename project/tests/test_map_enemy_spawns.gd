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
	await process_frame

	var map: Node = main.get_node_or_null("Chapter1Map")
	if map == null:
		push_error("Main should include the AB foothill map")
		quit(1)
		return
	var spawn_root: Node = map.get_node_or_null("EnemySpawns")
	if spawn_root == null:
		push_error("AB foothill map should own EnemySpawns")
		quit(1)
		return

	var spawn_points := get_nodes_in_group("enemy_spawn_point")
	if spawn_points.size() != 6:
		push_error("AB foothill should place six enemy spawn points for the first encounter pass")
		quit(1)
		return
	spawn_points.sort_custom(func(a: Node, b: Node) -> bool:
		return (a as Node2D).global_position.x < (b as Node2D).global_position.x
	)

	var expected_types := ["warrior", "torchman", "warrior", "torchman", "warrior", "archer"]
	for index in expected_types.size():
		if spawn_points[index].get("enemy_type") != expected_types[index]:
			push_error("Spawn point %d should be %s" % [index, expected_types[index]])
			quit(1)
			return
	var ab_archer := spawn_points[5] as Node2D
	if ab_archer.global_position.x > 14000.0 or ab_archer.global_position.y < 300.0:
		push_error("AB foothill exit Archer should stand on the lower flat before the final stairs")
		quit(1)
		return

	var map_enemies := get_nodes_in_group("map_spawned_enemy")
	if map_enemies.size() != spawn_points.size():
		push_error("AB foothill spawn points should create one map enemy each")
		quit(1)
		return

	main._spawn_enemy(main.WARRIOR_SCENE, Vector2(460, 360))
	main._spawn_enemy(main.BOSS_SCENE, Vector2(820, 360))
	await process_frame
	if get_nodes_in_group("minor_enemy").size() <= map_enemies.size():
		push_error("Debug Warrior should be added on top of map enemies")
		quit(1)
		return
	if get_nodes_in_group("boss").size() != 1:
		push_error("Debug Boss should spawn before reset")
		quit(1)
		return

	main.reset_test_field()
	await process_frame
	await process_frame
	if get_nodes_in_group("map_spawned_enemy").size() != spawn_points.size():
		push_error("Runtime reset should respawn the AB foothill map enemies")
		quit(1)
		return
	if get_nodes_in_group("boss").size() != 0:
		push_error("Runtime reset should clear debug-spawned bosses")
		quit(1)
		return
	if get_nodes_in_group("minor_enemy").size() != spawn_points.size():
		push_error("Runtime reset should leave only map-spawned minor enemies")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
