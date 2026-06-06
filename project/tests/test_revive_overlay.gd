extends SceneTree

func _initialize() -> void:
	var overlay_script: Script = load("res://scripts/revive_overlay.gd")
	if overlay_script == null:
		push_error("Revive overlay script should load")
		quit(1)
		return

	var overlay: CanvasLayer = overlay_script.new()
	overlay.set("fade_duration", 0.01)
	overlay.set("countdown_duration", 0.05)
	get_root().add_child(overlay)
	await process_frame

	if overlay.visible:
		push_error("Revive overlay should start hidden")
		quit(1)
		return
	if not overlay.has_method("show_revive_prompt"):
		push_error("Revive overlay should expose show_revive_prompt")
		quit(1)
		return
	if not overlay.has_method("confirm_selection"):
		push_error("Revive overlay should expose confirm_selection")
		quit(1)
		return
	if not overlay.has_method("move_selection"):
		push_error("Revive overlay should expose move_selection")
		quit(1)
		return
	if not overlay.has_method("hide_overlay_immediate"):
		push_error("Revive overlay should expose hide_overlay_immediate")
		quit(1)
		return

	overlay.show_revive_prompt()
	await create_timer(0.03).timeout
	await process_frame
	if not overlay.visible or not bool(overlay.get("is_active")):
		push_error("Revive overlay should become active after showing")
		quit(1)
		return

	var shade: ColorRect = overlay.get_node_or_null("Shade")
	var countdown_label: Label = overlay.get_node_or_null("Content/Box/CountdownGroup/CountdownLabel")
	var revive_label: Label = overlay.get_node_or_null("Content/Box/Options/ReviveLabel")
	var give_up_label: Label = overlay.get_node_or_null("Content/Box/Options/GiveUpLabel")
	var click_sfx := overlay.get_node_or_null("ButtonClickSfx") as AudioStreamPlayer
	if shade == null or countdown_label == null or revive_label == null or give_up_label == null:
		push_error("Revive overlay should build shade, countdown, and two option labels")
		quit(1)
		return
	if absf(shade.color.a - 0.8) > 0.05:
		push_error("Revive overlay shade should fade close to 80 percent opacity")
		quit(1)
		return
	if countdown_label.text != "15":
		push_error("Revive overlay countdown should start at 15")
		quit(1)
		return
	if not revive_label.text.contains("復活") or not give_up_label.text.contains("放棄"):
		push_error("Revive overlay options should include revive and give up")
		quit(1)
		return
	if click_sfx == null or click_sfx.stream == null:
		push_error("Revive overlay should include button click SFX")
		quit(1)
		return

	var signal_counts := {"revive": 0, "give_up": 0}
	overlay.revive_requested.connect(func() -> void: signal_counts["revive"] += 1)
	overlay.give_up_requested.connect(func() -> void: signal_counts["give_up"] += 1)

	overlay.confirm_selection()
	if int(signal_counts["revive"]) != 1:
		push_error("Default revive overlay selection should revive")
		quit(1)
		return
	if not click_sfx.playing:
		push_error("Confirming a revive overlay option should play button click SFX")
		quit(1)
		return

	overlay.show_revive_prompt()
	await create_timer(0.03).timeout
	overlay.move_selection(1)
	overlay.confirm_selection()
	if int(signal_counts["give_up"]) != 1:
		push_error("Moving revive overlay selection once should choose give up")
		quit(1)
		return

	overlay.show_revive_prompt()
	await create_timer(0.08).timeout
	if int(signal_counts["give_up"]) != 2:
		push_error("Revive overlay timeout should choose give up automatically")
		quit(1)
		return

	overlay.queue_free()
	await process_frame
	quit(0)
