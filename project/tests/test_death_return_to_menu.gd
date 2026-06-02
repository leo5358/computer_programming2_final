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

	quit(0)
