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

	var item_ui: Node = main.get_node_or_null("ItemUI")
	if item_ui == null:
		push_error("Main scene should include an ItemUI node")
		quit(1)
		return
	if not item_ui.has_method("get_display_count"):
		push_error("ItemUI should expose display counts")
		quit(1)
		return
	if item_ui.get_display_count("gourd") != 10:
		push_error("ItemUI should show player gourd count")
		quit(1)
		return
	var row := item_ui.get_node_or_null("Root/ItemRow") as HBoxContainer
	if row == null:
		push_error("ItemUI should expose an item row")
		quit(1)
		return
	var first_border := row.get_child(0).get_node_or_null("Border") as ColorRect
	var second_border := row.get_child(1).get_node_or_null("Border") as ColorRect
	if first_border == null or second_border == null or first_border.color.a <= second_border.color.a:
		push_error("ItemUI should highlight the first item slot by default")
		quit(1)
		return

	var player: Node = main.get_node_or_null("Player")
	if player == null or not player.has_method("use_item"):
		push_error("Main scene should include a usable player")
		quit(1)
		return

	player.use_item("gourd")
	await process_frame
	if item_ui.get_display_count("gourd") != 9:
		push_error("ItemUI should update after using an item")
		quit(1)
		return
	player.set("action_timer", 0.0)
	player._update_action_state(0.01)
	player.set("selected_item_index", 2)
	player.emit_signal("stats_changed")
	await process_frame
	var third_border := row.get_child(2).get_node_or_null("Border") as ColorRect
	if third_border == null or third_border.color.a <= first_border.color.a:
		push_error("ItemUI should move the thick selection frame to the selected slot")
		quit(1)
		return
	if not player.has_method("use_selected_item") or not player.use_selected_item():
		push_error("Player should use the currently selected item on confirm")
		quit(1)
		return
	await process_frame
	if item_ui.get_display_count("pill") != 9:
		push_error("Using selected item should consume the selected pill slot")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
