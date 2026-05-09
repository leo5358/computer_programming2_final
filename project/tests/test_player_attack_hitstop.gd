extends SceneTree

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Player.tscn")
	if scene == null:
		push_error("Player scene should load")
		quit(1)
		return

	var player = scene.instantiate()
	get_root().add_child(player)
	await process_frame

	player.current_attack_animation = "attack_a"
	player.velocity = Vector2(180.0, 0.0)
	player._trigger_attack_hit_feedback()
	if player.hitstop_timer != 0.0:
		push_error("Attack hit feedback should not pause the player's action timer")
		quit(1)
		return
	if player.sprite.speed_scale != 1.0:
		push_error("Attack hitstop should not alter the player's attack animation speed")
		quit(1)
		return

	player.sprite.speed_scale = 1.0
	player.current_attack_animation = "attack_chop"
	player.velocity = Vector2(180.0, 0.0)
	player._trigger_attack_hit_feedback()
	if player.hitstop_timer != 0.0:
		push_error("Chop hit feedback should not pause the player's action timer")
		quit(1)
		return

	player.set_physics_process(false)
	player.get_node("AnimatedSprite2D").sprite_frames = null
	player.queue_free()
	await process_frame
	quit(0)
