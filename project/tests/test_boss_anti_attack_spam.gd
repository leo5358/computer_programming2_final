extends SceneTree

func _initialize() -> void:
	var boss_scene: PackedScene = load("res://scenes/Boss.tscn")
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	if boss_scene == null or player_scene == null:
		push_error("Boss and Player scenes should load")
		quit(1)
		return

	var main := Node2D.new()
	main.name = "BossAntiAttackSpamTest"
	get_root().add_child(main)
	var boss = boss_scene.instantiate()
	var player = player_scene.instantiate()
	main.add_child(boss)
	main.add_child(player)
	await process_frame

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-92.0, 0.0)
	boss.facing = -1.0
	boss.guard_chance = 1.0
	boss.guard_lockout_duration = 0.0
	boss.attack_cooldown = 99.0

	for index in 20:
		var result: Variant = boss.receive_player_attack(16.0, 18.0)
		if not (result is Dictionary and bool(result.get("guarded", false))):
			push_error("Boss should guard every spammed player attack when guard_chance is 100%%")
			quit(1)
			return
		boss.feedback_timer = 0.0
		boss.guard_lockout_timer = 0.0

	if boss.posture >= boss.max_posture:
		push_error("Guarded player attack spam should not fill Boss posture")
		quit(1)
		return
	if boss.can_be_executed():
		push_error("Boss should not become executable from guarded attack spam")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-92.0, 0.0)
	boss.facing = -1.0
	boss.guard_chance = 1.0
	boss.guard_lockout_duration = 0.0
	boss.attack_cooldown = 99.0
	boss.receive_player_attack(16.0, 18.0)
	if boss.get("forced_counter_profile") == null:
		push_error("Boss deflect should expose a forced counter profile")
		quit(1)
		return
	if String(boss.get("forced_counter_profile")) != "attack":
		push_error("First Boss deflect should force a standard counter attack")
		quit(1)
		return
	if boss.attack_cooldown > 0.001:
		push_error("Boss deflect should prepare an immediate counter instead of waiting normal cooldown")
		quit(1)
		return
	var second_result: Variant = boss.receive_player_attack(16.0, 18.0)
	if not (second_result is Dictionary and bool(second_result.get("guarded", false))):
		push_error("Boss should keep guarding during deflect feedback")
		quit(1)
		return
	if String(boss.get("forced_counter_profile")) != "chop":
		push_error("Second consecutive Boss deflect should upgrade forced counter to chop")
		quit(1)
		return

	boss._physics_process(boss.deflect_feedback_time + 0.001)
	if not boss.is_attack_winding_up:
		push_error("Boss should counter after deflect feedback if player stays in range")
		quit(1)
		return
	if boss.current_attack_animation != "chop":
		push_error("Boss forced counter after repeated deflect should be chop")
		quit(1)
		return
	var counter_animation: String = boss.current_attack_animation
	boss.receive_player_attack(16.0, 18.0)
	if boss.current_attack_animation != counter_animation or not boss.is_attack_winding_up:
		push_error("Boss forced counter should not be interrupted by player attack spam")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-92.0, 0.0)
	boss.facing = -1.0
	boss.guard_chance = 1.0
	boss.guard_lockout_duration = 0.0
	boss.attack_cooldown = 99.0
	for index in 3:
		boss.receive_player_attack(16.0, 18.0)
		boss.feedback_timer = 0.0
		boss.guard_lockout_timer = 0.0
	if String(boss.get("forced_counter_profile")) != "thrust":
		push_error("Third consecutive Boss deflect should force a perilous thrust counter")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
