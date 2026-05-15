extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Boss.tscn")
	if scene == null:
		push_error("Boss scene should load")
		quit(1)
		return

	var boss: Node = scene.instantiate()
	get_root().add_child(boss)
	await process_frame
	if boss.get_node("AnimatedSprite2D").position.y >= -60.0:
		pass
	else:
		push_error("Boss sprite should be lowered so the feet sit on the ground")
		quit(1)
		return

	boss.current_boss_attack = boss.BossAttack.THRUST
	boss._start_attack_cue()
	var label: Label = boss.get_node("DebugResponseLabel")
	if not label.visible or label.text != "DODGE":
		push_error("Thrust cue should tell the player to dodge")
		quit(1)
		return
	var shape := boss.get_node("AttackArea/CollisionShape2D").shape as RectangleShape2D
	if shape.size.x < 150.0 or shape.size.y > 50.0:
		push_error("Thrust hitbox should be long and narrow")
		quit(1)
		return
	if boss.attack_cue_time > 0.45:
		push_error("Boss cue should fit inside the player's immediate parry window")
		quit(1)
		return
	boss._connect_attack_on_hit_frame()

	boss.current_boss_attack = boss.BossAttack.CHOP
	boss._start_attack_cue()
	if label.text != "PARRY":
		push_error("Chop cue should tell the player to parry")
		quit(1)
		return
	if shape.size.y < 90.0:
		push_error("Chop hitbox should cover a taller arc")
		quit(1)
		return
	var attack_texture: AtlasTexture = boss.sprite.sprite_frames.get_frame_texture("attack1", 0)
	if attack_texture.region.position.x <= 0.0 or attack_texture.region.size.x >= 128.0:
		push_error("Boss attack atlas region should be inset to avoid neighboring-frame bleed")
		quit(1)
		return

	boss.current_boss_attack = boss.BossAttack.ATTACK1
	boss._start_attack_windup()
	if boss.sprite.speed_scale >= 0.5:
		push_error("Boss attack windup should slow the animation instead of delaying damage after a finished swing")
		quit(1)
		return
	if boss.attack_has_connected:
		push_error("Boss attack should not connect before the configured hit frame")
		quit(1)
		return

	boss.deflect_chance = 1.0
	if boss.receive_player_attack(10.0, 10.0) != false:
		push_error("Boss deflect should not count as a confirmed player hit")
		quit(1)
		return

	boss.queue_free()
	await process_frame
	quit(0)
