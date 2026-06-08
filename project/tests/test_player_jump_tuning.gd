extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player = scene.instantiate()
	get_root().add_child(player)
	await process_frame

	if not is_equal_approx(player.jump_velocity, -559.0):
		push_error("Player jump velocity should be tuned 30 percent higher to -559.0")
		quit(1)
		return

	player.queue_free()
	await process_frame
	quit(0)
