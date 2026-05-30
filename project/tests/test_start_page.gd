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

	for node_path in ["menu_continue", "menu_new_game", "menu_quit", "menu_selector", "menu_selector_glow", "StartPageBgm", "FadeLayer/FadeRect"]:
		if start_page.get_node_or_null(node_path) == null:
			push_error("Start page should include menu node: %s" % node_path)
			quit(1)
			return
	var start_bgm: AudioStreamPlayer = start_page.get_node("StartPageBgm")
	if start_bgm.stream == null:
		push_error("Start page should have BGM stream")
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
	if not start_page.has_method("_confirm_selection"):
		push_error("Start page should confirm menu actions safely")
		quit(1)
		return
	if not start_page.has_method("_on_menu_mouse_entered"):
		push_error("Start page should support mouse hover selection")
		quit(1)
		return

	var main_scene: PackedScene = load(main_scene_path)
	if main_scene == null:
		push_error("Start page new game target should load")
		quit(1)
		return
	start_page._on_menu_mouse_entered(2)
	if start_page._selected_index != 2:
		push_error("Mouse hover should update selected menu item")
		quit(1)
		return
	start_page._selected_index = 1
	start_page._confirm_selection()
	await process_frame
	if start_page.get_tree() == null:
		push_error("New game should wait before changing scenes")
		quit(1)
		return
	for frame in 70:
		await process_frame
	if get_root().get_child_count() == 0:
		push_error("Confirming new game should not break the scene tree")
		quit(1)
		return

	start_page.queue_free()
	await process_frame
	quit(0)
