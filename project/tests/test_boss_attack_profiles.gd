extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossAttackProfilesTest"
	get_root().add_child(main)
	var boss = boss_scene.instantiate()
	var player = player_scene.instantiate()
	main.add_child(boss)
	main.add_child(player)
	await process_frame

	for profile_name in ["attack", "chop", "thrust"]:
		if not boss.has_attack_profile(profile_name):
			push_error("Boss should expose attack profile: %s" % profile_name)
			quit(1)
			return

	boss.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-60.0, 0.0)
	boss.facing = -1.0
	await physics_frame
	boss._start_normal_attack("chop")
	await physics_frame
	if boss.current_attack_animation != "chop":
		push_error("Forced chop profile should play chop animation")
		quit(1)
		return
	if not is_equal_approx(boss.attack_animation_total_time, 2.185):
		push_error("Chop profile should use its custom 2185ms duration timeline")
		quit(1)
		return
	boss.attack_elapsed = 1.539
	boss._sync_attack_animation_frame()
	if boss.sprite.frame != 4:
		push_error("Chop should still be airborne before the landing slash")
		quit(1)
		return
	boss.attack_elapsed = 1.320
	if not boss.is_attack_parry_window_open():
		push_error("Chop should open the cue/parry window before landing")
		quit(1)
		return
	boss.attack_elapsed = 1.540
	boss._sync_attack_animation_frame()
	if boss.sprite.frame != 5:
		push_error("Chop should enter landing slash frame at hit start")
		quit(1)
		return
	boss.attack_elapsed = 1.200
	boss._sync_attack_animation_frame()
	if boss.sprite.offset.y > -90.0:
		push_error("Chop airborne frames should lift the Boss higher than the player")
		quit(1)
		return
	boss.attack_elapsed = 1.550
	player._start_parry()
	player.parry_elapsed = 0.05
	var boss_posture_before_chop_parry: float = boss.posture
	player.receive_enemy_attack(boss.attack_damage, boss.attack_posture_damage, boss, 0)
	if boss.posture <= boss_posture_before_chop_parry:
		push_error("Parrying Boss chop should add Boss posture")
		quit(1)
		return
	if boss.current_animation != "chop" or not bool(boss.get("is_chop_parried_recovery_boss")):
		push_error("Parrying Boss chop should continue through chop recovery instead of switching to deflect")
		quit(1)
		return
	if boss.is_attack_winding_up or boss.is_attack_active:
		push_error("Parried Boss chop recovery should not keep the hitbox active")
		quit(1)
		return
	if player.stored_velocity.x >= 0.0:
		push_error("Parrying Boss chop should knock the player away from the Boss")
		quit(1)
		return
	player._physics_process(player.hitstop_timer + 0.01)
	if player.velocity.x >= -player.heavy_parry_rebound + 1.0:
		push_error("Parrying Boss chop should keep heavy recoil after hitstop ends")
		quit(1)
		return
	var hit_impact := player.get_node_or_null("HitImpactVfx") as AnimatedSprite2D
	if hit_impact == null or not hit_impact.visible or hit_impact.animation != "chop":
		push_error("Parrying Boss chop should show the chop hit impact VFX")
		quit(1)
		return
	var parry_distance_before: float = absf(player.global_position.x - boss.global_position.x)
	for frame in 24:
		await physics_frame
	var parry_distance_after: float = absf(player.global_position.x - boss.global_position.x)
	if parry_distance_after < parry_distance_before + 90.0:
		push_error("Parrying Boss chop should visibly knock both actors apart")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-310.0, 0.0)
	boss.facing = -1.0
	boss.attack_cooldown = 0.0
	await physics_frame
	if not boss._should_start_attack():
		push_error("Boss should be able to start chop from mid range")
		quit(1)
		return
	boss._start_normal_attack()
	if boss.current_attack_animation != "chop":
		push_error("Boss should prefer chop as a mid-range gap closer")
		quit(1)
		return
	boss.attack_elapsed = boss.chop_lunge_start_boss + 0.02
	boss._update_attack_state(0.05)
	if boss.velocity.x >= 0.0:
		push_error("Boss chop airborne frames should lunge toward the player")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-60.0, 0.0)
	boss.facing = -1.0
	await physics_frame
	boss._start_normal_attack("thrust")
	await physics_frame
	if boss.current_attack_animation != "thrust":
		push_error("Forced thrust profile should play thrust animation")
		quit(1)
		return
	if not boss.is_current_attack_perilous():
		push_error("Thrust profile should be a perilous attack")
		quit(1)
		return
	if not is_equal_approx(boss.attack_animation_total_time, 1.40):
		push_error("Thrust profile should use a readable 1400ms timeline")
		quit(1)
		return
	boss.attack_elapsed = 0.420
	boss._update_attack_visual(true, false)
	var warning_label := boss.get_node_or_null("DebugResponseLabel") as Label
	if warning_label == null or not warning_label.visible:
		push_error("Thrust cue should show the perilous warning label")
		quit(1)
		return
	boss.attack_elapsed = 0.810
	if boss.is_attack_active:
		push_error("Thrust should still be in readable pre-hit windup before 820ms")
		quit(1)
		return
	player._start_block()
	var player_health_before_block: float = player.health
	boss.attack_elapsed = 0.819
	boss._update_attack_state(0.002)
	if player.health >= player_health_before_block:
		push_error("Blocking a perilous thrust should not prevent health damage")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
