extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if player_scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player = player_scene.instantiate()
	get_root().add_child(player)
	await process_frame

	player.reset_combat_state()
	player.heartbeat = 150.0
	player._update_combat(1.0)
	if player.heartbeat >= 150.0:
		push_error("Heartbeat should cool down while the player is not blocking or under pressure")
		quit(1)
		return

	player.reset_combat_state()
	player.heartbeat = 199.0
	player._start_block()
	player._update_combat(1.0)
	if player.state != player.PlayerState.DEAD:
		push_error("Reaching 200 BPM through sustained guard pressure should enter final death")
		quit(1)
		return

	player.reset_combat_state()
	player.heartbeat = 200.0
	player._start_block()
	if player.block_time_left > 0.21:
		push_error("At 200 BPM, held block duration should be extremely short")
		quit(1)
		return

	player.reset_combat_state()
	player.heartbeat = 150.0
	var heartbeat_before_hit: float = player.heartbeat
	player.receive_enemy_attack(1.0, 1.0, null)
	if player.heartbeat <= heartbeat_before_hit:
		push_error("Taking a clean hit should spike heartbeat")
		quit(1)
		return

	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	await process_frame
	quit(0)
