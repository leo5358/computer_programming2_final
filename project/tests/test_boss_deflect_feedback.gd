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

	boss.guard_chance = 1.0
	boss.guard_lockout_duration = 0.0
	var guard_result: Variant = boss.receive_player_attack(16.0, 18.0)
	if not (guard_result is Dictionary and bool(guard_result.get("guarded", false))):
		push_error("Boss should guard when guard chance is forced to 100%%")
		quit(1)
		return
	var guarded_animation: String = boss.current_animation
	if guarded_animation != "deflect1" and guarded_animation != "deflect2":
		push_error("Boss successful guard should play deflect animation, got %s" % guarded_animation)
		quit(1)
		return
	if boss.feedback_timer < 0.5:
		push_error("Boss successful guard should keep deflect readable for at least 0.5 seconds")
		quit(1)
		return
	boss._physics_process(0.10)
	if boss.current_animation != guarded_animation:
		push_error("Boss successful guard should keep deflect animation during feedback instead of switching to hurt")
		quit(1)
		return

	boss.reset_combat_state()
	boss.guard_chance = 0.0
	var hit_result: Variant = boss.receive_player_attack(16.0, 18.0)
	if hit_result is Dictionary and bool(hit_result.get("guarded", false)):
		push_error("Boss direct hit with 0%% guard chance should not be guarded")
		quit(1)
		return
	if boss.current_animation != "hurt":
		push_error("Boss direct hit should play hurt animation, got %s" % boss.current_animation)
		quit(1)
		return
	boss._physics_process(0.10)
	if boss.current_animation != "hurt":
		push_error("Boss direct hit should keep hurt animation during hurt feedback")
		quit(1)
		return

	boss.queue_free()
	await process_frame
	quit(0)
