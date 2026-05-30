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

	if main.get_node_or_null("Boss") != null:
		push_error("Enemy test field should start without default Boss")
		quit(1)
		return
	if main.get_node_or_null("TrainingDummy") != null:
		push_error("Enemy test field should not include the old default TrainingDummy")
		quit(1)
		return
	if main.get_node_or_null("Chapter1Map") == null:
		push_error("Enemy test field should include the chapter 1 foothill stairs map")
		quit(1)
		return

	main._spawn_enemy(main.WARRIOR_SCENE, Vector2(460, 360))
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != 1:
		push_error("Spawner should create a minor enemy")
		quit(1)
		return

	var enemy: Node = get_nodes_in_group("minor_enemy")[0]
	if not enemy.has_method("get_vision_rect"):
		push_error("Spawned enemy should expose vision rect for debug mode")
		quit(1)
		return

	var runtime: Node = get_nodes_in_group("combat_runtime")[0]
	runtime.reset_combat()
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != 0:
		push_error("Runtime reset should clear spawned minor enemies in test mode")
		quit(1)
		return

	main._spawn_enemy(main.BOSS_SCENE, Vector2(820, 360))
	await process_frame
	if get_nodes_in_group("boss").size() != 1:
		push_error("Spawner should create a Boss")
		quit(1)
		return

	main.reset_test_field()
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != 0 or get_nodes_in_group("boss").size() != 0:
		push_error("Reset should clear all spawned enemies and bosses")
		quit(1)
		return
	if main.get_node_or_null("TrainingDummy") != null:
		push_error("Reset should not recreate the removed TrainingDummy reference object")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
