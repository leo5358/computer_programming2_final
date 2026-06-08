extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var save_manager: Node = get_root().get_node_or_null("SaveManager")
	if save_manager == null:
		push_error("SaveManager autoload should exist for checkpoint reload testing")
		quit(1)
		return
	if save_manager != null and save_manager.has_method("delete_save"):
		save_manager.delete_save()

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
		Vector2(8563, 96),
		Vector2(13751, 83),
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
	var rear_checkpoint_position := rear_checkpoint.global_position
	player.global_position = rear_checkpoint.global_position + Vector2(-250.0, 0.0)
	main._update_map_interaction_prompt()
	if not prompt.visible:
		push_error("Checkpoint should show the rest prompt when player is within 300 pixels")
		quit(1)
		return
	if prompt.text != "按下F在此處休息(存檔)":
		push_error("Checkpoint prompt should show the new rest/save text")
		quit(1)
		return
	player.global_position = rear_checkpoint.global_position
	await process_frame
	if not await main._activate_nearest_checkpoint():
		push_error("F interaction should activate nearby checkpoint")
		quit(1)
		return
	if player.get("spawn_position") != rear_checkpoint.global_position:
		push_error("Main checkpoint activation should update player spawn_position")
		quit(1)
		return
	if not main.has_method("_debug_kill_player") or not main.has_method("_retry_from_checkpoint"):
		push_error("Main should expose death retry flow for checkpoint restoration")
		quit(1)
		return
	save_manager.save_game("ab_foothill", rear_checkpoint_position, 37.0)
	main._debug_kill_player()
	await process_frame
	main._retry_from_checkpoint()
	await process_frame
	player = main.get_node_or_null("Player")
	if player == null:
		push_error("Retry after death should keep or recreate the player")
		quit(1)
		return
	if player.global_position.distance_to(rear_checkpoint_position) > 12.0:
		push_error("Retry after death should restore the last activated checkpoint position")
		quit(1)
		return
	if not is_equal_approx(float(player.get("health")), float(player.get("max_health"))):
		push_error("Retry after death should restore player health to full instead of saved low health")
		quit(1)
		return
	if int(player.get_item_count("kunai")) != 10 or int(player.get_item_count("gourd")) != 10:
		push_error("Checkpoint rest should refill item counts before retry state continues")
		quit(1)
		return
	await main._transition_ab_to_h_stone_plaza()
	if main.get("current_map_id") != "h_stone_plaza":
		push_error("Checkpoint interaction test should be on H stone plaza after transition")
		quit(1)
		return
	var plaza_checkpoint := main.get_node_or_null("Chapter1Map/Checkpoints/CheckpointPlaza") as Node2D
	if plaza_checkpoint == null:
		push_error("H stone plaza should include its plaza checkpoint after transition")
		quit(1)
		return
	if plaza_checkpoint.global_position.distance_to(Vector2(2087, 530)) > 1.0:
		push_error("H stone plaza checkpoint should keep its design position after transition")
		quit(1)
		return
	player.global_position = plaza_checkpoint.global_position + Vector2(250.0, 0.0)
	main._update_map_interaction_prompt()
	if not prompt.visible:
		push_error("H stone plaza checkpoint should show the rest prompt within 300 pixels")
		quit(1)
		return
	player.global_position = plaza_checkpoint.global_position
	await process_frame
	var f_event := InputEventKey.new()
	f_event.keycode = KEY_F
	f_event.pressed = true
	main._input(f_event)
	await process_frame
	await create_timer(3.2).timeout
	if not bool(plaza_checkpoint.get("activated")):
		push_error("H stone plaza checkpoint interaction should activate from the F flow")
		quit(1)
		return
	if save_manager.get_saved_map() != "h_stone_plaza":
		push_error("H stone plaza checkpoint should save plaza progress")
		quit(1)
		return
	if save_manager.get_saved_position().distance_to(plaza_checkpoint.global_position) > 1.0:
		push_error("H stone plaza checkpoint should save the checkpoint position")
		quit(1)
		return

	main.queue_free()
	await process_frame

	save_manager.save_game("ab_foothill", Vector2(13751, 83), 64.0)
	set_meta("load_from_save", true)
	var reloaded_main: Node = scene.instantiate()
	get_root().add_child(reloaded_main)
	await process_frame
	var reloaded_checkpoint_root: Node = reloaded_main.get_node_or_null("Chapter1Map/Checkpoints")
	if reloaded_checkpoint_root == null:
		push_error("Reloaded AB map should include checkpoint nodes")
		quit(1)
		return
	var reloaded_checkpoints := reloaded_checkpoint_root.get_children()
	var restored_checkpoint_found := false
	for checkpoint in reloaded_checkpoints:
		if checkpoint is Node2D and (checkpoint as Node2D).global_position.distance_to(Vector2(13751, 83)) <= 1.0:
			restored_checkpoint_found = bool(checkpoint.get("activated"))
	if not restored_checkpoint_found:
		push_error("Loading from save should initialize the saved checkpoint as activated")
		quit(1)
		return
	var reloaded_player: Node2D = reloaded_main.get_node_or_null("Player")
	if reloaded_player == null or reloaded_player.global_position.distance_to(Vector2(13751, 83)) > 12.0:
		push_error("Loading from save should restore player to saved checkpoint position")
		quit(1)
		return
	reloaded_main.queue_free()
	await process_frame

	quit(0)
