extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if player_scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player: Node = player_scene.instantiate()
	get_root().add_child(player)
	await process_frame

	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		push_error("Player should build sprite frames")
		quit(1)
		return
	if not sprite.sprite_frames.has_animation("deflect_miss"):
		push_error("Player should load deflect_miss animation from the new strip")
		quit(1)
		return
	if sprite.sprite_frames.get_frame_count("deflect_miss") != 8:
		push_error("Player deflect_miss should use the full 8-frame strip")
		quit(1)
		return

	player._start_parry()
	player._update_visuals()
	if player.current_animation != "deflect_miss" or sprite.animation != "deflect_miss":
		push_error("Player parry input should play deflect_miss as the base character animation")
		quit(1)
		return
	if sprite.scale != Vector2(1.1, 1.1):
		push_error("Player deflect_miss animation should render at 1.1x scale")
		quit(1)
		return

	Input.action_press("move_right")
	player.velocity.x = 180.0
	player._update_movement(0.10)
	Input.action_release("move_right")
	if player.velocity.x > 0.0:
		push_error("Player parry/deflect stance should not allow movement input to keep sliding forward")
		quit(1)
		return

	player._start_block()
	Input.action_press("block")
	Input.action_press("move_right")
	player.velocity.x = 180.0
	player._update_movement(0.10)
	Input.action_release("move_right")
	if absf(player.velocity.x) > 1.0:
		push_error("Holding K through block should lock player movement completely")
		quit(1)
		return
	sprite.frame = 4
	sprite.speed_scale = 1.0
	player._update_block_hold_animation()
	if sprite.frame != 3 or not is_equal_approx(sprite.speed_scale, 0.0):
		push_error("Held block should clamp deflect_miss at frame 4")
		quit(1)
		return

	Input.action_release("block")
	player._update_combat(0.016)
	if bool(player.get("is_blocking")):
		push_error("Releasing K should immediately remove block collision logic")
		quit(1)
		return
	if player.state != player.PlayerState.BLOCK or not bool(player.get("is_block_releasing")):
		push_error("Releasing K should keep the player in block release animation")
		quit(1)
		return
	if not is_equal_approx(sprite.speed_scale, 1.0):
		push_error("Block release should resume deflect_miss playback")
		quit(1)
		return

	player._update_action_state(player.block_release_time + 0.05)
	if player.state == player.PlayerState.BLOCK:
		push_error("Block release should return to idle after the final frames")
		quit(1)
		return

	player.reset_combat_state()
	player.facing = 1.0
	player.velocity.x = 220.0
	player._receive_attack_deflected()
	Input.action_press("move_right")
	player._update_movement(0.10)
	Input.action_release("move_right")
	if absf(player.velocity.x) > 1.0:
		push_error("Enemy deflect recoil should lock player movement instead of sliding")
		quit(1)
		return

	player.reset_combat_state()
	player.is_parrying = true
	player.receive_enemy_attack(0.0, 10.0)
	var hit_impact_vfx := player.get_node_or_null("HitImpactVfx") as AnimatedSprite2D
	if hit_impact_vfx == null or not hit_impact_vfx.visible:
		push_error("Successful parry should add hit_impact_sheet VFX on top of deflect_miss")
		quit(1)
		return

	player.reset_combat_state()
	player.health = player.max_health
	player.receive_enemy_attack(12.0, 10.0, null)
	var post_hit_health: float = float(player.health)
	player.receive_enemy_attack(12.0, 10.0, null)
	if not is_equal_approx(float(player.health), post_hit_health):
		push_error("Direct unguarded hits should grant iframe protection against immediate follow-up damage")
		quit(1)
		return
	if not player.get("hit_invulnerability_active"):
		push_error("Direct unguarded hits should activate hit invulnerability")
		quit(1)
		return
	if absf(float(player.get("hit_invulnerability_time_left")) - 0.55) > 0.05:
		push_error("Direct unguarded hits should start a 0.55 second hit invulnerability window")
		quit(1)
		return
	if sprite.modulate.a >= 0.95:
		push_error("Direct unguarded hit invulnerability should start a visible flicker")
		quit(1)
		return
	player._physics_process(0.56)
	if player.get("hit_invulnerability_active"):
		push_error("Hit invulnerability should end after 0.55 seconds")
		quit(1)
		return
	if absf(sprite.modulate.a - 1.0) > 0.01:
		push_error("Player sprite opacity should recover after hit invulnerability ends")
		quit(1)
		return

	player.reset_combat_state()
	player.health = player.max_health
	player._start_block()
	player.is_blocking = true
	player.receive_enemy_attack(12.0, 10.0, null)
	if player.get("hit_invulnerability_active"):
		push_error("Partial guard chip damage should not activate hit invulnerability")
		quit(1)
		return

	Input.action_release("block")
	player.queue_free()
	await process_frame
	quit(0)
