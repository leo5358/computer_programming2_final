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
	var save_manager: Node = get_root().get_node_or_null("SaveManager")
	if save_manager == null:
		push_error("SaveManager autoload should exist")
		quit(1)
		return

	for node_path in ["menu_continue", "menu_new_game", "menu_quit", "menu_selector", "menu_selector_glow", "StartPageBgm", "FadeLayer/FadeRect"]:
		if start_page.get_node_or_null(node_path) == null:
			push_error("Start page should include menu node: %s" % node_path)
			quit(1)
			return
	var click_sfx := start_page.get_node_or_null("ButtonClickSfx") as AudioStreamPlayer
	if click_sfx == null or click_sfx.stream == null:
		push_error("Start page should include button click SFX")
		quit(1)
		return
	if click_sfx.stream.resource_path != "res://assets/sfx/buttonClick.MP3":
		push_error("Start page button click SFX should use assets/sfx/buttonClick.MP3")
		quit(1)
		return
	var selector: CanvasItem = start_page.get_node("menu_selector")
	var selector_glow: CanvasItem = start_page.get_node("menu_selector_glow")
	if selector.visible or selector_glow.visible:
		push_error("Start page should not show a selected button before mouse or keyboard input")
		quit(1)
		return
	var clear_color: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color", Color(0.3, 0.3, 0.3, 1.0))
	if clear_color != Color.BLACK:
		push_error("Project clear color should be black to hide the default grey frame during scene transitions")
		quit(1)
		return
	var start_bgm: AudioStreamPlayer = start_page.get_node("StartPageBgm")
	if start_bgm.stream == null:
		push_error("Start page should have BGM stream")
		quit(1)
		return
	if start_bgm.stream.resource_path != "res://assets/audio/BGMs/start_page_music.mp3":
		push_error("Start page should use assets/audio/BGMs/start_page_music.mp3")
		quit(1)
		return
	if "loop" in start_bgm.stream and not bool(start_bgm.stream.loop):
		push_error("Start page BGM should loop")
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
	if not selector.visible or not selector_glow.visible:
		push_error("Mouse hover should reveal the selected button effect")
		quit(1)
		return
	if not start_page.has_method("_on_menu_mouse_exited"):
		push_error("Start page should support clearing mouse hover selection")
		quit(1)
		return
	start_page._on_menu_mouse_exited(2)
	if selector.visible or selector_glow.visible or start_page._selected_index != -1:
		push_error("Mouse exit should clear all selected button effects")
		quit(1)
		return
	save_manager.save_game("h_stone_plaza", Vector2(2850, 530.5), 50.0)
	if not save_manager.has_save():
		push_error("Test should create an existing save before New Game")
		quit(1)
		return
	start_page._selected_index = 1
	start_page._confirm_selection()
	if not click_sfx.playing:
		push_error("Confirming a start page option should play button click SFX")
		quit(1)
		return
	await process_frame
	if save_manager.has_save():
		push_error("New Game should clear existing checkpoint save")
		quit(1)
		return
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
