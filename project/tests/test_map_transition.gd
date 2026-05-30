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
	if player.global_position.distance_to(Vector2(220, 408)) > 1.0:
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
	if player.global_position.distance_to(Vector2(220, 595)) > 1.0:
		push_error("Player should spawn at boss interior entrance")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
