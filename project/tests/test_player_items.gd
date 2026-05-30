extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player: Node = scene.instantiate()
	get_root().add_child(player)
	await process_frame

	for item_id in ["gourd", "kunai", "pill", "capsule", "ash_balls"]:
		if not player.has_method("get_item_count"):
			push_error("Player should expose item counts")
			quit(1)
			return
		if player.get_item_count(item_id) != 10:
			push_error("Player should start with 10 %s" % item_id)
			quit(1)
			return

	if not player.has_method("use_item"):
		push_error("Player should expose item use")
		quit(1)
		return
	if not player.use_item("gourd"):
		push_error("Gourd should be usable")
		quit(1)
		return
	if player.get_item_count("gourd") != 9:
		push_error("Using gourd should consume one count")
		quit(1)
		return
	if player.velocity != Vector2.ZERO:
		push_error("Using an eat item should stop movement")
		quit(1)
		return
	if player.get_current_animation() != "mudra":
		push_error("Using an eat item should play mudra animation")
		quit(1)
		return
	if player.is_action_locked():
		for frame in 120:
			await process_frame
			if not player.is_action_locked():
				break
	if player.is_action_locked():
		push_error("Eat item action should finish after mudra animation")
		quit(1)
		return

	player.queue_free()
	await process_frame
	quit(0)
