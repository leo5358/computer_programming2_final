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

	var boss: CharacterBody2D = main.get_node_or_null("Boss") as CharacterBody2D
	var player: Node2D = main.get_node_or_null("Player") as Node2D
	if boss == null or player == null:
		push_error("Main scene should contain boss and player")
		quit(1)
		return

	boss.global_position = player.global_position + Vector2(520.0, 0.0)
	boss.spawn_position = boss.global_position
	var start_x: float = boss.global_position.x
	for frame in 45:
		await physics_frame

	if boss.global_position.x <= start_x + 8.0:
		push_error("Boss V0 should patrol horizontally")
		quit(1)
		return
	if boss.current_animation != "walk":
		push_error("Boss V0 should play walk while patrolling")
		quit(1)
		return
	if not boss.is_on_floor():
		push_error("Boss V0 should settle on the floor")
		quit(1)
		return
	for frame in 240:
		await physics_frame
	if boss.facing >= 0.0:
		push_error("Boss V0 should turn around at patrol bounds")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
