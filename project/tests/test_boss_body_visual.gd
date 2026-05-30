extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	if boss_scene == null:
		push_error("Boss scene should load")
		quit(1)
		return

	var boss: Node = boss_scene.instantiate()
	get_root().add_child(boss)
	await process_frame

	var body: CanvasItem = boss.get_node_or_null("Body") as CanvasItem
	if body == null:
		push_error("Boss should keep Body node for fallback/debug compatibility")
		quit(1)
		return
	if body.visible:
		push_error("Boss fallback Body ColorRect should be hidden when sprite art is present")
		quit(1)
		return

	boss.queue_free()
	await process_frame
	quit(0)
