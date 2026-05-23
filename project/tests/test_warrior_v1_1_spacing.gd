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

	warrior.global_position = Vector2(200.0, 360.0)
	player.global_position = Vector2(224.0, 360.0)
	warrior.receive_alert()
	warrior.target = player
	warrior.attack_cooldown = 0.0
	warrior._update_combat_movement()
	if warrior.state != warrior.EnemyState.FLEE or warrior.velocity.x >= 0.0:
		push_error("Warrior should backstep instead of attacking when the player is too close")
		quit(1)
		return

	player.global_position = Vector2(350.0, 360.0)
	warrior.attack_cooldown = 0.2
	warrior._update_combat_movement()
	if warrior.state != warrior.EnemyState.CHASE or warrior.velocity.x <= 0.0:
		push_error("Warrior should chase when alerted player is outside attack range")
		quit(1)
		return

	player.global_position = Vector2(350.0, 360.0)
	warrior.attack_cooldown = 0.0
	warrior._update_combat_movement()
	if warrior.state != warrior.EnemyState.ATTACK or warrior.current_attack_animation != "thrust":
		push_error("Warrior should use thrust to chase a player who tries to run just outside sword range")
		quit(1)
		return
	var attack_shape := warrior.get_node("AttackArea/CollisionShape2D").shape as RectangleShape2D
	if attack_shape == null or attack_shape.size.x < 118.0:
		push_error("Warrior thrust should extend the attack hitbox for anti-run chase pressure")
		quit(1)
		return
	if warrior.velocity.x <= 0.0:
		push_error("Warrior thrust should step forward during startup to catch retreating players")
		quit(1)
		return
	warrior._update_visuals()
	var sprite := warrior.get_node("AnimatedSprite2D") as AnimatedSprite2D
	if sprite.animation != "thrust":
		push_error("Warrior chase thrust should play thrust animation")
		quit(1)
		return

	player.global_position = Vector2(284.0, 360.0)
	warrior.attack_cooldown = 0.0
	warrior._update_combat_movement()
	if warrior.state != warrior.EnemyState.ATTACK or warrior.current_attack_animation != "attack":
		push_error("Warrior should attack from readable weapon range")
		quit(1)
		return

	if warrior.attack_cue_start < 0.52:
		push_error("Warrior cue should not appear too early; keep a readable windup before gold")
		quit(1)
		return
	if warrior.attack_hit_start - warrior.attack_cue_start < 0.14:
		push_error("Warrior gold cue should give enough time to press parry before hit")
		quit(1)
		return

	var attack_visual: ColorRect = warrior.get_node_or_null("AttackVisual") as ColorRect
	warrior.attack_elapsed = warrior.attack_cue_start
	warrior._update_attack(0.0)
	if attack_visual == null or not attack_visual.visible:
		push_error("Warrior gold cue should become visible at cue start")
		quit(1)
		return
	player.parry_elapsed = 0.04
	if not warrior.can_be_perfect_parried_by(player):
		push_error("Warrior should be perfect-parryable immediately after gold cue appears")
		quit(1)
		return

	warrior.queue_free()
	player.queue_free()
	await process_frame
	quit(0)
