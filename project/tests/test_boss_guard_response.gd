extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Boss.tscn")
	if scene == null:
		push_error("Boss scene should load")
		quit(1)
		return

	var boss = scene.instantiate()
	get_root().add_child(boss)
	await process_frame

	if boss.get("guard_chance") == null:
		push_error("Boss should expose guard_chance like Warrior")
		quit(1)
		return
	if not is_equal_approx(float(boss.get("guard_chance")), 0.8):
		push_error("Boss default guard chance should be 80%%")
		quit(1)
		return

	boss.guard_chance = 1.0
	boss.guard_lockout_duration = 0.0
	var posture_before_guard: float = boss.posture
	var guard_result: Variant = boss.receive_player_attack(16.0, 18.0)
	if not (guard_result is Dictionary and bool(guard_result.get("guarded", false))):
		push_error("Boss guarded player attack should return guarded dictionary")
		quit(1)
		return
	if boss.current_animation != "deflect1" and boss.current_animation != "deflect2":
		push_error("Boss guarded player attack should play deflect animation")
		quit(1)
		return
	if boss.posture <= posture_before_guard:
		push_error("Boss guarded player attack should still add posture")
		quit(1)
		return
	if boss.feedback_timer <= 0.0:
		push_error("Boss guarded player attack should create a readable deflect pause")
		quit(1)
		return

	boss.reset_combat_state()
	boss.guard_chance = 0.0
	var health_before_hit: float = boss.health
	var hit_result: Variant = boss.receive_player_attack(16.0, 18.0)
	if hit_result is Dictionary and bool(hit_result.get("guarded", false)):
		push_error("Boss direct hit with 0%% guard chance should not be guarded")
		quit(1)
		return
	if boss.current_animation != "hurt":
		push_error("Boss direct hit should play hurt animation")
		quit(1)
		return
	if boss.health >= health_before_hit:
		push_error("Boss direct hit should still reduce health before the no-kill floor")
		quit(1)
		return

	boss.health = 4.0
	boss.posture = 0.0
	boss.guard_chance = 0.0
	boss.receive_player_attack(999.0, 1.0)
	if boss.defeated_flag:
		push_error("Boss should not be defeated by raw player attack damage")
		quit(1)
		return
	if boss.health < boss.minimum_health_from_player_attack:
		push_error("Boss raw player attack should leave minimum health for posture execution")
		quit(1)
		return

	boss.posture = boss.max_posture
	boss.execute()
	if not boss.defeated_flag:
		push_error("Boss should still be defeated by posture execute")
		quit(1)
		return

	boss.queue_free()
	await process_frame
	quit(0)
