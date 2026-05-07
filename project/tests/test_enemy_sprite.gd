extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Enemy.tscn")
	if scene == null:
		push_error("Enemy scene should load")
		quit(1)
		return

	var enemy = scene.instantiate()
	get_root().add_child(enemy)
	await process_frame

	var sprite: AnimatedSprite2D = enemy.get_node("AnimatedSprite2D")
	if sprite.sprite_frames == null:
		push_error("Enemy should build sprite frames from enemy_sheet.png")
		quit(1)
		return
	for animation in ["idle", "walk", "attack", "attack_cue", "stunned", "death"]:
		if not sprite.sprite_frames.has_animation(animation):
			push_error("Enemy should have %s animation" % animation)
			quit(1)
			return

	enemy._update_movement(0.1)
	if enemy.velocity.x == 0.0:
		push_error("Enemy should patrol when no target is nearby")
		quit(1)
		return

	enemy.velocity = Vector2.ZERO
	enemy._physics_process(0.1)
	if enemy.velocity.y <= 0.0:
		push_error("Enemy should apply gravity when not on floor")
		quit(1)
		return

	enemy.set_physics_process(false)
	sprite.sprite_frames = null
	enemy.queue_free()
	await process_frame
	quit(0)
