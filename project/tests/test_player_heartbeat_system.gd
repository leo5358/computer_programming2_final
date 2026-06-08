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
	player.heartbeat = 101.0
	player._update_heartbeat(1.0)
	if player.heartbeat != 101.0:
		push_error("Heartbeat should wait two seconds before cooldown starts while out of combat")
		quit(1)
		return
	player._update_heartbeat(1.0)
	if player.heartbeat != 92.0:
		push_error("Heartbeat should floor its 8 percent cooldown from the current heartbeat after the two second delay")
		quit(1)
		return

	player.reset_combat_state()
	player.state = player.PlayerState.MOVE
	player.velocity.x = 90.0
	player.heartbeat = 70.0
	player._update_heartbeat(1.0)
	if player.heartbeat != 72.0:
		push_error("Walking should add floor(walk target * 3%%) per second until the walking target")
		quit(1)
		return

	player.reset_combat_state()
	player.state = player.PlayerState.MOVE
	player.velocity.x = 180.0
	player.is_running = true
	player.heartbeat = 95.0
	player._update_heartbeat(1.0)
	if player.heartbeat != 104.0:
		push_error("Running should add floor(run target * 6%%) per second until the running target")
		quit(1)
		return

	player.reset_combat_state()
	player.state = player.PlayerState.MOVE
	player.velocity.x = 180.0
	player.is_running = true
	player.heartbeat = 70.0
	player._update_heartbeat(1.0)
	if player.heartbeat != 79.0:
		push_error("Running from idle should use the same run rise rate and floor the result")
		quit(1)
		return

	player.reset_combat_state()
	player.state = player.PlayerState.MOVE
	player.velocity.x = 180.0
	player.is_running = true
	player.heartbeat = 120.0
	player.is_running = false
	player.velocity.x = 80.0
	player._update_heartbeat(1.0)
	if player.heartbeat != 120.0:
		push_error("Heartbeat should wait two seconds before cooling down when dropping from running to walking")
		quit(1)
		return
	player._update_heartbeat(1.0)
	if player.heartbeat != 110.0:
		push_error("Heartbeat should cool down toward the walking target after the two second delay")
		quit(1)
		return

	player.reset_combat_state()
	player.state = player.PlayerState.MOVE
	player.velocity.x = 180.0
	player.is_running = true
	player.heartbeat = 100.0
	player.heartbeat_combat_timer = 1.5
	player._update_heartbeat(1.0)
	if player.heartbeat != 104.0:
		push_error("Combat movement should only add combat pressure, not movement target rise")
		quit(1)
		return

	player.reset_combat_state()
	player.heartbeat = 100.0
	player._start_attack()
	if player.heartbeat != 104.0:
		push_error("Starting an attack should add 4 heartbeat immediately")
		quit(1)
		return
	player._update_heartbeat(1.0)
	if player.heartbeat != 108.0:
		push_error("Combat heartbeat should rise by 4 per second while combat is active")
		quit(1)
		return

	player.reset_combat_state()
	player._start_block()
	player.receive_enemy_attack(1.0, 1.0, null)
	if player.heartbeat != 75.0:
		push_error("Guarding an attack should add 5 heartbeat")
		quit(1)
		return
	if player.state == player.PlayerState.DEAD:
		push_error("Blocking a normal attack should not kill the player")
		quit(1)
		return

	player.reset_combat_state()
	player.heartbeat = 249.0
	player._start_attack()
	if player.state != player.PlayerState.DEAD:
		push_error("Reaching 250 heartbeat should trigger heartbeat death")
		quit(1)
		return

	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	await process_frame
	quit(0)
