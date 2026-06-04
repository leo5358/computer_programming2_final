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

	var player: Node = main.get_node_or_null("Player")
	if player == null:
		push_error("Main should include player for pause save")
		quit(1)
		return

	if not main.has_method("_save_and_return_to_start_page"):
		push_error("Main should expose save-and-return pause flow")
		quit(1)
		return

	main._open_pause_menu()
	await process_frame
	player.set("spawn_position", Vector2(930, 571))
	main._save_and_return_to_start_page()
	await process_frame

	if paused:
		push_error("Save-and-return should unpause before changing scenes")
		quit(1)
		return
	if save_manager == null or not save_manager.has_save():
		push_error("Save-and-return should preserve a checkpoint save for Continue")
		quit(1)
		return
	if save_manager.get_saved_position().distance_to(Vector2(930, 571)) > 1.0:
		push_error("Save-and-return should save the active checkpoint position before returning")
		quit(1)
		return

	if save_manager.has_method("delete_save"):
		save_manager.delete_save()
	await process_frame
	quit(0)
