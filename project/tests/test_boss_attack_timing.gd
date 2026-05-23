extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossAttackTimingTest"
	get_root().add_child(main)
	var boss = boss_scene.instantiate()
	var player = player_scene.instantiate()
	main.add_child(boss)
	main.add_child(player)
	await process_frame

	if boss.get("attack_frame_durations") == null:
		push_error("Boss attack should expose custom frame durations")
		quit(1)
		return
	if boss.get("attack_hit_time") == null or boss.get("attack_parry_window_start") == null:
		push_error("Boss attack should expose hit and parry window timing")
		quit(1)
		return

	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-60.0, 0.0)
	boss.facing = -1.0
	await physics_frame
	boss.attack_cooldown = 99.0
	boss._start_normal_attack("attack")
	await physics_frame

	if not is_equal_approx(boss.attack_animation_total_time, 1.11):
		push_error("Boss attack profile custom frame durations should total 1110ms")
		quit(1)
		return

	var expected_frames := {
		0.119: 0,
		0.120: 1,
		0.269: 1,
		0.271: 2,
		0.569: 2,
		0.571: 3,
		0.649: 3,
		0.651: 4,
		0.709: 4,
		0.711: 5,
		0.809: 5,
		0.811: 6,
		0.949: 6,
		0.951: 7,
	}
	for elapsed in expected_frames.keys():
		boss.attack_elapsed = float(elapsed)
		boss._sync_attack_animation_frame()
		if boss.sprite.frame != int(expected_frames[elapsed]):
			push_error("Boss attack frame at %.3fs should be %d, got %d" % [float(elapsed), int(expected_frames[elapsed]), boss.sprite.frame])
			quit(1)
			return

	if not boss.is_attack_parry_window_open():
		boss.attack_elapsed = 0.620
		if not boss.is_attack_parry_window_open():
			push_error("Boss attack parry window should open at the easy-mode gold cue timing")
			quit(1)
			return
	boss.attack_elapsed = 0.881
	if boss.is_attack_parry_window_open():
		push_error("Boss attack parry window should close after the active hit window")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-60.0, 0.0)
	boss.facing = -1.0
	await physics_frame
	boss.attack_cooldown = 99.0
	boss._start_normal_attack("attack")
	await physics_frame
	boss.attack_elapsed = 0.619
	player._start_parry()
	player.parry_elapsed = 0.08
	var player_health_before_parry: float = player.health
	var boss_posture_before_parry: float = boss.posture
	boss._update_attack_state(0.161)
	if player.health != player_health_before_parry:
		push_error("Perfect parry should not damage player health")
		quit(1)
		return
	if boss.posture <= boss_posture_before_parry:
		push_error("Perfect parry should add Boss posture")
		quit(1)
		return
	if boss.is_attack_winding_up or boss.is_attack_active:
		push_error("Perfect parry should interrupt Boss attack")
		quit(1)
		return
	if boss.hitstop_timer <= 0.09 or player.hitstop_timer <= 0.09:
		push_error("Perfect parry should trigger a stronger local hitstop on both actors")
		quit(1)
		return
	if player.action_timer > player.parry_success_recovery_time + 0.001:
		push_error("Perfect parry should shorten the player's remaining recovery")
		quit(1)
		return
	if boss.feedback_timer < 0.44:
		push_error("Perfect parry should leave the Boss in a readable parried recovery")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-60.0, 0.0)
	boss.facing = -1.0
	await physics_frame
	boss.attack_cooldown = 99.0
	boss._start_normal_attack("attack")
	await physics_frame
	boss.attack_elapsed = 0.779
	player._start_parry()
	player.parry_elapsed = 0.34
	var boss_posture_before_early_parry: float = boss.posture
	boss._update_attack_state(0.002)
	if boss.posture - boss_posture_before_early_parry >= boss.normal_attack_parry_posture_damage:
		push_error("Early parry input before the gold cue should not count as a perfect parry")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-60.0, 0.0)
	boss.facing = -1.0
	await physics_frame
	boss.attack_cooldown = 99.0
	boss._start_normal_attack("attack")
	await physics_frame
	var player_health_before_hit: float = player.health
	var player_posture_before_hit: float = player.posture
	boss.attack_elapsed = 0.779
	boss._update_attack_state(0.002)
	if player.health >= player_health_before_hit:
		push_error("Raw Boss hit should damage player health")
		quit(1)
		return
	if player.posture <= player_posture_before_hit:
		push_error("Raw Boss hit should increase player posture")
		quit(1)
		return
	if player.state != player.PlayerState.HURT:
		push_error("Raw Boss hit should put player into hurt stun")
		quit(1)
		return
	if boss.hitstop_timer < 0.065 or player.hitstop_timer < 0.065:
		push_error("Raw Boss hit should trigger 70ms local hitstop")
		quit(1)
		return
	if boss.current_animation != "attack":
		push_error("Raw Boss hit should keep the Boss attack animation playing")
		quit(1)
		return
	boss.hitstop_timer = 0.0
	player.hitstop_timer = 0.0
	boss._update_attack_state(0.22)
	if boss.current_animation != "attack" or boss.sprite.frame < 6:
		push_error("Raw Boss hit should continue through the remaining attack frames")
		quit(1)
		return
	boss._update_attack_state(0.34)
	if not boss.is_attack_recovering:
		push_error("Boss should enter recovery only after the attack animation finishes")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
