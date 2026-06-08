extends SceneTree

func _initialize() -> void:
	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var main_scene: PackedScene = load("res://scenes/Main.tscn")
	if player_scene == null or main_scene == null:
		push_error("Player and Main scenes should load")
		quit(1)
		return

	var player: Node = player_scene.instantiate()
	get_root().add_child(player)
	await process_frame

	if not player.has_method("force_execution_thrust_attack"):
		push_error("Player should expose a shared execution thrust attack helper")
		quit(1)
		return
	player._start_attack()
	player.force_execution_thrust_attack()
	var sprite: AnimatedSprite2D = player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if player.current_attack_animation != "attack_thrust":
		push_error("Minor-enemy execute attacks should force the player's current attack to thrust")
		quit(1)
		return
	if sprite == null or sprite.animation != &"attack_thrust":
		push_error("Minor-enemy execute attacks should visibly play the player thrust animation")
		quit(1)
		return
	player.queue_free()
	await process_frame

	var main = main_scene.instantiate()
	get_root().add_child(main)
	await process_frame
	var main_player := main.get_node_or_null("Player") as Node2D
	if main_player == null:
		push_error("Main should have a player")
		quit(1)
		return
	main._play_player_final_execution_attack(main_player)
	await process_frame
	if main_player.get("current_attack_animation") != "attack_thrust":
		push_error("Boss final execution should force the player's attack to thrust")
		quit(1)
		return
	var main_sprite := main_player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if main_sprite == null or main_sprite.animation != &"attack_thrust":
		push_error("Boss final execution should visibly play the player thrust animation; got %s" % [main_sprite.animation if main_sprite != null else "<null>"])
		quit(1)
		return

	main.queue_free()
	await process_frame
	quit(0)
