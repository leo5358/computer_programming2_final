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

	main.queue_free()
	await process_frame
	quit(0)
