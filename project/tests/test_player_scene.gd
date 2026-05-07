extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player: Node = scene.instantiate()
	if player == null:
		push_error("Player scene should instantiate")
		quit(1)
		return

	get_root().add_child(player)
	await process_frame
	if not player.is_in_group("player"):
		push_error("Player should join player group")
		quit(1)
		return

	if not player.has_node("AttackSfx"):
		push_error("Player should have attack sfx player")
		quit(1)
		return
	if not player.has_node("HurtSfx"):
		push_error("Player should have hurt sfx player")
		quit(1)
		return
	if not player.has_node("DeathSfx"):
		push_error("Player should have death sfx player")
		quit(1)
		return

	player.velocity.x = 400.0
	player._apply_horizontal_control(0.0, 0.1)
	if player.velocity.x > 100.0:
		push_error("Player should brake quickly after releasing movement")
		quit(1)
		return

	player.velocity.x = 400.0
	player._apply_horizontal_control(-1.0, 0.1)
	if player.velocity.x >= 0.0:
		push_error("Player should brake into opposite direction when reversing input")
		quit(1)
		return

	player.posture = 99.0
	player.receive_enemy_attack(0.0, 10.0)
	if player.state != player.PlayerState.STUNNED:
		push_error("Player should enter stunned when posture reaches max")
		quit(1)
		return

	for frame in 45:
		await physics_frame
	if player.state == player.PlayerState.STUNNED:
		push_error("Player should recover from stunned after timer")
		quit(1)
		return

	player.posture = 0.0
	player.receive_enemy_attack(1.0, 1.0)
	if player.hurt_flash_timer <= 0.0:
		push_error("Failed parry/block should trigger hurt feedback")
		quit(1)
		return

	player.reset_combat_state()
	player.health = 1.0
	player.velocity = Vector2(120.0, -40.0)
	player.receive_enemy_attack(10.0, 0.0)
	if player.state != player.PlayerState.DEAD:
		push_error("Player should enter dead state when health reaches zero")
		quit(1)
		return
	if player.current_animation != "death":
		push_error("Player death should immediately play death animation")
		quit(1)
		return

	player.velocity = Vector2.ZERO
	player._physics_process(0.1)
	if player.velocity.y <= 0.0:
		push_error("Dead player should still fall if killed in the air")
		quit(1)
		return

	player.reset_combat_state()
	if player.state != player.PlayerState.IDLE:
		push_error("Reset should recover player from death")
		quit(1)
		return

	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	await process_frame
	await process_frame
	quit(0)
