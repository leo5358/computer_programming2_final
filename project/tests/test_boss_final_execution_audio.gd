extends SceneTree

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	if main_scene == null:
		push_error("Main scene should load")
		quit(1)
		return

	var main = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame

	var player := main.get_node_or_null("Player") as Node2D
	if player == null:
		push_error("Main should have a player")
		quit(1)
		return

	main._play_player_final_execution_attack(player)
	await process_frame

	var attack_sfx := player.get_node_or_null("AttackSfx") as AudioStreamPlayer2D
	if attack_sfx == null:
		push_error("Final execution player thrust should have normal attack SFX")
		quit(1)
		return
	if attack_sfx.playing:
		push_error("Final execution attack SFX should wait for the slow-motion impact timing")
		quit(1)
		return
	await create_timer(1.25).timeout
	if not attack_sfx.playing:
		push_error("Final execution player thrust should play normal attack SFX after the impact delay")
		quit(1)
		return
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.animation != &"attack_thrust" or sprite.frame < 4:
		push_error("Final execution impact SFX should line up with the visible thrust impact frame")
		quit(1)
		return

	var final_sfx := player.get_node_or_null("FinalExecutionSfx") as AudioStreamPlayer2D
	if final_sfx == null or final_sfx.stream == null or final_sfx.stream.resource_path != "res://assets/sfx/final.mp3":
		push_error("Final execution player thrust should play final.mp3")
		quit(1)
		return
	if not final_sfx.playing:
		push_error("Final execution final.mp3 SFX should be playing")
		quit(1)
		return

	while player.get_node_or_null("AnimatedSprite2D").speed_scale < 1.0:
		await process_frame
	attack_sfx.stop()
	for frame in 20:
		await physics_frame
	if attack_sfx.playing and attack_sfx.stream != null and attack_sfx.stream.resource_path.begins_with("res://assets/sfx/attack_miss"):
		push_error("Final execution should not resume player attack state and play a late attack_miss SFX")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
