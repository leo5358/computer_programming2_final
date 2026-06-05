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
	var save_manager: Node = get_root().get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_method("delete_save"):
		save_manager.delete_save()

	var player: Node2D = main.get_node_or_null("Player")
	var prompt: CanvasItem = main.get_node_or_null("MapTransitionUI/PromptLabel")
	if player == null or prompt == null:
		push_error("Main scene should include player and map transition prompt")
		quit(1)
		return
	var bgm: Node = main.get_node_or_null("BgmPlayer")
	if bgm == null or not bgm.has_method("get_bgm_path"):
		push_error("Main scene should include map-aware BgmPlayer")
		quit(1)
		return
	if bgm.get_bgm_path() != "res://assets/BGMs/general_music.mp3":
		push_error("AB foothill should start with general BGM")
		quit(1)
		return
	if player.global_position.distance_to(Vector2(430, 571)) > 1.0:
		push_error("Player should start grounded on AB foothill")
		quit(1)
		return

	player.global_position = Vector2(15060.0, 571.0)
	await process_frame
	if not prompt.visible:
		push_error("AB foothill exit should show F prompt inside interaction range")
		quit(1)
		return
	if prompt.text != "按下F進入":
		push_error("AB foothill exit should show the new door-enter prompt text")
		quit(1)
		return

	if not main.has_method("_transition_ab_to_h_stone_plaza"):
		push_error("Main scene should expose AB to H stone plaza transition")
		quit(1)
		return

	player.global_position = Vector2(14990.0, 571.0)
	await process_frame
	main._update_map_interaction_prompt()
	if prompt.visible:
		push_error("AB foothill exit prompt should not show outside Door center x ± 300")
		quit(1)
		return
	player.global_position = Vector2(15170.0, 571.0)
	await process_frame
	if not prompt.visible:
		push_error("AB foothill exit prompt should show again inside Door center x ± 300")
		quit(1)
		return
	if main._can_use_ab_exit():
		push_error("AB foothill exit should not trigger interaction outside Door center x ± 150")
		quit(1)
		return
	player.global_position = Vector2(15341.0, 571.0)
	await process_frame
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
	player.global_position.x = 2998.0
	if not player._is_at_world_horizontal_boundary(1.0):
		push_error("H stone plaza should set player climb boundary to x=3000")
		quit(1)
		return
	if bgm.get_bgm_path() != "res://assets/BGMs/general_music.mp3":
		push_error("H stone plaza should keep general BGM after transition")
		quit(1)
		return
	player.global_position = Vector2(2550.0, 530.5)
	var boss_gate_position := player.global_position
	await process_frame
	main._update_map_interaction_prompt()
	if not prompt.visible:
		push_error("H stone plaza exit should show F prompt inside interaction range")
		quit(1)
		return
	if prompt.text != "按下F進入":
		push_error("H stone plaza exit should show the new door-enter prompt text")
		quit(1)
		return
	player.global_position = Vector2(2500.0, 530.5)
	boss_gate_position = player.global_position
	await process_frame
	main._update_map_interaction_prompt()
	if prompt.visible:
		push_error("H stone plaza exit prompt should not show outside ShimenawaCurtain center x ± 300")
		quit(1)
		return
	player.global_position = Vector2(2650.0, 530.5)
	await process_frame
	main._update_map_interaction_prompt()
	if not prompt.visible:
		push_error("H stone plaza exit prompt should show again inside ShimenawaCurtain center x ± 300")
		quit(1)
		return
	if main._can_use_h_stone_plaza_exit():
		push_error("H stone plaza exit should not trigger interaction outside ShimenawaCurtain center x ± 150")
		quit(1)
		return
	player.global_position = Vector2(2825.16, 530.5)
	boss_gate_position = player.global_position

	if not main.has_method("_transition_h_stone_plaza_to_boss_interior"):
		push_error("Main scene should expose H stone plaza to boss interior transition")
		quit(1)
		return

	await main._transition_h_stone_plaza_to_boss_interior()

	if main.get("current_map_id") != "boss_interior":
		push_error("Interacting with H stone plaza exit should switch to boss interior")
		quit(1)
		return
	if save_manager == null or not save_manager.has_save():
		push_error("Entering boss interior should save the boss gate checkpoint")
		quit(1)
		return
	if save_manager.get_saved_map() != "h_stone_plaza":
		push_error("Boss gate checkpoint should save H stone plaza, not boss interior")
		quit(1)
		return
	if save_manager.get_saved_position().distance_to(boss_gate_position) > 1.0:
		push_error("Boss gate checkpoint should restore the player to the F interaction point before boss")
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
	player.global_position.x = 1998.0
	if not player._is_at_world_horizontal_boundary(1.0):
		push_error("Boss interior should set player climb boundary to x=2000")
		quit(1)
		return
	if bgm.get_bgm_path() != "res://assets/BGMs/boss_music.mp3":
		push_error("Boss interior should switch to boss BGM after transition")
		quit(1)
		return
	if bgm.has_method("get_current_loop_start") and not is_equal_approx(bgm.get_current_loop_start(), 6.0):
		push_error("Boss interior BGM should loop from 6 seconds")
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
