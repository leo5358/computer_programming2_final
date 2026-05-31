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

	var map: Node = main.get_node_or_null("Chapter1Map")
	if map == null:
		push_error("Main should include AB foothill map")
		quit(1)
		return
	var checkpoint_root: Node = map.get_node_or_null("Checkpoints")
	if checkpoint_root == null:
		push_error("AB foothill map should own its checkpoint nodes")
		quit(1)
		return
	if main.get_node_or_null("Checkpoints") != null:
		push_error("Main should not own map checkpoints directly")
		quit(1)
		return

	var checkpoints := get_nodes_in_group("checkpoint")
	if checkpoints.size() != 3:
		push_error("AB foothill should have front, middle, and rear checkpoints")
		quit(1)
		return
	checkpoints.sort_custom(func(a: Node, b: Node) -> bool:
		return (a as Node2D).global_position.x < (b as Node2D).global_position.x
	)

	var expected_positions := [
		Vector2(1200, 581),
		Vector2(8563, -84),
		Vector2(13751, -101),
	]
	for index in expected_positions.size():
		var checkpoint := checkpoints[index] as Node2D
		if checkpoint == null or checkpoint.global_position.distance_to(expected_positions[index]) > 1.0:
			push_error("Checkpoint %d should be placed at its AB foothill design position" % index)
			quit(1)
			return
		if checkpoint.z_index != 80:
			push_error("Checkpoint %d should render above map art and below characters" % index)
			quit(1)
			return

	if not main.has_method("_activate_nearest_checkpoint"):
		push_error("Main should activate the nearest checkpoint from the F interaction flow")
		quit(1)
		return

	var player: Node2D = main.get_node_or_null("Player")
	var prompt: CanvasItem = main.get_node_or_null("MapTransitionUI/PromptLabel")
	if player == null or prompt == null:
		push_error("Main should include player and prompt")
		quit(1)
		return

	var rear_checkpoint := checkpoints[2] as Node2D
	player.global_position = rear_checkpoint.global_position
	main._update_map_interaction_prompt()
	if not prompt.visible:
		push_error("Checkpoint should show the F prompt when player is nearby")
		quit(1)
		return
	if not main._activate_nearest_checkpoint():
		push_error("F interaction should activate nearby checkpoint")
		quit(1)
		return
	if player.get("spawn_position") != rear_checkpoint.global_position:
		push_error("Main checkpoint activation should update player spawn_position")
		quit(1)
		return
	await main._transition_ab_to_h_stone_plaza()
	if main.get_node_or_null("Chapter1Map/Checkpoints") != null:
		push_error("AB checkpoints should be removed with the AB map after leaving AB foothill")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
