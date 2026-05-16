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

	var attack_visual: ColorRect = boss.get_node_or_null("AttackVisual") as ColorRect
	if attack_visual == null:
		push_error("Boss should expose AttackVisual for attack cue feedback")
		quit(1)
		return

	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-92.0, 0.0)
	boss.attack_cooldown = 0.0
	for frame in 8:
		await physics_frame
		if boss.is_attack_winding_up:
			break

	if not boss.is_attack_winding_up:
		push_error("Boss should enter windup for attack cue test")
		quit(1)
		return
	if not attack_visual.visible:
		push_error("Boss attack cue should show AttackVisual during windup")
		quit(1)
		return
	if attack_visual.position.x * boss.facing <= 0.0:
		push_error("Boss AttackVisual should be placed in front of the boss")
		quit(1)
		return
	var attack_area := boss.get_node_or_null("AttackArea") as Area2D
	var attack_shape_node := boss.get_node_or_null("AttackArea/CollisionShape2D") as CollisionShape2D
	var attack_shape := attack_shape_node.shape as RectangleShape2D if attack_shape_node != null else null
	if attack_area == null or attack_shape == null:
		push_error("Boss should expose an attack hitbox for debug and collision")
		quit(1)
		return
	if attack_shape.size.x > 134.0:
		push_error("Boss normal attack hitbox should match attack.png fifth-frame weapon reach, not the old oversized range")
		quit(1)
		return
	if attack_shape.size != Vector2(66.0, 80.0):
		push_error("Boss normal attack hitbox should use the right half of the original gold frame")
		quit(1)
		return
	if attack_area.position != Vector2(87.0 * boss.facing, -36.0):
		push_error("Boss normal attack hitbox should keep the forward edge of the original gold frame fixed")
		quit(1)
		return
	var hitbox_left: float = attack_area.position.x - attack_shape.size.x * 0.5
	var hitbox_top: float = attack_area.position.y - attack_shape.size.y * 0.5
	if absf(hitbox_left - attack_visual.position.x) > 0.01 or absf(hitbox_top - attack_visual.position.y) > 0.01 or absf(attack_shape.size.x - attack_visual.size.x) > 0.01 or absf(attack_shape.size.y - attack_visual.size.y) > 0.01:
		push_error("Boss AttackVisual gold frame should exactly match the actual AttackArea hitbox")
		quit(1)
		return

	for frame in 90:
		await physics_frame
		if boss.attack_has_connected:
			break
	if not boss.attack_has_connected:
		push_error("Boss attack should connect for active visual test")
		quit(1)
		return
	if not attack_visual.visible:
		push_error("Boss AttackVisual should remain visible during active frames")
		quit(1)
		return

	for frame in 160:
		await physics_frame
		if not boss.is_attack_winding_up and not boss.is_attack_active and not boss.is_attack_recovering:
			break
	if attack_visual.visible:
		push_error("Boss AttackVisual should hide after attack recovery")
		quit(1)
		return

	boss.reset_combat_state()
	player.reset_combat_state()
	boss.global_position = Vector2(520.0, 360.0)
	boss.spawn_position = boss.global_position
	player.global_position = boss.global_position + Vector2(-92.0, 0.0)
	boss.attack_cooldown = 0.0
	for frame in 8:
		await physics_frame
		if boss.is_attack_winding_up:
			break
	for frame in 20:
		await physics_frame
	player._start_parry()
	player.action_timer = 1.0
	for frame in 90:
		await physics_frame
		if boss.posture >= 32.0:
			break

	if boss.is_attack_winding_up or boss.is_attack_active:
		push_error("Perfect parry should interrupt Boss normal attack")
		quit(1)
		return
	if attack_visual.visible:
		push_error("Perfect parry should hide Boss AttackVisual")
		quit(1)
		return
	if boss.posture < 32.0:
		push_error("Perfect parry should add significant Boss posture")
		quit(1)
		return
	if boss.current_animation != "deflect1" and boss.current_animation != "deflect2":
		push_error("Perfect parry should play a Boss deflect animation")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
