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
	await physics_frame

	var boss: Node2D = main._spawn_enemy(main.BOSS_SCENE, Vector2(760.0, 529.0)) as Node2D
	var player := main.get_node_or_null("Player") as Node2D
	if boss == null or player == null:
		push_error("Main should spawn a connected Boss and expose the player")
		quit(1)
		return
	player.global_position = boss.global_position + Vector2(-96.0, 0.0)
	boss.set("guard_chance", 0.0)
	boss.set("health", 8.0)
	boss.receive_player_attack(20.0, 0.0)
	await process_frame

	if not bool(main.get("is_boss_final_execution_playing")):
		push_error("Dropping Boss health to zero should start the final execution scene")
		quit(1)
		return
	if bool(boss.get("defeated_flag")):
		push_error("Boss should wait for final execution cutscene completion before defeated_flag is set")
		quit(1)
		return

	while bool(main.get("is_boss_final_execution_playing")):
		await process_frame

	if not bool(boss.get("defeated_flag")):
		push_error("Boss should be defeated after final execution scene completes")
		quit(1)
		return

	main.queue_free()
	await process_frame

	main = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	await physics_frame

	boss = main._spawn_enemy(main.BOSS_SCENE, Vector2(760.0, 529.0)) as Node2D
	player = main.get_node_or_null("Player") as Node2D
	if boss == null or player == null:
		push_error("Main should provide player and boss for real hit flow")
		quit(1)
		return
	player.global_position = boss.global_position + Vector2(-48.0, 0.0)
	player.set("facing", 1.0)
	player.set("base_attack_damage", 20.0)
	boss.set("guard_chance", 0.0)
	boss.set("health", 8.0)
	if player.has_method("_start_attack"):
		player._start_attack()
	await physics_frame
	player._apply_attack_hit()
	await process_frame

	if not bool(main.get("is_boss_final_execution_playing")):
		push_error("A real player attack that drops Boss health to zero should start the final execution scene")
		quit(1)
		return

	while bool(main.get("is_boss_final_execution_playing")):
		await process_frame

	if not bool(boss.get("defeated_flag")):
		push_error("Boss should be defeated after player-triggered final execution scene completes")
		quit(1)
		return

	main.queue_free()
	await process_frame

	main = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	await physics_frame

	boss = main._spawn_enemy(main.BOSS_SCENE, Vector2(760.0, 529.0)) as Node2D
	if boss == null:
		push_error("Main should spawn a Boss for posture-break final execution flow")
		quit(1)
		return
	boss.set("guard_chance", 0.0)
	boss.set("posture", boss.get("max_posture"))
	boss._break_posture_boss_internal()
	boss.receive_player_attack(20.0, 999.0)
	await process_frame

	if not bool(main.get("is_boss_final_execution_playing")):
		push_error("A posture-break follow-up attack should start the final execution scene")
		quit(1)
		return
	if bool(boss.get("defeated_flag")):
		push_error("Posture-break follow-up should not mark Boss defeated before the final execution scene")
		quit(1)
		return

	while bool(main.get("is_boss_final_execution_playing")):
		await process_frame

	if not bool(boss.get("defeated_flag")):
		push_error("Boss should be defeated after posture-break final execution scene completes")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
