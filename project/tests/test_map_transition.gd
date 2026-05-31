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

	var player: Node2D = main.get_node_or_null("Player")
	var prompt: CanvasItem = main.get_node_or_null("MapTransitionUI/PromptLabel")
	if player == null or prompt == null:
		push_error("Main scene should include player and map transition prompt")
		quit(1)
		return
	if player.global_position.distance_to(Vector2(430, 571)) > 1.0:
		push_error("Player should start grounded on AB foothill")
		quit(1)
		return

	player.global_position.x = 15300.0
	await process_frame
	if not prompt.visible:
		push_error("AB foothill exit should show F prompt inside interaction range")
		quit(1)
		return

	if not main.has_method("_transition_ab_to_h_stone_plaza"):
		push_error("Main scene should expose AB to H stone plaza transition")
		quit(1)
		return

	await main._transition_ab_to_h_stone_plaza()

	if main.get("current_map_id") != "h_stone_plaza":
		push_error("Interacting with AB exit should switch to H stone plaza")
		quit(1)
		return
	if main.get_node_or_null("Chapter1Map/Camera") == null:
		push_error("Next map should provide an active map camera")
		quit(1)
		return
	if player.global_position.distance_to(Vector2(220, 530.5)) > 1.0:
		push_error("Player should spawn at H stone plaza entrance")
		quit(1)
		return
	player.global_position.x = 2850.0
	await process_frame
	main._update_map_interaction_prompt()
	if not prompt.visible:
		push_error("H stone plaza exit should show F prompt inside interaction range")
		quit(1)
		return

	if not main.has_method("_transition_h_stone_plaza_to_boss_interior"):
		push_error("Main scene should expose H stone plaza to boss interior transition")
		quit(1)
		return

	await main._transition_h_stone_plaza_to_boss_interior()

	if main.get("current_map_id") != "boss_interior":
		push_error("Interacting with H stone plaza exit should switch to boss interior")
		quit(1)
		return
	if main.get_node_or_null("Chapter1Map/Camera") == null:
		push_error("Boss interior should provide an active map camera")
		quit(1)
		return
	if player.global_position.distance_to(Vector2(220, 640.5)) > 1.0:
		push_error("Player should spawn at boss interior entrance")
		quit(1)
		return
	if get_nodes_in_group("boss").size() != 1:
		push_error("Entering boss interior through the normal F transition should spawn exactly one Boss")
		quit(1)
		return

	main._spawn_enemy(main.WARRIOR_SCENE, Vector2(460, 360))
	main._spawn_enemy(main.BOSS_SCENE, Vector2(820, 360))
	await process_frame
	if not main.has_method("_debug_warp_to_boss_interior"):
		push_error("Main scene should expose debug boss interior warp")
		quit(1)
		return

	await main._debug_warp_to_boss_interior()

	if main.get("current_map_id") != "boss_interior":
		push_error("Debug boss warp should switch directly to boss interior")
		quit(1)
		return
	if get_nodes_in_group("minor_enemy").size() != 0:
		push_error("Debug boss warp should clear old minor enemies")
		quit(1)
		return
	if get_nodes_in_group("boss").size() != 1:
		push_error("Debug boss warp should spawn exactly one Boss")
		quit(1)
		return
	var boss: Node2D = get_nodes_in_group("boss")[0] as Node2D
	if boss.global_position.x <= player.global_position.x:
		push_error("Debug boss warp should place Boss on the right side of the arena")
		quit(1)
		return
	if player.global_position.distance_to(Vector2(220, 640.5)) > 1.0:
		push_error("Debug boss warp should place player at boss interior entrance")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
