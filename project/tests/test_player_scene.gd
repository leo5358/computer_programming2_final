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
	if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		push_error("Player sprite should use nearest texture filtering so atlas frames do not bleed into each other")
		quit(1)
		return
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
	if sprite.sprite_frames.get_frame_count("climb") != 8:
		push_error("Player should use the 8-frame climb strip from assets/sprites/player")
		quit(1)
		return
	var run_first_frame := sprite.sprite_frames.get_frame_texture("run", 0) as AtlasTexture
	if run_first_frame == null or run_first_frame.region != Rect2(0, 0, 96, 96):
		push_error("Current player strip art should keep the full 96px frame to avoid clipping")
		quit(1)
		return
	var attack_regions := [
		Rect2(0, 0, 96, 96),
		Rect2(96, 0, 96, 96),
		Rect2(192, 0, 92, 96),
		Rect2(284, 0, 92, 96),
		Rect2(376, 0, 111, 96),
		Rect2(487, 0, 109, 96),
		Rect2(596, 0, 96, 96),
		Rect2(692, 0, 96, 96),
	]
	if sprite.sprite_frames.get_frame_count("attack_a") != attack_regions.size():
		push_error("Player attack strip should use all 8 variable-width attack frames")
		quit(1)
		return
	for index in attack_regions.size():
		var attack_frame := sprite.sprite_frames.get_frame_texture("attack_a", index) as AtlasTexture
		if attack_frame == null or attack_frame.region != attack_regions[index]:
			push_error("Player attack frame %d should match the 788x96 variable-width attack strip" % index)
			quit(1)
			return
	var attack_fifth_frame := sprite.sprite_frames.get_frame_texture("attack_a", 4) as AtlasTexture
	if attack_fifth_frame == null or attack_fifth_frame.region != Rect2(376, 0, 111, 96):
		push_error("Player attack strip should use the widened fifth frame for the blade")
		quit(1)
		return
	var dash_sixth_frame := sprite.sprite_frames.get_frame_texture("dash", 5) as AtlasTexture
	if dash_sixth_frame == null or dash_sixth_frame.region != Rect2(480, 0, 96, 96):
		push_error("Player dash strip should keep full-width frames because the current art reaches the frame edge")
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

	Input.action_press("jump")
	player._apply_wall_climb(1.0)
	Input.action_release("jump")
	if player.state != player.PlayerState.WALL_CLIMB:
		push_error("Player should enter wall climb state while climbing a wall")
		quit(1)
		return
	if player.velocity.y >= 0.0:
		push_error("Holding jump during wall climb should move the player upward")
		quit(1)
		return
	player._update_visuals()
	if player.current_animation != "climb":
		push_error("Wall climb state should play climb animation")
		quit(1)
		return
	player.velocity.y = 500.0
	player._apply_wall_climb(1.0)
	if player.velocity.y > player.wall_slide_speed:
		push_error("Wall contact without jump should cap downward slide speed")
		quit(1)
		return
	if player.auto_step_max_height < 24.0:
		push_error("Player should expose enough auto-step height for small stair collisions")
		quit(1)
		return
	player.auto_step_enabled = true
	player.coyote_timer = 0.08
	if not player._should_prefer_auto_step_over_climb():
		push_error("Recently grounded player should prefer auto-step over wall climb")
		quit(1)
		return
	player.coyote_timer = 0.0
	if player._should_prefer_auto_step_over_climb():
		push_error("Fully airborne player should still be allowed to wall climb")
		quit(1)
		return
	if not player.wall_climb_requires_jump:
		push_error("Wall climb should require intentional jump input by default")
		quit(1)
		return
	player._set_state(player.PlayerState.JUMP)
	Input.action_release("jump")
	if player._has_wall_climb_input():
		push_error("Pressing into a wall without jump should not start wall climb")
		quit(1)
		return
	Input.action_press("jump")
	if not player._has_wall_climb_input():
		push_error("Holding jump should allow intentional wall climb")
		quit(1)
		return
	player.wall_climb_lockout_timer = 0.2
	player._set_state(player.PlayerState.JUMP)
	if not player._should_defer_wall_climb_for_jump():
		push_error("Fresh normal jump should defer wall climb so medium ledges can be jumped onto")
		quit(1)
		return
	player.wall_climb_lockout_timer = 0.0
	if player._should_defer_wall_climb_for_jump():
		push_error("Wall climb should become available again after the jump-first lockout")
		quit(1)
		return
	if not player.has_method("set_map_climb_bounds"):
		push_error("Player should expose map-specific climb bounds")
		quit(1)
		return
	player.set_map_climb_bounds(0.0, 15600.0)
	player.global_position.x = 40.0
	if not player._is_at_world_horizontal_boundary(-1.0):
		push_error("Player should detect ab_foothill left map boundary as unclimbable")
		quit(1)
		return
	if player._is_at_world_horizontal_boundary(1.0):
		push_error("Player should only block wall climb when pressing toward the nearby boundary")
		quit(1)
		return
	player.global_position.x = 15598.0
	if not player._is_at_world_horizontal_boundary(1.0):
		push_error("Player should detect ab_foothill right map boundary as unclimbable")
		quit(1)
		return
	player.set_map_climb_bounds(0.0, 3000.0)
	player.global_position.x = 2998.0
	if not player._is_at_world_horizontal_boundary(1.0):
		push_error("Player should detect plaza right map boundary as unclimbable")
		quit(1)
		return
	player.set_map_climb_bounds(0.0, 2000.0)
	player.global_position.x = 1998.0
	if not player._is_at_world_horizontal_boundary(1.0):
		push_error("Player should detect boss interior right map boundary as unclimbable")
		quit(1)
		return
	Input.action_release("jump")

	player.posture = 99.0
	player.receive_enemy_attack(0.0, 10.0)
	if player.state != player.PlayerState.STUNNED:
		push_error("Player should enter stunned when posture reaches max")
		quit(1)
		return
	player._update_visuals()
	if player.current_animation != "posture_knockdown_forward":
		push_error("Posture break should start by playing the first three death frames forward")
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
		if player.current_animation != "posture_knockdown_reverse":
			push_error("Posture break should reverse the first three death frames for recovery stand-up")
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
	player.health = player.max_health
	player.facing = 1.0
	player.receive_enemy_attack(1.0, 1.0)
	if player.current_animation != "hurt" or sprite.animation != "hurt":
		push_error("Unblocked hit should immediately play hurt animation")
		quit(1)
		return
	var hurt_duration := float(sprite.sprite_frames.get_frame_count("hurt")) / sprite.sprite_frames.get_animation_speed("hurt")
	if player.action_timer < hurt_duration:
		push_error("Unblocked hit should keep player in hurt long enough to play every hurt frame")
		quit(1)
		return
	if player.hurt_flash_timer <= 0.0:
		push_error("Failed parry/block should trigger hurt feedback")
		quit(1)
		return
	if player.velocity.x > -210.0:
		push_error("Unblocked hit should shove player back hard enough to read")
		quit(1)
		return
	player._update_movement(0.10)
	if player.velocity.x > -160.0:
		push_error("Unblocked hit should keep sliding briefly instead of being cancelled by friction immediately")
		quit(1)
		return
	var attacker := Node2D.new()
	get_root().add_child(attacker)
	player.reset_combat_state()
	player.global_position = Vector2(280.0, 360.0)
	attacker.global_position = Vector2(200.0, 360.0)
	player.facing = 1.0
	player.receive_enemy_attack(1.0, 1.0, attacker)
	if player.velocity.x <= 0.0:
		push_error("Clean hit should knock the player away from the attacker, not based on player facing")
		quit(1)
		return
	attacker.queue_free()
	await process_frame

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
	if player.state != player.PlayerState.STUNNED:
		push_error("Player should enter life knockdown when one HP bar is depleted while lives remain")
		quit(1)
		return
	if player.lives != player.max_lives - 1 or player.health != player.max_health:
		push_error("Depleting HP with lives remaining should consume one life and refill HP")
		quit(1)
		return
	if player.current_animation != "life_knockdown_forward":
		push_error("Life loss should play the full death animation as a heavier knockdown")
		quit(1)
		return

	player.reset_combat_state()
	player.lives = 1
	player.health = 1.0
	player.velocity = Vector2(120.0, -40.0)
	player.receive_enemy_attack(10.0, 0.0)
	if player.state != player.PlayerState.DEAD:
		push_error("Player should enter dead state when final life reaches zero")
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
	player.global_position = Vector2(0.0, player.world_death_bounds.position.y + player.world_death_bounds.size.y + 16.0)
	player._physics_process(0.016)
	if player.state != player.PlayerState.DEAD:
		push_error("Player should die after falling outside the world death bounds")
		quit(1)
		return
	if player.current_animation != "death":
		push_error("World bounds death should use the normal death animation")
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
