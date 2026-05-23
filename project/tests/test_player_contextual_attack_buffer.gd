extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player = scene.instantiate()
	get_root().add_child(player)
	player.global_position = Vector2(160.0, 408.0)
	player.facing = 1.0
	await process_frame

	Input.action_press("move_right")
	player._start_attack()
	player.attack_elapsed = player.attack_startup * 0.5
	player.queue_attack_buffer()
	if player.attack_buffer_queued:
		push_error("Player should not buffer another attack during startup")
		await _cleanup(player, 1)
		return

	player.attack_elapsed = player.attack_startup + player.attack_active_time + 0.02
	player.queue_attack_buffer()
	if player.attack_buffer_queued:
		push_error("Player should prioritize movement over empty attack buffering when no target is nearby")
		await _cleanup(player, 1)
		return

	var near_enemy := Node2D.new()
	near_enemy.global_position = Vector2(238.0, 408.0)
	near_enemy.add_to_group("enemy")
	get_root().add_child(near_enemy)
	await process_frame

	player.queue_attack_buffer()
	if not player.attack_buffer_queued:
		push_error("Player should still buffer attack when a nearby enemy can be pressured")
		near_enemy.queue_free()
		await _cleanup(player, 1)
		return

	near_enemy.global_position = Vector2(420.0, 408.0)
	player.attack_buffer_queued = false
	player.attack_buffer_timer = 0.0
	player.queue_attack_buffer()
	if player.attack_buffer_queued:
		push_error("Player should not chain empty swings toward enemies far outside soft-lock distance")
		near_enemy.queue_free()
		await _cleanup(player, 1)
		return

	near_enemy.queue_free()
	await _cleanup(player, 0)

func _cleanup(player: Node, code: int) -> void:
	Input.action_release("move_right")
	player.queue_free()
	await process_frame
	quit(code)
