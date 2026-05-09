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
	if not player.has_node("DashSfx"):
		push_error("Player should have dash sfx player")
		quit(1)
		return
	if not player.has_node("PerfectDodgeSfx"):
		push_error("Player should have perfect dodge sfx player")
		quit(1)
		return
	for removed_node in [
		"Body",
		"AttackVisual",
		"BlockVisual",
		"ParryVisual",
		"BlockImpactVisual",
		"HurtImpactVisual",
		"AttackSlashVfx",
		"ParrySparkVfx",
		"BlockSparkVfx",
		"HurtSlashVfx",
		"PerfectDodgeVfx",
		"DodgeAfterimageVfx",
		"DashVisual",
		"StateLabel",
	]:
		if player.has_node(removed_node):
			push_error("Player should not keep debug/effect node: %s" % removed_node)
			quit(1)
			return

	var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if sprite.sprite_frames == null:
		push_error("Player should build sprite frames from the current art assets")
		quit(1)
		return
	if sprite.sprite_frames.get_frame_count("idle") != 8:
		push_error("Player should use the 8-frame idle strip from assets/sprites/player")
		quit(1)
		return
	if sprite.sprite_frames.get_frame_count("parry") != 8:
		push_error("Player should use the 8-frame deflect strip for parry")
		quit(1)
		return

	var legacy_layout: Dictionary = player._resolve_sheet_layout(Vector2i(768, 512))
	if legacy_layout["cell_size"] != 64:
		push_error("Legacy player sheet should resolve to 64x64 layout")
		quit(1)
		return

	var samurai_layout: Dictionary = player._resolve_sheet_layout(Vector2i(1152, 864))
	if samurai_layout["cell_size"] != 96:
		push_error("Samurai player sheet should resolve to 96x96 layout")
		quit(1)
		return
	if samurai_layout["block"]["source"] != "guard":
		push_error("Samurai layout should map block state to guard row")
		quit(1)
		return

	var player2_layout: Dictionary = player._resolve_sheet_layout(Vector2i(1086, 1448))
	if player2_layout["cell_size"] != 181:
		push_error("Player2 sheet should resolve to 181x181 layout")
		quit(1)
		return
	if player2_layout["attack_a"]["count"] != 6:
		push_error("Player2 attack animation should use its 6-frame attack row")
		quit(1)
		return

	var player3_layout: Dictionary = player._resolve_sheet_layout(Vector2i(768, 1152))
	if player3_layout["cell_size"] != 128:
		push_error("Player3 sheet should resolve to 128x128 layout")
		quit(1)
		return
	if player3_layout["dash"]["row"] != 2:
		push_error("Player3 dash animation should use its low dash row")
		quit(1)
		return

	var player4_layout: Dictionary = player._resolve_sheet_layout(Vector2i(1024, 1536))
	if player4_layout["cell_size"] != 128:
		push_error("Player4 sheet should resolve to 128x128 layout")
		quit(1)
		return
	if player4_layout["death"]["row"] != 8:
		push_error("Player4 death animation should use row 8")
		quit(1)
		return

	var standard_96_layout: Dictionary = player._resolve_sheet_layout(Vector2i(576, 864))
	if standard_96_layout["cell_size"] != 96:
		push_error("Standard 96px player sheet should resolve to 96x96 layout")
		quit(1)
		return
	if standard_96_layout["attack_a"]["row"] != 6:
		push_error("Standard 96px player attack should use row 6")
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
	player._update_visuals()
	if player.current_animation != "stunned_death_forward":
		push_error("Posture break should start by playing death animation forward as a knockdown")
		quit(1)
		return
	if player.action_timer < 1.19:
		push_error("Posture break should stun player for about 1.2 seconds")
		quit(1)
		return
	if player.sprite.speed_scale >= 1.0:
		push_error("Posture break knockdown should slow the death animation to match the longer stun")
		quit(1)
		return

	player._update_action_state(0.61)
	player._update_visuals()
	if player.state == player.PlayerState.STUNNED:
		if player.current_animation != "stunned_death_reverse":
			push_error("Posture break should reverse death animation for recovery stand-up")
			quit(1)
			return
		if player.sprite.speed_scale >= 1.0:
			push_error("Posture break stand-up should keep the slowed death animation speed")
			quit(1)
			return

	player._update_action_state(0.60)
	if player.state == player.PlayerState.STUNNED:
		push_error("Player should recover from stunned after timer")
		quit(1)
		return

	player.posture = 0.0
	player.facing = 1.0
	player.receive_enemy_attack(1.0, 1.0)
	if player.hurt_flash_timer <= 0.0:
		push_error("Failed parry/block should trigger hurt feedback")
		quit(1)
		return
	if player.velocity.x > -210.0:
		push_error("Unblocked hit should shove player back hard enough to read")
		quit(1)
		return

	player.reset_combat_state()
	player.is_blocking = true
	player.facing = 1.0
	player.receive_enemy_attack(0.0, 10.0)
	if player.block_flash_timer < 0.18:
		push_error("Blocked hit should show a longer blue impact flash")
		quit(1)
		return
	if player.velocity.x > -130.0:
		push_error("Blocked hit should shove player back less than a clean hit but still visibly")
		quit(1)
		return

	player.reset_combat_state()
	player.is_parrying = true
	player.facing = 1.0
	player.velocity = Vector2(140.0, 0.0)
	player.receive_enemy_attack(0.0, 10.0)
	if player.parry_flash_timer < 0.12:
		push_error("Perfect parry should show a satisfying gold impact flash")
		quit(1)
		return
	if player.hitstop_timer < 0.08:
		push_error("Perfect parry should briefly freeze the action")
		quit(1)
		return
	if player.stored_velocity.x > -100.0:
		push_error("Perfect parry should rebound the player backward a little")
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
