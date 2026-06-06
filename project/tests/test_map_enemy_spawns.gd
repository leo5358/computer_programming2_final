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
	var expected_spawns := {
		Vector2(2197, 475.5): "warrior",
		Vector2(3798, 79.9): "archer",
		Vector2(6548, 273.4): "archer",
		Vector2(5687.1, 499.4): "torchman",
		Vector2(4829.4, 491.4): "torchman",
		Vector2(8083, 627.7): "warrior",
		Vector2(12581, 262.7): "archer",
		Vector2(11808, 262.7): "torchman",
		Vector2(15004, -119.3): "warrior",
		Vector2(10236, -240.4): "archer",
	}
	if spawn_points.size() != expected_spawns.size():
		push_error("AB foothill should have %d enemy spawn points, found %d" % [expected_spawns.size(), spawn_points.size()])
		quit(1)
		return
	for spawn_point in spawn_points:
		if not spawn_point is Node2D:
			push_error("AB foothill spawn point should be Node2D")
			quit(1)
			return
		var position := (spawn_point as Node2D).position
		if not expected_spawns.has(position):
			push_error("Unexpected AB foothill spawn point at %s" % position)
			quit(1)
			return
		var expected_type: String = expected_spawns[position]
		if String(spawn_point.get("enemy_type")) != expected_type:
			push_error("Spawn at %s should be %s, found %s" % [position, expected_type, spawn_point.get("enemy_type")])
			quit(1)
			return

	var map_enemies := get_nodes_in_group("map_spawned_enemy")
	if map_enemies.size() != spawn_points.size():
		push_error("AB foothill should create one map enemy for each spawn point")
		quit(1)
		return

	main._spawn_enemy(main.WARRIOR_SCENE, Vector2(460, 360))
	main._spawn_enemy(main.BOSS_SCENE, Vector2(820, 360))
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != spawn_points.size() + 1:
		push_error("Debug Warrior should be added alongside AB foothill map enemies")
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
		push_error("Runtime reset should restore AB foothill map enemies")
		quit(1)
		return
	if get_nodes_in_group("boss").size() != 0:
		push_error("Runtime reset should clear debug-spawned bosses")
		quit(1)
		return
	if get_nodes_in_group("minor_enemy").size() != spawn_points.size():
		push_error("Runtime reset should clear debug minor enemies and keep AB foothill map enemies")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
