extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	if scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main: Node = scene.instantiate()
	get_root().add_child(main)
	await process_frame

	var boss = main.get_node_or_null("Boss")
	var player = main.get_node_or_null("Player")
	if boss == null or player == null:
		push_error("Main scene should contain boss and player")
		quit(1)
		return

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

	if not is_equal_approx(boss.attack_animation_total_time, 0.84):
		push_error("Boss attack profile custom frame durations should total 840ms")
		quit(1)
		return

	var expected_frames := {
		0.099: 0,
		0.100: 1,
		0.239: 1,
		0.241: 2,
		0.459: 2,
		0.461: 3,
		0.504: 3,
		0.506: 4,
		0.539: 4,
		0.541: 5,
		0.609: 5,
		0.611: 6,
		0.709: 6,
		0.711: 7,
	}
	for elapsed in expected_frames.keys():
		boss.attack_elapsed = float(elapsed)
		boss._sync_attack_animation_frame()
		if boss.sprite.frame != int(expected_frames[elapsed]):
			push_error("Boss attack frame at %.3fs should be %d, got %d" % [float(elapsed), int(expected_frames[elapsed]), boss.sprite.frame])
			quit(1)
			return

	if not boss.is_attack_parry_window_open():
		boss.attack_elapsed = 0.360
		if not boss.is_attack_parry_window_open():
			push_error("Boss attack parry window should open at 360ms")
			quit(1)
			return
	boss.attack_elapsed = 0.541
	if boss.is_attack_parry_window_open():
		push_error("Boss attack parry window should close after the 540ms active hit window")
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
	boss.attack_elapsed = 0.375
	player._start_parry()
	player.parry_elapsed = 0.08
	var player_health_before_parry: float = player.health
	var boss_posture_before_parry: float = boss.posture
	boss._update_attack_state(0.085)
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
	boss.attack_elapsed = 0.459
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
	boss.attack_elapsed = 0.459
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
	boss._update_attack_state(0.19)
	if boss.current_animation != "attack" or boss.sprite.frame < 6:
		push_error("Raw Boss hit should continue through the remaining attack frames")
		quit(1)
		return
	boss._update_attack_state(0.30)
	if not boss.is_attack_recovering:
		push_error("Boss should enter recovery only after the attack animation finishes")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
