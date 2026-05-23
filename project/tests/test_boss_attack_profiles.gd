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
	if not is_equal_approx(boss.attack_animation_total_time, 1.245):
		push_error("Chop profile should use its custom 1245ms duration timeline")
		quit(1)
		return
	boss.attack_elapsed = 0.819
	boss._sync_attack_animation_frame()
	if boss.sprite.frame != 2:
		push_error("Chop should still be in the heavy charge frame before 820ms")
		quit(1)
		return
	boss.attack_elapsed = 0.820
	if not boss.is_attack_parry_window_open():
		push_error("Chop should have a cue/parry window at its hit timing")
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
	boss.attack_elapsed = 0.420
	boss._update_attack_visual(true, false)
	var warning_label := boss.get_node_or_null("DebugResponseLabel") as Label
	if warning_label == null or not warning_label.visible or warning_label.text != "危":
		push_error("Thrust cue should show the perilous warning label")
		quit(1)
		return
	player._start_block()
	var player_health_before_block: float = player.health
	boss.attack_elapsed = 0.539
	boss._update_attack_state(0.002)
	if player.health >= player_health_before_block:
		push_error("Blocking a perilous thrust should not prevent health damage")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
