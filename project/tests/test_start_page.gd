extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/start_page.tscn")
	if scene == null:
		push_error("Start page scene should load")
		quit(1)
		return

	var start_page: Node = scene.instantiate()
	get_root().add_child(start_page)
	await process_frame

	for node_path in ["menu_continue", "menu_new_game", "menu_quit", "menu_selector", "menu_selector_glow"]:
		if start_page.get_node_or_null(node_path) == null:
			push_error("Start page should include menu node: %s" % node_path)
			quit(1)
			return

	if not start_page.has_method("get_main_scene_path"):
		push_error("Start page should expose new game target path")
		quit(1)
		return

	var main_scene_path: String = start_page.get_main_scene_path()
	if main_scene_path != "res://scenes/Main.tscn":
		push_error("New game should target Main.tscn")
		quit(1)
		return

	if not start_page.has_method("_handle_menu_option"):
		push_error("Start page should handle menu actions")
		quit(1)
		return

	var main_scene: PackedScene = load(main_scene_path)
	if main_scene == null:
		push_error("Start page new game target should load")
		quit(1)
		return

	start_page.queue_free()
	await process_frame
	quit(0)
