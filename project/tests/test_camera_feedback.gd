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

	player.global_position.x = 2200.0
	await process_frame
	if camera.limit_bottom != 540:
		push_error("AB foothill camera bottom should lower to 540 on the first foothill shelf")
		quit(1)
		return

	player.global_position.x = 3100.0
	await process_frame
	if camera.limit_bottom != 655:
		push_error("AB foothill camera bottom should use the default bottom after removing the second foothill shelf limit")
		quit(1)
		return

	player.global_position.x = 9500.0
	await process_frame
	if camera.limit_bottom != 490:
		push_error("AB foothill camera bottom should lower to 490 at the expanded rear shelf start")
		quit(1)
		return

	player.global_position.x = 11000.0
	await process_frame
	if camera.limit_bottom != 490:
		push_error("AB foothill camera bottom should lower to 490 before the rear stairs")
		quit(1)
		return

	player.global_position.x = 12000.0
	await process_frame
	if camera.limit_bottom != 400:
		push_error("AB foothill camera bottom should lower to 400 on the rear stairs approach")
		quit(1)
		return

	player.global_position.x = 13360.0
	await process_frame
	if camera.limit_bottom != 300:
		push_error("AB foothill camera bottom should linearly raise from 400 to 200 on the final climb")
		quit(1)
		return

	player.global_position.x = 1570.0
	await process_frame
	if camera.limit_bottom <= 540 or camera.limit_bottom >= 655:
		push_error("AB foothill camera bottom should use the expanded buffer before the first custom shelf")
		quit(1)
		return

	player.global_position.x = 14000.0
	await process_frame
	if camera.limit_bottom != 200:
		push_error("AB foothill camera bottom should finish at 200 at the top of the final climb")
		quit(1)
		return

	player.global_position.x = 14700.0
	await process_frame
	if camera.limit_bottom != -10:
		push_error("AB foothill camera bottom should continue raising to -10 by x=14700")
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
