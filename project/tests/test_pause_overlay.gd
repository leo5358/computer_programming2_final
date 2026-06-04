extends SceneTree

func _initialize() -> void:
	var overlay_script: Script = load("res://scripts/pause_overlay.gd")
	if overlay_script == null:
		push_error("Pause overlay script should load")
		quit(1)
		return

	var overlay: CanvasLayer = overlay_script.new()
	get_root().add_child(overlay)
	await process_frame

	if overlay.visible:
		push_error("Pause overlay should start hidden")
		quit(1)
		return
	if overlay.process_mode != Node.PROCESS_MODE_ALWAYS:
		push_error("Pause overlay should keep processing while the tree is paused")
		quit(1)
		return
	if not overlay.has_signal("resume_requested"):
		push_error("Pause overlay should emit resume_requested")
		quit(1)
		return
	if not overlay.has_signal("save_and_menu_requested"):
		push_error("Pause overlay should emit save_and_menu_requested")
		quit(1)
		return
	if not overlay.has_method("show_pause") or not overlay.has_method("hide_pause"):
		push_error("Pause overlay should expose show_pause and hide_pause")
		quit(1)
		return
	if not overlay.has_method("select_option") or not overlay.has_method("confirm_option"):
		push_error("Pause overlay should expose mouse option selection and confirmation helpers")
		quit(1)
		return

	overlay.show_pause()
	await process_frame
	if not overlay.visible or not bool(overlay.get("is_active")):
		push_error("Pause overlay should become active when opened")
		quit(1)
		return

	var title: Label = overlay.get_node_or_null("Content/Box/TitleLabel")
	var resume: Label = overlay.get_node_or_null("Content/Box/Options/ResumeLabel")
	var save_menu: Label = overlay.get_node_or_null("Content/Box/Options/SaveMenuLabel")
	var click_sfx := overlay.get_node_or_null("ButtonClickSfx") as AudioStreamPlayer
	if title == null or resume == null or save_menu == null:
		push_error("Pause overlay should build title and two option labels")
		quit(1)
		return
	if click_sfx == null or click_sfx.stream == null:
		push_error("Pause overlay should include button click SFX")
		quit(1)
		return
	if click_sfx.stream.resource_path != "res://assets/sfx/buttonClick.MP3":
		push_error("Pause overlay button click SFX should use assets/sfx/buttonClick.MP3")
		quit(1)
		return
	if title.text != "暫停":
		push_error("Pause overlay title should be 暫停")
		quit(1)
		return
	if not resume.text.contains("繼續遊戲") or not save_menu.text.contains("存檔並返回主頁"):
		push_error("Pause overlay options should include resume and save-to-menu")
		quit(1)
		return

	var signal_counts := {"resume": 0, "save_menu": 0}
	overlay.resume_requested.connect(func() -> void: signal_counts["resume"] += 1)
	overlay.save_and_menu_requested.connect(func() -> void: signal_counts["save_menu"] += 1)

	overlay.confirm_selection()
	if int(signal_counts["resume"]) != 1:
		push_error("Default pause overlay selection should resume")
		quit(1)
		return
	if not click_sfx.playing:
		push_error("Confirming a pause overlay option should play button click SFX")
		quit(1)
		return

	overlay.show_pause()
	overlay.move_selection(1)
	overlay.confirm_selection()
	if int(signal_counts["save_menu"]) != 1:
		push_error("Moving pause overlay selection once should choose save-and-menu")
		quit(1)
		return
	
	overlay.show_pause()
	overlay.select_option(overlay.OPTION_SAVE_MENU)
	if int(overlay.get("selected_index")) != overlay.OPTION_SAVE_MENU:
		push_error("Mouse hovering pause save-and-menu should select it")
		quit(1)
		return
	overlay.confirm_option(overlay.OPTION_SAVE_MENU)
	if int(signal_counts["save_menu"]) != 2:
		push_error("Mouse clicking pause save-and-menu should confirm it")
		quit(1)
		return

	overlay.hide_pause()
	await process_frame
	if overlay.visible or bool(overlay.get("is_active")):
		push_error("Pause overlay should hide cleanly")
		quit(1)
		return

	overlay.queue_free()
	await process_frame
	quit(0)
