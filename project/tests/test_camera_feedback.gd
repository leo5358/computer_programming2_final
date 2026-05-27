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

	var camera := main.get_node_or_null("Player/Camera2D")
	if camera == null:
		push_error("Main scene should include player camera")
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
