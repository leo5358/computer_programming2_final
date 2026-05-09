extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player = scene.instantiate()
	get_root().add_child(player)
	player.global_position = Vector2(160, 408)
	player.facing = 1.0
	await process_frame

	player._start_attack()
	if player.velocity.x < 110.0:
		push_error("Attack should add a small forward step even without a target")
		quit(1)
		return
	player.velocity.x = 360.0
	player._update_movement(0.1)
	if player.velocity.x > 60.0:
		push_error("Attack state should lock out free movement and brake player input")
		quit(1)
		return

	player.reset_combat_state()
	player.global_position = Vector2(160, 408)
	player.facing = 1.0
	var near_enemy := Node2D.new()
	near_enemy.global_position = Vector2(238, 408)
	near_enemy.add_to_group("enemy")
	get_root().add_child(near_enemy)
	await process_frame

	player._start_attack()
	if player.velocity.x < 230.0:
		push_error("Attack should gain extra soft-lock step toward a nearby enemy just outside range")
		quit(1)
		return

	player.reset_combat_state()
	player.global_position = Vector2(160, 408)
	player.facing = 1.0
	near_enemy.global_position = Vector2(360, 408)
	player._start_attack()
	if player.velocity.x > 170.0:
		push_error("Attack should not magnetize toward enemies that are clearly too far away")
		quit(1)
		return

	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	near_enemy.queue_free()
	await process_frame
	quit(0)
