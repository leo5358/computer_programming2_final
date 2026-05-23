extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var warrior_scene: PackedScene = load("res://scenes/WarriorEnemy.tscn")
	if player_scene == null or warrior_scene == null:
		push_error("Player and Warrior scenes should load")
		quit(1)
		return

	var player: Node2D = player_scene.instantiate()
	var warrior: Node2D = warrior_scene.instantiate()
	get_root().add_child(player)
	get_root().add_child(warrior)
	await process_frame

	player.global_position = Vector2(100.0, 360.0)
	warrior.global_position = Vector2(180.0, 360.0)
	warrior.facing = -1.0
	if not warrior.can_see_player():
		push_error("Warrior should see the player inside forward-facing vision")
		quit(1)
		return

	player.global_position = Vector2(260.0, 360.0)
	if warrior.can_see_player():
		push_error("Warrior should not see the player behind its facing direction")
		quit(1)
		return

	warrior.receive_alert()
	warrior.target = player
	player.global_position = Vector2(280.0, 360.0)
	warrior._update_combat_movement()
	if warrior.state != warrior.EnemyState.CHASE or warrior.velocity.x <= 0.0:
		push_error("Warrior should chase toward an alerted player outside ideal distance")
		quit(1)
		return

	var attack_area: Area2D = warrior.get_node_or_null("AttackArea") as Area2D
	var attack_visual: ColorRect = warrior.get_node_or_null("AttackVisual") as ColorRect
	if attack_area == null:
		push_error("Warrior should expose an AttackArea")
		quit(1)
		return
	if attack_visual == null:
		push_error("Warrior should expose an AttackVisual")
		quit(1)
		return
	warrior.facing = -1.0
	warrior._update_visuals()
	var left_attack_x: float = attack_area.position.x
	var left_visual_center_x: float = attack_visual.position.x + attack_visual.size.x * 0.5
	warrior.facing = 1.0
	warrior._update_visuals()
	var right_attack_x: float = attack_area.position.x
	var right_visual_center_x: float = attack_visual.position.x + attack_visual.size.x * 0.5
	if left_attack_x >= 0.0 or right_attack_x <= 0.0:
		push_error("Warrior attack hitbox should mirror with facing")
		quit(1)
		return
	if sign(left_visual_center_x) != sign(left_attack_x) or sign(right_visual_center_x) != sign(right_attack_x):
		push_error("Warrior gold attack visual should stay aligned with the real hitbox")
		quit(1)
		return

	warrior._start_attack()
	warrior.attack_elapsed = warrior.attack_cue_start - 0.02
	player.parry_elapsed = 0.04
	if warrior.can_be_perfect_parried_by(player):
		push_error("Warrior should not be perfect-parryable before the cue window")
		quit(1)
		return
	warrior.attack_elapsed = warrior.attack_hit_start
	if not warrior.can_be_perfect_parried_by(player):
		push_error("Warrior should be perfect-parryable during the cue/hit window")
		quit(1)
		return
	player.parry_elapsed = warrior.perfect_parry_input_leeway + 0.05
	if warrior.can_be_perfect_parried_by(player):
		push_error("Warrior should reject stale parry input")
		quit(1)
		return

	player.global_position = warrior.global_position + Vector2(48.0, 0.0)
	if not warrior.has_method("can_be_perfect_dodged_by") or not warrior.can_be_perfect_dodged_by(player):
		push_error("Warrior attack cue in range should be perfect-dodgeable")
		quit(1)
		return
	var posture_before: float = warrior.posture
	if not warrior.has_method("receive_dodge_feedback"):
		push_error("Warrior should accept perfect dodge feedback")
		quit(1)
		return
	warrior.receive_dodge_feedback()
	if warrior.posture <= posture_before:
		push_error("Perfect dodge feedback should add Warrior posture")
		quit(1)
		return

	warrior.queue_free()
	player.queue_free()
	await process_frame
	quit(0)
