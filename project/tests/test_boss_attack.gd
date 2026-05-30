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

	for property_name in [
		"attack_range",
		"attack_cooldown",
		"attack_damage",
		"attack_posture_damage",
		"is_attack_winding_up",
		"is_attack_active",
		"attack_has_connected",
	]:
		if boss.get(property_name) == null:
			push_error("Boss V1 attack should expose %s" % property_name)
			quit(1)
			return
	if boss.attack_range < 132.0:
		push_error("Boss V1.2 normal attack should have monk-like long weapon range")
		quit(1)
		return
	if boss.attack_windup_time < 0.85:
		push_error("Boss V1.2 normal attack should have a readable heavy windup")
		quit(1)
		return
	if boss.attack_cooldown_duration < 1.30:
		push_error("Boss V1.2 normal attack should leave a meaningful recovery/counter window")
		quit(1)
		return
	if boss.get("chase_speed") == null or boss.get("is_chasing") == null:
		push_error("Boss V1.3 should expose chase state and speed")
		quit(1)
		return
	if boss.get("attack_start_distance") == null or boss.get("attack_step_distance") == null:
		push_error("Boss should expose real-hitbox attack distance and windup step tuning")
		quit(1)
		return
	if boss.attack_start_distance > 90.0:
		push_error("Boss should not start normal attack farther than the calibrated hitbox can reach")
		quit(1)
		return

	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-210.0, 0.0)
	boss.set("attack_cooldown", 0.0)
	var chase_start_x: float = boss.global_position.x
	for frame in 20:
		await physics_frame
	if not boss.get("is_chasing"):
		push_error("Boss V1.3 should chase players inside detection range but outside attack range")
		quit(1)
		return
	if boss.global_position.x >= chase_start_x - 8.0:
		push_error("Boss V1.3 should move toward the player while chasing")
		quit(1)
		return
	if boss.current_animation != "walk":
		push_error("Boss V1.3 should use walk animation while chasing")
		quit(1)
		return
	player.global_position = boss.global_position + Vector2(-72.0, 0.0)
	boss.attack_cooldown = 0.6
	for frame in 20:
		await physics_frame
	if boss.facing != -1.0:
		push_error("Boss should keep facing the nearby player during attack cooldown instead of flickering back to patrol")
		quit(1)
		return
	if absf(boss.velocity.x) > 1.0:
		push_error("Boss should hold position when the player is already in close engagement range")
		quit(1)
		return

	boss.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-126.0, 0.0)
	boss.set("attack_cooldown", 0.0)
	for frame in 8:
		await physics_frame
	if boss.get("is_attack_winding_up"):
		push_error("Boss should keep chasing at 126px because the calibrated hitbox cannot reach that far")
		quit(1)
		return
	if not boss.get("is_chasing"):
		push_error("Boss should chase instead of attacking when just outside calibrated range")
		quit(1)
		return

	boss.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-84.0, 0.0)
	boss.set("attack_cooldown", 0.0)

	var start_health: float = player.health
	var start_posture: float = player.posture
	var attack_start_x: float = boss.global_position.x
	for frame in 14:
		await physics_frame

	if boss.get("is_attack_winding_up"):
		push_error("Boss should pause under pressure before starting an in-range attack")
		quit(1)
		return
	if float(boss.get("attack_pressure_timer")) <= 0.0:
		push_error("Boss should expose pressure pause while preparing an in-range attack")
		quit(1)
		return

	for frame in 60:
		await physics_frame
		if boss.get("is_attack_winding_up"):
			break

	if not boss.get("is_attack_winding_up"):
		push_error("Boss should start attack windup after the pressure pause")
		quit(1)
		return
	if boss.current_animation != "attack":
		push_error("Boss should play attack animation during normal attack windup")
		quit(1)
		return
	for frame in 14:
		await physics_frame
	if absf(boss.velocity.x) > 0.01:
		push_error("Boss should finish the short windup step quickly, then stop during attack windup")
		quit(1)
		return
	if boss.global_position.x > attack_start_x - 8.0:
		push_error("Boss should take a short forward step at the start of normal attack windup")
		quit(1)
		return
	if boss.global_position.x < attack_start_x - 30.0:
		push_error("Boss windup step should be short, not a sudden long slide")
		quit(1)
		return
	if player.health != start_health or player.posture != start_posture:
		push_error("Boss should not damage the player before the attack connects")
		quit(1)
		return

	for frame in 90:
		await physics_frame
		if boss.get("attack_has_connected"):
			break

	if not boss.get("attack_has_connected"):
		push_error("Boss normal attack should connect on its configured hit frame")
		quit(1)
		return
	if player.health >= start_health:
		push_error("Boss normal attack should reduce player health on hit")
		quit(1)
		return
	if player.posture <= start_posture:
		push_error("Boss normal attack should add player posture on hit")
		quit(1)
		return

	var health_after_hit: float = player.health
	for frame in 20:
		await physics_frame
	if player.health != health_after_hit:
		push_error("Boss normal attack should only hit once per swing")
		quit(1)
		return

	for frame in 120:
		await physics_frame
		if not boss.get("is_attack_winding_up") and not boss.get("is_attack_active") and not boss.get("is_attack_recovering"):
			break
	if boss.get("is_attack_winding_up") or boss.get("is_attack_active") or boss.get("is_attack_recovering"):
		push_error("Boss normal attack should finish and leave attack state")
		quit(1)
		return
	if boss.current_animation != "walk":
		push_error("Boss should resume patrol animation after normal attack recovery")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
