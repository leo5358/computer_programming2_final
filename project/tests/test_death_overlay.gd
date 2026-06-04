extends SceneTree

func _initialize() -> void:
	var overlay_script: Script = load("res://scripts/death_overlay.gd")
	if overlay_script == null:
		push_error("Death overlay script should load")
		quit(1)
		return

	var overlay: CanvasLayer = overlay_script.new()
	get_root().add_child(overlay)
	await process_frame

	if overlay.visible:
		push_error("Death overlay should start hidden")
		quit(1)
		return
	if not overlay.has_method("show_death"):
		push_error("Death overlay should expose show_death")
		quit(1)
		return
	if not overlay.has_method("confirm_selection"):
		push_error("Death overlay should expose confirm_selection")
		quit(1)
		return
	if not overlay.has_method("move_selection"):
		push_error("Death overlay should expose move_selection")
		quit(1)
		return
	if not overlay.has_method("select_option") or not overlay.has_method("confirm_option"):
		push_error("Death overlay should expose mouse option selection and confirmation helpers")
		quit(1)
		return

	overlay.show_death()
	await process_frame
	if not overlay.visible or not bool(overlay.get("is_active")):
		push_error("Death overlay should become active after player death")
		quit(1)
		return

	var title: Label = overlay.get_node_or_null("Content/Box/TitleLabel")
	var options_container := overlay.get_node_or_null("Content/Box/Options")
	var retry: Label = overlay.get_node_or_null("Content/Box/Options/RetryLabel")
	var menu: Label = overlay.get_node_or_null("Content/Box/Options/MainMenuLabel")
	var click_sfx := overlay.get_node_or_null("ButtonClickSfx") as AudioStreamPlayer
	if title == null or retry == null or menu == null:
		push_error("Death overlay should build title and two option labels")
		quit(1)
		return
	if click_sfx == null or click_sfx.stream == null:
		push_error("Death overlay should include button click SFX")
		quit(1)
		return
	if click_sfx.stream.resource_path != "res://assets/sfx/buttonClick.MP3":
		push_error("Death overlay button click SFX should use assets/sfx/buttonClick.MP3")
		quit(1)
		return
	if not (options_container is VBoxContainer):
		push_error("Death overlay options should be stacked vertically")
		quit(1)
		return
	if title.text != "心音斷絕":
		push_error("Death overlay title should be 心音斷絕")
		quit(1)
		return
	if not retry.text.contains("重新挑戰") or not menu.text.contains("返回主選單"):
		push_error("Death overlay options should include retry and main menu")
		quit(1)
		return

	var signal_counts := {"retry": 0, "menu": 0}
	overlay.retry_requested.connect(func() -> void: signal_counts["retry"] += 1)
	overlay.main_menu_requested.connect(func() -> void: signal_counts["menu"] += 1)

	overlay.confirm_selection()
	if int(signal_counts["retry"]) != 1:
		push_error("Default death overlay selection should retry")
		quit(1)
		return
	if not click_sfx.playing:
		push_error("Confirming a death overlay option should play button click SFX")
		quit(1)
		return

	overlay.show_death()
	overlay.move_selection(1)
	overlay.confirm_selection()
	if int(signal_counts["menu"]) != 1:
		push_error("Moving death overlay selection once should choose main menu")
		quit(1)
		return
	
	overlay.show_death()
	overlay.select_option(overlay.OPTION_MAIN_MENU)
	if int(overlay.get("selected_index")) != overlay.OPTION_MAIN_MENU:
		push_error("Mouse hovering death overlay main menu should select it")
		quit(1)
		return
	overlay.confirm_option(overlay.OPTION_MAIN_MENU)
	if int(signal_counts["menu"]) != 2:
		push_error("Mouse clicking death overlay main menu should confirm it")
		quit(1)
		return

	overlay.queue_free()
	await process_frame
	quit(0)
