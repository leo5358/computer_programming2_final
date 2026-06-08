extends SceneTree

func _initialize() -> void:
	var scenes := [
		load("res://scenes/TorchmanEnemy.tscn"),
		load("res://scenes/WarriorEnemy.tscn"),
		load("res://scenes/ArcherEnemy.tscn"),
	]
	for enemy_scene in scenes:
		if enemy_scene == null:
			push_error("Enemy scenes should load")
			quit(1)
			return
		var enemy = enemy_scene.instantiate()
		get_root().add_child(enemy)
		await process_frame

		enemy.facing = 1.0
		enemy.guard_chance = 0.0
		var health_before: float = enemy.health
		enemy.receive_player_attack(1.0, 1.0)
		if enemy.health >= health_before:
			push_error("%s should take direct player attack damage" % enemy.name)
			quit(1)
			return
		if enemy.state != enemy.EnemyState.HURT:
			push_error("%s should enter HURT when directly hit" % enemy.name)
			quit(1)
			return
		if enemy.direct_hit_hurt_time < 0.24:
			push_error("%s should use a noticeable hurt duration" % enemy.name)
			quit(1)
			return
		if enemy.hit_recoil_timer < enemy.direct_hit_hurt_time - 0.01:
			push_error("%s should keep a real hurt recoil timer" % enemy.name)
			quit(1)
			return
		if absf(enemy.velocity.x) < enemy.direct_hit_recoil_force - 1.0:
			push_error("%s should be visibly knocked back by direct hits" % enemy.name)
			quit(1)
			return
		var sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if sprite == null or sprite.animation != "hurt" or sprite.frame != 0:
			push_error("%s should immediately restart hurt animation from frame 1" % enemy.name)
			quit(1)
			return
		enemy._physics_process(0.0)
		var first_hurt_alpha: float = sprite.modulate.a
		if first_hurt_alpha >= 0.95:
			push_error("%s should start a visible hit flicker when directly hit" % enemy.name)
			quit(1)
			return
		if sprite.modulate.r > 1.05 or sprite.modulate.g > 1.05 or sprite.modulate.b > 1.05:
			push_error("%s hit flicker should dim like the player instead of being hidden by an overbright flash" % enemy.name)
			quit(1)
			return
		enemy._physics_process(0.08)
		if is_equal_approx(sprite.modulate.a, first_hurt_alpha):
			push_error("%s hit flicker should alternate opacity while hurt feedback is active" % enemy.name)
			quit(1)
			return
		enemy._physics_process(enemy.direct_hit_hurt_time * 0.5)
		if enemy.state != enemy.EnemyState.HURT:
			push_error("%s should stay in HURT briefly instead of instantly resuming AI" % enemy.name)
			quit(1)
			return
		if enemy.display_name == "Warrior":
			if not ("direct_hit_thrust_lockout_time" in enemy) or enemy.direct_hit_thrust_lockout_time < 0.45:
				push_error("Warrior should have a direct-hit thrust lockout after being knocked back")
				quit(1)
				return
			enemy.hit_recoil_timer = 0.0
			enemy.attack_cooldown = 0.0
			enemy.target = Node2D.new()
			get_root().add_child(enemy.target)
			enemy.target.global_position = enemy.global_position + Vector2(enemy.attack_range + 24.0, 0.0)
			enemy._update_movement_state(enemy.direct_hit_thrust_lockout_time * 0.5)
			if enemy.current_attack_animation == "thrust" or enemy.state == enemy.EnemyState.ATTACK:
				push_error("Warrior should not immediately thrust after being directly hit")
				quit(1)
				return
			enemy.target.queue_free()

		enemy.queue_free()
		await process_frame

	quit(0)
