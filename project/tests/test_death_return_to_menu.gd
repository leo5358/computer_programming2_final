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
	if save_manager == null:
		push_error("SaveManager autoload should exist")
		quit(1)
		return
	save_manager.save_game("ab_foothill", Vector2(1200, 581), 50.0)
	if not save_manager.has_save():
		push_error("Test should create a checkpoint save before returning to menu")
		quit(1)
		return
	if not main.has_method("_return_to_start_page"):
		push_error("Main should expose return to start page death flow")
		quit(1)
		return

	main._return_to_start_page()
	await process_frame
	if save_manager.has_save():
		push_error("Returning to start page from death should reset checkpoint save")
		quit(1)
		return

	main = scene.instantiate()
	get_root().add_child(main)
	await process_frame
	if not main.has_method("_debug_warp_to_boss_interior"):
		push_error("Main should expose debug boss warp for boss death return flow")
		quit(1)
		return
	await main._debug_warp_to_boss_interior()
	await process_frame
	var player: Node = get_first_node_in_group("player")
	var death_overlay: Node = main.get_node_or_null("DeathOverlay")
	if player == null or death_overlay == null:
		push_error("Boss return flow should have player and death overlay")
		quit(1)
		return
	if not main.has_method("_debug_kill_player"):
		push_error("Main should expose debug kill for death overlay flow")
		quit(1)
		return
	main._debug_kill_player()
	await process_frame
	if not bool(death_overlay.get("is_active")):
		push_error("Boss death should activate death overlay before returning to menu")
		quit(1)
		return
	paused = true
	if death_overlay.has_method("confirm_option"):
		death_overlay.confirm_option(1)
	else:
		main._return_to_start_page()
	await process_frame
	if paused:
		push_error("Returning to start page from boss death should leave the tree unpaused")
		quit(1)
		return

	quit(0)
