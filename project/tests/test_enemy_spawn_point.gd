extends SceneTree

func _initialize() -> void:
	var spawn_point_scene_script: Script = load("res://scripts/enemy_spawn_point.gd")
	if spawn_point_scene_script == null:
		push_error("EnemySpawnPoint script should load")
		quit(1)
		return

	var root := Node2D.new()
	get_root().add_child(root)

	var spawn_point := Node2D.new()
	spawn_point.set_script(spawn_point_scene_script)
	spawn_point.set("enemy_type", "warrior")
	spawn_point.set("spawn_on_ready", false)
	spawn_point.set("facing", -1.0)
	spawn_point.global_position = Vector2(640, 360)
	root.add_child(spawn_point)
	await process_frame

	if not spawn_point.is_in_group("enemy_spawn_point"):
		push_error("EnemySpawnPoint should register itself for map reset")
		quit(1)
		return
	if not spawn_point.has_method("respawn_enemy"):
		push_error("EnemySpawnPoint should expose respawn_enemy")
		quit(1)
		return
	if not spawn_point.has_method("despawn_enemy"):
		push_error("EnemySpawnPoint should expose despawn_enemy")
		quit(1)
		return

	var enemy: Node = spawn_point.respawn_enemy()
	if enemy == null or not is_instance_valid(enemy):
		push_error("EnemySpawnPoint should spawn an enemy instance")
		quit(1)
		return
	if not enemy.is_in_group("minor_enemy"):
		push_error("Spawned Warrior should enter the minor_enemy group")
		quit(1)
		return
	if not enemy.is_in_group("map_spawned_enemy"):
		push_error("Map-spawned enemies should be distinguishable from debug-spawned enemies")
		quit(1)
		return
	if (enemy as Node2D).global_position.distance_to(Vector2(640, 360)) > 1.0:
		push_error("Spawned enemy should appear at the spawn point position")
		quit(1)
		return
	if enemy.get("facing") != -1.0:
		push_error("Spawned enemy should inherit the spawn point facing")
		quit(1)
		return
	await process_frame

	var same_enemy: Node = spawn_point.respawn_enemy()
	await process_frame
	if same_enemy != enemy:
		push_error("Respawning while the enemy is alive should not duplicate it")
		quit(1)
		return
	if get_nodes_in_group("map_spawned_enemy").size() != 1:
		push_error("Alive spawn point should own exactly one map-spawned enemy")
		quit(1)
		return

	spawn_point.despawn_enemy()
	await process_frame
	if get_nodes_in_group("map_spawned_enemy").size() != 0:
		push_error("Despawning should remove the active map enemy")
		quit(1)
		return

	root.queue_free()
	await process_frame
	quit(0)
