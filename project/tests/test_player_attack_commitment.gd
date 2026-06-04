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
	if sprite.sprite_frames.get_frame_count("attack_a") != 8:
		push_error("Player attack should keep the existing 8-frame custom strip")
		quit(1)
		return
	if not is_equal_approx(sprite.sprite_frames.get_animation_speed("attack_a"), player.ATTACK_ANIMATION_FPS):
		push_error("Player attack animation should match the faster 0.7s attack timing")
		quit(1)
		return
	if not is_equal_approx(sprite.sprite_frames.get_animation_speed("attack_chop"), player.ATTACK_ANIMATION_FPS):
		push_error("Player chop animation should use the same faster committed timing as normal attack")
		quit(1)
		return
	if sprite.sprite_frames.get_frame_count("attack_chop") != 8:
		push_error("Player chop strip should use its full 8 fixed-width frames")
		quit(1)
		return
	var expected_attack_regions := [
		Rect2(0, 0, 96, 96),
		Rect2(96, 0, 96, 96),
		Rect2(192, 0, 92, 96),
		Rect2(284, 0, 92, 96),
		Rect2(376, 0, 111, 96),
		Rect2(487, 0, 109, 96),
		Rect2(596, 0, 96, 96),
		Rect2(692, 0, 96, 96),
	]
	for index in expected_attack_regions.size():
		var attack_frame: AtlasTexture = sprite.sprite_frames.get_frame_texture("attack_a", index) as AtlasTexture
		if attack_frame == null or attack_frame.region != expected_attack_regions[index]:
			push_error("Player attack frame %d should keep the hand-authored variable-width crop" % index)
			quit(1)
			return

	player._start_attack()
	if sprite.animation != player.current_attack_animation:
		push_error("Player attack should immediately play the committed attack animation on the same frame as input")
		quit(1)
		return
	if player.current_animation != player.current_attack_animation:
		push_error("Player current_animation should sync immediately when attack starts")
		quit(1)
		return
	if not is_equal_approx(player.attack_startup, 0.16) or not is_equal_approx(player.attack_active_time, 0.24):
		push_error("Player attack should come out about 0.3s faster than the old committed attack")
		quit(1)
		return
	if not is_equal_approx(player.attack_recovery, 0.30):
		push_error("Player attack should keep about 0.3s of recovery lockout after the hit")
		quit(1)
		return
	if not is_equal_approx(player.action_timer, 0.70):
		push_error("Player attack should total about 0.7s after the faster timing pass")
		quit(1)
		return
	if player.attack_lunge_time < player.attack_startup:
		push_error("Player attack movement should last through startup so empty swings do not feel like a static freeze")
		quit(1)
		return

	player._update_action_state(player.attack_startup - 0.01)
	if player.is_attacking or player.attack_has_hit:
		push_error("Player attack should not hit during startup frames 1-3")
		quit(1)
		return

	player._update_action_state(0.02)
	if not player.attack_has_hit:
		push_error("Player attack should apply its hit during active frames 4-5")
		quit(1)
		return

	player._update_action_state(player.attack_active_time + 0.01)
	player.queue_attack_buffer()
	sprite.frame = 7
	sprite.frame_progress = 0.9
	while player.state == player.PlayerState.ATTACK and player.attack_elapsed > 0.02:
		player._update_action_state(0.02)
	if player.state != player.PlayerState.ATTACK:
		push_error("Buffered attack should start after recovery instead of allowing instant mashing")
		quit(1)
		return
	if player.attack_elapsed > 0.02:
		push_error("Buffered attack should restart from frame 1 after recovery completes")
		quit(1)
		return
	if sprite.animation != player.current_attack_animation or sprite.frame != 0:
		push_error("Buffered same-animation attack should visibly restart from frame 1")
		quit(1)
		return

	player.reset_combat_state()
	player._start_attack()
	player.action_timer = 0.0
	player._update_action_state(0.0)
	player._start_attack()
	player.attack_elapsed = player.attack_startup + player.attack_active_time + 0.01
	player.queue_attack_buffer()
	var safety_frames := 0
	while player.state == player.PlayerState.ATTACK and player.current_attack_animation != "attack_chop" and safety_frames < 80:
		player._update_action_state(0.02)
		safety_frames += 1
	if player.current_attack_animation != "attack_chop":
		push_error("Queued third attack should reliably become chop instead of dropping into idle")
		quit(1)
		return

	var health_before_deflect: float = player.health
	var posture_before_deflect: float = player.posture
	player._receive_attack_deflected()
	if player.state != player.PlayerState.HURT:
		push_error("Enemy deflect should force player into a short recoil state")
		quit(1)
		return
	if player.health != health_before_deflect:
		push_error("Enemy deflecting the player's attack should not deal health damage")
		quit(1)
		return
	if player.posture <= posture_before_deflect:
		push_error("Enemy deflecting the player's attack should add player posture pressure")
		quit(1)
		return
	if player.current_animation != "deflect_miss" or sprite.animation != "deflect_miss":
		push_error("Enemy deflect should play the player's deflect_miss recoil animation instead of hurt")
		quit(1)
		return
	if player.attack_combo_step != 0:
		push_error("Enemy deflect should reset the player's attack combo instead of allowing continued pressure")
		quit(1)
		return
	if player.attack_lockout_timer < player.attack_deflected_attack_lockout_time - 0.01:
		push_error("Enemy deflect should start an attack lockout")
		quit(1)
		return
	if player._can_start_attack():
		push_error("Enemy deflect should prevent immediate follow-up attacks")
		quit(1)
		return
	if not player._can_start_defensive_action():
		push_error("Enemy deflect recoil should still allow defensive parry or dodge responses")
		quit(1)
		return
	if player.action_timer < player.attack_deflected_stun_time:
		push_error("Enemy deflect should impose a real attack penalty")
		quit(1)
		return
	if player.attack_buffer_timer != 0.0 or player.attack_buffer_queued:
		push_error("Enemy deflect should clear buffered attack input")
		quit(1)
		return
	if player.attack_deflected_rebound < 250.0:
		push_error("Enemy deflect should push the player far enough to reset close-range mash pressure")
		quit(1)
		return
	if absf(player.velocity.x) < 250.0:
		push_error("Enemy deflect should visibly rebound the player backward")
		quit(1)
		return
	player._update_action_state(player.attack_deflected_stun_time + 0.01)
	if player.state != player.PlayerState.IDLE:
		push_error("Enemy deflect recoil should end before attack lockout fully expires")
		quit(1)
		return
	if player._can_start_attack():
		push_error("Player should not be able to attack immediately after deflect recoil ends")
		quit(1)
		return
	player._update_action_state(player.attack_lockout_timer + 0.01)
	if not player._can_start_attack():
		push_error("Player should regain attack after the deflect lockout expires")
		quit(1)
		return

	player.queue_free()
	await process_frame
	quit(0)
