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
	if spawn_points.size() != 0:
		push_error("AB foothill should start with no enemy spawn points while encounters are being re-placed")
		quit(1)
		return

	var map_enemies := get_nodes_in_group("map_spawned_enemy")
	if map_enemies.size() != spawn_points.size():
		push_error("AB foothill should not create map enemies when no spawn points are placed")
		quit(1)
		return

	main._spawn_enemy(main.WARRIOR_SCENE, Vector2(460, 360))
	main._spawn_enemy(main.BOSS_SCENE, Vector2(820, 360))
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != 1:
		push_error("Debug Warrior should still be added when AB foothill has no map enemies")
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
		push_error("Runtime reset should leave AB foothill map enemies empty")
		quit(1)
		return
	if get_nodes_in_group("boss").size() != 0:
		push_error("Runtime reset should clear debug-spawned bosses")
		quit(1)
		return
	if get_nodes_in_group("minor_enemy").size() != spawn_points.size():
		push_error("Runtime reset should clear all minor enemies when AB foothill has no map spawns")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
