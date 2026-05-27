extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var enemy_scene: PackedScene = load("res://scenes/Enemy.tscn")
	if player_scene == null or enemy_scene == null:
		push_error("Player and enemy scenes should load")
		quit(1)
		return

	var player = player_scene.instantiate()
	var enemy = enemy_scene.instantiate()
	get_root().add_child(player)
	get_root().add_child(enemy)
	await process_frame

	player.global_position = Vector2(100, 360)
	enemy.global_position = Vector2(150, 360)
	player.facing = 1.0
	enemy.is_attack_cue_active = true
	enemy.attack_visual.visible = true

	if not enemy.can_be_perfect_dodged_by(player):
		push_error("Enemy attack cue in range should be perfect-dodgeable")
		quit(1)
		return

	player._start_dash()
	if not player.is_perfect_dodging:
		push_error("Dash should become perfect dodge inside enemy attack cue")
		quit(1)
		return
	if player.perfect_dodge_timer <= 0.0:
		push_error("Perfect dodge should start a visible feedback timer")
		quit(1)
		return
	if player.velocity.x >= 0.0:
		push_error("Perfect dodge should backstep away from the enemy instead of dashing forward")
		quit(1)
		return
	if absf(player.stored_velocity.x) > 760.0:
		push_error("Perfect dodge backstep should be short enough to stay near the fight")
		quit(1)
		return
	if player.dash_timer > 0.18:
		push_error("Perfect dodge should finish quickly instead of sliding too far back")
		quit(1)
		return
	if player.hitstop_timer < 0.07:
		push_error("Perfect dodge should briefly freeze time like a parry")
		quit(1)
		return
	if enemy.dodge_spark_timer <= 0.0:
		push_error("Enemy should receive perfect dodge feedback")
		quit(1)
		return
	if enemy.posture < 8.0:
		push_error("Perfect dodge should add a small amount of enemy posture")
		quit(1)
		return

	player.queue_free()
	enemy.queue_free()
	await process_frame
	quit(0)
