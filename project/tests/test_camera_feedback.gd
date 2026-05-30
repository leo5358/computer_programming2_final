extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main := scene.instantiate()
	get_root().add_child(main)
	await process_frame

	var camera := main.get_node_or_null("Chapter1Map/Camera")
	if camera == null:
		push_error("Main scene should use the active map camera")
		quit(1)
		return
	if not camera.is_in_group("feedback_camera"):
		push_error("Camera should be discoverable as feedback_camera")
		quit(1)
		return
	if not camera.has_method("shake"):
		push_error("Camera should expose a shake method")
		quit(1)
		return
	var player: Node2D = main.get_node_or_null("Player")
	if player == null:
		push_error("Main scene should include player for map camera follow")
		quit(1)
		return

	var camera_start_x: float = camera.global_position.x
	player.global_position.x += 240.0
	for frame in 5:
		await process_frame
	if camera.global_position.x <= camera_start_x + 4.0:
		push_error("Map camera should follow player movement")
		quit(1)
		return
	camera.dynamic_bottom_limit_enabled = true
	camera.bottom_limit_start_x = 12800.0
	camera.bottom_limit_end_x = 15663.0
	camera.bottom_limit_start = 655
	camera.bottom_limit_end = -50
	player.global_position.x = 15663.0
	await process_frame
	if camera.limit_bottom != -50:
		push_error("Map camera should raise bottom limit near the final stairs")
		quit(1)
		return

	camera.shake(12.0, 0.12)
	await process_frame
	if camera.offset.length() < 4.0:
		push_error("Camera shake should be visibly stronger than 4px")
		quit(1)
		return

	for frame in 20:
		await process_frame
	if camera.offset.length() > 0.25:
		push_error("Camera shake should decay back to rest")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
