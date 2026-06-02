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
	var save_manager: Node = get_root().get_node_or_null("SaveManager")
	if save_manager != null and save_manager.has_method("delete_save"):
		save_manager.delete_save()

	if main.get_node_or_null("Boss") != null:
		push_error("Enemy test field should start without default Boss")
		quit(1)
		return
	if main.get_node_or_null("TrainingDummy") != null:
		push_error("Enemy test field should not include the old default TrainingDummy")
		quit(1)
		return
	if main.get_node_or_null("Chapter1Map") == null:
		push_error("Enemy test field should include the chapter 1 foothill stairs map")
		quit(1)
		return

	main._spawn_enemy(main.WARRIOR_SCENE, Vector2(460, 360))
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != 1:
		push_error("Spawner should create a minor enemy")
		quit(1)
		return

	var enemy: Node = get_nodes_in_group("minor_enemy")[0]
	if not enemy.has_method("get_vision_rect"):
		push_error("Spawned enemy should expose vision rect for debug mode")
		quit(1)
		return

	var runtime: Node = get_nodes_in_group("combat_runtime")[0]
	runtime.reset_combat()
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != 0:
		push_error("Runtime reset should clear spawned minor enemies in test mode")
		quit(1)
		return

	main._spawn_enemy(main.BOSS_SCENE, Vector2(820, 360))
	await process_frame
	if get_nodes_in_group("boss").size() != 1:
		push_error("Spawner should create a Boss")
		quit(1)
		return
	main.reset_test_field()
	await process_frame
	if not main.has_method("_spawn_debug_boss"):
		push_error("Spawner should expose debug Boss spawning for key 0")
		quit(1)
		return
	main._spawn_debug_boss()
	await process_frame
	if get_nodes_in_group("boss").size() != 1:
		push_error("Debug Boss spawn should create exactly one Boss")
		quit(1)
		return
	var debug_boss: Node = get_nodes_in_group("boss")[0]
	if debug_boss.get("debug_fixed_attack_profile_boss") != "chop":
		push_error("Key 0 debug Boss should be locked to chop profile")
		quit(1)
		return
	if debug_boss.has_method("_choose_attack_profile_boss") and debug_boss._choose_attack_profile_boss() != "chop":
		push_error("Debug Boss should choose chop every time")
		quit(1)
		return
	if debug_boss.has_method("_choose_attack_profile_boss") and debug_boss._choose_attack_profile_boss() != "chop":
		push_error("Debug Boss should keep choosing chop after repeated choices")
		quit(1)
		return

	main.reset_test_field()
	await process_frame
	if get_nodes_in_group("minor_enemy").size() != 0 or get_nodes_in_group("boss").size() != 0:
		push_error("Reset should clear all spawned enemies and bosses")
		quit(1)
		return
	if main.get_node_or_null("TrainingDummy") != null:
		push_error("Reset should not recreate the removed TrainingDummy reference object")
		quit(1)
		return

	var player: Node = main.get_node_or_null("Player")
	if player == null:
		push_error("Main should include player for debug death test")
		quit(1)
		return
	if not main.has_method("_debug_kill_player"):
		push_error("Spawner should expose debug player death for checkpoint testing")
		quit(1)
		return
	player.set("health", player.get("max_health"))
	main._debug_kill_player()
	await process_frame
	if float(player.get("health")) > 0.0:
		push_error("Debug player death should force HP to zero")
		quit(1)
		return
	var death_overlay: CanvasLayer = main.get_node_or_null("DeathOverlay")
	if death_overlay == null or not death_overlay.visible:
		push_error("Player death should show the death overlay")
		quit(1)
		return
	var bgm: AudioStreamPlayer = main.get_node_or_null("BgmPlayer")
	if bgm == null:
		push_error("Main should include BgmPlayer for retry BGM restart")
		quit(1)
		return
	if not main.has_method("_retry_from_checkpoint"):
		push_error("Main should expose retry from checkpoint")
		quit(1)
		return
	player.set("spawn_position", Vector2(720, 571))
	bgm.stop()
	bgm.play(12.0)
	main._retry_from_checkpoint()
	await process_frame
	if not bgm.playing:
		push_error("Retry should restart the current map BGM")
		quit(1)
		return
	if bgm.get_playback_position() > 0.5:
		push_error("Retry should restart the current map BGM from the beginning")
		quit(1)
		return
	if death_overlay.visible:
		push_error("Retry should hide the death overlay")
		quit(1)
		return
	if float(player.get("health")) <= 0.0:
		push_error("Retry should revive the player")
		quit(1)
		return
	if (player as Node2D).global_position.distance_to(Vector2(720, 571)) > 1.0:
		push_error("Retry without a save should return player to current spawn_position")
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
